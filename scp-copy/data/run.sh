#!/usr/bin/with-contenv bashio

LOG_LEVEL="$(bashio::config 'log_level' 'info')"
bashio::log.level "$LOG_LEVEL"

bashio::log.notice "Starting SCP copy `date`"

MOD_TIME="$(bashio::config 'mtime' '-1')"
bashio::log.debug "MTIME: ${MOD_TIME}"

bashio::log.debug "Searching for backups modified in last 24h"
files=$( find /backup -name *.tar -maxdepth 1 -mtime $MOD_TIME )


bashio::log.debug "files to be copied:" $files 

bashio::log.debug "Get configuration"

private_key="$(bashio::config 'private_key')"
remote_user="$(bashio::config 'remote_user')"
remote_host="$(bashio::config 'remote_host')"
remote_path="$(bashio::config 'remote_path')"

complete_remote="${remote_user}@${remote_host}:${remote_path}"

bashio::log.debug "Private key: [${private_key}]"
bashio::log.debug "Complete remote address: [${complete_remote}]"

/usr/bin/scp -i "${private_key}" -o \
	StrictHostKeyChecking=no \
	$files \
	"${complete_remote}" 2>&1
RESULT=$?

bashio::log.notice "SCP completed to $(bashio::config 'remote_host'). Result: ${RESULT}"

bashio::log.debug "Post scp_copy_complete event"
bashio::log.info `curl --no-progress-meter -X POST -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" -H "Content-Type: application/json" --data "{\"result\":\"${RESULT}\"}" "http://supervisor/core/api/events/scp_copy_complete" 2>&1`

bashio::log.debug "Posted event"

bashio::log.notice "Done  `date`"