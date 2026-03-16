-- ha-addon/config/lrh_util.lua
local lrh_util = {}
local cjson = require("cjson")

-- ログ出力用関数
local function log(msg)
  print(string.format("[%s] [Util] %s", os.date("%Y-%m-%d %H:%M:%S"), msg))
end

lrh_util.gateway_tx_url = "http://localhost:8080"

lrh_util.dispatch = function(target_type, code)    
  local payload = cjson.encode({ type = target_type, code = code })
  log(string.format("🚀 Dispatching %s: %s to %s", target_type, code, lrh_util.gateway_tx_url))
  -- 非同期送信 (ラグ防止)
  local cmd = string.format("curl -s -X POST -d '%s' %s &", payload, lrh_util.gateway_tx_url)
  os.execute(cmd)
end

lrh_util.call_ha_api = function(domain, service, data)
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

lrh_util.set_mode_to_ha = function(mode_name)
  lrh_util.call_ha_api("input_select", "select_option", {
    entity_id = "input_select.lrh_mode",
      option = mode_name
  })
end

lrh_util.send_ir  = function(code) lrh_util.dispatch("ir", code) end
lrh_util.send_bt  = function(code) lrh_util.dispatch("bt", code) end
lrh_util.send_cec = function(code) lrh_util.dispatch("cec", code) end

lrh_util.bind = function(mode_table, source, target)
  for k, v in pairs(source.keys) do
    if target.keys[k] then
      mode_table[v] = { type = target.type, code = target.keys[k] }
    end
  end
end

return lrh_util
