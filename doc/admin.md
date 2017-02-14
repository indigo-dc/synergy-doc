# Manual installation and configuration

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

```
GRANT ALL PRIVILEGES ON 
._ TO 'synergy'@'localhost' \  
IDENTIFIED BY 'SYNERGY_DBPASS';  
GRANT ALL PRIVILEGES ON synergy._ TO 'synergy'@'%' \  
IDENTIFIED BY 'SYNERGY_DBPASS';  
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

### Adjust nova notifications
Make sure that nova notifications are enabled on the **compute node**. Edit the _/etc/nova/nova.conf_ file. In the [DEFAULT] and [oslo_messaging_notifications] sections add the following attributes:

```
[DEFAULT]
...
notify_on_state_change = vm_and_task_state
default_notification_level = INFO

[oslo_messaging_notifications]
...
driver = messagingv2
topics = notifications
```
The _topics_ parameter is used by Nova for informing listeners about the state changes of the VMs. In case some other service (e.g. Ceilometer) is listening on the default topic _notifications_, to avoid the competition on consuming the notifications, please define a new topic specific for Synergy (e.g. _topics = notifications,**synergy_notifications**_).


### Edit the sources file for proper messaging
On the **controller node** edit _/usr/lib/python2.7/site-packages/nova/cmd/conductor.py_ \(for CentOS\) / _/usr/lib/python2.7/site-packages/nova/cmd/conductor.py_ \(for Ubuntu\) replacing:

```python
topic=CONF.conductor.topic,
```

with:

```python
topic=CONF.conductor.topic + "_synergy",
```

### Restart nova
Then restart the nova services on the Controller and Compute nodes.

### Configure and start Synergy
Configure the Synergy service, as explained in the following section.

Then start and enable the Synergy service.  
On CentOS:

```
systemctl start synergy
systemctl enable synergy
```

On Ubuntu:

````
service synergy start
```

If Synergy complains about incompatibility with the version of installed oslo packages, e.g.:

```
synergy.service - ERROR - manager 'timer' instantiation error: (oslo.log 
1.10.0 (/usr/lib/python2.7/site-packages), 
Requirement.parse('oslo.log<2.3.0,>=2.0.0')) 

synergy.service - ERROR - manager 'timer' instantiation error: 
(oslo.service 0.9.0 (/usr/lib/python2.7/site-packages), 
Requirement.parse('oslo.service<1.3.0,>=1.0.0')) 

synergy.service - ERROR - manager 'timer' instantiation error: 
(oslo.concurrency 2.6.0 (/usr/lib/python2.7/site-packages), 
Requirement.parse('oslo.concurrency<3.3.0,>=3.0.0')) 

synergy.service - ERROR - manager 'timer' instantiation error: 
(oslo.middleware 2.8.0 (/usr/lib/python2.7/site-packages), 

Requirement.parse('oslo.middleware<3.5.0,>=3.0.0'))
```

please patch the the file `/usr/lib/python2.7/site-packages/synergy_service-1.0.0-py2.7.egg-info/requires.txt` by removing the versions after the dependencies.

## The Synergy configuration file
Synergy must be configured properly filling the _/etc/synergy/synergy.conf_ configuration file. To apply the changes of any configuration parameter, the Synergy service must be restarted.

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


[SchedulerManager]
autostart = True

# set the manager rate (minutes)
rate = 1

# set the list of projects accessing to the shared quota
# projects = prj_a, prj_b
#projects =

# set the projects share
# shares = prj_a=70, prj_b=30
#shares =

# set the default max time to live (minutes) for VM/Container (default: 2880)
default_TTL = 2880

# set, for the specified projects, the max time to live (minutes) for VM/Container
# TTLs = prj_a=1440, prj_b=2880
#TTLs =

# set the max depth used by the backfilling strategy (default: 100)
# this allows Synergy to not check the whole queue when looking for VMs to start
backfill_depth = 100

# set the notification topic used by Nova for informing listeners about the state
# changes of the VMs. In case some other service (e.g. Ceilometer) is listening
# on the default Nova topic (i.e. "notifications"), please define a new topic
specific for Synergy (e.g. notification_topics = notifications,synergy_notifications)
notification_topic = notifications


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


[NovaManager]
autostart = True

# set the manager rate (minutes)
rate = 5

#set the http connection timeout (default: 60)
timeout = 60

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

# set the Nova conductor topic (default: conductor)
conductor_topic = conductor

