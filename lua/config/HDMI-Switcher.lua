-- ==========================================
-- リモコン受信信号の定義 (UGREEN HDMI Switcher / 4ボタン)
-- ==========================================
local BUTTONS = {}
BUTTONS.type = "IR"
BUTTONS.keys = {
  -- 1段目 (円形方向キー)
  NUM_1 = "\x02\x20\x00\x80\x7f\x02\xfd", -- BUTTON_1
  NUM_1 = "\x02\x20\x00\x80\x7f\x04\xfb", -- BUTTON_2
  NUM_1 = "\x02\x20\x00\x80\x7f\x06\xf9", -- BUTTON_3
  NEXT  = "\x02\x20\x00\x80\x7f\x08\xf7", -- BUTTON_Next
}

return BUTTONS
