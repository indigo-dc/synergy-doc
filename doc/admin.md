
# Manual installation and configuration

TBC: Lisa



# Installation and configuration using puppet

We provide a Puppet module for Synergy so users can install and configure Synergy with Puppet.
The module provides both the `synergy-service` and `synergy-scheduler-components`.

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

TBC: Massimo