#!/usr/bin/env lua

-- 1. パスの定義
local config_dir = "/etc/lua-remote-hub/"
local system_lua_dir = "/usr/share/lua-remote-hub/lua/"

-- 2. パス解決の設定
-- /etc (設定) -> システムのluaフォルダ -> 標準パス の順で探す
package.path = config_dir .. "?.lua;" .. 
               config_dir .. "?/init.lua;" .. 
               system_lua_dir .. "?.lua;" .. 
               package.path

-- Cモジュール (usbir.so) は標準のlibへ
package.cpath = "/usr/lib/lua/5.4/?.so;" .. package.cpath

local usbir = require("usbir")
local remapper = require("remapper")

-- 3. config.lua のロード
-- 存在しない場合はエラーを出して終了する
local status, config = pcall(require, "config")
if not status then
    print("Error: Configuration file not found at " .. config_dir .. "config.lua")
    os.exit(1)
end

-- ログ出力用関数
local function log(msg)
  print(string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S"), msg))
end

-- バイナリデータを16進数文字列に変換
local function to_hex(data)
  return (data:gsub('.', function(c)
    return string.format('%02X ', string.byte(c))
  end))
end

-- 受信用デバイスのオープン (必須)
local rdev, err = usbir.open(0)
if not rdev then
  log("❌ 受信用デバイスエラー (Index 0): " .. (err or "不明"))
  os.exit(1)
end

-- 送信用デバイスのオープン (必須)
local wdev, err = usbir.open(1)
if not wdev then
  log("❌ 送信用デバイスエラー (Index 1): " .. (err or "不明"))
  os.exit(1)
end

-- remapperに送信デバイスをセット
remapper.wdev = wdev

log("🚀 ir-remapper 起動成功")
log("📡 受信待機中...")

-- メインループ
while true do
  local recv_data = rdev:receive()
  if recv_data and #recv_data > 0 then
    local action = config.remap[recv_data] or config.current_mode[recv_data]

    if action then
      if type(action) == "function" then
        action(wdev, recv_data)
      elseif type(action) == "table" and action.code then
        local t, c = action.type, action.code
        if t == "IR" then
          wdev:send(c)
        elseif t == "BT" then
          -- 非同期実行でラグを防止
          os.execute(string.format("python3 /usr/share/lua-remote-hub/scripts/send_key.py %s &", c))
        end
      end
    end
  end
end
