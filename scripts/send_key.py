#!/usr/bin/python3
import sys
import dbus
import time
import argparse

class BtkKeyClient():
    def __init__(self):
        try:
            self.bus = dbus.SystemBus()
            self.btkservice = self.bus.get_object(
                'com.khronos31.btkbservice', '/com/khronos31/btkbservice')
            self.iface = dbus.Interface(self.btkservice, 'com.khronos31.btkbservice')
        except dbus.DBusException as e:
            print(f"Error: サーバーが見つかりません。btk_server.py を先に起動してください。\n{e}")
            sys.exit(1)

    def send_key(self, scancode, modifier=0):
        """通常のキーボード入力を送信 (Report ID 1)"""
        keys = [scancode, 0, 0, 0, 0, 0]
        self.iface.send_keys(modifier, keys)
        time.sleep(0.02)
        self.iface.send_keys(0, [0, 0, 0, 0, 0, 0])

    def send_consumer_key(self, scancode):
        """リモコン・コンシューマー入力を送信 (Report ID 3)"""
        # btk_server.py に追加したメソッドを呼び出す
        # 引数は (key_code, modifier) だが、Consumer系は基本modifier 0
        self.iface.send_consumer_key(scancode, 0)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Bluetooth HID Key Sender')
    parser.add_argument('code', type=int, help='Scancode to send (10進数)')
    parser.add_argument('--consumer', action='store_true', help='Use Consumer Control (Report ID 3)')
    parser.add_argument('--modifier', type=int, default=0, help='Modifier byte (default: 0)')

    args = parser.parse_args()
    client = BtkKeyClient()

    if args.consumer:
        print(f"Sending Consumer Key: {args.code}")
        client.send_consumer_key(args.code)
    else:
        print(f"Sending Keyboard Key: {args.code} (Modifier: {args.modifier})")
        client.send_key(args.code, args.modifier)

    print("Done.")
