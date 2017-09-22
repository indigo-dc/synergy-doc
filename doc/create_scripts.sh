#!/bin/bash
echo `date`" info: Starting.." >>/root/synergy_scripts/log.txt;
# Create Synergy cron file
cat << EOF >/etc/cron.d/synergy_cron
*/1 * * * * root /root/synergy_scripts/check_execution_time.sh
EOF
if [ $? -eq 0 ]; then 
  echo `date`" info: 'synergy_cron' file created correctly" >>/root/synergy_scripts/log.txt;
else
  echo `date`" error: 'synergy_cron file not created" >>/root/synergy_scripts/log.txt;
fi
user_script_path=$(curl -s http://169.254.169.254/openstack/latest/user_data | grep -m1 -oP '(?<=user_script_path=).*')
if [ $? -ne 0 ]; then 
  echo `date`" error: 'user_script_path' variable not valorized" >>/root/synergy_scripts/log.txt;
fi

# Check user script creation
if [[ -x "$user_script_path" ]]; then
  echo `date`" info: user script created correctly" >>/root/synergy_scripts/log.txt;
fi

# Create check execution time script
cat << 'EOF' >> /root/synergy_scripts/check_execution_time.sh
#!/bin/bash
# Expiration time in sec. since 1970-01-01 00:00:00 UTC
expiration_time=$(curl -s http://169.254.169.254/openstack/latest/meta_data.json | grep -oP "(?<=\"expiration_time\": \")[^\"]+")
if [ $? -ne 0 ]; then 
  echo `date`" error: 'expiration_time' variable not valorized" >>/root/synergy_scripts/log.txt;
fi

# Time in min.
syn_clock=$(curl -s http://169.254.169.254/openstack/latest/user_data | grep -m1 -oP '(?<=syn_clock=).*')
if [ $? -ne 0 ]; then 
  echo `date`" error: 'syn_clock' variable not valorized" >>/root/synergy_scripts/log.txt;
fi

# Current time in sec. since 1970-01-01 00:00:00 UTC
curr_time=$(date -u +%s)

# Compute the difference time in min.
let "time_diff=($expiration_time-$curr_time)/60"
if [ "$time_diff" -le "$syn_clock" ]
then
EOF
cat <<EOF>> /root/synergy_scripts/check_execution_time.sh
    $user_script_path
EOF
cat <<'EOF'>> /root/synergy_scripts/check_execution_time.sh
    if [ $? -eq 0 ]; then 
      echo `date`" info: user script executed correctly" >>/root/synergy_scripts/log.txt;
      rm -rf /etc/cron.d/synergy_cron; 
      echo `date`" info: 'synergy_cron' file removed correctly" >>/root/synergy_scripts/log.txt;
    fi
else
    echo `date`" info: execution time checked" >>/root/synergy_scripts/log.txt;
fi
EOF
if [ $? -eq 0 ]; then 
  echo `date`" info: 'check_execution_time' script created correctly " >>/root/synergy_scripts/log.txt;
else
  echo `date`" error: 'check_execution_time' script not created" >>/root/synergy_scripts/log.txt;
fi
chmod 755 /root/synergy_scripts/check_execution_time.sh
