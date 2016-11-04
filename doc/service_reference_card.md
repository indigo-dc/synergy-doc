
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


