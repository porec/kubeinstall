#!/bin/bash
green=`tput setaf 2`
reset=`tput sgr0` 
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Preparing Infrastructure${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo ""
echo ""
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Updating Server${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
dnf -y upgrade
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Disabling SELinux enforcement${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Enabling transparent masquerading and facilitate Virtual Extensible LAN (VxLAN) traffic for communication between Kubernetes pods across the cluster${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
modprobe br_netfilter
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Enabling IP masquerade at the firewall${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
firewall-cmd --add-masquerade --permanent
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Reloading firewall${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
firewall-cmd --reload
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Set bridged packets to traverse iptables rules${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Loading the new rules${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
sysctl --system
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}New rules are loaded${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Disabling all memory swaps to increase performance${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
swapoff -a
sed -i 's|/dev/mapper/cs-swap|#/dev/mapper/cs-swap|g' /etc/fstab
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Installing Docker${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
sleep 1s
echo ""
echo ""
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Adding the repository for the docker installation package${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo -y
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Installing container.io which is not yet provided by the package manager before installing docker${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
dnf install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Installing Docker from repositories${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
dnf install docker-ce --nobest -y
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Starting Docker service${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
systemctl start docker
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Making Docker service to start after reboot${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
systemctl enable docker
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Checiking Docker version${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
if docker version | grep -q 'Version'; then
  echo "------------------------------------------------------------------------------------------------------------------------------------"
  echo "${green}Docker is running${reset}"
  echo "------------------------------------------------------------------------------------------------------------------------------------"
else
  echo "------------------------------------------------------------------------------------------------------------------------------------"  
  echo "${green}Docker deployment failed${reset}"
  echo "------------------------------------------------------------------------------------------------------------------------------------"
fi
docker version
sleep 1s

