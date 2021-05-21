#!/bin/bash
green=`tput setaf 2`
reset=`tput sgr0`
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Enabling strict ARP mode${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Creating namespace for MetalLB${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/namespace.yaml
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Deploying Metal LB${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/metallb.yaml
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Creating secret to enable communication between MetalLB speakers${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Configuring MetalLB - External addresses 192.168.250.100-192.168.250.110 - can be changed in a file to customise${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
cat <<EOF > mlb.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.250.100-192.168.250.110
EOF

kubectl apply -f mlb.yaml
sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Deploying NGINX Ingress Controller for MetalLB${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.46.0/deploy/static/provider/baremetal/deploy.yaml
sleep 1s
