#!/bin/bash

####### Initiate Variables
DOMAIN=yourdomain.com
SERVERNAME=stor01
STORAGESERVER=stor01
DATABASESERVER=db01
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

sudo apt update
sudo apt install nfs-kernel-server -y
mkdir -p /export/secondary
printf "/export $STORAGESERVER.$DOMAIN(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports
printf "rpcbind mountd nfsd statd lockd rquotad : $STORAGESERVER.$DOMAIN" >> /etc/hosts.allow
sudo exportfs -a
sudo systemctl restart nfs-kernel-server.service
