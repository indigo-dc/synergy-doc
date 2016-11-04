
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


## Configuration files

Synergy must be configured properly filling the /etc/synergy/synergy.conf configuration file.

This is an example of the synergy.conf configuration file:


location with example or template
Logfile locations (and management) and other useful audit information
Open ports
Possible unit test of the service
Where is service state held (and can it be rebuilt)
Cron jobs
Security information
Access control Mechanism description (authentication & authorization)
How to block/ban a user
Network Usage
Firewall configuration
Security recommendations

