-- ha-addon/main.lua
local socket = require("socket")
local cjson  = require("cjson")

-- 1. ログ出力用関数
local function log(msg)
  print(string.format("[%s] %s", os.date("%Y-%m-%d %H:%M:%S"), msg))
end

-- 2. パス解決：config/lrh_util.lua や config/config.lua を探せるようにする
package.path = package.path .. ";/lrh_controller/config/?.lua;./?.lua"

-- 3. モジュールとコンフィグのロード
local lrh = require("lrh_util")
local status, config = pcall(require, "config")
if not status then
  log("❌ Error: Configuration file (config.lua) not found.")
  os.exit(1)
end
lrh.gateway_tx_url = config.gateway_tx_url

-- 4. サーバー起動 (ポート 8888)
local server = assert(socket.bind("0.0.0.0", 8888))
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
      
      -- JSONパースと判定ロジック 
      local ok, msg = pcall(cjson.decode, body)
        
        if ok then
          -- 【ルートA】物理リモコン信号の判定
          if msg.code and not msg.type then
            local hex_code = msg.code:lower()
            log("📩 Signal Received: " .. hex_code)
            local action = config.remap[hex_code] or config.current_mode[hex_code]

            if action then
              if type(action) == "table" and action.code then
                lrh.dispatch(action.type:lower(), action.code)
              elseif type(action) == "function" then
                action(hex_code)
              end
            end
          elseif msg.type and msg.code then
            log("🎮 Command from HAOS: " .. msg.type .. " -> " .. msg.code)
            lrh.dispatch(msg.type:lower(), msg.code)
          elseif msg.key then
            log("🎮 Command from HAOS: " .. msg.type .. " -> " .. msg.key)
            local keys ={}
            for str in string.gmatch(msg.key, "([^.]+)") do
              table.insert(keys, str)
            end
            local hex_code = config[keys[1]][keys[2]][keys[3]]
            local action = config.remap[hex_code] or config.current_mode[hex_code]

            if action then
              if type(action) == "table" and action.code then
                lrh.dispatch(action.type:lower(), action.code)
              elseif type(action) == "function" then
                action(hex_code)
              end
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
