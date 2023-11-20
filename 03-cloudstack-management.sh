#!/bin/bash

####### Initiate Variables
DOMAIN=yourdomain.com
SERVERNAME=mgmt01
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

####### Obtain Cloudstack Packages
echo "deb https://download.cloudstack.org/ubuntu $RELEASE $VERSION" > /etc/apt/sources.list.d/cloudstack.list 
wget -O - https://download.cloudstack.org/release.asc | sudo tee /etc/apt/trusted.gpg.d/cloudstack.asc 

####### Update APT and Install Cloudstack and Requirements 
sudo apt update
apt-get install chrony -y
sudo apt install cloudstack-management -y

####### Setup Database (Database Server Available and YOLO root passwords)
cloudstack-setup-databases cloud:cloud@$DATABASESERVER.$DOMAIN --deploy-as=root:randompassword1234567890

####### Create and Mount Directories from Storage Server (Server must be available)
sudo apt install nfs-common
mkdir -p /mnt/secondary
mount -t nfs $STORAGESERVER.$DOMAIN:/export/secondary /mnt/secondary

####### Setup Finalize 
cloudstack-setup-management
