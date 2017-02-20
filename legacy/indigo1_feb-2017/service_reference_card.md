** ⚠ This is the documentation for an old version of Synergy on INDIGO 1 ⚠ **

The Synergy package versions corresponding to this documentation are:
- synergy-service v1.4.0
- synergy-scheduler-manager v2.3.0
- - - 

# Service Reference Card


## Daemons running

synergy 


## Init scripts



On CentOS:

```
systemctl [start|stop|status] synergy
```
On Ubuntu:
```
service synergy [start|stop|status]
```


## Configuration file

Synergy must be configured properly filling the */etc/synergy/synergy.conf* configuration file.

Instructions how to fill this file, along with an example, are available in the 'Deployment and Administrator Guide'

## Logfile 

By default synergy logs its activities on the file */var/log/synergy/synergy.log*. This file name can be changed modifying the synergy configuration file (attribute *filename* of the *[Logger]* section)

## Open ports

To interact with Synergy using the client tool, just one port needs to be open. This is the port defined in the synergy configuration file (attribute *port* in the *[WSGI]* section). The default value is 8051.

## Synergy storage

Likewise the OpenStack services, synergy stores persistently the needed information in a relational database.
Instructions how to create this database are reported in the 'Deployment and Administrator Guide'.

## Cron jobs

Synergy doesn't use any cron jobs



