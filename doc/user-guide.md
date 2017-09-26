# How to use Synergy

Synergy doesn't need extra tools to create VMs into the private or shared quota but they are created in the standard OpenStack way \(i.e. shell and dashboard\). For example:

```
# openstack server create <options>
```
By default, the VMs are instantiated into the private quota. To select the shared quota, is needed to place special keys in the local user data file and pass it through the`--user-data <user-data-file>` parameter at instance creation:

```
# cat mydata.txt 
quota=shared

# openstack server create --image ubuntu-cloudimage --flavor 1 --user-data mydata.txt VM_INSTANCE
```
Another way to select the shared quota is using Openstack `--property` parameter during instance creation:

```
# openstack server create --image ubuntu-cloudimage --flavor 1 --property quota=shared VM_INSTANCE
```
# Running automated tasks before VM termination

A virtual machine instantiated into the shared quota is deleted by Synergy when its time to live (TTL) is expired. A mechanism, based on TTL expiration, that allows you to execute automated tasks (i.e. exporting data, turning off services) in your instance before Synergy deletes it is provided. The following example shows how to use this mechanism.
