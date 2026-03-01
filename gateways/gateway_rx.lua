local usbir = require("usbir")
local socket = require("socket.http")
local ltn12 = require("ltn12")
local cjson = require("cjson")

local rdev = assert(usbir.open(0))
local HA_URL = "http://homeassistant.local:8123/api/webhook/ir_remote_gateway"

while true do
    local data = rdev:receive()
    if data then
        local hex = (data:gsub('.', function(c) return string.format('%02x:', string.byte(c)) end):sub(1, -2))
        socket.request {
            url = HA_URL, method = "POST",
            headers = { ["Content-Type"] = "application/json" },
            source = ltn12.source.string(cjson.encode({ code = hex }))
        }
    end
end
