#!/bin/bash

####### Initiate Variables
DOMAIN=yourdomain.com
SERVERNAME=mgmt01
STORAGESERVER=mgmt01
DATABASESERVER=mgmt01
RELEASE=$(cat /etc/lsb-release | grep CODENAME | awk -F'='  '{print $2}')
VERSION=4.18

####### Check FQDN and reboot after changing (when needed)
if [ hostname --fqdn != $SERVERNAME.$DOMAIN ]
then
        printf "If statement checked servername\n"
        printf "Changing hostname to $SERVERNAME.$DOMAIN\n"
        hostnamectl $SERVERNAME.$DOMAIN
        printf "I'll wait 10 seconds before rebooting\n"
        sleep 10
        reboot
fi

####### Obtain Cloudstack Packages
echo "deb https://download.cloudstack.org/ubuntu $RELEASE $VERSION" > /etc/apt/sources.list.d/cloudstack.list
wget -O - https://download.cloudstack.org/release.asc | sudo tee /etc/apt/trusted.gpg.d/cloudstack.asc

####### Install Cloudstack

sudo apt update
sudo apt install cloudstack-management -y

####### Install MySQL
sudo apt update
sudo apt install mysql-server -y
printf "\n[mysqld]\ninnodb_rollback_on_timeout=1\ninnodb_lock_wait_timeout=600\nmax_connections=350\nlog-bin=mysql-bin\nbinlog-format=ROW" >> /etc/mysql/mysql.conf.d/mysqld.cnf
server-id = 1
sudo systemctl restart mysql

####### Setup Cloudstack Database Config
sudo cloudstack-setup-databases cloud:cloud@$DATABASESERVER.$DOMAIN --deploy-as=root

####### Setup Mounts (Needs update)
sudo apt update
sudo apt install nfs-kernel-server -y
mkdir -p /export/secondary
printf '/export *(rw,async,no_root_squash,no_subtree_check)' >> /etc/exports
printf "rpcbind mountd nfsd statd lockd rquotad : $STORAGESERVER.$DOMAIN" >> /etc/hosts.allow
sudo exportfs -a
sudo systemctl restart nfs-kernel-server.service

####### Finalizing Steps
cloudstack-setup-management