# set the Nova compute topic (default: compute)
compute_topic = compute

# set the Nova scheduler topic (default: scheduler)
scheduler_topic = scheduler

# set the Nova database connection
db_connection=DIALECT+DRIVER://USER:PASSWORD@DB_HOST/nova

# set the Nova CPU allocation ratio (default: 16)
cpu_allocation_ratio = 16

# set the Nova RAM allocation ratio (default: 1.5)
ram_allocation_ratio = 1.5

# set the Nova metadata_proxy_shared_secret
metadata_proxy_shared_secret =

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
```

The following describes the meaning of the attributes of the Synergy configuration file, for each possible section:

**Section \[Logger\]**

| Attribute | Description |
| --- | --- |
| filename | The name of the log file |
| level | The logging level. Valid values are: CRITICAL, ERROR, WARNING, INFO, DEBUG, NOTSET |
| formatter | The format of the logged messages |
| maxBytes | The maximum size of a log file. When this size is reached, the log file is rotated |
| backupCount | The number of log files to be kept |

---

**Section \[WSGI\]**

| Attribute | Description |
| --- | --- |
| host | The hostname where the Synergy service is deployed |
| port | The port used by the Synergy service |
| threads | The number of threads used by the Synergy service |
| use ssl | Specify if the service is secured through SSL |
| ssl\_ca\_file | The CA certificate file to use to verify connecting clients |
| ssl\_cert\_file | The Identifying certificate PEM file to present to clients |
| ssl\_key\_file | The Private key PEM file used to sign cert\_file certificate |
| max\_header\_line | The maximum size of message headers to be accepted \(default: 16384\) |
| retry\_until\_window | The number of seconds to keep retrying for listening \(default: 30sec\) |
| tcp\_keepidle | The value of TCP\_KEEPIDLE in seconds for each server socket |
| backlog | The number of backlog requests to configure the socket with \(default: 4096\). The listen backlog is a socket setting specifying that the kernel how to limit the number of outstanding \(i.e. not yet accepted\) connections in the listen queue of a listening socket. If the number of pending connections exceeds the specified size, new ones are automatically rejected |

---

**Section \[SchedulerManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the SchedulerManager manager should be started when Synergy starts |
| rate | the time \(in minutes\) between two executions of the task implementing this manager |
| projects | Defines the list of OpenStack projects entitled to access the dynamic resources |
| shares | Defines, for each project entitled to access the dynamic resources, the relevant share for the usage of such resources. If for a project the value is not specified, the value set for the attribute _default\_share_ in the _FairShareManager_ section is used |
| default\_TTL | Specifies the default maximum Time to Live for a Virtual Machine/container, in minutes \(default: 2880\) |
| TTLs | For each project, specifies the maximum Time to Live for a Virtual Machine/container, in minutes. VMs and containers running for more that this value will be killed by Synergy. If for a certain project the value is not specified, the value specified by the _default\_TTL_ attribute will be used |
| backfill\_depth | The integer value expresses the max depth used by the backfilling strategy: this allows Synergy to not check the whole queue when looking for VMs to start \(default: 100\) |
| notification\_topic | The notification topic used by Nova for informing listeners about the state changes of the VMs. In case some other service (e.g. Ceilometer) is listening on the default Nova topic (i.e. "notifications"), please define a new topic specific for Synergy (e.g. notification_topics = notifications,synergy_notifications) |

---

**Section \[FairShareManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the FairShare manager should be started when Synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manager |
| period\_length | The time window considered for resource usage by the fair-share algorithm used by Synergy is split in periods having all the same length, and the most recent periods are given a higher weight. This attribute specifies the length, in days, of a single period \(default: 7\) |
| periods | The time window considered for resource usage by the fairshare algoritm used by Synergy is split in periods having all the same length, and the most recent periods are given a higher weight. This attribue specifies the number of periods to be considered \(default: 3\) |
| default\_share | Specifies the default to be used for a project, if not specified in the _shares_ attribute of the _SchedulerManager_ section \(default: 10\) |
| decay\_weight | Value  between 0 and 1, used by the fairshare scheduler, to define how oldest periods should be given a less weight wrt resource usage \(default: 0.5\) |
| vcpus\_weight | The weight to be used for the attribute concerning vcpus usage in the fairshare algorithm used by Synergy \(default: 100\) |
| age\_weight | This attribute defines how oldest requests \(and therefore with low priority\) should have their priority increased so thay cam be eventaully served \(default: 10\) |
| memory\_weight | The weight to be used for the attribute concerning memory usage in the fairshare algorithm used by Synergy \(default: 70\) |

---

**Section \[KeystoneManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the Keystone manager should be started when Synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manage |
| auth\_url | The URL of the OpenStack identity service. Please note that the v3 API endpoint must be used |
| username | The name of the user with admin role |
| password | The password of the specified user with admin role |
| project\_id | The project id to request authorization on |
| project\_name | The project name to request authorization on |
| user\_domain\_name | The user domain name \(default: "default"\) |
| project\_domain\_name | The project domain name \(default: "default"\) |
| timeout | The http connection timeout \(default: 60\) |
| clock\_skew | Forces the request for token, a delta time before the token expiration \(default: 60 sec\) |

---

**Section \[NovaManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the nova manager should be started when Synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manager |
| host | The hostname where the nova-conductor service runs \(default: localhost\) |
| timeout | The http connection timeout \(default: 60\) |
| amqp\_backend | The AMQP backend tpye \(rabbit or qpid\) |
| amqp\_hosts | The AMQP HA cluster host:port pairs |
| amqp\_host | The server where the AMQP service runs \(default: localhost\) |
| amqp\_port | The port used by the AMQP service |
| amqp\_user | The AMQP userid |
| amqp\_password | The password of the AMQP user |
| amqp\_virtual\_host | The AMQP virtual host |
| conductor\_topic | The topic on which conductor nodes listen on \(default: conductor\) |
| compute\_topic | The topic on which compute nodes listen on \(default: compute\) |
| scheduler\_topic | The topic on which scheduler nodes listen on \(default: scheduler\) |
| cpu\_allocation\_ratio | The Nova CPU allocation ratio \(default: 16\) |
| ram\_allocation\_ratio | The Nova RAM allocation ratio \(default: 1.5\) |
| metadata\_proxy\_shared\_secret | The Nova metadata\_proxy\_shared\_secret |
| db\_connection | The SQLAlchemy connection string to use to connect to the Nova database |

---

**Section \[QueueManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the Queue manager should be started when Synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manager |
| db\_connection | The SQLAlchemy connection string to use to connect to the Synergy database |
| db\_pool\_size | The number of SQL connections to be kept open \(default: 10\) |
| db\_pool\_recycle | The number of seconds after which a connection is automatically recycled \(default: 30\) |
| db\_max\_overflow | The max overflow with SQLAlchemy \(default: 5\) |

---

**Section \[QuotaManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the Quota manager should be started when Synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manager |

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

### synergy usage
```
usage: synergy [-h] [--version] [--debug] [--os-username <auth-user-name>]
               [--os-password <auth-password>]
               [--os-user-domain-id <auth-user-domain-id>]
               [--os-user-domain-name <auth-user-domain-name>]
               [--os-project-name <auth-project-name>]
               [--os-project-id <auth-project-id>]
               [--os-project-domain-id <auth-project-domain-id>]
               [--os-project-domain-name <auth-project-domain-name>]
               [--os-auth-token <auth-token>] [--os-auth-token-cache]
               [--os-auth-url <auth-url>] [--os-auth-system <auth-system>]
               [--bypass-url <bypass-url>] [--os-cacert <ca-certificate>]
               {manager,queue,quota,usage} ...

