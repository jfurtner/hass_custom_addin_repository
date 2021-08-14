# hass_log_syslog_forwarder
Home Assistant addin to forward home-assistant.log from HASS to a remote syslog server

# Description
Tails the home assistant log and forwards lines to the designated syslog server. Uses swatchdog
(https://sourceforge.net/projects/swatch/) to monitor the home-assistant.log file, and *logger*
 from util-linux to send the log line on. 

# Configuration
- rsyslog_host: remote syslog server to send logs to
- rsyslog_port: remote syslog server port to send logs on (UDP port, default 514)
- filter_regexps: List of regular expressions to use in watchdog line to determine what should
be sent to syslog.
   - note that first regular expression to match will send line

# Future consideration:
- Expand filtering, not sure if swatch provides a native exclude
- Use a single-process based tool to do this (instead of launching *logger* for every line, could
see that causing extra load on HASS system, though on my Raspberry Pi4 the add-on sits at 0% CPU