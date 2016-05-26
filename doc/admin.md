
# Manual installation and configuration


## The synergy configuration file

Synergy must be configured properly filling the */etc/synergy/synergy.conf* configuration file.

This is an example of the synergy.conf configuration file:

```
[DEFAULT]


[Logger]
filename=/var/log/synergy/synergy.log
level=INFO
formatter="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
maxBytes=1048576
backupCount=100


[WSGI]
host=localhost
port=8051
threads=2
use_ssl=False
#ssl_ca_file=
#ssl_cert_file=
#ssl_key_file=
max_header_line=16384
retry_until_window=30
tcp_keepidle=600
backlog=4096



[SchedulerManager]
autostart=True
# rate (minutes)
rate=1

# the list of projects accessing to the dynamic quota
projects=prj_a, prj_b

# the integer value expresses the share
shares=prj_a=70, prj_b=30

# the integer value expresses the default max time to live (minutes) for VM/Container
default_TTL=2

# the integer value expresses the max time to live (minutes) for VM/Container
TTLs=prj_a=1, prj_b=1



[FairShareManager]
autostart=True
# rate (minutes)
rate=2

# period size (default=7 days)
period_length=1
# num of periods (default=3)
periods=3

# default share value (default=10)
default_share = 10

# weights
decay_weight=0.5
vcpus_weight=50
age_weight=0
memory_weight=50



[KeystoneManager]
autostart=True
rate=5

# the Keystone url (v3 only)
auth_url=http://10.64.31.19:5000/v3
# the name of user with admin role
username=admin
# the password of user with admin role
password=ADMIN
# the project to request authorization on
project_name=admin
# set the http connection timeout
timeout=60
# set the trust expiration
trust_expiration=24


[NovaManager]
autostart=True
rate=5

# the nova configuration file: if specified the following attributes are used:
# my_ip, conductor_topic, compute_topic, scheduler_topic, connection, rpc_backend
# in case of RABBIT backend: rabbit_host, rabbit_port, rabbit_virtual_host, rabbit_userid, rabbit_password
# in case of QPID backend: qpid_hostname, qpid_port, qpid_username, qpid_password
nova_conf=/etc/synergy/nova.conf

host=10.64.31.19
#set the http connection timeout (default=60)
timeout=60

# the amqp backend tpye (e.g. rabbit, qpid)
amqp_backend=rabbit
amqp_host=10.64.31.19
amqp_port=5672
amqp_user=openstack
amqp_password=RABBIT_PASS
amqp_virtual_host=/
# the conductor topic
conductor_topic = conductor
# the compute topic
compute_topic = compute
# the scheduler topic
scheduler_topic = scheduler
# the NOVA database connection
db_connection = mysql+pymysql://nova:NOVA_DBPASS@10.64.31.19/nova


[QueueManager]
autostart=True
rate=5
# the Synergy database connection
db_connection=mysql://synergy:SYNERGY_DBPASS@10.64.31.19/synergy
# the connection pool size (default=10)
db_pool_size = 10
# the max overflow (default=5)
db_max_overflow = 5


[QuotaManager]
autostart=True
rate=5

```

The following describes the meaning of the attributes of the synergy configuration file, for each possible section:


**Section: [Logger]**

| Attribute | Description |
| -- | -- |
| filename | The name of the log file |
| level | The log level. Possible values are xxx |
| formatter | The format of the log file |
| maxBytes | The maximum size of a log file. When this size is reached, the log file is rotated |
| backupCount | The number of log files to be kept |


---
**Section: [WSGI]**

| Attribute | Description |
| -- | -- |
| host | The hostname where the synergy service is deployed |
| port | The port used by the synergy service |
| threads | The number of threads used by the synergy service |
| use ssl | Specify if the service is secured through SSL|
| ssl_ca_file | CA certificate file to use to verify connecting clients |
| ssl_cert_file | Identifying certificate PEM file to present to clients |
| ssl_key_file | Private key PEM file used to sign cert_file certificate |
| max_header_line | xxx |
| retry_until_window | xxx |
| tcp_keepidle | Sets the value of TCP_KEEPIDLE in seconds for each server socket |
| backlog | xxx |




TBC: Lisa



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
  synergy_db_url          => 'mysql://test:test@localhost',
  dynamic_quotas          => {'project_A' => 1,  'project_B' => 2},
  project_shares          => {'project_A' => 70, 'project_B' => 30 },
  user_shares             => {'project_A' => {'user1' => 60, 'user2' => 40 },
                              'project_B' => {'user3' => 80, 'user4' => 20}},
  keystone_url            => 'https://example.com',
  keystone_admin_user     => 'admin',
  keystone_admin_password => 'the admin password',
}
```

# The Synergy command line interface

The Synergy service provides a command-line client, called **synergycli**, which allows the Cloud administrator to control and monitor the Synergy service.

Before running the synergycli client command, you must create and source the *admin-openrc.sh* file to set the relevant environment variables. This is the same script used to run the OpenStack command line tools. 

Note that the OS_AUTH_URL variables must refer to the v3 version of the keystone API, e.g.:

```export OS_AUTH_URL=https://cloud-areapd.pd.infn.it:35357/v3```




