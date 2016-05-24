
# Manual installation and configuration

TBC: Lisa



# Installation and configuration using puppet

We provide a Puppet module for Synergy so users can install and configure Synergy with Puppet.
The module provides both the `synergy-service` and `synergy-scheduler-manager` components.

The module will be available in the [Puppet Forge](https://forge.puppet.com/). (TODO)

Usage example:
```puppet
class { "puppet-synergy":
  synergy_db_url          => "mysql://test:test@localhost",
  dynamic_quotas          => {'A' => 1,  'B' => 2},
  project_shares          => {'A' => 70, 'B' => 30 },
  user_shares             => {'A' => {'u1' => 60, 'u2' => 40 },
                              'B' => {'u3' => 80, 'u4' => 20}},
  keystone_url            => "https://example.com",
  keystone_admin_user     => "admin",
  keystone_admin_password => "the admin password",
}
```

# The Synergy command line interface

The Synergy service provides a command-line client, called **synergycli**, which allows the Cloud administrator to monitor and control the Synergy service.

Before running the synergycli client command, you must create and source the *admin-openrc.sh* file to set the relevant environment variables. This is the same script used to run the OpenStack command line tools. 

Note that the OS_AUTH_URL variables must refer to the v3 version of the keystone API, e.g.:

```export OS_AUTH_URL=https://cloud-areapd.pd.infn.it:35357/v3```




### synergycli usage

```
synergycli [-h] [--version] [--debug] [--os-username <auth-user-name>]
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

TBC



