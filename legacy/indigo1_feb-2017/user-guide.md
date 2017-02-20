** ⚠ This is the documentation for an old version of Synergy on INDIGO 1 ⚠ **

The Synergy package versions corresponding to this documentation are:
- synergy-service v1.4.0
- synergy-scheduler-manager v2.3.0
- - - 
# How to use Synergy

Synergy doesn't need extra tools to create VMs into the private or shared quota but they are created in the standard OpenStack way \(i.e. shell and dashboard\). For example:

```
# openstack server create <options>
```

By default, the VMs are instantiated into the private quota. To select the shared quota, is needed to place special keys in the local user data file and pass it through the`--user-data <user-data-file>` parameter at instance creation:

```
# cat mydata.txt 
[synergy]
quota=shared

# openstack server create --image ubuntu-cloudimage --flavor 1 --user-data mydata.txt VM_INSTANCE
```



