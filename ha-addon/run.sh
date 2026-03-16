#!/usr/bin/with-contenv bashio

echo "🚀 LRH Logic Controller Starting..."

# マウントされた本体の /config 内にフォルダを作成
TARGET_DIR="/config/lua-remote-hub"

if [ ! -d f"$TARGET_DIR/comfig.lua" ]; then
    bashio::log.info "Creating config directory at $TARGET_DIR"
    bashio::log.info "Config files not found. Initializing with default configs..."
    mkdir -p "$TARGET_DIR"
    cp -pr /defaults/. "$TARGET_DIR/"
else
    bashio::log.info "Config files found. Skipping initialization."
fi

# Lua 5.4 でメインスクリプトを実行
lua5.4 /main.lua
