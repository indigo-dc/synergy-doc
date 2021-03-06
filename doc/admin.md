# Manual installation and configuration

Synergy version: service 1.5.3, scheduler 2.6.0

OpenStack supported versions: Mitaka, Newton, Ocata

### Repository
Install the [INDIGO repository](https://indigo-dc.gitbooks.io/indigo-datacloud-releases/content/generic_installation_and_configuration_guide_1.html).

### Install the Synergy packages
On CentOS7:

```
yum install python-synergy-service python-synergy-scheduler-manager
```

On Ubuntu:

```
apt-get install python-synergy-service python-synergy-scheduler-manager
```

They can be installed in the OpenStack controller node or on another node.


### Updating the Synergy packages
The Synergy project makes periodic releases. As a system administrator you can get the latest features and bug fixes by updating Synergy.

This is done using the standard update commands for your OS, as long you have the INDIGO repository set up.

On Ubuntu:

```
apt-get update
apt-get upgrade
```

On CentOS:

```
yum update
```
Once the update is complete remember to restart the service. Follow the instructions in "Configure and start Synergy" section of this guide to see how to do it.


### Setup the Synergy database
Then use the database access client to connect to the database server as the root user:

```bash
$ mysql -u root -p
```

Create the synergy database:

```
CREATE DATABASE synergy;
```

Grant proper access to the glance database:

```SQL
GRANT ALL PRIVILEGES ON synergy.* TO 'synergy'@'%' IDENTIFIED BY 'SYNERGY_DBPASS';  
flush privileges;
```

Replace SYNERGY\_DBPASS with a suitable password.

Exit the database access client.

### Add Synergy as an OpenStack endpoint and service
Source the admin credentials to gain access to admin-only CLI commands:

```bash
$ . admin-openrc
```

Register the Synergy service and endpoint in the Openstack service catalog:

```bash
openstack service create --name synergy management
openstack endpoint create --region RegionOne management public http://$SYNERGY_HOST_IP:8051 
openstack endpoint create --region RegionOne management admin http://$SYNERGY_HOST_IP:8051
openstack endpoint create --region RegionOne management internal http://$SYNERGY_HOST_IP:8051
```

### Setup the Nova notifications
Make sure that nova notifications are enabled on the **controller and compute node**. Edit the _/etc/nova/nova.conf_ file. The following configuration regards the OpenStack **Ocata** version. In the [notifications] and [oslo_messaging_notifications] sections add the following attributes:

```
[notifications]
...
notify_on_state_change = vm_state
default_notification_level = INFO

[oslo_messaging_notifications]
...
driver = messaging
topics = notifications
```
The _topics_ parameter is used by Nova for informing listeners about the state changes of the VMs. In case some other service (e.g. Ceilometer) is listening on the default topic _notifications_, to avoid the competition on consuming the notifications, please define a new topic specific for Synergy (e.g. _topics = notifications,**synergy_notifications**_).

Then restart the Nova services on the Controller and Compute node.


### Setup the Keystone notifications
Synergy listens on the Keystone notification topic about the events on projects and users. Please set the keystone.conf as following:

```
[DEFAULT]
...
notification_format = basic

notification_opt_out=identity.authenticate.success
notification_opt_out=identity.authenticate.pending
notification_opt_out=identity.authenticate.failed

[oslo_messaging_notifications]
...
driver = messaging
topics = notification
```

Then restart the Keystone service.


### Configure Controller to use Synergy
Perform these steps on the controller node. In _/etc/nova/_ create a _nova-api.conf_ file. Edit _/etc/nova/nova-api.conf_ file and add the following to it:

```
[conductor]
topic=synergy
```

The _topic_ must have the same value of the _synergy_topic_ defined in the _/etc/synergy/synergy_scheduler.conf_ file.

Only for Ubuntu 16.04, edit the _/etc/init.d/nova-api_ file and replace

```
[ "x$USE_LOGFILE" != "xno" ] && DAEMON_ARGS="$DAEMON_ARGS --log-file=$LOGFILE"
```
with

```
[ "x$USE_LOGFILE" != "xno" ] && DAEMON_ARGS="$DAEMON_ARGS --config-file /etc/nova/nova-api.conf --log-file=$LOGFILE"
```

Restart nova-api service to enable your configuration.

On the node where it is installed RabbitMQ, run the following command to check whether your configuration is correct:

```
# rabbitmqctl list_queues | grep synergy
synergy_fanout_1e30d613c19142ec8ce452292042c35c    0
synergy    0
synergy.192.168.60.231    0 
```
The output of the command should show something similar.

### Configure and start Synergy
Configure the Synergy service, as explained in the following section.

Then start and enable the Synergy service.  
On CentOS:

```
systemctl start synergy
systemctl enable synergy
```

On Ubuntu:

```
service synergy start
```

## The Synergy configuration file
Synergy must be configured properly by filling the _synergy.conf_ and _synergy_scheduler.conf_ configuration files in _/etc/synergy/_. To apply the changes of any configuration parameter, the Synergy service must be restarted.

This is an example of the **synergy.conf** configuration file:

```
[DEFAULT]


[Logger]
# set the logging file name
filename = /var/log/synergy/synergy.log

# set the logging level. Valid values are: CRITICAL, ERROR, WARNING, INFO, DEBUG, NOTSET.
level = INFO

# set the format of the logged messages
formatter = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

# set the max file size
maxBytes = 1048576

# set the logging rotation threshold
backupCount = 100 


[WSGI]
# set the Synergy hostname
host = SYNERGY_HOST

# set the WSGI port (default: 8051)
port = 8051

# set the number of threads
threads = 2

# set the SSL
use_ssl = False
#ssl_ca_file =  
#ssl_cert_file = 
#ssl_key_file = 
max_header_line = 16384
retry_until_window = 30
tcp_keepidle = 600
backlog = 4096

[Authorization]
# set the authorization plugin (default: synergy.auth.plugin.LocalHostAuthorization)
plugin = synergy_scheduler_manager.auth.plugin.KeystoneAuthorization
policy_file = /etc/synergy/policy.json
```

The following describes the meaning of the attributes of the _synergy.conf_ file, for each possible section:

**Section [Logger]**

| Attribute | Description |
| --- | --- |
| filename | the name of the log file |
| level | the logging level. Valid values are: CRITICAL, ERROR, WARNING, INFO, DEBUG, NOTSET |
| formatter | the format of the logged messages |
| maxBytes | the maximum size of a log file. When this size is reached, the log file is rotated |
| backupCount | the number of log files to be kept |

**Section [WSGI]**

| Attribute | Description |
| --- | --- |
| host | the hostname where the Synergy service is deployed |
| port | the port used by the Synergy service |
| threads | the number of threads used by the Synergy service |
| use ssl | specify if the service is secured through SSL |
| ssl_ca_file | the CA certificate file to use to verify connecting clients |
| ssl_cert_file | the Identifying certificate PEM file to present to clients |
| ssl_key_file | the Private key PEM file used to sign cert_file certificate |
| max_header_line | the maximum size of message headers to be accepted (default: 16384) |
| retry_until_window | the number of seconds to keep retrying for listening (default: 30sec) |
| tcp_keepidle | the value of TCP_KEEPIDLE in seconds for each server socket |
| backlog | the number of backlog requests to configure the socket with (default: 4096). The listen backlog is a socket setting specifying that the kernel how to limit the number of outstanding (i.e. not yet accepted) connections in the listen queue of a listening socket. If the number of pending connections exceeds the specified size, new ones are automatically rejected |

**Section [Authorization]**

| Attribute | Description |
| --- | --- |
| plugin | Synergy has security mechanism highly configurable. The security policies are pluggable so that it is possible to define any kind of authorization checks. The simplest authorization plugin is _synergy.auth.plugin.LocalHostAuthorization_ which denies any command coming from clients having IP address different from the Synergy's one. A more advanced security policies can be defined by using the _synergy_scheduler_manager.auth.plugin.KeystoneAuthorization_ plugin based on the policy.json |
| policy_file | set the policy.json file used by the _synergy_scheduler_manager.auth.plugin.KeystoneAuthorization_ plugin |


This example shows how to configure the **synergy_scheduler.conf** file:

```
[DEFAULT]

[SchedulerManager]
autostart = True

# set the manager rate (minutes)
rate = 1

# set the max depth used by the backfilling strategy (default: 100)
# this allows Synergy to not check the whole queue when looking for VMs to start
backfill_depth = 100


[FairShareManager]
autostart = True

# set the manager rate (minutes)
rate = 2

# set the period size (default: 7 days)
period_length = 7

# set num of periods (default: 3)
periods = 3

# set the default share value (default: 10)
default_share = 10

# set the dacay weight, float value [0,1] (default: 0.5)
decay_weight = 0.5

# set the vcpus weight (default: 100)
vcpus_weight = 50

# set the age weight (default: 10)
age_weight = 10

# set the memory weight (default: 70)
memory_weight = 70


[KeystoneManager]
autostart = True

# set the manager rate (minutes)
rate = 5

# set the Keystone url (v3 only)
auth_url = http://CONTROLLER_HOST:5000/v3

# set the name of user with admin role
#username =

# set the password of user with admin role
#password =

# set the project name to request authorization on
#project_name =

# set the project id to request authorization on
#project_id =

# set the http connection timeout (default: 60)
timeout = 60

# set the user domain name (default: default)
user_domain_name = default

# set the project domain name (default: default)
project_domain_name = default

# set the clock skew. This forces the request for token, a
# delta time before the token expiration (default: 60 sec)
clock_skew = 60

# set the PEM encoded Certificate Authority to use when verifying HTTPs connections
#ssl_ca_file =

# set the SSL client certificate (PEM encoded)
#ssl_cert_file =

# set the AMQP server url (e.g. rabbit://RABBIT_USER:RABBIT_PASS@RABBIT_HOST_IP)
#amqp_url =

# set the AMQP exchange (default: keystone)
amqp_exchange = keystone

# set the AMQP notification topic (default: notification)
amqp_topic = notification


[NovaManager]
autostart = True

# set the manager rate (minutes)
rate = 5

#set the http connection timeout (default: 60)
timeout = 60

# the amqp transport url
# amqp_url =

# set the AMQP backend type (e.g. rabbit, qpid)
#amqp_backend =

# set the AMQP HA cluster host:port pairs
#amqp_hosts =

# set the AMQP broker address where a single node is used (default: localhost)
amqp_host = localhost

# set the AMQP broker port where a single node is used
amqp_port = 5672

# set the AMQP user
#amqp_user =

# set the AMQP user password
#amqp_password =

# set the AMQP virtual host (default: /)
amqp_virtual_host = /

# set the Nova host (default: localhost)
host = CONTROLLER_HOST

# set the Synery topic as defined in nova-api.conf file (default: synergy)
synergy_topic = synergy

# set the Nova conductor topic (default: conductor)
conductor_topic = conductor

# set the Nova compute topic (default: compute)
compute_topic = compute

# set the Nova scheduler topic (default: scheduler)
scheduler_topic = scheduler

# set the notification topic used by Nova for informing listeners about the state
# changes of the VMs. In case some other service (e.g. Ceilometer) is listening
# on the default Nova topic (i.e. "notifications"), please define a new topic
specific for Synergy (e.g. notification_topics = notifications,synergy_notifications)
notification_topic = notification

# set the Nova database connection
db_connection = DIALECT+DRIVER://USER:PASSWORD@DB_HOST/nova

# set the Nova CPU allocation ratio (default: 16)
cpu_allocation_ratio = 16

# set the Nova RAM allocation ratio (default: 1.5)
ram_allocation_ratio = 1.5

# set the Nova metadata_proxy_shared_secret
#metadata_proxy_shared_secret =

# set the PEM encoded Certificate Authority to use when verifying HTTPs connections
#ssl_ca_file =

# set the SSL client certificate (PEM encoded)
#ssl_cert_file = 


[QueueManager]
autostart = True

# set the manager rate (minutes)
rate = 60

# set the Synergy database connection:
db_connection = DIALECT+DRIVER://USER:PASSWORD@DB_HOST/synergy

# set the connection pool size (default: 10)
db_pool_size = 10

# set the number of seconds after which a connection is automatically
# recycled (default: 30)
db_pool_recycle = 30

# set the max overflow (default: 5)
db_max_overflow = 5


[QuotaManager]
autostart = True

# set the manager rate (minutes)
rate = 5


[ProjectManager]
autostart = True

# set the manager rate (minutes)
rate = 60

# set the Synergy database connection:
db_connection = DIALECT+DRIVER://USER:PASSWORD@DB_HOST/synergy

# set the connection pool size (default: 10)
db_pool_size = 10

# set the number of seconds after which a connection is automatically
# recycled (default: 30)
db_pool_recycle = 30

# set the max overflow (default: 5)
db_max_overflow = 5

# set the default max time to live (minutes) for VM/Container (default: 2880)
default_TTL = 2880

# set the default share value (default: 10)
default_share = 10
```

Attributes and their meanings are described in the following tables:

**Section [SchedulerManager]**

| Attribute | Description |
| --- | --- |
| autostart | specifies if the SchedulerManager manager should be started when Synergy starts |
| rate | the time (in minutes) between two executions of the task implementing this manager |
| backfill_depth | the integer value expresses the max depth used by the backfilling strategy: this allows Synergy to not check the whole queue when looking for VMs to start (default: 100) |

**Section [FairShareManager]**

| Attribute | Description |
| --- | --- |
| autostart | specifies if the FairShare manager should be started when Synergy starts |
| rate | the time (in minutes) between two executions of the task implementing this manager |
| period_length | The time window considered for resource usage by the fair-share algorithm used by Synergy is split in periods having all the same length, and the most recent periods are given a higher weight. This attribute specifies the length, in days, of a single period (default: 7) |
| periods | the time window considered for resource usage by the fairshare algoritm used by Synergy is split in periods having all the same length, and the most recent periods are given a higher weight. This attribue specifies the number of periods to be considered (default: 3) |
| default_share | specifies the default to be used for a project, if not specified in the _shares_ attribute of the _SchedulerManager_ section (default: 10) |
| decay_weight | value  between 0 and 1, used by the fairshare scheduler, to define how oldest periods should be given a less weight wrt resource usage (default: 0.5) |
| vcpus_weight | the weight to be used for the attribute concerning vcpus usage in the fairshare algorithm used by Synergy (default: 100) |
| age_weight | this attribute defines how oldest requests (and therefore with low priority) should have their priority increased so thay cam be eventaully served (default: 10) |
| memory_weight | the weight to be used for the attribute concerning memory usage in the fairshare algorithm used by Synergy (default: 70) |

**Section [KeystoneManager]**

| Attribute | Description |
| --- | --- |
| autostart | specifies if the Keystone manager should be started when Synergy starts |
| rate | the time (in minutes) between two executions of the task implementing this manage |
| auth_url | the URL of the OpenStack identity service. Please note that the v3 API endpoint must be used |
| username | the name of the user with admin role |
| password | the password of the specified user with admin role |
| project_id | the project id to request authorization on |
| project_name | the project name to request authorization on |
| user_domain_name | the user domain name (default: "default") |
| project_domain_name | the project domain name (default: "default") |
| timeout | the http connection timeout (default: 60) |
| clock_skew | force the request for token, a delta time before the token expiration (default: 60 sec) |
| ssl_ca_file | set the PEM encoded Certificate Authority to use when verifying HTTPs connections |
| ssl_cert_file | set the SSL client certificate (PEM encoded) |
| amqp_url | set the AMQP server url (e.g. rabbit://RABBIT_USER:RABBIT_PASS@RABBIT_HOST_IP) |
| amqp_exchange | set the AMQP exchange (default: keystone) |
| amqp_topic | set the AMQP notification topic on which Keystone communicates with Synergy. It must have the same value of the topic defined in keystone.conf file (e.g. topics = notification) (default: notification) |

**Section [NovaManager]**

| Attribute | Description |
| --- | --- |
| autostart | specifies if the nova manager should be started when Synergy starts |
| rate | the time (in minutes) between two executions of the task implementing this manager |
| host | the hostname where the nova-conductor service runs (default: localhost) |
| timeout | the http connection timeout (default: 60) |
| amqp_url | the amqp transport url |
| amqp_backend | the AMQP backend tpye (rabbit or qpid) |
| amqp_hosts | the AMQP HA cluster host:port pairs |
| amqp_host | the server where the AMQP service runs (default: localhost) |
| amqp_port | the port used by the AMQP service |
| amqp_user | the AMQP userid |
| amqp_password | the password of the AMQP user |
| amqp_virtual_host | the AMQP virtual host |
| synergy_topic | the topic on which Nova API communicates with Synergy. It must have the same value of the _topic_ defined in _nova-api.conf_ file (default: synergy) |
| conductor_topic | the topic on which conductor nodes listen on (default: conductor) |
| compute_topic | the topic on which compute nodes listen on (default: compute) |
| scheduler_topic | the topic on which scheduler nodes listen on (default: scheduler) |
| notification_topic | the notification topic used by Nova for informing listeners about the state changes of the VMs. In case some other service (e.g. Ceilometer) is listening on the default Nova topic (i.e. "notifications"), please define a new topic specific for Synergy (e.g. notification_topics = notifications,synergy_notifications) |
| cpu_allocation_ratio | the Nova CPU allocation ratio (default: 16) |
| ram_allocation_ratio | the Nova RAM allocation ratio (default: 1.5) |
| metadata_proxy_shared_secret | the Nova metadata_proxy_shared_secret |
| db_connection | the SQLAlchemy connection string to use to connect to the Nova database |
| ssl_ca_file | set the PEM encoded Certificate Authority to use when verifying HTTPs connections |
| ssl_cert_file | set the SSL client certificate (PEM encoded) |

**Section [QueueManager]**

| Attribute | Description |
| --- | --- |
| autostart | specifies if the Queue manager should be started when Synergy starts |
| rate | the time (in minutes) between two executions of the task implementing this manager |
| db_connection | the SQLAlchemy connection string to use to connect to the Synergy database |
| db_pool_size | the number of SQL connections to be kept open (default: 10) |
| db_pool_recycle | the number of seconds after which a connection is automatically recycled (default: 30) |
| db_max_overflow | the max overflow with SQLAlchemy (default: 5) |

**Section [QuotaManager]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the Quota manager should be started when Synergy starts |
| rate | The time (in minutes) between two executions of the task implementing this manager |

**Section [ProjectManager]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the Quota manager should be started when Synergy starts |
| rate | The time (in minutes) between two executions of the task implementing this manager |
| db_connection | the SQLAlchemy connection string to use to connect to the Synergy database |
| db_pool_size | the number of SQL connections to be kept open (default: 10) |
| db_pool_recycle | the number of seconds after which a connection is automatically recycled (default: 30) |
| db_max_overflow | the max overflow with SQLAlchemy (default: 5) |
| default_TTL |set the default max time to live (minutes) for VM/Container (default: 2880)|
| default_share | set the default share value (default: 10) |


# Installation and configuration using puppet
We provide a Puppet module for Synergy so users can install and configure Synergy with Puppet.  
The module provides both the `synergy-service` and `synergy-scheduler-manager` components.

The module is available on the [Puppet Forge](https://forge.puppet.com/) : [vll/synergy](https://forge.puppet.com/vll/synergy/readme).

Install the puppet module with:

```
puppet module install vll-synergy
```

Usage example:

```puppet
class { 'synergy':
  synergy_db_url          => 'mysql://synergy:test@localhost/synergy',
  synergy_project_shares  => {'A' => 70, 'B' => 30 },
  keystone_url            => 'https://example.com',
  keystone_admin_user     => 'admin',
  keystone_admin_password => 'the keystone password',
  nova_url                => 'https://example.com',
  nova_db_url             => 'mysql://nova:test@localhost/nova',
  amqp_backend            => 'rabbit',
  amqp_host               => 'localhost',
  amqp_port               => 5672,
  amqp_user               => 'openstack',
  amqp_password           => 'the amqp password',
  amqp_virtual_host       => '/',
}
```

# The Synergy command line interface
The Synergy service provides a command-line client, called **synergy**, which allows the Cloud administrator to control and monitor the Synergy service.

Before running the Synergy client command, you must create and source the _admin-openrc.sh_ file to set the relevant environment variables. This is the same script used to run the OpenStack command line tools.

Note that the OS\_AUTH\_URL variables must refer to the v3 version of the keystone API, e.g.:

`export OS_AUTH_URL=https://cloud-areapd.pd.infn.it:35357/v3`

### $ synergy usage
```
# synergy --help
usage: synergy [-h] [--version] [--debug] [--os-username <auth-user-name>]
               [--os-password <auth-password>]
               [--os-user-domain-id <auth-user-domain-id>]
               [--os-user-domain-name <auth-user-domain-name>]
               [--os-project-name <auth-project-name>]
               [--os-project-id <auth-project-id>]
               [--os-project-domain-id <auth-project-domain-id>]
               [--os-project-domain-name <auth-project-domain-name>]
               [--os-auth-url <auth-url>] [--bypass-url <bypass-url>]
               [--os-cacert <ca-certificate>]
               {manager,project,user} ...

positional arguments:
  {manager,project,user}
                        commands

optional arguments:
  -h, --help            show this help message and exit
  --version             show program's version number and exit
  --debug               print debugging output
  --os-username <auth-user-name>
                        defaults to env[OS_USERNAME]
  --os-password <auth-password>
                        defaults to env[OS_PASSWORD]
  --os-user-domain-id <auth-user-domain-id>
                        defaults to env[OS_USER_DOMAIN_ID]
  --os-user-domain-name <auth-user-domain-name>
                        defaults to env[OS_USER_DOMAIN_NAME]
  --os-project-name <auth-project-name>
                        defaults to env[OS_PROJECT_NAME]
  --os-project-id <auth-project-id>
                        defaults to env[OS_PROJECT_ID]
  --os-project-domain-id <auth-project-domain-id>
                        defaults to env[OS_PROJECT_DOMAIN_ID]
  --os-project-domain-name <auth-project-domain-name>
                        defaults to env[OS_PROJECT_DOMAIN_NAME]
  --os-auth-url <auth-url>
                        defaults to env[OS_AUTH_URL]
  --bypass-url <bypass-url>
                        use this API endpoint instead of the Service Catalog
  --os-cacert <ca-certificate>
                        Specify a CA bundle file to use in verifying a TLS
                        (https) server certificate. Defaults to env[OS_CACERT]

Command-line interface to the OpenStack Synergy API.
```

The _synergy_ optional arguments:

**-h, --help**

```
Show help message and exit
```

**--version**

```
Show program’s version number and exit
```

**--debug**

```
Show debugging information
```

**--os-username** &lt;auth-user-name&gt;

```
Username to login with. Defaults to env[OS_USERNAME]
```

**--os-password** &lt;auth-password&gt;

```
Password to use.Defaults to env[OS_PASSWORD]
```

**--os-project-name** &lt;auth-project-name&gt;

```
Project name to scope to. Defaults to env:[OS_PROJECT_NAME]
```

**--os-project-id** &lt;auth-project-id&gt;

```
Id of the project to scope to. Defaults to env[OS_PROJECT_ID]
```

**--os-project-domain-id** &lt;auth-project-domain-id&gt;

```
Specify the project domain id. Defaults to env[OS_PROJECT_DOMAIN_ID]
```

**--os-project-domain-name** &lt;auth-project-domain-name&gt;

```
Specify the project domain name. Defaults to env[OS_PROJECT_DOMAIN_NAME]
```

**--os-user-domain-id** &lt;auth-user-domain-id&gt;

```
Specify the user domain id. Defaults to env[OS_USER_DOMAIN_ID]
```

**--os-user-domain-name** &lt;auth-user-domain-name&gt;

```
Specify the user domain name. Defaults to env[OS_USER_DOMAIN_NAME]
```

**--os-auth-url** &lt;auth-url&gt;

```
The URL of the Identity endpoint. Defaults to env[OS_AUTH_URL]

```

**--bypass-url** &lt;bypass-url&gt;

```
Use this API endpoint instead of the Service Catalog
```

**--os-cacert** &lt;ca-bundle-file&gt;

```
Specify a CA certificate bundle file to use in verifying a TLS
(https) server certificate. Defaults to env[OS_CACERT]
```

### $ synergy manager
This command allows to get information about the managers deployed in the Synergy service and control their execution:

```
# synergy manager --help
usage: synergy manager [-h] {list,status,start,stop} ...

positional arguments:
  {list,status,start,stop}
    list                list the managers
    status              show the managers status
    start               start the manager
    stop                stop the manager

optional arguments:
  -h, --help            show this help message and exit
```

The command **synergy manager list** provides the list of all managers deployed in the Synergy service:

```
# synergy manager list
╒══════════════════╕
│ manager          │
╞══════════════════╡
│ QuotaManager     │
├──────────────────┤
│ NovaManager      │
├──────────────────┤
│ FairShareManager │
├──────────────────┤
│ TimerManager     │
├──────────────────┤
│ QueueManager     │
├──────────────────┤
│ KeystoneManager  │
├──────────────────┤
│ ProjectManager   │
├──────────────────┤
│ SchedulerManager │
╘══════════════════╛
```

To get the status about managers, use:

```
# synergy manager status
╒══════════════════╤══════════╤══════════════╕
│ manager          │ status   │   rate (min) │
╞══════════════════╪══════════╪══════════════╡
│ QuotaManager     │ RUNNING  │            2 │
├──────────────────┼──────────┼──────────────┤
│ NovaManager      │ RUNNING  │            5 │
├──────────────────┼──────────┼──────────────┤
│ FairShareManager │ RUNNING  │            2 │
├──────────────────┼──────────┼──────────────┤
│ TimerManager     │ ACTIVE   │           60 │
├──────────────────┼──────────┼──────────────┤
│ QueueManager     │ RUNNING  │           60 │
├──────────────────┼──────────┼──────────────┤
│ KeystoneManager  │ RUNNING  │            5 │
├──────────────────┼──────────┼──────────────┤
│ ProjectManager   │ RUNNING  │           60 │
├──────────────────┼──────────┼──────────────┤
│ SchedulerManager │ RUNNING  │            1 │
╘══════════════════╧══════════╧══════════════╛


# synergy manager status TimerManager
╒══════════════╤══════════╤══════════════╕
│ manager      │ status   │   rate (min) │
╞══════════════╪══════════╪══════════════╡
│ TimerManager │ ACTIVE   │           60 │
╘══════════════╧══════════╧══════════════╛
```

To control the execution of a specific manager, use the **start** and **stop** sub-commands:

```
# synergy manager start TimerManager
╒══════════════╤════════════════════════════════╤══════════════╕
│ manager      │ status                         │   rate (min) │
╞══════════════╪════════════════════════════════╪══════════════╡
│ TimerManager │ RUNNING (started successfully) │           60 │
╘══════════════╧════════════════════════════════╧══════════════╛

# synergy manager stop TimerManager
╒══════════════╤═══════════════════════════════╤══════════════╕
│ manager      │ status                        │   rate (min) │
╞══════════════╪═══════════════════════════════╪══════════════╡
│ TimerManager │ ACTIVE (stopped successfully) │           60 │
╘══════════════╧═══════════════════════════════╧══════════════╛
```


### $ synergy project
This command allows to manage the projects in Synergy:

```
# synergy project --help
usage: synergy project [-h] {list,show,add,remove,set} ...

positional arguments:
  {list,show,add,remove,set}
    list                shows the projects list
    show                shows the project info
    add                 adds a new project
    remove              removes a project
    set                 sets the project values

optional arguments:
  -h, --help            show this help message and exit
```

To show all options related to each project command, use the --help argument, for example:

```
# synergy project add -h
usage: synergy project add [-h] (-i <id> | -n <name>) [-s <share>] [-t <TTL>]

optional arguments:
  -h, --help            show this help message and exit
  -i <id>, --id <id>
  -n <name>, --name <name>
  -s <share>, --share <share>
  -t <TTL>, --ttl <TTL>
```

The following examples show how to use the project sub-commands (list, add, set, show, remove):

```
# synergy project list
╒════════╕
│ name   │
╞════════╡
│ prj_a  │
├────────┤
│ prj_b  │
├────────┤
│ prj_c  │
╘════════╛
  
 # synergy project add --name prj_a --share 30 --ttl 5000
╒════════╤═════════════════╤═══════╕
│ name   │ share           │   TTL │
╞════════╪═════════════════╪═══════╡
│ prj_a  │ 30.00% | 27.27% │  5000 │
╘════════╧═════════════════╧═══════╛

# synergy project set --name prj_a --share 10 --ttl 3500

# synergy project show --name prj_a --share --ttl
╒════════╤═════════════════╤═══════╕
│ name   │ share           │   TTL │
╞════════╪═════════════════╪═══════╡
│ prj_a  │ 10.00% | 11.11% │  3500 │
╘════════╧═════════════════╧═══════╛

# synergy project remove --name prj_a

# synergy project list
╒════════╕
│ name   │
╞════════╡
│ prj_b  │
├────────┤
│ prj_c  │
╘════════╛
```
N.B. the values concerning the _share_ attribute will be explained in the next section 


### $ synergy user
This command allows to get information about the users belonging to a project managed by Synergy:

```
# synergy user --help
usage: synergy user [-h] {show} ...

positional arguments:
  {show}
    show      shows the user info
    
 
# synergy user show --help
usage: synergy user show [-h] (-i <id> | -n <name> | -a) (-j <id> | -m <name>)
                         [-s] [-u] [-p] [-l]

optional arguments:
  -h, --help            show this help message and exit
  -i <id>, --id <id>
  -n <name>, --name <name>
  -a, --all
  -j <id>, --prj_id <id>
  -m <name>, --prj_name <name>
  -s, --share
  -u, --usage
  -p, --priority
  -l, --long
  
 # synergy user show --all --prj_name prj_a
╒═════════╕
│ name    │
╞═════════╡
│ user_a2 │
├─────────┤
│ user_a1 │
╘═════════╛

# synergy user show --all --prj_name prj_a --share --usage --priority
╒═════════╤═════════╤═════════════════════════════╤════════════╕
│ name    │ share   │ usage                       │   priority │
╞═════════╪═════════╪═════════════════════════════╪════════════╡
│ user_a1 │ 12.50%  │ vcpus: 10.00% | ram: 10.00% │         80 │
├─────────┼─────────┼─────────────────────────────┼────────────┤
│ user_a2 │ 12.50%  │ vcpus: 33.00% | ram: 33.00% │         50 │
╘═════════╧═════════╧═════════════════════════════╧════════════╛
```


### The quota concept
The overall cloud resources can be grouped in:

* **private quota**: composed of resources statically allocated and managed using the 'standard' OpenStack policies
* **shared quota**: composed of resources non statically allocated and fairly distributed among users by Synergy

The size of the shared quota is calculated as the difference between the total amount of cloud resources \(considering also the over-commitment ratios\) and the total resources allocated to the private quotas. Therefore for all projects it is necessary to specify the proper quota for instances, VCPUs and RAM so that their total is less than the total amount of cloud resources.

<p align="center">
    <img src="../images/quota.png">
</p>

Since Synergy is installed, the private quota of projects **cannot be managed anymore by using the Horizon dashboard**, but **only via command line tools** using the following OpenStack command:

```
# openstack quota set --cores <num_vcpus> --ram <memory_size> --instances <max_num_instances> --class <project_id>
```

The private and shared quotas will be updated from Synergy after a few minutes without restart it. This example shows how the private quota of the project _prj\_a \(id=_a5ccbaf2a9da407484de2af881198eb9\) has been modified:

```
# synergy project show --name prj_a --p_quota --s_quota
╒════════╤═══════════════════════════════════════╤═════════════════════════════════════════╕
│ name   │ private quota                         │ shared quota                            │
╞════════╪═══════════════════════════════════════╪═════════════════════════════════════════╡
│ prj_a  │ vcpus: 0.0 of 1.0 | ram: 0.0 of 512.0 │ vcpus: 0.0 of 8.0 | ram: 0.0 of 10740.0 │
╘════════╧═══════════════════════════════════════╧═════════════════════════════════════════╛

# openstack quota set --cores 2 --ram 1024 --instances 10 --class a5ccbaf2a9da407484de2af881198eb9

# synergy project show --name prj_a --p_quota --s_quota
╒════════╤════════════════════════════════════════╤════════════════════════════════════════════╕
│ name   │ private quota                          │ shared quota                               │
╞════════╪════════════════════════════════════════╪════════════════════════════════════════════╡
│ prj_a  │ vcpus: 0.0 of 2.0 | ram: 0.0 of 1024.0 │ vcpus: 2.0 of 7.0 | ram: 1024.0 of 10228.0 │
╘════════╧════════════════════════════════════════╧════════════════════════════════════════════╛
```
In this example the total amount of VCPUs allocated to the shared quota is 7 whereof have been used just 2 CPUs (similarly to the memory number). The private quota of the prj_a project have 2 VCPUS and 1024MB of RAM but if you check that quota by OpenStack CLI (or Horizon dashboard), you will notice that values of the _cores, ram_ attributes have been changed and set to -1 (i.e. unlimited). This means that Synergy is managing such resources rightly.

```
# openstack quota show prj_a
+----------------------+----------------------------------+
| Field                | Value                            |
+----------------------+----------------------------------+
| cores                | -1                               |
| ram                  | -1                               |
| instances            | -1                               |
| floating-ips         | 50                               |
| health_monitors      | None                             |
| injected-file-size   | 10240                            |
| injected-files       | 5                                |
| injected-path-size   | 255                              |
| key-pairs            | 100                              |
| l7_policies          | None                             |
| listeners            | None                             |
| ...                  | ....                             |
+----------------------+----------------------------------+
```
To know how many resources each project is consuming, use:

```
# synergy project show --all --p_quota --s_quota
╒════════╤══════════════════════════════════════════╤════════════════════════════════════════════╕
│ name   │ private quota                            │ shared quota                               │
╞════════╪══════════════════════════════════════════╪════════════════════════════════════════════╡
│ prj_a  │ vcpus: 0.0 of 3.0 | ram: 0.0 of 2048.0   │ vcpus: 2.0 of 7.0 | ram: 1024.0 of 10228.0 │
├────────┼──────────────────────────────────────────┼────────────────────────────────────────────┤
│ prj_b  │ vcpus: 1.0 of 2.0 | ram: 512.0 of 1024.0 │ vcpus: 0.0 of 7.0 | ram: 0.0 of 10228.0    │
╘════════╧══════════════════════════════════════════╧════════════════════════════════════════════╛
```
In this example the project _prj_a_ is consuming just the shared quota (2 VCPUs and 1024MB of memory) while the _prj_b_ is currently consuming just resources of its private quota (1 VCPU and 512MB of memory) while the shared quota is not used.
Whenever the shared quota is saturated, all new requests for resources consuming are not rejected (as in standard OpenStack mode), but will be inserted into a persistent priority queue and processed as soon as some resources are again available. 

```
# synergy project show --all --p_quota --s_quota --queue
╒════════╤════════════════════════════════════════╤════════════════════════════════════════════╤══════════════╕
│ name   │ private quota                          │ shared quota                               │ queue usage  │
╞════════╪════════════════════════════════════════╪════════════════════════════════════════════╪══════════════╡
│ prj_b  │ vcpus: 0.0 of 3.0 | ram: 0.0 of 2048.0 │ vcpus: 5.0 of 7.0 | ram: 2560.0 of 10228.0 │ 50 (25.00%)  │
├────────┼────────────────────────────────────────┼────────────────────────────────────────────┼──────────────┤
│ prj_a  │ vcpus: 0.0 of 2.0 | ram: 0.0 of 1024.0 │ vcpus: 2.0 of 7.0 | ram: 1024.0 of 10228.0 │ 150 (75.00%) │
╘════════╧════════════════════════════════════════╧════════════════════════════════════════════╧══════════════╛
```
The above table shows that the _prj_a_ has 50 requests enqueued which corresponds to 25% of total queue usage. Analogously, the _prj_b_ uses the 75%.

To get information about the usage of shared resources at project use:
```
# synergy project show --all --usage --share
╒════════╤═════════════════════════════╤═════════════════╕
│ name   │ usage                       │ share           │
╞════════╪═════════════════════════════╪═════════════════╡
│ prj_a  │ vcpus: 74.76% | ram: 74.76% │ 10.00% | 25.00% │
├────────┼─────────────────────────────┼─────────────────┤
│ prj_b  │ vcpus: 25.34% | ram: 25.34% │ 30.00% | 75.00% │
╘════════╧═════════════════════════════╧═════════════════╛
```
In this case _prj_a_ is consuming the 74.76% of resources (VCPUS and memory), while _prj_b_ the 25.34%. The share values defined by the Cloud administrator are 10% and 30% respectivly. The table shows even the normalized values of the shares (25% and 75%).
The user usage can be retrieved as following:

```
# synergy user show --all --prj_name prj_a --usage --share --priority
╒═════════╤═════════╤═════════════════════════════╤════════════╕
│ name    │ share   │ usage                       │   priority │
╞═════════╪═════════╪═════════════════════════════╪════════════╡
│ user_a1 │ 15.00%  │ vcpus: 25.34% | ram: 25.34% │      35.71 │
├─────────┼─────────┼─────────────────────────────┼────────────┤
│ user_a2 │ 15.00%  │ vcpus: 0.00% | ram: 0.00%   │      55.68 │
╘═════════╧═════════╧═════════════════════════════╧════════════╛

# synergy user show --all --prj_name prj_b --usage --share --priority
╒═════════╤═════════╤═════════════════════════════╤════════════╕
│ name    │ share   │ usage                       │   priority │
╞═════════╪═════════╪═════════════════════════════╪════════════╡
│ user_b1 │ 35.00%  │ vcpus: 29.71% | ram: 29.71% │      31.00 │
├─────────┼─────────┼─────────────────────────────┼────────────┤
│ user_b2 │ 35.00%  │ vcpus: 44.95% | ram: 44.95% │      28.75 │
╘═════════╧═════════╧═════════════════════════════╧════════════╛
```

This example shows the usage and priority of all users. The main factors which affect the priority value are the project and user shares and their historical resource usage. The user requests having a higher the priority value will be executed first. 


### Open Ports
To interact with Synergy using the client tool, just one port needs to be open.  
This is the port defined in the Synergy configuration file \(attribute `port` in the `[WSGI]` section\). The default value is 8051.
