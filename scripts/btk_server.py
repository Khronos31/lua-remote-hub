#!/usr/bin/python3
#
# Bluetooth keyboard/Mouse emulator DBUS Service
#

from __future__ import absolute_import, print_function
from optparse import OptionParser, make_option
import os
import sys
import uuid
import dbus
import dbus.service
import dbus.mainloop.glib
import time
import socket
from gi.repository import GLib
from dbus.mainloop.glib import DBusGMainLoop
import logging
from logging import debug, info, warning, error
import socket

logging.basicConfig(level=logging.DEBUG)

class BTKbDevice():
    # change these constants
    MY_DEV_NAME = "Lua_Remote_Hub"

    # define some constants
    P_CTRL = 17  # Service port - must match port configured in SDP record
    P_INTR = 19  # Interrupt port - must match port configured in SDP record
    # dbus path of the bluez profile we will create
    # file path of the sdp record to load
    SDP_RECORD_PATH = "/usr/share/lua-remote-hub/scripts/sdp_record.xml"
    UUID = "00001124-0000-1000-8000-00805f9b34fb"

    def __init__(self):
        print("2. Setting up BT device")
        # 1. 先にデバイスを起動してアドレスを取得可能にする
        self.init_bt_device()
        # 2. 動的にアドレスを取得して保持する
        self.MY_ADDRESS = self.get_bdaddr()
        print(f"Using Bluetooth Address: {self.MY_ADDRESS}")
        # 3. プロファイル登録
        self.init_bluez_profile()

    def get_bdaddr(self):
        """hci0のBluetoothアドレスを動的に取得する"""
        try:
            # hciconfigを使用してアドレスを抽出
            output = subprocess.check_output(["hciconfig", "hci0"], encoding='utf-8')
            for line in output.split('\n'):
                if 'BD Address' in line:
                    return line.split()[2]
        except Exception as e:
            error(f"Failed to get Bluetooth address: {e}")
            # 取得失敗時のフォールバック（必要に応じて設定）
            return "00:00:00:00:00:00"

    # configure the bluetooth hardware device
    def init_bt_device(self):
        print("3. Configuring Device with safety delays")
        # デーモン起動直後の不安定な時間を避ける
        time.sleep(2)
        
        # 1. アダプタをリセットして確実に起動
        os.system("hciconfig hci0 down")
        time.sleep(1)
        os.system("hciconfig hci0 up")
        
        # 2. SSP (Secure Simple Pairing) を有効化
        # スタック回避のため、バックグラウンド実行 or タイムアウト付きで
        os.system("btmgmt ssp on >/dev/null 2>&1 &") 
        
        # 3. クラスと名前の設定
        os.system("hciconfig hci0 class 0x000540")
        os.system("hciconfig hci0 name " + BTKbDevice.MY_DEV_NAME)
        
        # 4. スキャン有効化
        os.system("hciconfig hci0 piscan")
        print("Initial configuration done.")

    # set up a bluez profile to advertise device capabilities from a loaded service record
    def init_bluez_profile(self):
        print("4. Configuring Bluez Profile")
        # setup profile options
        service_record = self.read_sdp_service_record()
        opts = {
            "AutoConnect": True,
            "ServiceRecord": service_record,
            "RequireAuthentication": True,  # 追加：認証を要求しない
            "RequireAuthorization": True,   # 追加：承認を要求しない
        }
        # retrieve a proxy for the bluez profile interface
        bus = dbus.SystemBus()
        manager = dbus.Interface(bus.get_object(
            "org.bluez", "/org/bluez"), "org.bluez.ProfileManager1")
        manager.RegisterProfile("/org/bluez/hci0", BTKbDevice.UUID, opts)
        print("6. Profile registered ")
        os.system("hciconfig hci0 class 0x002540")

    # read and return an sdp record from a file
    def read_sdp_service_record(self):
        print("5. Reading service record")
        try:
            fh = open(BTKbDevice.SDP_RECORD_PATH, "r")
        except:
            sys.exit("Could not open the sdp record. Exiting...")
        return fh.read()

    def setup_socket(self):
        self.scontrol = socket.socket(
            socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET, socket.BTPROTO_L2CAP)  # BluetoothSocket(L2CAP)
        self.sinterrupt = socket.socket(
            socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET, socket.BTPROTO_L2CAP)  # BluetoothSocket(L2CAP)
        self.scontrol.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sinterrupt.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        # bind these sockets to a port - port zero to select next available
        self.scontrol.bind((self.MY_ADDRESS, self.P_CTRL))
        self.sinterrupt.bind((self.MY_ADDRESS, self.P_INTR))

    # listen for incoming client connections
    def listen(self):
        # 1. 先にSocketを準備し、OSに「待ち受け中」であることを知らせる
        self.setup_socket()
        self.scontrol.listen(5)
        self.sinterrupt.listen(5)
        
        print("\033[0;33m7. Waiting for connections\033[0m")

        # 2. 接続を待機（テレビが反応すればここが動き出す）
        self.ccontrol, cinfo = self.scontrol.accept()
        print (
            "\033[0;32mGot a connection on the control channel from %s \033[0m" % cinfo[0])

        self.cinterrupt, cinfo = self.sinterrupt.accept()
        print (
            "\033[0;32mGot a connection on the interrupt channel from %s \033[0m" % cinfo[0])

    # send a string to the bluetooth host machine
    def send_string(self, message):
        try:
            self.cinterrupt.send(bytes(message))
        except OSError as err:
            error(err)
            self.listen()


