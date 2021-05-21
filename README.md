This automates deployment of Kubernetes with Master Node and any amount of Worker Nodes on CentOS 8 Upstream.

Scripts are using this guidance with some adjustments for automation purposes:

https://upcloud.com/community/tutorials/install-kubernetes-cluster-centos-8/

Follow these steps to deploy Kubernetes:

1. Install Centos 8 on your Virtual Environment: i.e. VMWare Fusion
2. Login as root to your Master Node and Worker Nodes and deploy git by using:

	**yum install git**	

3. Get this repository by using:

	**git clone https://github.com/porec/kubeinstall**
 
4. Change directory

	**cd kubeinstall**

5. Make files owned by root and executable

	**chmod 777 install_common.sh**
	**chmod 777 configure_master.sh**

6. Run install_common.sh on Master node and all Worker Nodes. This will prepare your system for Kubernetes implementation

	**./install_common.sh**

7. Run configure_master.sh ONLY on Master node. This will configure Kubernetes Master Node with Control Plane and will deploye Calico CNI for Network Management. Please also take a note on command for connectivity from Worker Nodes. Visible under red colored statement "Remember to copy tokens for adding Worker Nodes".

	**./configure_master.sh**

8. Join all Worker Nodes to Master Node by executing command on Worker Node. Command was visible on Master Node after execution of ./configure_master.sh

	**kubeadm join 192.168.250.2:6443 --token <YOUR_TOKEN> \
	--discovery-token-ca-cert-hash sha256: <YOUR_TOKEN_HASH>**
