#!/bin/bash

####### Initiate Variables
DOMAIN=yourdomain.com
SERVERNAME=kvm01
STORAGESERVER=stor01
DATABASESERVER=db01
MANAGEMENTSERVER=mgmt01
RELEASE=$(cat /etc/lsb-release | grep CODENAME | awk -F'='  '{print $2}')
VERSION=4.18

####### Obtain Cloudstack Packages
echo "deb https://download.cloudstack.org/ubuntu $RELEASE $VERSION" > /etc/apt/sources.list.d/cloudstack.list
wget -O - https://download.cloudstack.org/release.asc | sudo tee /etc/apt/trusted.gpg.d/cloudstack.asc
apt update

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

####### Install Packages
apt install chrony -y
apt install net-tools -y
apt install cloudstack-agent -y
apt install libvirt-daemon -y

####### Setup KVM properties
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
