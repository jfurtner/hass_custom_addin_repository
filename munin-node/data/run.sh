#!/usr/bin/env bashio

echo retrieve log level
LOG_LEVEL=$(bashio::config 'log_level' 'trace')
bashio::log.level "$LOG_LEVEL"

bashio::log.debug "Init"

bashio::log.info "Get plugins"
munin-node-configure --shell | grep -v veth > /tmp/munin-node-configure-links || true

bashio::log.info "Link plugins"
chmod 755 /tmp/munin-node-configure-links
sh /tmp/munin-node-configure-links || true

bashio::log.info "Set up munin-node.conf"
echo "background 0" >> /etc/munin/munin-node.conf
echo "setsid 0" >> /etc/munin/munin-node.conf

bashio::log.info "Set host_name if needed"
HOSTNAME=$(bashio::config 'host_name')
if [ ! -z HOSTNAME ] ; then
	bashio::log.info "Set host_name $HOSTNAME"
	echo "host_name $HOSTNAME" >> /etc/munin/munin-node.conf
fi

bashio::log.info "Configure allow directives"
for allow in $(bashio::config 'allow') ; do
	bashio::log.debug "adding allow ${allow}"
	echo "allow ${allow}" >> /etc/munin/munin-node.conf
done

bashio::log.info "Start munin-node"
#monit -d 5 -I -c /munin-node.monitor
munin-node