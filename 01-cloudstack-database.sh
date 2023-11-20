#!/bin/bash

####### Initiate Variables
DOMAIN=yourdomain.com
SERVERNAME=db01
STORAGESERVER=stor01
DATABASESERVER=db01
RELEASE=$(cat /etc/lsb-release | grep CODENAME | awk -F'='  '{print $2}')
VERSION=4.18

####### Check FQDN and reboot after changing (when needed)
if [ $(hostname --fqdn) != $SERVERNAME.$DOMAIN ]
then
        printf "If statement checked servername\n"
        printf "Changing hostname to $SERVERNAME.$DOMAIN\n"
        hostnamectl set-hostname $SERVERNAME.$DOMAIN
        printf "I'll wait 10 seconds before rebooting\n"
        sleep 10
        reboot
fi


sudo apt update
sudo apt install mysql-server -y
printf "\n[mysqld]\ninnodb_rollback_on_timeout=1\ninnodb_lock_wait_timeout=600\nmax_connections=350\nlog-bin=mysql-bin\nbinlog-format=ROW"\nserver-id=1 >> /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql
