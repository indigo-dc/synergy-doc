
# Manual installation and configuration

TBC: Lisa



# Installation and configuration using puppet

We provide a Puppet module for Synergy so users can install and configure Synergy with Puppet.
The module provides both the `synergy-service` and `synergy-scheduler-manager` components.

The module will be available in the [Puppet Forge](https://forge.puppet.com/). (**TODO**)

Usage example:
```puppet
class { 'indigodc-synergy':
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

TBC: Massimo