class BTKbService(dbus.service.Object):

    def __init__(self):
        print("1. Setting up service")
        # set up as a dbus service
        bus_name = dbus.service.BusName(
            "com.khronos31.btkbservice", bus=dbus.SystemBus())
        dbus.service.Object.__init__(
            self, bus_name, "/com/khronos31/btkbservice")
        # create and setup our device
        self.device = BTKbDevice()
        # start listening for connections
        self.device.listen()

    @dbus.service.method('com.khronos31.btkbservice', in_signature='yay')
    def send_keys(self, modifier_byte, keys):
        print("Get send_keys request through dbus")
        print("key msg: ", keys)
        state = [ 0xA1, 1, 0, 0, 0, 0, 0, 0, 0, 0 ]
        state[2] = int(modifier_byte)
        count = 4
        for key_code in keys:
            if(count < 10):
                state[count] = int(key_code)
            count += 1
        self.device.send_string(state)
    
    @dbus.service.method('com.khronos31.btkbservice', in_signature='qq')
    def send_consumer_key(self, key_code, modifier=0):
        print(f"Get consumer_key request: {key_code}")
        # Report ID 3 (Consumer Control) のパケット構造
        # [Report ID, Key LSB, Key MSB]
        state = [0xA1, 3, 0, 0]
        state[2] = key_code & 0xFF
        state[3] = (key_code >> 8) & 0xFF
        
        # キー入力送信
        self.device.send_string(state)
        
        # キー離上送信 (重要)
        time.sleep(0.02)
        self.device.send_string([0xA1, 3, 0, 0])

    @dbus.service.method('com.khronos31.btkbservice', in_signature='yay')
    def send_mouse(self, modifier_byte, keys):
        state = [0xA1, 2, 0, 0, 0, 0]
        count = 2
        for key_code in keys:
            if(count < 6):
                state[count] = int(key_code)
            count += 1
        self.device.send_string(state)


# main routine
if __name__ == "__main__":
    # we an only run as root
    try:
        if not os.geteuid() == 0:
            sys.exit("Only root can run this script")

        DBusGMainLoop(set_as_default=True)
        myservice = BTKbService()
        loop = GLib.MainLoop()
        loop.run()
    except KeyboardInterrupt:
        sys.exit()