positional arguments:
  {manager,queue,quota,usage}
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
  --os-auth-token <auth-token>
                        defaults to env[OS_AUTH_TOKEN]
  --os-auth-token-cache
                        Use the auth token cache. Defaults to False if
                        env[OS_AUTH_TOKEN_CACHE] is not set
  --os-auth-url <auth-url>
                        defaults to env[OS_AUTH_URL]
  --os-auth-system <auth-system>
                        defaults to env[OS_AUTH_SYSTEM]
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

**--os-username **`<auth-user-name>`

```
Username to login with. Defaults to env[OS_USERNAME]
```

** --os-password **`<auth-password>`

```
Password to use.Defaults to env[OS_PASSWORD]
```

**--os-project-name **`<auth-project-name>`

```
Project name to scope to. Defaults to env:[OS_PROJECT_NAME]
```

**--os-project-id **`<auth-project-id>`

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

**--os-auth-token **`<auth-token>`

```
The auth token to be used. Defaults to env[OS_AUTH_TOKEN]
```

**--os-auth-token-cache**

```
Use the auth token cache. Defaults to env[OS_AUTH_TOKEN_CACHE]to False. 
Defaults to 'false' if not set
```

**--os-auth-url **`<auth-url>`

```
The URL of the Identity endpoint. Defaults to env[OS_AUTH_URL]
```