### synergycli usage

```
usage: synergycli [-h] [--version] [--debug] [--os-username <auth-user-name>]
               [--os-password <auth-password>]
               [--os-project-name <auth-project-name>]
               [--os-project-id <auth-project-id>]
               [--os-auth-token <auth-token>] [--os-auth-token-cache]
               [--os-auth-url <auth-url>] [--os-auth-system <auth-system>]
               [--bypass-url <bypass-url>] [--os-cacert <ca-certificate>]
               [--insecure]
               {list,start,stop,status,get_quota,get_priority,get_share,get_usage,get_queue}
               ...



positional arguments:
  {list,start,stop,status,get_quota,get_priority,get_share,get_usage,get_queue}
                        commands
    list                list the managers
    start               start the managers
    stop                stop the managers
    status              retrieve the manager's status
    get_quota           retrieve the project quota
    get_priority        retrieve the user priority
    get_share           retrieve the user share
    get_usage           retrieve the resource usage
    get_queue           retrieve the queue information

optional arguments:
  -h, --help            show this help message and exit
  --version             show program's version number and exit
  --debug               print debugging output
  --os-username <auth-user-name>
                        defaults to env[OS_USERNAME]
  --os-password <auth-password>
                        defaults to env[OS_PASSWORD]
  --os-project-name <auth-project-name>
                        defaults to env[OS_PROJECT_NAME]
  --os-project-id <auth-project-id>
                        defaults to env[OS_PROJECT_ID]
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
  --insecure            explicitly allow Synergy's client to perform
                        "insecure" SSL (https) requests. The server's
                        certificate will not be verified against any
                        certificate authorities. This option should be used
                        with caution.
```


### synergycli optional arguments

**-h, --help**

    Show help message and exit
    
**--version**

    Show program’s version number and exit

    
**--debug**

    Show debugging information
    
**--os-username ```<auth-user-name>```**

    Username to login with. Defaults to env[OS_USERNAME]
    
** --os-password ```<auth-password>```**

    Password to use.Defaults to env[OS_PASSWORD]
    
 **--os-project-name ```<auth-project-name>```**
 
    Project name to scope to. Defaults to env:[OS_PROJECT_NAME]  

**--os-project-id ```<auth-project-id>```**

    Id of the project to scope to. Defaults to env[OS_PROJECT_ID]
    
**--os-auth-token ```<auth-token>```**

    The auth token to be used. Defaults to env[OS_AUTH_TOKEN]
    
**--os-auth-token-cache**

    Use the auth token cache. Defaults to env[OS_AUTH_TOKEN_CACHE]to False. 
    Defaults to 'false' if not set
    
**--os-auth-url ```<auth-url>```**

    The URL of the Identity endpoint. Defaults to env[OS_AUTH_URL]
    
**--os-auth-system ```<auth-system>```**

    The auth system to be used. Defaults to env[OS_AUTH_SYSTEM]

**--bypass-url ```<bypass-url>```**

    Use this API endpoint instead of the Service Catalog
    
**--os-cacert ```<ca-bundle-file>```**

    Specify a CA certificate bundle file to use in verifying a TLS
    (https) server certificate. Defaults to env[OS_CACERT]
   
**--insecure**

      Disable server certificate verification, i.e. the server's certificate 
      will not be verified against any certificate authority
    



### synergycli list                

This command returns the list of managers that have been deployed in the synergy service.

E.g.:

```
$ synergycli list
--------------------
| manager          |
--------------------
| QuotaManager     |
| FairShareManager |
| QueueManager     |
--------------------
```




### synergycli start               

This command starts the managers deployed in the synergy service.

E.g.:

```
$ synergycli start
-----------------------------------------------------
| manager          | status  | message              |
-----------------------------------------------------
| QuotaManager     | RUNNING | started successfully |
| FairShareManager | RUNNING | started successfully |
| QueueManager     | RUNNING | started successfully |
```



### synergycli stop                

This command stops the managers deployed in the synergy service.

E.g.:

```
$ synergycli stop
----------------------------------------------------
| manager          | status | message              |
----------------------------------------------------
| QuotaManager     | ACTIVE | stopped successfully |
| FairShareManager | ACTIVE | stopped successfully |
| QueueManager     | ACTIVE | stopped successfully |
----------------------------------------------------
```



### synergycli status              

This command returns the status of the managers deployed in the synergy service. 

E.g.:

```
$ synergycli status
------------------------------
| manager          | status  |
------------------------------
| QuotaManager     | RUNNING |
| FairShareManager | RUNNING |
| QueueManager     | RUNNING |
------------------------------
```



