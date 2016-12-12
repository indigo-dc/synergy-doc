# Manual installation and configuration

## Quota setting

The overall cloud resources can be grouped in two groups:

* **private quota**: composed of resources statically allocated and managed using the 'standard' OpenStack policies
* **shared quota**: composed of resources non statically allocated and fairly distributed among users by Synergy

The size of the shared quota is calculated as the difference between the total amount of cloud resources \(considering also the over-commitment ratios\) and the total resources allocated to the private quotas. Therefore for all projects it is necessary to specify the proper quota for instances, VCPUs and RAM so that their total sum is less than the total amount of cloud resources.

## Installation

Install the INDIGO repository.

### Install the synergy packages

On CentOS7:

```
yum install python-synergy-service python-synergy-scheduler-manager
```

On Ubuntu:

```
apt-get install python-synergy-service python-synergy-scheduler-manager
```

They can be installed in the OpenStack controller node or on another node.

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
GRANT ALL PRIVILEGES ON synergy._ TO 'synergy'@'localhost' \  
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

Register the synergy service and endpoint in the Openstack service catalog:

```bash
openstack service create --name synergy management
openstack endpoint create --region RegionOne management public http://$SYNERGY_HOST_IP:8051 
openstack endpoint create --region RegionOne management admin http://$SYNERGY_HOST_IP:8051
openstack endpoint create --region RegionOne management internal http://$SYNERGY_HOST_IP:8051
```

### Adjust nova notifications

Make sure that nova notifications are enanbled. On the controller node add the following attributes in the _nova.conf_ file and then restart the nova services:

```
notify_on_state_change = vm_state
default_notification_level = INFO
notification_driver = messaging
notification_topics = notifications
```

### Edit the source files for proper messaging

Two changes are then needed on the controller node.

The first one is edit _/usr/lib/python2.7/site-packages/oslo\_messaging/localcontext.py_ \(for CentOS\) /_/usr/lib/python2.7/dist-packages/oslo\_messaging/localcontext.py_ \(for Ubuntu\) , replacing:

```python
def _clear_local_context():
    """Clear the request context for the current thread."""
    delattr(_STORE, _KEY)
```

with:

```python
def _clear_local_context():
    """Clear the request context for the current thread."""
    if hasattr(_STORE, _KEY):
        delattr(_STORE, _KEY)
```

The second one is edit _/usr/lib/python2.7/site-packages/nova/cmd/conductor.py_ \(for CentOS\) / _/usr/lib/python2.7/site-packages/nova/cmd/conductor.py_ \(for Ubuntu\) replacing:

```python
topic=CONF.conductor.topic,
```

with:

```python
topic=CONF.conductor.topic + "_synergy",
```

### Restart nova

Then restart the nova services on the Controller node.

### Configure and start Synergy

Configure the synergy service, as explained in the following section.

Then start and enable the synergy service.  
On CentOS:

```
systemctl start synergy
systemctl enable synergy
```

On Ubuntu:

````
service synergy start
```

If synergy complains about  incompatibility with the version of installed oslo packages, e.g.:

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

## The synergy configuration file

Synergy must be configured properly filling the _/etc/synergy/synergy.conf_ configuration file.

This is an example of the synergy.conf configuration file:

```
[DEFAULT]


[Logger]
filename = /var/log/synergy/synergy.log
level = INFO
formatter = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
maxBytes = 1048576
backupCount = 100 


[WSGI]
host = SYNERGY_HOST
port = 8051
threads = 2
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

# rate (minutes)
rate = 1

# the list of projects accessing to the dynamic quota
projects = prj_a, prj_b

# the integer value expresses the share
shares = prj_a=70, prj_b=30

# the integer value expresses the default max time to live (minutes) for VM/Container
default_TTL = 2880

# the integer value expresses the max time to live (minutes) for VM/Container
TTLs = prj_a=1440, prj_b=2880

# the integer value expresses the max depth used by the backfilling strategy:
# this allows Synergy to not check the whole queue when looking for VMs to start
backfill_depth = 100


[FairShareManager]
autostart = True

# rate (minutes)
rate = 2

# period size (default: 7 days)
period_length = 1

# num of periods (default: 3)
periods = 3

# default share value (default: 10)
default_share = 10

# weights
decay_weight = 0.5
vcpus_weight = 50
age_weight = 0
memory_weight = 50


[KeystoneManager]
autostart = True

# rate (minutes)
rate = 5

# the Keystone url (v3 only)
auth_url = http://CONTROLLER_HOST:5000/v3

# the name of user with admin role
username = admin

# the password of user with admin role
password = ADMIN

# the project to request authorization on
project_name = admin

# set the http connection timeout
timeout = 60

# set the user domain name
user_domain_name = default

