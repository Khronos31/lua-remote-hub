local lrh      = require("lrh_util")

local config = {}
config.C_RT1    = require("C-RT1")
config.J_MX     = require("J-MX100RC")
config.RC_R2    = require("RC-R2")
config.Nintendo = require("Bluetooth")
config.HDMI     = require("HDMI-Switcher")
config.HDMI_CEC = require("HDMI-CEC")

config.modes = {
  ["TV"]       = {},
  ["Recorder"] = {},
  ["Switch"]   = {}
}

-- 初期モードを設定
config.current_mode = config.modes["TV"]

config.gateway_tx_url = "http://192.168.1.142:8080"

-- 1. 基本一括バインド
lrh.bind(config.modes.TV,       config.C_RT1, config.J_MX)
lrh.bind(config.modes.Recorder, config.C_RT1, config.RC_R2)
lrh.bind(config.modes.Switch,   config.C_RT1, config.Nintendo)

-- 2. 数字キーの放送波集約（D, BS, CS, A すべてを各デバイスのNUMに紐付け）
local prefixes = { "D_", "BS_", "CS_", "A_" }
for i = 1, 12 do
  for _, pre in ipairs(prefixes) do
    local source_sig = config.C_RT1.keys[pre .. i]
    config.TV[source_sig]       = { type = "IR", code = config.J_MX.keys["NUM_"..i] }
    config.Recorder[source_sig] = { type = "IR", code = config.RC_R2.keys["NUM_"..i] }
  end
end

-- 3. メイン設定（共通操作 & モード切替）
config.remap = {
  -- モード切替
  [config.C_RT1.keys.SUB_CH] = function()
    lrh.set_mode_to_ha("TV")
    lrh.send_ir(config.J_MX.keys.MODE_DIGITAL)
    print("📺 Mode: TV")
  end,
  [C_RT1.keys.WOOO_LINK] = function()
    lrh.set_mode_to_ha("Recorder")
    lrh.send_cec(config.HDMI_CEC.keys.HDMI_1)
    lrh.send_ir(config.HDMI.keys.NUM_3)
    print("📼 Mode: Recorder")
  end,
  [C_RT1.keys.INTERNET] = function()
    lrh.set_mode_to_ha("Switch")
    lrh.send_cec(config.HDMI_CEC.keys.HDMI_1)
    lrh.send_ir(config.HDMI.keys.NUM_2)
    print("🎮 Mode: Switch")
  end,

  -- 全モード共通
  [config.C_RT1.keys.INPUT_SELECT] = { type = "IR", code = config.J_MX.keys.INPUT_SELECT },
}

return config
