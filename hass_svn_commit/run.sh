#!/usr/bin/env bashio

echo retrieve log level

LOG_LEVEL=$(bashio::config 'log_level' 'trace')
bashio::log.level "$LOG_LEVEL"

echo init
bashio::log.debug "Init"

bashio::config.require.username
bashio::config.require.password

echo get username/password
SVN_USER=$(bashio::config 'username' )
SVN_PASS=$(bashio::config 'password' )

MSG="Automated checkin $(date)"

bashio::log.info "Generated message: $MSG"

bashio::log.debug "Username: [$SVN_USER]"
MD5=$(echo -n "$SVN_PASS" | md5sum | awk '{print $1}')
bashio::log.debug "Password_MD5: $MD5"

cd /config
FILESLIST=/tmp/svn-checkin-files

bashio::log.info "Searching for files"
svn st | awk '{print $2 }' > $FILESLIST

for ex in $(bashio::config 'excludes|values') ; do
	COUNT=$(wc -l $FILESLIST | awk '{print $1}')
	bashio::log.debug "Before exclude: ${ex} count ${COUNT}"
	
	bashio::log.debug "Rename"
	mv $FILESLIST $FILESLIST.orig
	bashio::log.debug "grep"
	grep -v "${ex}" < $FILESLIST.orig > $FILESLIST
done

bashio::log.info "Get count of files"
COUNT=$(wc -l $FILESLIST | awk '{print $1}')
bashio::log.info "Found $COUNT file(s) to checkin"

if [ $COUNT != 0 ] ; then
	bashio::log.info "Execute checkin"
	svn ci --targets ${FILESLIST} \
		-m "${MSG}" --no-auth-cache \
		--username "${SVN_USER}" \
		--password "${SVN_PASS}" \
		--non-interactive --trust-server-cert-failures=unknown-ca
else
	bashio::log.warning "Nothing to do"
fi

echo sleeping
sleep 3600