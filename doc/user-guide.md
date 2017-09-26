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
## Running automated tasks before VM termination

A virtual machine instantiated into the shared quota is deleted by Synergy when its time to live (TTL) is expired. A mechanism, based on TTL expiration, that allows you to execute automated tasks (i.e. exporting data, turning off services) in your instance before Synergy deletes it is provided. The following example shows how to use this mechanism.

## Example

Before you begin check your enviroment.This mechnism support:

- Synergy version: service 1.5.3, scheduler 2.6.0

- Operating Systems: CentOS 7, Ubuntu 14.04

- OpenStack versions: Ocata, Newton

- Make sure you have access to the Internet from your virtual machine

### Creating personal script

Define in an executable bash script any actions you want to perform before your VM is deleted from the shared quota. Of course, script commands must be executable by the O.S. that will be installed on the virtual machine.

In this example _my_script.sh_ simply mounts a volume and creates the _synergy_test_result.txt_ file where it will be printed execution date and time of _my_script.sh_ file.

```
# cat my_script.sh 
#!/bin/bash
vm_id=`ls /dev/disk/by-id`
mkfs.ext4 /dev/disk/by-id/$vm_id
mkdir -p /mnt/volume
mount /dev/disk/by-id/$vm_id /mnt/volume
echo "User script executed on:" `date` >> /mnt/volume/synergy_test_result.txt

```
## Creating the wrapper script

This bash script creates the user data that will be used during VM contextualization phase (contextualisation phase configure a VM after it has been installed).

Create an executable bash script that contains the same content of _generate_userdata.sh_ script.

```
# cat generate_userdata.sh
#!/bin/bash
script=$(cat $1)
ex_1="false"
while [ $ex_1 != "true" ] ; do
  echo -n "Do you want to run your script 5 minutes before Synergy deletes your VM from the shared quota (y/n)? "
  read answer
  if [[ "$answer" = "y" || "$answer" = "n" ]] ; then
    ex_1="true"
  fi
done
if  echo "$answer" | grep -iq "^n" ;then
    ex_2="false"
    while [ $ex_2 != "true" ] ; do
      echo "Please enter your value in minutes, it must be less or equal to TTL"
      read input_time
      if ! [[ "$input_time" =~ ^[0-9]+$ ]] ; then
        echo "The value entered must be a number!"
      else
       ex_2="true"
      fi
    done
    syn_clock=$input_time
else
    syn_clock=5
fi
ex_3="false"
while [ $ex_3 != "true" ] ; do
  echo "Please enter user data name:"
  read answer
  if [[ "$answer" != "" ]] ; then
    ex_3="true"
  fi
done

userdata_name="$answer.txt"
encoded_user_script=$(echo -n "$script" | base64)
encoded_script_github=$(curl -sL https://raw.githubusercontent.com/indigo-dc/synergy-doc/master/doc/create_scripts.sh | base64)
work_dir=/root/synergy_scripts

cat <<EOF>> $userdata_name
#!/bin/bash
quota=shared
syn_clock=$syn_clock
# Create work dir
mkdir -p $work_dir
# Dencoding user script
echo -n "$encoded_user_script" | base64 -d > $work_dir/$1
chmod 755 $work_dir/$1
user_script_path=$work_dir/$1
# Dencoding github script
echo -n "$encoded_script_github" | base64 -d > $work_dir/create_scripts.sh
chmod 755 $work_dir/create_scripts.sh
$work_dir/create_scripts.sh
rm -rf $work_dir/create_scripts.sh
EOF
```
## Generating user data file

To generate user data file run the following comand:

```
# ./generate_userdata.sh my_script.sh
```
Specify how many minutes before TTL expiration your script will run (_my_script.sh_). The default value is 5 minutes.

```
Do you want to run your script 5 minutes before Synergy deletes your VM from the shared quota (y/n)? y
```
Enter user data file name.

```
Please enter user data name:

my_userdata
```
If everything is fine you will find a _.txt_ file (_my_userdata.txt_) in the current directory.
```
# ls
generate_userdata.sh  my_script.sh  my_userdata.txt
```
### Creating a volume
```
# openstack volume create --size 1 volume_test

 # openstack volume list
+--------------------------------------+--------------+-----------+------+-------------+
| ID                                   | Display Name | Status    | Size | Attached to |
+--------------------------------------+--------------+-----------+------+-------------+
| 1549a5d3-86f9-471f-894a-45c780ef4d02 | volume_test  | available |    1 |             |
+--------------------------------------+--------------+-----------+------+-------------+

```
### Creating Virtual Machine
To create a VM into the shared quota folow the paragraph "How to use Synergy".
```
# openstack server create --image centos7 --flavor m1.small --user-data my_userdata.txt vm_test

# openstack server list
+--------------------------------------+---------+--------+-----------------------+------------+
| ID                                   | Name    | Status | Networks              | Image Name |
+--------------------------------------+---------+--------+-----------------------+------------+
| 9ec68b44-80f4-415a-8ee6-5e4dd16663ea | vm_test | ACTIVE | prj_a_net=192.168.5.4 | centos7    |
+--------------------------------------+---------+--------+-----------------------+------------+

# synergy project show -n prj_a -r -t -p -s
╒════════╤════════════════════════════════════════╤═════════════════════════════════════════════╤═════════════════╤═══════╕
│ name   │ private quota                          │ shared quota                                │ share           │   TTL │
╞════════╪════════════════════════════════════════╪═════════════════════════════════════════════╪═════════════════╪═══════╡
│ prj_a  │ vcpus: 0.0 of 3.0 | ram: 0.0 of 2048.0 │ vcpus: 1.0 of 52.0 | ram: 2048.0 of 89052.0 │ 70.00% | 63.64% │    10 │
╘════════╧════════════════════════════════════════╧═════════════════════════════════════════════╧═════════════════╧═══════╛
```
### Attaching a volume

```
# openstack server add volume vm_test volume_test

# openstack volume list
+--------------------------------------+--------------+--------+------+----------------------------------+
| ID                                   | Display Name | Status | Size | Attached to                      |
+--------------------------------------+--------------+--------+------+----------------------------------+
| 32214804-e2a2-4d26-b866-fb3a1522556e | volume_test  | in-use |    1 | Attached to vm_test on /dev/vdb  |
+--------------------------------------+--------------+--------+------+-------------------------------

```
### Verify operation

Access to your virtual machine and check that the _log.txt_ file in new directory _/root/synergy_scripts_ has a similar content:

```
# cat log.txt 
Fri Sep 15 13:06:39 UTC 2017 info: Starting..
Fri Sep 15 13:06:39 UTC 2017 info: 'synergy_cron' file created correctly
Fri Sep 15 13:06:40 UTC 2017 info: user script created correctly
Fri Sep 15 13:06:40 UTC 2017 info: 'check_expiration_time' script created correctly 
Fri Sep 15 13:07:02 UTC 2017 info: expiration time checked
```
For this example check also the _synergy_test_result.txt_ file in /mnt/volume

```
# cat synergy_test_result.txt 
User script executed on: Fri Sep 15 13:11:05 UTC 2017
```