# set the project domain name
project_domain_name = default

# set the clock skew (default: 60 sec)
clock_skew = 60


[NovaManager]
autostart = True

# rate (minutes)
rate = 5

#set the http connection timeout (default: 60)
timeout = 60

# the amqp backend tpye (e.g. rabbit, qpid)
amqp_backend = rabbit
amqp_host = CONTROLLER_HOST
amqp_port = 5672
amqp_user = openstack
amqp_password = RABBIT_PASS
amqp_virtual_host = /

# set the NOVA host
host = CONTROLLER_HOST

# set the NOVA conductor topic
conductor_topic = conductor

# set the NOVA compute topic
compute_topic = compute

# set the NOVA scheduler topic
scheduler_topic = scheduler

# set the NOVA database connection
db_connection = mysql://nova:NOVA_DBPASS@CONTROLLER_HOST/nova

# set the NOVA CPU allocation ratio (default: 16)
cpu_allocation_ratio = 16

# set the NOVA RAM allocation ratio (default: 1.5)
ram_allocation_ratio = 1.5

# set the NOVA metadata_proxy_shared_secret
metadata_proxy_shared_secret =


[QueueManager]
autostart = True

# rate (minutes)
#rate = 60

# the Synergy database connection
db_connection = mysql://synergy:SYNERGY_DBPASS@CONTROLLER_HOST/synergy

# the connection pool size (default: 10)
db_pool_size = 10

# the max overflow (default: 5)
db_max_overflow = 5


[QuotaManager]
autostart = True

