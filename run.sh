#!/usr/bin/with-contenv bashio

CONFIG_FILE=swatchdog.conf

echo "Creating $CONFIG_FILE"

RSYSLOG_HOST=$(bashio::config 'rsyslog_host')
RSYSLOG_PORT=$(bashio::config 'rsyslog_port')
LOGGER_LINE="  exec logger --server $RSYSLOG_HOST --port $RSYSLOG_PORT -- \"\$_\""

set -o noglob
echo "# built on `date`" > "$CONFIG_FILE"
for regexp in "$(bashio::config 'filter_regexps')" ; do
	{
	echo "watchfor /$regexp/"
	echo $LOGGER_LINE
	} >> "$CONFIG_FILE"
done
set +o noglob

cat $CONFIG_FILE

echo Starting swatchdog
swatchdog --config-file $CONFIG_FILE --tail-file /config/home-assistant.log --restart-time="03:25am" --tail-args="-F"