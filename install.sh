#!/bin/bash
green=`tput setaf 2`
reset=`tput sgr0` 
echo "${green}Updating Server${reset}"
dnf -y upgrade
echo "${green}Disabling SELinux enforcement${reset}"
sleep 1s
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sleep 1s
echo "${green}Enabling transparent masquerading and facilitate Virtual Extensible LAN (VxLAN) traffic for communication between Kubernetes pods across the cluster${reset}"
modprobe br_netfilter
sleep 1s
echo "${green}Enabling IP masquerade at the firewall${reset}"
firewall-cmd --add-masquerade --permanent
sleep 1s
echo "${green}Reloading firewall${reset}"
firewall-cmd --reload
sleep 1s
echo "${green}Set bridged packets to traverse iptables rules${reset}"
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sleep 1s
echo "${green}Loading the new rules${reset}"
sysctl --system
echo "${green}New rules are loaded${reset}"
sleep 1s
echo "${green}Disabling all memory swaps to increase performance${reset}"
swapoff -a
sed -i 's|/dev/mapper/cs-swap|#/dev/mapper/cs-swap|g' /etc/fstab
sleep 1s
