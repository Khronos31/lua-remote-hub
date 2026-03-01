-- ha-addon/main.lua
local socket = require("socket")
local cjson  = require("cjson")

-- 1. パス解決：自身のディレクトリにある lrh_util.lua や config/ 配下を読み込めるようにする
local script_path = debug.getinfo(1).source:match("@?(.*[\\/])") or "./"
package.path = package.path .. ";" .. script_path .. "?.lua;" .. script_path .. "config/?.lua"

-- 2. ロジックの継承
local lrh = require("lrh_util") -- config/lrh_util.lua
local status, config = pcall(require, "config") -- config/config.lua

if not status then
    print("❌ Configuration file (config.lua) not found in config/ directory.")
    os.exit(1)
end

-- 3. 送信先（手足となるゲートウェイ）の定義
-- スティックPC（旧LRH端末）のIPアドレスを設定してください
local GATEWAY_TX_URL = config.gateway_tx_url

-- ログ出力
local function log(msg)
    print(string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S"), msg))
end

-- 命令送信関数（ゲートウェイへHTTP POST）
local function dispatch(target_type, code)
    local payload = cjson.encode({ type = target_type, code = code })
    log(string.format("🚀 Dispatching %s: %s", target_type, code))
    
    -- アドオン内蔵の curl を使用して非同期で送信（ラグ防止）
    local cmd = string.format("curl -s -X POST -d '%s' %s &", payload, GATEWAY_TX_URL)
    os.execute(cmd)
end

lrh.dispatcher = dispatch

-- 4. 信号受信用サーバー起動 (アドオンの Port: 8888 で待機)
local server = assert(socket.bind("*", 8888))
server:settimeout(0)
log("📡 LRH Logic Controller: Listening for signals on port 8888...")

-- メインループ
while true do
    local client = server:accept()
    if client then
        client:settimeout(1)
        local body, err = client:receive()
        
        if not err and body then
            -- 受信側（gateways/gateway_rx.lua）から届いたJSONをパース
            local ok, msg = pcall(cjson.decode, body)
            if ok and msg.code then
                local hex_code = msg.code:lower()
                log("📩 Received signal: " .. hex_code)
                
                -- 旧 main.lua の判定ロジックを継承
                -- 受信側が既に16進数文字列に変換しているため、バイナリ変換なしで比較
                local action = config.remap[hex_code] or config.current_mode[hex_code]

                if action then
                    if type(action) == "table" and action.code then
                        -- 送信コマンドの種別判定
                        local t = action.type:lower()
                        if t == "ir" or t == "cec" or t == "bt" then
                            dispatch(t, action.code)
                        end
                    elseif type(action) == "function" then
                        -- 関数形式のバインド（wdevの代わりにdispatchを呼ぶよう要調整）
                        action(hex_code)
                    end
                end
            end
        end
        -- レスポンスを返して接続を即座に解放
        client:send("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nOK")
        client:close()
    end
    socket.sleep(0.01) -- CPU負荷軽減
end
