-- gateways/gateway_rx.lua
local usbir = require("usbir")
local http = require("socket.http")
local ltn12 = require("ltn12")
local cjson = require("cjson")

local rdev = assert(usbir.open(0))
local ADDON_URL = "http://homeassistant.local:8888" 

print("📡 Gateway RX: Monitoring IR signals...")

while true do
    local data = rdev:receive()
    if data then
        -- コロン区切りに変換
        local hex = (data:gsub('.', function(c) return string.format('%02x:', string.byte(c)) end):sub(1, -2))
        
        print("📩 Captured: " .. hex)
        http.request {
            url = ADDON_URL,
            method = "POST",
            headers = { ["Content-Type"] = "application/json", ["Content-Length"] = tostring(#cjson.encode({code=hex})) },
            source = ltn12.source.string(cjson.encode({ code = hex }))
        }
    end
end
