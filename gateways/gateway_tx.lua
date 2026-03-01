local socket = require("socket")
local cjson = require("cjson")

local function to_bytes(str)
   local clean_str = str:gsub(":", "") -- コロン対応
   return (clean_str:gsub("..", function(cc) return string.char(tonumber(cc, 16)) end))
end

-- デバイス初期化 
local wdev = assert(require("usbir").open(1))
local cec = require("cec")
local cec_enabled = cec.init()

-- 送信実務関数
local function physical_send(target_type, code)
    if target_type == "ir" then
        wdev:send(to_bytes(code))
    elseif target_type == "cec" and cec_enabled then
        cec.transmit(code)
    elseif target_type == "bt" then
        local script = "/usr/share/lua-remote-hub/scripts/send_key.py"
        os.execute(string.format("/usr/bin/python3 %s %s &", script, code))
    end
end

local server = assert(socket.bind("*", 8080))
print("📡 Command Executor listening on port 8080...")

while true do
    local client = server:accept()
    if client then
        client:settimeout(0.1)
        
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
                    physical_send(cmd.type, cmd.code)
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
