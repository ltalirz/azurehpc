#!/bin/bash
  
# arg: $1 = nfsserver
nfs_server=$1
new_user=hpcuser
home_root=/share/home

# Check to see which OS this is running on.
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')

# Script to be run on all compute nodes
if [ "$os_release" == "centos" ];then
   if [ "$(hostname)" = "$nfs_server" ]; then
       CREATE_HOME="--create-home"
   else
       CREATE_HOME="--no-create-home"
   fi
   adduser \
       $CREATE_HOME \
       --home-dir $home_root/$new_user \
       $new_user
elif [ "$os_release" == "ubuntu" ];then
   if [ "$(hostname)" = "$nfs_server" ]; then
       CREATE_HOME=""
   else
       CREATE_HOME="--no-create-home"
   fi
   adduser $new_user $CREATE_HOME --home $home_root/$new_user --gecos "HPC USER,1,1,1" --disabled-password
fi



if [ "$(hostname)" = "$nfs_server" ]; then
    mkdir -p $home_root/$new_user/.ssh
    cat <<EOF >$home_root/$new_user/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF
    ssh-keygen -f $home_root/$new_user/.ssh/id_rsa -t rsa -N ''
    # add admin user public key (the only user in /home)
    cat /home/*/.ssh/id_rsa.pub >$home_root/$new_user/.ssh/authorized_keys
    cat $home_root/$new_user/.ssh/id_rsa.pub >>$home_root/$new_user/.ssh/authorized_keys
    chown $new_user:$new_user $home_root/$new_user/.ssh
    chown $new_user:$new_user $home_root/$new_user/.ssh/*
    chmod 700 $home_root/$new_user/.ssh
    chmod 600 $home_root/$new_user/.ssh/id_rsa
    chmod 644 $home_root/$new_user/.ssh/id_rsa.pub
    chmod 644 $home_root/$new_user/.ssh/config
    chmod 644 $home_root/$new_user/.ssh/authorized_keys
fi
echo "$new_user ALL=(ALL) NOPASSWD:      ALL" | tee -a /etc/sudoers
