# Dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

RUN apk add --no-cache lua5.4 lua-socket lua-sec lua-cjson curl

COPY run.sh /
COPY main.lua /

RUN chmod a+x /run.sh

EXPOSE 8888

CMD [ "/run.sh" ]
