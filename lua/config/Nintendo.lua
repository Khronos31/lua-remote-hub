-- ==========================================
-- リモコン受信信号の定義 (Fire TV風 / 15ボタン)
-- ==========================================
local BUTTONS = {}
BUTTONS.type = "BT"
BUTTONS.keys = {
  -- 1段目 (円形方向キー)
  UP           = "82", -- BUTTON_1
  DOWN         = "81", -- BUTTON_2
  LEFT         = "80", -- BUTTON_3
  RIGHT        = "79", -- BUTTON_4
  ENTER        = "--consumer 65", -- BUTTON_5

  -- 2段目 (アイコン)
  RETURN       = "--consumer 548", -- BUTTON_6
  HOME         = "--consumer 547", -- BUTTON_7
  MENU         = "--consumer 64",  -- BUTTON_8

  -- 3段目 (再生系)
  PREV_SKIP    = "--consumer 182", -- BUTTON_9
  PLAY_PAUSE   = "--consumer 205", -- BUTTON_10
  NEXT_SKIP    = "--consumer 181", -- BUTTON_11

  -- 4段目 (音量・ガイド)
  MUTE         = "--consumer 226", -- BUTTON_12
  VOL_UP       = "--consumer 233", -- BUTTON_13
  GUIDE        = "--consumer 141", -- BUTTON_14

  -- 5段目 (音量下)
  VOL_DOWN     = "--consumer 234", -- BUTTON_15
  
  -- 追加
  REWIND       = "--consumer 180", -- 早戻し
  PLAY         = "--consumer 176", -- 再生
  FAST_FORWARD = "--consumer 179", -- 早送り
  PAUSE        = "--consumer 205", -- 再生/一時停止
  STOP         = "120", -- 停止
  REC          = "--consumer 547", -- ホーム
}

return BUTTONS
