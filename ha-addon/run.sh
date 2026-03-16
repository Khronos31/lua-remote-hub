#!/usr/bin/with-contenv bashio

echo "🚀 LRH Logic Controller Starting..."

# にファイルが一つもなければ、初期サンプルをコピーする
if [ ! -f "/config/config.lua" ]; then
    bashio::log.info "Config files not found. Initializing with default configs..."
    cp -pr /defaults/. /config/
else
    bashio::log.info "Config files found. Skipping initialization."
fi

# Lua 5.4 でメインスクリプトを実行
lua5.4 /main.lua
