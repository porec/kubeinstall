#!/bin/bash

green=`tput setaf 2`
red=`tput setaf 1`
reset=`tput sgr0`

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Insert Prisma Cloud Compute Download link${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
read pcc_lnk
export PCC_LINK=$pcc_lnk
export PCC_FILE=$(echo $PCC_LINK | cut -d "/" -f 6)

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Insert Prisma Cloud Compute Access Token${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
read pcc_tok
export PCC_TOKEN=$pcc_tok

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Insert Prisma Cloud Compute license key${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
read pcc_lic
export PCC_LICENSE=$pcc_lic

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Input initial user name for login to Prisma Cloud Compute Console: i.e. admin${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
read usr_nam
export PCC_USER=$usr_nam

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Input password for initial user ${PCC_USER}${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"
read usr_pas
export PCC_PASS=$usr_pas

sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Downloading Prisma Cloud Compute Software${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"


mkdir prisma_cloud
wget $PCC_LINK
tar xvzf $PCC_FILE -C prisma_cloud/

sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Creating Persistent Volume for Prisma Cloud Compute Console: 1GB is enough for Test deployment${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"

#Creating  directory mapping for persistent volume

mkdir /var/pcc-volume

# Creating local persistent volume on Master Node

cat << EOF > pcc-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pcc-volume
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /var/pcc-volume
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - master
EOF

kubectl apply -f pcc-pv.yaml

sleep 1s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Generating Prisma Cloud Compute Console Deployment file while exposing port 8083 over Master Node port 30083 and port 8084 via Master Node Port 30084 ${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"

cd prisma_cloud

# Generating Prisma Cloud Compute Console Deployment File, while exposing port 8083 over Master Node port 30083 and port 8084 via Master Node Port 30084

linux/twistcli console export kubernetes --service-type LoadBalancer --persistent-volume-storage 1Gi --storage-class local-storage --registry-token $PCC_TOKEN
sleep 2s
sed -i '/  port: 8083/a\    nodePort: 30083' twistlock_console.yaml
sed -i '/  port: 8084/a\    nodePort: 30084' twistlock_console.yaml


sleep 3s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Deploying Prisma Cloud Compute Console. Please Wait for 1 minute ${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"


#Deploying Console

kubectl create -f twistlock_console.yaml

#Getting Service IP - PCC_SIP and Cluster IP PCC_CIP

sleep 60s

export PCC_CIP=$(kubectl get pod -A -o wide | grep etcd-master | awk '{print $7}')
export PCC_SIP=$(kubectl get services -A | grep twistlock-console | awk '{print $5}')

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Service IP Adress is: ${PCC_SIP} ${reset}"
echo "${green}Cluster IP Adress is: ${PCC_CIP} ${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Creating Initital User for Prisma Cloud Compute. Please Wait for 1 minute. ${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"

sleep 60s

#Create initial username

curl -k \
  -H 'Content-Type: application/json' \
  -X POST \
  -d '{"username": "'${PCC_USER}'", "password": "'${PCC_PASS}'"}' \
  https://$PCC_SIP:8083/api/v1/signup

#Generating API Token

sleep 3s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Creating API Token ${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"


export API_TOKEN=$(curl -H "Content-Type: application/json" -d '{"username":"'${PCC_USER}'", "password":"'${PCC_PASS}'"}' https://$PCC_SIP:8083/api/v1/authenticate --insecure | cut -d ":" -f 2 | tr -d "}" | tr -d '"')

sleep 3s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Licensing Prisma Cloud Compute ${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"


#License twistlock_console

curl -k \
  -H 'Authorization: Bearer '${API_TOKEN}'' \
  -H 'Content-Type: application/json' \
  -X POST \
  -d '{"key": "'${PCC_LICENSE}'"}' \
  https://$PCC_SIP:8083/api/v1/settings/license --insecure



sleep 3s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Adding SAN Fields with Service IP address: ${PCC_SIP} and Cluster IP address: ${PCC_CIP}  ${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"



curl -k \
  -H 'Authorization: Bearer '${API_TOKEN}'' \
  -H 'Content-Type: application/json' \
  -w "\nResponse code: %{http_code}\n" \
  -X POST \
  -d '
  {
    "consoleSAN": [
      "'${PCC_SIP}'",
      "'${PCC_CIP}'",
      "127.0.0.1"
    ]
  }' \
  https://$PCC_SIP:8083/api/v1/settings/certs --insecure



sleep 10s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Generating Defender Deployment File ${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"

linux/twistcli defender export kubernetes --privileged --address https://$PCC_SIP:8083 --user $PCC_USER --password $PCC_PASS --cluster-address $PCC_CIP:30084

sleep 10s
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "${green}Deploying Defenders ${reset}"
echo "------------------------------------------------------------------------------------------------------------------------------------"

kubectl create -f defender.yaml

#curl -k \
#  -H 'Authorization: Bearer '${API_TOKEN}'' \
#  -H 'Content-Type: application/json' \
#  -X GET \
#  https://$PCC_SIP:8083/api/v1/defenders --insecure