**--os-auth-system **`<auth-system>`

```
The auth system to be used. Defaults to env[OS_AUTH_SYSTEM]
```

**--bypass-url **`<bypass-url>`

```
Use this API endpoint instead of the Service Catalog
```

**--os-cacert **`<ca-bundle-file>`

```
Specify a CA certificate bundle file to use in verifying a TLS
(https) server certificate. Defaults to env[OS_CACERT]
```

### synergy manager
This command allows to get information about the managers deployed in the Synergy service and control their execution:

```
# synergy manager -h
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

The command **synergy manager list **provides the list of all managers deployed in the Synergy service:

```
# synergy manager list
╒══════════════════╕
│ manager          │
╞══════════════════╡
│ QuotaManager     │
├──────────────────┤
│ NovaManager      │
├──────────────────┤
│ SchedulerManager │
├──────────────────┤
│ TimerManager     │
├──────────────────┤
│ QueueManager     │
├──────────────────┤
│ KeystoneManager  │
├──────────────────┤
│ FairShareManager │
╘══════════════════╛
```

To get the status about managers, use:

```
# synergy manager status
╒══════════════════╤══════════╤══════════════╕
│ manager          │ status   │   rate (min) │
╞══════════════════╪══════════╪══════════════╡
│ QuotaManager     │ RUNNING  │            1 │
├──────────────────┼──────────┼──────────────┤
│ NovaManager      │ RUNNING  │            1 │
├──────────────────┼──────────┼──────────────┤
│ SchedulerManager │ RUNNING  │            1 │
├──────────────────┼──────────┼──────────────┤
│ TimerManager     │ ACTIVE   │           60 │
├──────────────────┼──────────┼──────────────┤
│ QueueManager     │ RUNNING  │           10 │
├──────────────────┼──────────┼──────────────┤
│ KeystoneManager  │ RUNNING  │            1 │
├──────────────────┼──────────┼──────────────┤
│ FairShareManager │ RUNNING  │            1 │
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

### synergy quota
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

The private quota will be updated from Synergy after a few minutes without restart it. This example shows how the private quota of the project _prj\_a \(id=_a5ccbaf2a9da407484de2af881198eb9\) has been modified:

```
# synergy quota show --project_name prj_a
╒═══════════╤═══════════════════════════════════════════════╤═════════════════════════════════════════════════════════════════════════════╕
│ project   │ private quota                                 │ shared quota │
╞═══════════╪═══════════════════════════════════════════════╪═════════════════════════════════════════════════════════════════════════════╡
│ prj_a     │ vcpus: 0.00 of 3.00 | memory: 0.00 of 1024.00 │ vcpus: 0.00 of 26.00 | memory: 0.00 of 59956.00 | share: 70.00% | TTL: 5.00 │
╘═══════════╧═══════════════════════════════════════════════╧═════════════════════════════════════════════════════════════════════════════╛ 

# openstack quota set --cores 2 --ram 2048 --instances 10 --class a5ccbaf2a9da407484de2af881198eb9

# synergy quota show --project_name prj_a
╒═══════════╤═══════════════════════════════════════════════╤═════════════════════════════════════════════════════════════════════════════╕
│ project   │ private quota                                 │ shared quota │
╞═══════════╪═══════════════════════════════════════════════╪═════════════════════════════════════════════════════════════════════════════╡
│ prj_a     │ vcpus: 0.00 of 2.00 | memory: 0.00 of 2048.00 │ vcpus: 0.00 of 27.00 | memory: 0.00 of 58932.00 | share: 70.00% | TTL: 5.00 │
╘═══════════╧═══════════════════════════════════════════════╧═════════════════════════════════════════════════════════════════════════════╛
```

To get information about the private and shared quotas you must use the **synergy quota** command :

```
# synergy quota -h
usage: synergy quota [-h] {show} ...

positional arguments:
  {show}
    show      shows the quota info

optional arguments:
  -h, --help  show this help message and exit

# synergy quota show -h
usage: synergy quota show [-h] [-i <id> | -n <name> | -a | -s]

optional arguments:
  -h, --help            show this help message and exit
  -i <id>, --project_id <id>
  -n <name>, --project_name <name>
  -a, --all_projects
  -s, --shared
```

