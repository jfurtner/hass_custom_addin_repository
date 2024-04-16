#!/usr/bin/env bashio

echo retrieve log level
LOG_LEVEL=$(bashio::config 'log_level' 'trace')
bashio::log.level "$LOG_LEVEL"

bashio::log.debug "Init"

bashio::config.require.username 'svn_username'
bashio::config.require.password 'svn_password'
bashio::config.require.username 'mqtt_username'
bashio::config.require.password 'mqtt_password'

SVN_USER=$(bashio::config 'svn_username' )
SVN_PASS=$(bashio::config 'svn_password' )

MQTT_USERNAME=$(bashio::config 'mqtt_username')
MQTT_PASSWORD=$(bashio::config 'mqtt_password')

MQTT_BASE="mqtt://$MQTT_USERNAME:$MQTT_PASSWORD@core-mosquitto/homeassistant/sensor/system/svn_checkin"

MSG="Automated checkin $(date)"

bashio::log.info "Generated message: $MSG"

bashio::log.debug "Username: [$SVN_USER]"
MD5=$(echo -n "$SVN_PASS" | md5sum | awk '{print $1}')
bashio::log.debug "Password_MD5: $MD5"

cd /config
FILESLIST=/tmp/svn-checkin-files

bashio::log.info "Searching for files"
svn st | grep -v '^?' | awk '{print $2 }' > $FILESLIST

for ex in $(bashio::config 'excludes') ; do
	COUNT=$(wc -l $FILESLIST | awk '{print $1}')
	bashio::log.debug "Before exclude: ${ex} count ${COUNT}"

	bashio::log.debug "Rename"
	mv $FILESLIST $FILESLIST.orig
	bashio::log.debug "grep"
	grep -v -- "${ex}" < $FILESLIST.orig > $FILESLIST || true
	bashio::log.debug "after grep"
done

bashio::log.info "Get count of files"
COUNT=$(wc -l $FILESLIST | awk '{print $1}')
bashio::log.info "Found $COUNT file(s) to checkin"

SVN_OUTPUT=/tmp/svn-out

bashio::log.info "Post count"
echo "$COUNT" | mosquitto_pub -r -L "$MQTT_BASE/count" -l -i 'svn_file_count'

if [ $COUNT != 0 ] ; then
	bashio::log.info "Execute checkin"
	svn ci --targets ${FILESLIST} \
		-m "${MSG}" --no-auth-cache \
		--username "${SVN_USER}" \
		--password "${SVN_PASS}" \
		--non-interactive --trust-server-cert-failures=unknown-ca 2>&1 > $SVN_OUTPUT
	cat $SVN_OUTPUT
	SVNRESULT=$?
else
	bashio::log.warning "Nothing to do"
	SVNRESULT=0

	echo '' > $SVN_OUTPUT
fi

bashio::log.info "output: `cat $SVN_OUTPUT`"

bashio::log.info "Post SVNRESULT"
echo "$SVNRESULT" | mosquitto_pub -r -L "$MQTT_BASE/result_code" -l -i 'svn_file_count'

bashio::log.info "Post datetime"
date +%s | mosquitto_pub -r -L "$MQTT_BASE/execution_timestamp" -l -i 'svn_file_count'