#!/bin/bash

####### Initiate Variables
DOMAIN=yourdomain.com
SERVERNAME=mgmt01
STORAGESERVER=mgmt01
DATABASESERVER=mgmt01
RELEASE=$(cat /etc/lsb-release | grep CODENAME | awk -F'='  '{print $2}')
VERSION=4.18

####### Check FQDN and reboot after changing (when needed)
if [ $(hostname --fqdn) != $SERVERNAME.$DOMAIN ]
then
        printf "If statement checked servername\n"
        printf "Changing hostname to $SERVERNAME.$DOMAIN\n"
        hostnamectl set-hostname $SERVERNAME.$DOMAIN
        printf "I'll wait 10 seconds before rebooting\n"
        sleep 5
        reboot
fi

####### Change /etc/hosts
printf "127.0.0.1 $SERVERNAME.$DOMAIN\n" >> /etc/hosts
printf "127.0.0.1 $DOMAIN\n" >> /etc/hosts

####### Obtain Cloudstack Packages
echo "deb https://download.cloudstack.org/ubuntu $RELEASE $VERSION" > /etc/apt/sources.list.d/cloudstack.list
wget -O - https://download.cloudstack.org/release.asc | sudo tee /etc/apt/trusted.gpg.d/cloudstack.asc

####### Install Cloudstack

sudo apt update
sudo apt install cloudstack-management -y

####### Install MySQL
sudo apt update
sudo apt install mysql-server -y
printf "\n[mysqld]\ninnodb_rollback_on_timeout=1\ninnodb_lock_wait_timeout=600\nmax_connections=350\nlog-bin=mysql-bin\nbinlog-format=ROW\nserver-id = 1\n" >> /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql
sleep 5

####### Setup Cloudstack Database Config
sudo cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root

####### Setup Mounts (Needs update)
sudo apt update
sudo apt install nfs-kernel-server -y
mkdir -p /export/secondary
printf '/export *(rw,async,no_root_squash,no_subtree_check)' >> /etc/exports
printf "rpcbind mountd nfsd statd lockd rquotad : $STORAGESERVER.$DOMAIN" >> /etc/hosts.allow
sudo exportfs -a
sudo systemctl restart nfs-kernel-server.service

mkdir /primary_test
mount -t nfs 127.0.0.1:/export/primary /primary_test
umount /primary_test
rm -r /primary_test

mkdir /secondary_test
mount -t nfs 127.0.0.1:/export/secondary /secondary_test
umount /secondary_test
rm -r /secondary_test

####### Finalizing Steps
cloudstack-setup-management

####### Install a cloudstack-agent with local KVM host
sudo apt install cloudstack-agent -y
printf "\nguest.cpu.mode=custom\nguest.cpu.model=SandyBridge" >> /etc/cloudstack/agent/agent.properties
sed -i "s/^\host=.*/host=${MGMTSERVER}.${DOMAIN}/" /etc/cloudstack/agent/agent.properties
printf '\nlisten_tls = 0\nlisten_tcp = 0\ntls_port = "16514"\ntcp_port = "16509"\nauth_tcp = "none"\nmdns_adv = 0\n' >> /etc/libvirt/libvirtd.conf
printf '\nLIBVIRTD_ARGS="--listen"' >> /etc/default/libvirtd
service restart libvirtd

####### Setup apparmor to allow stuff
dpkg --list 'apparmor'
ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper

####### Finalizing Database
printf "Finalizing Database\n"
printf "Wait for 2 Minutes\n"
sleep 120
printf "Browse to http://$SERVERNAME.$DOMAIN:8080"