To get the status about the shared quota, use the option **--shared**:

```
# synergy quota show --shared
╒════════════╤════════╤════════╕
│ resource   │   used │   size │
╞════════════╪════════╪════════╡
│ vcpus      │      2 │     27 │
├────────────┼────────┼────────┤
│ memory     │   1024 │  60980 │
├────────────┼────────┼────────┤
│ instances  │      1 │     -1 │
╘════════════╧════════╧════════╛
```

in this example the total amount of VCPUs allocated to the shared quota is 27 whereof have been used just 2 CPUs \(similarly to the memory and instances number\). The value -1 means that the Cloud administrator has not fixed the limit of the number of instances \(i.e. VMs\), so in this example the VMs can be unlimited.

The** --all\_projects** option provides information about the private and shared quotas of all projects:

```
# synergy quota show --all_projects
╒═══════════╤════════════════════════════════════════════════╤═══════════════════════════════════════════════════════════════════════════════╕
│ project   │ private quota                                  │ shared quota                                                                  │
╞═══════════╪════════════════════════════════════════════════╪═══════════════════════════════════════════════════════════════════════════════╡
│ prj_b     │ vcpus: 1.00 of 3.00 | memory: 512.0 of 1536.00 │ vcpus: 0.00 of 27.00 | memory: 0.00 of 60980.00 | share: 30.00% | TTL: 5.00   │
├───────────┼────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ prj_a     │ vcpus: 0.00 of 1.00 | memory: 0.00 of 512.00   │ vcpus: 2.00 of 27.00 | memory: 1024.0 of 60980.00 | share: 70.00% | TTL: 5.00 │
╘═══════════╧════════════════════════════════════════════════╧═══════════════════════════════════════════════════════════════════════════════╛

# synergy quota show --project_name prj_a
╒═══════════╤══════════════════════════════════════════════╤═══════════════════════════════════════════════════════════════════════════════╕
│ project   │ private quota                                │ shared quota                                                                  │
╞═══════════╪══════════════════════════════════════════════╪═══════════════════════════════════════════════════════════════════════════════╡
│ prj_a     │ vcpus: 0.00 of 1.00 | memory: 0.00 of 512.00 │ vcpus: 2.00 of 27.00 | memory: 1024.0 of 60980.00 | share: 70.00% | TTL: 5.00 │
╘═══════════╧══════════════════════════════════════════════╧═══════════════════════════════════════════════════════════════════════════════╛
```

In this example the project prj\_b is currently consuming just resources of its private quota \(1 VCPU and 512MB of memory\) while the shared quota is not used. By contrary, the _prj\_a_ is consuming just the shared quota \(2 VCPUs and 1024MB of memory\). The share values fixed by the Cloud administrator are 70% for prj\_a and 30% prj\_b \(the attribute _shares_ in synergy.conf\) while for both projects the TTL has been set to 5 minutes \(the _TTL_ attribute\). Remark, in this example, the VMs instantiated in the shared quota can live just 5 minutes while the ones created in the private quota can live forever.

### synergy queue
This command provides information about the amount of user requests stored in the persistent priority queue:

```
# synergy queue -h
usage: synergy queue [-h] {show} ...

positional arguments:
  {show}
    show      shows the queue info

optional arguments:
  -h, --help  show this help message and exit

# synergy queue show
╒═════════╤════════╤═══════════╕
│ name    │   size │ is open   │
╞═════════╪════════╪═══════════╡
│ DYNAMIC │    544 │ true      │
╘═════════╧════════╧═══════════╛
```

### synergy usage
To get information about the usage of shared resources at project or user level, use:

```
# synergy usage show -h
usage: synergy usage show [-h] {project,user} ...

positional arguments:
  {project,user}
    project       project help
    user          user help

optional arguments:
  -h, --help      show this help message and exit


# synergy usage show project -h
usage: synergy usage show project [-h] [-d <id> | -m <name> | -a]

optional arguments:
  -h, --help            show this help message and exit
  -d <id>, --project_id <id>
  -m <name>, --project_name <name>
  -a, --all_projects


# synergy usage show user -h
usage: synergy usage show user [-h] (-d <id> | -m <name>)
                               (-i <id> | -n <name> | -a)

optional arguments:
  -h, --help            show this help message and exit
  -d <id>, --project_id <id>
  -m <name>, --project_name <name>
  -i <id>, --user_id <id>
  -n <name>, --user_name <name>
  -a, --all_users
```

