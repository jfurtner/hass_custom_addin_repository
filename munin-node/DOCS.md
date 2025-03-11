# Home Assistant Add-on: Munin-node

`host_name`: Name of the host in the munin-node configuration

`allow`: List of addresses as regular expressions

This add-on configures and launches Munin-Node, and makes it available to a
munin-update instance hosted externally.

It will find and start all plugins that are available on the host.