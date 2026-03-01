-- gateways/gateway_tx.lua
local socket = require("socket")
local cjson = require("cjson")

-- ユーティリティ：コロン区切り16進数 -> バイナリ
local function to_bytes(str)
   local clean_str = str:gsub(":", "")
   return (clean_str:gsub("..", function(cc) return string.char(tonumber(cc, 16)) end))
end

-- デバイス初期化
local wdev = assert(require("usbir").open(1))
local cec = require("cec")
local cec_enabled = cec.init()

-- 物理送信実行
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
print("📡 Gateway TX: Listening on port 8080...")

while true do
    local client = server:accept()
    if client then
        client:settimeout(0.5)
        local line = client:receive()
        local content_length = 0
        while line and line ~= "" do
            local cl = line:match("Content%-Length: (%d+)")
            if cl then content_length = tonumber(cl) end
            line = client:receive()
        end
        
        if content_length > 0 then
            local body = client:receive(content_length)
            local ok, cmd = pcall(cjson.decode, body)
            if ok then physical_send(cmd.type, cmd.code) end
        end
        client:close()
    end
end
