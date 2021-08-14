ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# log monitoring tool
RUN apk add --no-cache swatch
# for full-featured logger command that supports remote hosts (built-in is busybox!)
RUN apk add --no-cache util-linux

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]