local lrh_util = {}

-- main.lua から dispatch 関数をここに注入する
lrh_util.dispatcher = nil 

lrh_util.bind = function(mode_table, source, target)
  for k, v in pairs(source.keys) do
    if target.keys[k] then
      mode_table[v] = { type = target.type, code = target.keys[k] }
    end
  end
end

lrh_util.send_ir  = function(code) if lrh_util.dispatcher then lrh_util.dispatcher("ir", code) end end
lrh_util.send_bt  = function(code) if lrh_util.dispatcher then lrh_util.dispatcher("bt", code) end end
lrh_util.send_cec = function(code) if lrh_util.dispatcher then lrh_util.dispatcher("cec", code) end end

return lrh_util
