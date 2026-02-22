local remapper = require("remapper")
local C_RT1    = require("C-RT1")
local J_MX     = require("J-MX100RC")
local RC_R2    = require("RC-R2")
local Nintendo = require("Nintendo")

local config = {}
local mode_tv       = {}
local mode_recorder = {}
local mode_switch   = {}

-- 1. 基本一括バインド
remapper.bind(mode_tv,       C_RT1, J_MX)
remapper.bind(mode_recorder, C_RT1, RC_R2)
remapper.bind(mode_switch,   C_RT1, Nintendo)

-- 2. 数字キーの放送波集約（D, BS, CS, A すべてを各デバイスのNUMに紐付け）
local prefixes = { "D_", "BS_", "CS_", "A_" }
for i = 1, 12 do
  for _, pre in ipairs(prefixes) do
    local source_sig = C_RT1.keys[pre .. i]
    -- 直接2行で書くことで可視性を確保
    mode_tv[source_sig]       = { type = "IR", code = J_MX.keys["NUM_"..i] }
    mode_recorder[source_sig] = { type = "IR", code = RC_R2.keys["NUM_"..i] }
  end
end

-- 3. メイン設定（共通操作 & モード切替）
config.remap = {
  -- モード切替
  [C_RT1.keys.SUB_CH]    = function() config.current_mode = mode_tv;       print("📺 Mode: TV") end,
  [C_RT1.keys.WOOO_LINK] = function() config.current_mode = mode_recorder; print("📼 Mode: Recorder") end,
  [C_RT1.keys.INTERNET]  = function() config.current_mode = mode_switch;   print("🎮 Mode: Switch") end,

  -- 全モード共通
  [C_RT1.keys.INPUT_SELECT] = { type = "IR", code = J_MX.keys.INPUT_SELECT },
}

config.current_mode = mode_tv
return config

