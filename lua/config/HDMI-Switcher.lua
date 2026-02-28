-- ==========================================
-- リモコン受信信号の定義 (UGREEN HDMI Switcher / 4ボタン)
-- ==========================================
local BUTTONS = {}
BUTTONS.type = "IR"
BUTTONS.keys = {
  NUM_1 = "\x01\x22\x00\x80\x7F\x02\xFD\x03",
  NUM_2 = "\x01\x22\x00\x80\x7F\x04\xFB\x03",
  NUM_3 = "\x01\x22\x00\x80\x7F\x06\xF9\x03",
  NEXT  = "\x01\x22\x00\x80\x7F\x08\xF7\x03",
}

return BUTTONS