The **project** sub-command provides the resource usage information by the projects.

The following example shows the projects prj\_a \(share: 70%\) and prj\_b \(share: 30%\) have consumed in the last three days, respectively 70.40% and 29.40% of shared resources:

```
# synergy usage show project --all_projects
╒═══════════╤═══════════════════════════════════════════════════════════════╤═════════╕
│ project   │ shared quota (09 Dec 2016 14:35:43 - 12 Dec 2016 14:35:43)    │ share   │
╞═══════════╪═══════════════════════════════════════════════════════════════╪═════════╡
│ prj_b     │ vcpus: 29.60% | memory: 29.60%                                │ 30.00%  │
├───────────┼───────────────────────────────────────────────────────────────┼─────────┤
│ prj_a     │ vcpus: 70.40% | memory: 70.40%                                │ 70.00%  │
╘═══════════╧═══════════════════════════════════════════════════════════════╧═════════╛

# synergy usage show project --project_name prj_a
╒═══════════╤══════════════════════════════════════════════════════════════╤═════════╕
│ project   │ shared quota (09 Dec 2016 15:01:44 - 12 Dec 2016 15:01:44)   │ share   │
╞═══════════╪══════════════════════════════════════════════════════════════╪═════════╡
│ prj_a     │ vcpus: 70.40% | memory: 70.40%                               │ 70.00%  │
╘═══════════╧══════════════════════════════════════════════════════════════╧═════════╛
```

The time window is defined by Cloud administrator by setting the attributes _period_ and _period\_length_ in synergy.conf.

It may happen that the prj\_a \(or prj\_b\) doesn't have the need to consume shared resources for a while: in this scenario the others projects \(i.e. prj\_b\) can take advantage and so consume more resources than the fixed share \(i.e. 30%\):

```
# synergy usage show project --all_projects
╒═══════════╤═══════════════════════════════════════════════════════════════╤═════════╕
│ project   │ shared quota (09 Dec 2016 14:35:43 - 12 Dec 2016 14:35:43)    │ share   │
╞═══════════╪═══════════════════════════════════════════════════════════════╪═════════╡
│ prj_b     │ vcpus: 98.40% | memory: 98.40%                                │ 30.00%  │
├───────────┼───────────────────────────────────────────────────────────────┼─────────┤
│ prj_a     │ vcpus: 1.60% | memory: 1.60%                                  │ 70.00%  │
╘═══════════╧═══════════════════════════════════════════════════════════════╧═════════╛
```

However, as soon as the prj\_a requires more shared resources, it will gain a higher priority than the prj\_b, in order to balance their usage.

The **user** sub-command provides the resource usage information by the project users.

The following example shows the usage report of users belonging to the project prj\_a. They have the same value for share \(35%\) but different priority \(user\_a1=80, user\_a2=100\) because the user\_a1 has consumed too much with respect to user\_a2 \(51.90% VS 48.10%\).

```
# synergy usage show user --project_name prj_a --all_users
╒═════════╤══════════════════════════════════════════════════════════════╤═════════╤════════════╕
│ user    │ shared quota (09 Dec 2016 14:58:44 - 12 Dec 2016 14:58:44)   │ share   │   priority │
╞═════════╪══════════════════════════════════════════════════════════════╪═════════╪════════════╡
│ user_a2 │ vcpus: 48.10% | memory: 48.10%                               │ 35.00%  │        100 │
├─────────┼──────────────────────────────────────────────────────────────┼─────────┼────────────┤
│ user_a1 │ vcpus: 51.90% | memory: 51.90%                               │ 35.00%  │         80 │
╘═════════╧══════════════════════════════════════════════════════════════╧═════════╧════════════╛

# synergy usage show user --project_name prj_a --user_name user_a1
╒═════════╤══════════════════════════════════════════════════════════════╤═════════╤════════════╕
│ user    │ shared quota (09 Dec 2016 14:58:44 - 12 Dec 2016 14:58:44)   │ share   │   priority │
╞═════════╪══════════════════════════════════════════════════════════════╪═════════╪════════════╡
│ user_a1 │ vcpus: 51.90% | memory: 51.90%                               │ 35.00%  │         80 │
╘═════════╧══════════════════════════════════════════════════════════════╧═════════╧════════════╛
```

### Open Ports
To interact with Synergy using the client tool, just one port needs to be open.  
This is the port defined in the Synergy configuration file \(attribute `port` in the `[WSGI]` section\). The default value is 8051.

