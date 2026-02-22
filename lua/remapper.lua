local remapper = {}

remapper.wdev = nil
remapper.cec  = nil

remapper.bind = function(mode_table, source, target)
  for k, v in pairs(source.keys) do
    if target.keys[k] then
      mode_table[v] = { type = target.type, code = target.keys[k] }
    end
  end
end

remapper.send_ir = function(code)
  if remapper.wdev then
    remapper.wdev:send(code)
  end
end

remapper.send_bt = function(code)
  local script = "/usr/share/lua-remote-hub/scripts/send_key.py"
  os.execute(string.format("/usr/bin/python3 %s %s &", script, code))
end

remapper.send_cec = function(code)
  if remapper.cec then
    remapper.cec.transmit(code)
  else
    print("Error: CEC is not initialized in remapper")
  end
end

return remapper