### synergycli get_quota           

This command, for each dynamic project, shows the resources being used wrt the total number of dynamic resources.

In the following example:

* *limit=15.0* for *vcpus* for each dynamic project says that the total number of VCPUs for the dynamic portion of the resources is 15. This is calculated considering the total number of resources and the ones allocated to static projects. The overcommitment factor is also taken into account.
* limit=17512.0 for *memory* for each dynamic project says that the total number of MB of RAM for the dynamic portion of the resources is 17512. This is calculated considering the total number of resources and the ones allocated to static projects. The overcommitment factor is also taken into account.
* *prj_a* is currently using 5 VCPUs and 2560 MB of RAM
* *prj_a* is currently using 10 VCPUs and 5120 MB of RAM
* the total number of VCPUs currently used by the dynamic projects is 15 (the value reported between parenthesis)
* the total number of MB of RAM currently used by the dynamic projects is 7680 (the value reported between parenthesis)


```
$ synergycli get_quota
------------------------------------------------------------------------------
| project | vcpus                       | memory                             |
------------------------------------------------------------------------------
| prj_b   | in use=10 (15) | limit=15.0 | in use=5120 (7680) | limit=17512.0 |
| prj_a   | in use=5 (15)  | limit=15.0 | in use=2560 (7680) | limit=17512.0 |
------------------------------------------------------------------------------
```




### synergycli get_priority        

This command returns the priority set in that moment by Synergy to all users of the dynamic projects, to guarantee the fair share use of the resources (considering the policies specified  by the Cloud administrator and considering the past usage of such resources).

E.g. in the following example *user_a2* of project *prj_a* has the highest priority:

```
$ synergycli get_priority
--------------------------------
| project | user    | priority |
--------------------------------
| prj_b   | user_b2 | 20       |
| prj_b   | user_b1 | 4        |
| prj_a   | user_a2 | 72       |
| prj_a   | user_a1 | 52       |
--------------------------------
```



### synergycli get_share           

This command reports the shares imposed by the Cloud administrator (attribute *shares* in the synergy configuration file) to the dynamic projects and to their users.

E.g. in the following example *prj_a* was given 70 % of the share, and the rest (30 %) was given to *prj_b*. 

The relevant users of these 2 projects were given the same share. 

Therefore the 2 users of *prj_a* has each one a share of 50 % within the project, and a share of 35 % (50 % of 70 %) of total resources.

The 2 users of *prj_b* has each one a share of 50 % within the project, and a share of 15 % (50 % of 30 %) of total resources.


```
$ synergycli get_share
------------------------------------------------
| project | share | user    | user share (abs) |
------------------------------------------------
| prj_b   | 30.0% | user_b2 | 50.00% (15.00%)  |
| prj_b   | 30.0% | user_b1 | 50.00% (15.00%)  |
| prj_a   | 70.0% | user_a2 | 50.00% (35.00%)  |
| prj_a   | 70.0% | user_a1 | 50.00% (35.00%)  |
------------------------------------------------
```




### synergycli get_usage           

This command reports the usage of the resources by the dynamic projects in the last time frame considered by synergy (attribute *period_length* of the synergy configuration file * attribute *time window*).

In the following example it is reported that, in the considered time frame:

* *proj_a* has used 31.26% of cores and 31.26% of RAM
* *proj_b* has used 68.74% of cores and 68.74% of RAM
* *user_a1* has used 100 % of resources within its project (and 31.26% considering the overall usage)
* *user_a2* hasn't used resources at all
* *user_b1* has used 100 % of resources within its project (and 68.74% considering the overall usage)
* *user_b2* hasn't used resources at all



```
$ synergycli get_usage
--------------------------------------------------------------------------------------
| project | cores usage | ram usage | user    | cores usage (abs) | ram usage (abs)  |
--------------------------------------------------------------------------------------
| prj_b   | 68.74%      | 68.74%    | user_b2 | 0.00% (0.00%)     | 0.00% (0.00%)    |
| prj_b   | 68.74%      | 68.74%    | user_b1 | 100.00% (68.74%)  | 100.00% (68.74%) |
| prj_a   | 31.26%      | 31.26%    | user_a2 | 0.00% (0.00%)     | 0.00% (0.00%)    |
| prj_a   | 31.26%      | 31.26%    | user_a1 | 100.00% (31.26%)  | 100.00% (31.26%) |
--------------------------------------------------------------------------------------
```




### synergycli get_queue   

This command returns the number of queued requests (i.e. requests in scheduling state, waiting for available resources) for each static project and for the dynamic projects, in total.

E.g. in the following example there are no pending requests for the 2 static projects (admin and service), while there are 70 queued requests in total for the dynamic projects.

```
$ synergycli get_queue
---------------------------
| name    | status | size |
---------------------------
| admin   | ON     | 0    |
| dynamic | ON     | 70   |
| service | ON     | 0    |
---------------------------
```





