-- ==========================================
-- リモコン受信信号の定義 (UGREEN HDMI Switcher / 4ボタン)
-- ==========================================
local BUTTONS = {}
BUTTONS.type = "IR"
BUTTONS.keys = {
  NUM_1 = "\x02\x20\x00\x80\x7f\x02\xfd",
  NUM_2 = "\x02\x20\x00\x80\x7f\x04\xfb",
  NUM_3 = "\x02\x20\x00\x80\x7f\x06\xf9",
  NEXT  = "\x02\x20\x00\x80\x7f\x08\xf7",
}

return BUTTONS
