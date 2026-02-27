local socket = require("socket")
local remapper = require("remapper")
local cjson = require("cjson")

local function to_bytes(str)
   return (str:gsub("..", function(cc) return string.char(tonumber(cc, 16)) end))
end

-- デバイス初期化
remapper.wdev = assert(require("usbir").open(1))
local cec = require("cec")
if cec.init() then remapper.cec = cec end

local server = assert(socket.bind("*", 8080))
print("📡 Command Executor listening on port 8080...")

while true do
    local client = server:accept()
    if client then
        client:settimeout(2) -- 確実に最後まで読むためのタイムアウト
        
        local request_lines = {}
        local line
        local content_length = 0

        -- 1. ヘッダーを読み切る
        while true do
            line = client:receive()
            if not line or line == "" then break end -- 空行でヘッダー終了
            -- Content-Length を探す
            local cl = line:match("Content%-Length: (%d+)")
            if cl then content_length = tonumber(cl) end
        end

        -- 2. ボディ（JSON）を読み取る
        if content_length > 0 then
            local body, err = client:receive(content_length)
            if body then
                print("📩 受信JSON: " .. body)
                local status, cmd = pcall(cjson.decode, body)
                if status then
                    if cmd.type == "ir"  then remapper.send_ir(cmd.code) end
                    if cmd.type == "cec" then remapper.send_cec(to_bytes(code))  end
                    if cmd.type == "bt"  then remapper.send_bt(cmd.code) end
                else
                    print("❌ JSONパース失敗")
                end
            end
        end

        -- 3. HAにレスポンスを返して接続を閉じる
        client:send("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nOK")
        client:close()
    end
end
