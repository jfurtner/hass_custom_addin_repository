#!/usr/bin/env bashio

LOG_LEVEL=$(bashio::config 'log_level' 'info')
bashio::log.level "$LOG_LEVEL"

bashio::log.debug "get database_connection_url"
#postgresql://homeassistant:PASSWORD_GOES_here@77b2833f-timescaledb/homeassistant
DBURL=$(bashio::config 'database_connection_url')

bashio::log.debug "process db parameters"
dbProto="$(echo "$DBURL" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
# remove the protocol
dbUrlCooked="${DBURL/$dbProto/}"
# extract the user (if any)
dbUserPass="$(echo "$dbUrlCooked" | grep @ | cut -d@ -f1)"
dbPass="$(echo "$dbUserPass" | grep : | cut -d: -f2)"
if [ -n "$dbPass" ]; then
	dbUser="$(echo "$dbUserPass" | grep : | cut -d: -f1)"
else
	dbUser=$dbUserPass
fi

# extract the host
dbHost="$(echo "${dbUrlCooked/$dbUserPass@/}" | cut -d/ -f1)"
# fails due to set -o pipefail
# by request - try to extract the port
#set +o pipefail
#dbPort="$(echo $dbHost | grep : | sed -e 's,.*:,:,g' -e 's,.*:\([0-9]*\),\1,g' -e 's,[^0-9],,g')"
#set -o pipefail
# extract the path (if any)
dbName="$(echo "$dbUrlCooked" | grep / | cut -d/ -f2-)"

unset dbUserPass
unset dbUrlCooked
unset dbProto

if [[ -z ${dbPort-} ]] ; then
	dbPort=5432
fi

dbTimeZone="$(bashio::config 'database_time_zone')"
if [[ -z ${dbTimeZone-} ]] ; then
	dbTimeZone="America/Denver" # centre of the world?
fi


bashio::log.info "DB info: user: $dbUser @ $dbHost:$dbPort database: $dbName"

bashio::log.debug "Creating PGPASSFILE"
export PGPASSFILE=/tmp/pgpass.conf
touch $PGPASSFILE
chmod 600 $PGPASSFILE
echo "$dbHost:$dbPort:$dbName:$dbUser:$dbPass" > $PGPASSFILE

bashio::log.debug "Setting start date"
for view in $(bashio::config 'views|keys') ; do
	viewname=$(bashio::config "views[$view].name")
	
	bashio::log.debug "Checking view $viewname for starting time"
	if bashio::config.exists "views[$view].daily_time_24h" ; then
		bashio::log.debug "$viewname has daily_time_24h set"
		refresh_frequency_minutes=$(( 24 * 60 ))
		
		daily_time_24h=$(bashio::config "views[$view].daily_time_24h")
		bashio::log.debug "daily_time_24h: [$daily_time_24h]"
		
		now=$( date --date="$daily_time_24h" +%s )		
		statFile="/tmp/$viewname"

		nowPlus1Day=$(( now + 86400 ))		
		bashio::log.debug "Setting $statFile to $nowPlus1Day"
		
		touch -t "@$nowPlus1Day" $statFile 
	fi
	
done

bashio::log.info "Starting loop"
while true ; do
	loop_datetime=$(date +%s)
	bashio::log.debug "start loop $loop_datetime"
	for view in $(bashio::config 'views|keys') ; do
		bashio::log.debug "index $view"

		viewname=$(bashio::config "views[$view].name")
		refresh_frequency_minutes=5

		if bashio::config.exists "views[$view].refresh_frequency_minutes" ; then
			refresh_frequency_minutes=$(bashio::config "views[$view].refresh_frequency_minutes")
		fi

		bashio::log.debug "view: $viewname $refresh_frequency_minutes"

		statFile="/tmp/$viewname"

		last_changed=0
		if [[ -f $statFile ]] ; then
			last_changed=$(stat -c%Y "$statFile")
		fi

		next_change_time=$(( last_changed + (refresh_frequency_minutes * 60) ))
		bashio::log.debug "last changed: $last_changed next change time: $next_change_time"

		if [[ $next_change_time -lt $loop_datetime ]] ; then
			bashio::log.debug "updating view $viewname"
			psql --host "$dbHost" --username "$dbUser" --dbname "$dbName" --no-psqlrc --single-transaction  --command "SET TIME ZONE '$dbTimeZone'; REFRESH MATERIALIZED VIEW \"$viewname\"; " || true
			touch "$statFile"
			bashio::log.debug "Update complete"
		fi

	done

	bashio::log.debug "Starting sleep"
	sleep 50s
done

bashio::log.error "Exited loop, shouldn't get here"