-- ha-addon/config/lrh_util.lua
local lrh_util = {}

lrh_util.dispatcher = nil 
lrh_util.ha_handler = nil

lrh_util.bind = function(mode_table, source, target)
  for k, v in pairs(source.keys) do
    if target.keys[k] then
      mode_table[v] = { type = target.type, code = target.keys[k] }
    end
  end
end

lrh_util.call_ha = function(domain, service, data)
    if lrh_util.ha_handler then lrh_util.ha_handler(domain, service, data) end
end

lrh_util.set_mode_to_ha = function(mode_name)
    lrh_util.call_ha("input_select", "select_option", {
        entity_id = "input_select.lrh_mode",
        option = mode_name
    })
end

lrh_util.send_ir  = function(code) if lrh_util.dispatcher then lrh_util.dispatcher("ir", code) end end
lrh_util.send_bt  = function(code) if lrh_util.dispatcher then lrh_util.dispatcher("bt", code) end end
lrh_util.send_cec = function(code) if lrh_util.dispatcher then lrh_util.dispatcher("cec", code) end end

return lrh_util
