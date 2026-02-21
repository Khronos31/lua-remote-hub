# lua-remote-hub 🚀

`lua-remote-hub` は、赤外線（IR）、HDMI-CEC、Bluetooth HID エミュレーションを統合し、あらゆるデバイスを Lua スクリプトで自在に操作可能にする高性能なホームオートメーション・ゲートウェイです。

バラバラに開発されていた `libusbir`, `lua-usbir`, `ir-remapper`, `keyboard_mouse_emulate_on_linux` を一つのエコシステムとして統合し、圧倒的な低遅延と柔軟なカスタマイズ性を実現しました。



## 🌟 主な特徴

- **マルチプロトコル統合**:
  - **IR (Infrared)**: `libusb` をベースとした独自の送受信制御。
  - **HDMI-CEC**: `libcec` ネイティブバインディングによる、TVやレコーダーの爆速操作。
  - **Bluetooth**: HID キーボードエミュレーションによる PC や Android/Switch の操作。
- **Lua による柔軟なロジック**: 
  - モード切替（TVモード、Switchモード等）を Lua でシンプルに記述。
  - 「ボタン一つでテレビを点けて入力を切り替える」といったマクロも自由自在。
- **高速ディスパッチャ**: C++ 拡張によるオーバーヘッドの最小化。

## 🚀 セットアップ

### 1. 依存関係のインストール (Ubuntu 25.04+)

```bash
sudo apt update
sudo apt install cmake g++ libusb-1.0-0-dev libcec-dev lua5.4 liblua5.4-dev

```

### 2. ビルド

```bash
mkdir build && cd build
cmake ..
make

```

## 📝 設定例 (`config/config.lua`)

Lua を使って、ボタン一つに複雑な挙動を割り当てられます。

```lua
-- インターネットボタンを押した時のマクロ例
config.remap[C_RT1.keys.INTERNET] = function()
  -- 1. モードをゲーム機操作へ切り替え
  config.current_mode = mode_switch
  -- 2. CECでテレビの電源を入れ、入力を自分(RPi等)に切り替える
  remote.cec_send("on")
  remote.cec_send("as") -- Active Source
  print("🎮 Switch Mode: Power ON & Input Switched")
end

```

## 📜 ライセンス

MIT License

## 👨‍💻 作者

Khronos31
