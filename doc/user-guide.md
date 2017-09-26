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

Synergy version: service 1.5.3, scheduler 2.6.0

Operating Systems: CentOS 7, Ubuntu 14.04

OpenStack versions: Ocata, Newton

Make sure you have access to the Internet from your virtual machine

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

This bash script creates the userdata that will be used during VM contextualization phase (contextualisation phase configure a VM after it has been installed).

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
  echo "Please enter userdata name:"
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
## Generating userdate file

To generate userdata run the following comand:

```
# ./generate_userdata.sh my_script.sh
```
