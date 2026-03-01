-- ha-addon/main.lua
local socket = require("socket")
local cjson  = require("cjson")

-- 1. パス解決：config/lrh_util.lua や config/config.lua を探せるようにする
package.path = package.path .. ";/lrh_controller/config/?.lua;./?.lua"

-- 2. ログ出力用関数
local function log(msg)
    print(string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S"), msg))
end

-- 3. 送信実務（ゲートウェイへHTTP POST）
local function dispatch(target_type, code)
    -- config.lua がロードされた後に確定する URL を使用
    local status, config = pcall(require, "config")
    local tx_url = status and config.gateway_tx_url or "http://localhost:8080"
    
    local payload = cjson.encode({ type = target_type, code = code })
    log(string.format("🚀 Dispatching %s: %s to %s", target_type, code, tx_url))
    
    -- 非同期送信 (ラグ防止)
    local cmd = string.format("curl -s -X POST -d '%s' %s &", payload, tx_url)
    os.execute(cmd)
end

-- 4. HAOS API 呼び出し関数
local function call_ha_api(domain, service, data)
    local url = string.format("http://supervisor/core/api/services/%s/%s", domain, service)
    local payload = cjson.encode(data)
    local token = os.getenv("SUPERVISOR_TOKEN") or ""
    
    log(string.format("📡 HA API Call: %s/%s", domain, service))
    local cmd = string.format(
        "curl -s -X POST -H 'Authorization: Bearer %s' -H 'Content-Type: application/json' -d '%s' %s &",
        token, payload, url
    )
    os.execute(cmd)
end

-- 5. モジュールロードと注入
local lrh = require("lrh_util")
lrh.dispatcher = dispatch
lrh.ha_handler = call_ha_api

local status, config = pcall(require, "config")
if not status then
    log("❌ Error: Configuration file (config.lua) not found.")
    os.exit(1)
end

-- 6. サーバー起動 (ポート 8888)
local server = assert(socket.bind("*", 8888))
server:settimeout(0)
log("📡 LRH Logic Controller: Active on port 8888")

while true do
    local client = server:accept()
    if client then
        client:settimeout(0.5) -- タイムアウトを短く設定
        log("🔍 Connection attempt detected!") -- 接続があったら即ログ

        local line, err = client:receive() -- まず1行目（リクエストライン）を読む
        local content_length = 0

        if not err then
            log("📡 Request: " .. tostring(line))
            -- ヘッダーを読み飛ばしつつ Content-Length を探す
            while line and line ~= "" do
                local cl = line:match("Content%-Length: (%d+)")
                if cl then content_length = tonumber(cl) end
                line = client:receive()
            end
        end

        -- ボディがある場合は読み取る
        if content_length > 0 then
            local body = client:receive(content_length)
            log("📥 Payload: " .. (body or "empty"))
            
            -- JSONパースと判定ロジック (ここから先は既存と同じ)
            local ok, msg = pcall(cjson.decode, body)
                
                if ok then
                    -- 【ルートA】物理リモコン信号の判定
                    if msg.code and not msg.type then
                        local hex_code = msg.code:lower()
                        log("📩 Signal Received: " .. hex_code)
                        local action = config.remap[hex_code] or config.current_mode[hex_code]

                        if action then
                            if type(action) == "table" and action.code then
                                dispatch(action.type:lower(), action.code)
                            elseif type(action) == "function" then
                                action(hex_code)
                            end
                        end

                    -- 【ルートB】HAOS（UI/自動化）からの直接命令
                    elseif msg.type and msg.code then
                        log("🎮 Command from HAOS: " .. msg.type .. " -> " .. msg.code)
                        dispatch(msg.type:lower(), msg.code)
                    end
                end
        end

        -- 即座に応答して切断する
        client:send("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 13\r\nConnection: close\r\n\r\nLRH_LOGIC_OK\n")
        client:close()
        log("✅ Request handled and connection closed.")
    end
    socket.sleep(0.02)
end
