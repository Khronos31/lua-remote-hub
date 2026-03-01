ARG BUILD_FROM
FROM $BUILD_FROM

# Luaと通信用ライブラリのインストール
RUN apk add --no-cache \
    lua5.3 \
    lua-socket \
    lua-sec \
    lua-cjson \
    curl

# 実行ファイルをコピー
COPY run.sh /
COPY main.lua /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
