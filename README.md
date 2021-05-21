This automates deployment of Kubernetes with Master Node and any amount of Worker Nodes on CentOS 8 Upstream.

Scripts are using this guidance with some adjustments for automation purposes:

https://upcloud.com/community/tutorials/install-kubernetes-cluster-centos-8/

Follow these steps to deploy Kubernetes:

1. Install Centos 8 on your Virtual Environment: i.e. VMWare Fusion
2. Login as root to your Master Node and Worker Nodes and deploy git by using:

	yum install git	

3. Get this repository by using:

	git clone https://github.com/porec/kubeinstall
 
4. Change directory

	cd kubeinstall

5. Make files owned by root and executable

	chmod 777 install_common.sh

6. Run install_common.sh on Master node and all Worker Nodes. This will prepare your system for Kubernetes implementation

	./install_commob.sh
