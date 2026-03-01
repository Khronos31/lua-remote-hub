ARG BUILD_FROM
FROM $BUILD_FROM

RUN apk add --no-cache lua5.4 lua-socket lua-sec lua-cjson curl

# 実行ファイルと設定ファイルをすべてコピー
COPY run.sh /
COPY main.lua /
# configフォルダの中身をコンテナの /config にコピー
COPY config/ /config/

RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
