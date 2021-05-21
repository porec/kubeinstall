#!/bin/bash
echo "Updating Server"
dnf -y upgrade
echo "Disabling SELinux enforcement"
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
echo "Enabling transparent masquerading and facilitate Virtual Extensible LAN (VxLAN) traffic for communication between Kubernetes pods across the cluster"
modprobe br_netfilter
echo "Enabling IP masquerade at the firewall"
firewall-cmd --add-masquerade --permanent
echo "Reloading firewall"
firewall-cmd --reload