# rate (minutes)
rate = 5
```

The following describes the meaning of the attributes of the synergy configuration file, for each possible section:

**Section \[Logger\]**

| Attribute | Description |
| --- | --- |
| filename | The name of the log file |
| level | The log level. Possible values are  DEBUG, INFO, WARNING, ERROR, CRITICAL |
| formatter | The format of the log file |
| maxBytes | The maximum size of a log file. When this size is reached, the log file is rotated |
| backupCount | The number of log files to be kept |

---

**Section \[WSGI\]**

| Attribute | Description |
| --- | --- |
| host | The hostname where the synergy service is deployed |
| port | The port used by the synergy service |
| threads | The number of threads used by the synergy service |
| use ssl | Specify if the service is secured through SSL |
| ssl\_ca\_file | CA certificate file to use to verify connecting clients |
| ssl\_cert\_file | Identifying certificate PEM file to present to clients |
| ssl\_key\_file | Private key PEM file used to sign cert\_file certificate |
| max\_header\_line | Maximum size of message headers to be accepted \(default: 16384\) |
| retry\_until\_window | Number of seconds to keep retrying for listening \(default: 30sec\) |
| tcp\_keepidle | Sets the value of TCP\_KEEPIDLE in seconds for each server socket |
| backlog | Number of backlog requests to configure the socket with \(default: 4096\). The listen backlog is a socket setting specifying that the kernel how to limit the number of outstanding \(i.e. not yet accepted\) connections in the listen queue of a listening socket. If the number of pending connections exceeds the specified size, new ones are automatically rejected |

---

**Section \[SchedulerManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the SchedulerManager manager should be started when synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manager |
| projects | Defines the list of OpenStack projects entitled to access the dynamic resources |
| shares | Defines, for each project entitled to access the dynamic resources, the relevant share for the usage of such resources. If for a project the value is not specified, the value set for the attribute _default\_share_ in the _FairShareManager_ section is used |
| default\_TTL | Specifies the default maximum Time to Live for a Virtual Machine/container, in minutes |
| TTLs | For each project, specifies the maximum Time to Live for a Virtual Machine/container, in minutes. VMs and containers running for more that this value will be killed by synergy. If for a certain project the value is not specified, the value specified by the _default\_TTL_ attribute will be used |
| backfill\_depth | The integer value expresses the max depth used by the backfilling strategy: this allows Synergy to not check the whole queue when looking for VMs to start |

---

**Section \[FairShareManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the FairShare manager should be started when synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manager |
| period\_length | The time window considered for resource usage by the fairshare algoritm used by synergy is split in periods having all the same length, and the most recent periods are given a higher weight. This attribue specifies the length, in days, of a single period \(default: 7 days\) |
| periods | The time window considered for resource usage by the fairshare algoritm used by synergy is split in periods having all the same length, and the most recent periods are given a higher weight. This attribue specifies the number of periods to be considered |
| default\_share | Specifies the default to be used for a project, if not specified in the _shares_ attribute of the _SchedulerManager_ section |
| decay\_weight | Value  between 0 and 1, used by the fairshare scheduler, to define how oldest periods should be given a less weight wrt resource usage |
| vcpus\_weight | The weight to be used for the attribute concerning vcpus usage in the fairshare algorithm used by synergy |
| age\_weight | This attribute defines how oldest requests \(and therefore with low priority\) should have their priority increased so thay cam be eventaully served |
| memory\_weight | The weight to be used for the attribute concerning memory usage in the fairshare algorithm used by synergy |

---

**Section \[KeystoneManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the Keystone manager should be started when synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manage |
| auth\_url | The URL of the OpenStack identity service. Please note that the v3 API endpoint must be used |
| username | the name of the user with admin role |
| password | the password of the specified user with admin role |
| project\_name | the project to request authorization on |
| user\_domain\_name | set the user domain name \(default: "default"\) |
| project\_domain\_name | set the project domain name \(default: "default"\) |
| timeout | the http connection timeout |
| clock\_skew | force the request for token, a delta time before the token expiration \(default: 60 sec\) |

---

**Section \[NovaManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the nova manager should be started when synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manager |
| nova\_conf | The pathname of the nova configuration file, if synergy is deployed in the OpenStack controller node. Otherwise it is necessary to specify the attributes host, conductor\_topic, compute\_topic, scheduler\_topic, db\_connection, and the ones referring to the AMQP system. This file must be readable by the synergy user |
| host | The hostname where the nova-conductor service runs |
| timeout | The http connection timeout |
| amqp\_backend | The AMQP backend tpye \(rabbit or qpid\) |
| amqp\_host | The server where the AMQP service runs |
| amqp\_port | The port used by the AMQP service |
| amqp\_user | The AMQP userid |
| amqp\_password | The password of the AMQP user |
| amqp\_virtual\_host | The AMQP virtual host |
| conductor\_topic | The topic on which conductor nodes listen on |
| compute\_topic | The topic on which compute nodes listen on |
| scheduler\_topic | The topic on which scheduler nodes listen on |
| cpu\_allocation\_ratio | The NOVA CPU allocation ratio \(default: 16\) |
| ram\_allocation\_ratio | The NOVA RAM allocation ratio \(default: 1.5\) |
| metadata\_proxy\_shared\_secret | The NOVA metadata\_proxy\_shared\_secret |
| db\_connection | The SQLAlchemy connection string to use to connect to the Nova database. |

---

**Section \[QueueManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the Queue manager should be started when synergy starts |
| rate | The time \(in minutes\) between two executions of the task implementing this manager |
| db\_connection | The SQLAlchemy connection string to use to connect to the synergy database. |
| db\_pool\_size | The number of SQL connections to be kept open |
| db\_max\_overflow | The max overflow with SQLAlchemy |

---

** Section \[QuotaManager\]**

| Attribute | Description |
| --- | --- |
| autostart | Specifies if the Quota manager should be started when synergy starts |
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

Before running the synergy client command, you must create and source the _admin-openrc.sh_ file to set the relevant environment variables. This is the same script used to run the OpenStack command line tools.

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

### synergy optional arguments

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

This command allows to get information about the managers deployed in the synergy service and control their execution:

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

### synergy start

This command start a manager deployed in the synergy service.

E.g.:

```
# synergy start TimerManager
-------------------------------------------------
| manager      | status  | message              |
-------------------------------------------------
| TimerManager | RUNNING | started successfully |
-------------------------------------------------
```

### synergy stop

This command stops a manager deployed in the synergy service.

E.g.:

```
# synergy stop KeystoneManager
---------------------------------------------------
| manager         | status | message              |
---------------------------------------------------
| KeystoneManager | ACTIVE | stopped successfully |
---------------------------------------------------
```

### synergy status

This command returns the status of the managers deployed in the synergy service.

E.g.:

```
# synergy status
------------------------------
| manager          | status  |
------------------------------
| QuotaManager     | RUNNING |
| NovaManager      | RUNNING |
| FairShareManager | RUNNING |
| TimerManager     | ACTIVE  |
| QueueManager     | RUNNING |
| KeystoneManager  | RUNNING |
| SchedulerManager | RUNNING |
------------------------------
```

### synergy get\_quota

This command shows the dynamic resources being used wrt the total number of dynamic resources.

E.g:

```
# synergy get_quota 
-------------------------------
| type     | in use | limit   |
-------------------------------
| ram (MB) | 9728   | 9808.00 |
| cores    | 19     | 28.00   |
-------------------------------
```

Using the _--long_ option, it is also possible to see the status for each project.

In the following example:

* _limit=28.0_ for _vcpus_ for each dynamic project says that the total number of VCPUs for the dynamic portion of the resources is 28. This is calculated considering the total number of resources and the ones allocated to static projects. The overcommitment factor is also taken into account.
* limit=9808.0 for _memory_ for each dynamic project says that the total number of MB of RAM for the dynamic portion of the resources is 9808. This is calculated considering the total number of resources and the ones allocated to static projects. The overcommitment factor is also taken into account.
* _prj\_a_ is currently using 9 VCPUs and 4608 MB of RAM
* _prj\_b_ is currently using 10 VCPUs and 5120 MB of RAM
* the total number of VCPUs currently used by the dynamic projects is 19 \(the value reported between parenthesis\)
* the total number of MB of RAM currently used by the dynamic projects is 9728 \(the value reported between parenthesis\)

```
# synergy get_quota --long
-------------------------------------------------------------------------------
| project | cores                        | ram (MB)                           |
-------------------------------------------------------------------------------
| prj_b   | in use=10 (19) | limit=28.00 | in use=5120 (9728) | limit=9808.00 |
| prj_a   | in use= 9 (19) | limit=28.00 | in use=4608 (9728) | limit=9808.00 |
-------------------------------------------------------------------------------
```

### synergy get\_priority

This command returns the priority set in that moment by Synergy to all users of the dynamic projects, to guarantee the fair share use of the resources \(considering the policies specified  by the Cloud administrator and considering the past usage of such resources\).

E.g. in the following example _user\_a2_ of project _prj\_a_ has the highest priority:

```
# synergy get_priority
--------------------------------
| project | user    | priority |
--------------------------------
| prj_a   | user_a1 | 78.00    |
| prj_a   | user_a2 | 80.00    |
| prj_b   | user_b1 | 5.00     |
| prj_b   | user_b2 | 5.00     |
--------------------------------
```

### synergy get\_share

This command reports the shares imposed by the Cloud administrator \(attribute _shares_ in the synergy configuration file\) to the dynamic projects and to their users.

E.g. in the following example the administrator specified in the synergy configuration file the value 70 for the share value of _prj\_a_, and 10 as share value for _prj\_b_. The command also reports the % values.

```
# synergy get_share
----------------------------
| project | share          |
----------------------------
| prj_b   | 12.50% (10.00) |
| prj_a   | 87.50% (70.00) |
----------------------------
```

With the _--long_ option it is also possible to see the shares for the users. The relevant users of the 2 projects are given the same share.

Therefore the 2 users of _prj\_a_ has each one a share of 43.75 % \(50 % of 87.50 %\) of total resources.

The 2 users of _prj\_b_ has each one a share of 6.25 % \(50 % of 12.50 %\) of total resources.

```
# synergy get_share --long
-----------------------------------------------
| project | share          | user    | share  |
-----------------------------------------------
| prj_b   | 12.50% (10.00) | user_b1 | 6.25%  |
| prj_b   | 12.50% (10.00) | user_b2 | 6.25%  |
| prj_a   | 87.50% (70.00) | user_a1 | 43.75% |
| prj_a   | 87.50% (70.00) | user_a2 | 43.75% |
-----------------------------------------------
```

### synergy get\_usage

This command reports the usage of the resources by the dynamic projects in the last time frame considered by synergy \(attribute _period\_length_ of the synergy configuration file \_ attribute \_time window\*\).

In the following example it is reported that, in the considered time frame:

* _proj\_a_ has used 31.26% of cores and 31.26% of RAM
* _proj\_b_ has used 68.74% of cores and 68.74% of RAM
* _user\_a1_ has used 100 % of resources within its project \(and 31.26% considering the overall usage\)
* _user\_a2_ hasn't used resources at all
* _user\_b1_ has used 100 % of resources within its project \(and 68.74% considering the overall usage\)
* _user\_b2_ hasn't used resources at all

```
# synergy get_usage
---------------------------------------------------------------------------
| project | cores  | ram    | user    | cores (abs)     | ram (abs)       | 
---------------------------------------------------------------------------
| prj_b   | 28.47% | 28.47% | user_b1 | 48.58% (13.83%) | 48.58% (13.83%) | 
| prj_b   | 28.47% | 28.47% | user_b2 | 51.42% (14.64%) | 51.42% (14.64%) | 
| prj_a   | 71.53% | 71.53% | user_a1 | 59.68% (42.69%) | 59.68% (42.69%) | 
| prj_a   | 71.53% | 71.53% | user_a2 | 40.32% (28.84%) | 40.32% (28.84%) | 
---------------------------------------------------------------------------
```

### synergy get\_queue

This command returns the number of queued requests for the dynamic projects, in total.

E.g. in the following example there are 45 queued requests in total for the dynamic projects.

```
# synergy get_queue
---------------------------
| queue   | status | size |
---------------------------
| DYNAMIC | ON     | 45   |
---------------------------
```

## Open Ports

To interact with Synergy using the client tool, just one port needs to be open.  
This is the port defined in the synergy configuration file \(attribute `port` in the `[WSGI]` section\). The default value is 8051.

