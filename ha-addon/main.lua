-- ha-addon/main.lua
local socket = require("socket")
local cjson  = require("cjson")

-- 1. パス解決：config/lrh_util.lua や config/config.lua を探せるようにする
local script_path = debug.getinfo(1).source:match("@?(.*[\\/])") or "./"
package.path = package.path .. ";" .. script_path .. "?.lua;" .. script_path .. "config/?.lua"

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
        client:settimeout(1)
        local body, err = client:receive("*a") -- ボディ全体を受け取る
        
        if not err and body then
            -- ヘッダーを飛ばしてJSON部分のみ抽出する簡易処理（あるいは全体パース）
            local json_start = body:find("{")
            if json_start then
                local json_str = body:sub(json_start)
                local ok, msg = pcall(cjson.decode, json_str)
                
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
        end
        client:send("HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK")
        client:close()
    end
    socket.sleep(0.01)
end
