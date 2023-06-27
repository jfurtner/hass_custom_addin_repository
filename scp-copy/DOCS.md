# Home Assistant Add-on: SCP Copy

## Installing

From the supervisor add-on store, add the following repository:

https://github.com/darthsebulba04/hassio-addons

Then, in the new list of add-ons, install `SCP Copy`

## How to use

1. Take a manual snapshot or write an automation to take one.
2. Start the add-on.

### As an automation

```
alias: Backup
description: Create a snapshot every night and copy to remote location for replication.
trigger:
  - at: '00:40'
    platform: time
condition: []
action:
  - data:
      name: 'hass-{{ now().strftime(''%Y-%m-%d-%H-%M'') }}'
    service: hassio.snapshot_full
  - delay: '00:15:00'
  - service: hassio.addon_start
    data:
      addon: 0bd49cf9_scp_copy
mode: single
```

## Configuration

Add-on configuration:

### Option `log_level`
Log level of the add on.

### Option `private_key`
The private key to use to initiate the SCP.

Default: `/config/.ssh/id_rsa`

### Option `remote_host`
The remote ip address or hostname to copy the snapshot to.

### Option `remote_user`
The remote user to use when logging into the host.

### Option `remote_path`
The location to copy the snapshots.

### Option `mtime`
Last modified time to use when copying backups

## Events
- scp_copy_complete : Fired when copy is completed by SCP. Helps to monitor SCP so 
backups can be verified or actioned if they do not correctly fire.
Data in the event is the `result` code from SCP. 0 is OK, anything else is an error.


```
alias: Event - scp_copy_complete - Backup - SCP Copy addon completed offload
description: ""
trigger:
  - platform: event
    event_type: scp_copy_complete
condition: []
action:
  - if:
      - condition: template
        value_template: "{{ trigger.event.data.result | int(-1) == 0}}"
    then:
      - service: input_datetime.set_datetime
        target:
          entity_id: input_datetime.scp_copy_last_on
        data:
          timestamp: "{{ utcnow()|as_timestamp }}"
    else:
      - service: persistent_notification.create
        data:
          notification_id: backup_scp_copy_failed
          title: Backup
          message: SCP copy failed. Error number {{ trigger.event.data.result }}
mode: single
```
