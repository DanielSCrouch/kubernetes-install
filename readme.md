
# Kubernetes Installation Script

A shell installation script for installing Kubernetes onto a Linux Ubuntu virtual machine. The script will automatically configure the host, install Docker, Kubernetes, and deploy a Flannel based CNI with a common **default Kubeadm cluster token**. 

Install master node:

```bash 
chmod +x install.sh
# Run with defaults
sudo ./install.sh
# Set custom options
sudo ./install.sh --node master --cluster-name cluster1 --token g1utv3.j0ehzl2roqi1yaok
sudo ./install.sh -n master -c cluster1 -t g1utv3.j0ehzl2roqi1yaok
```

Install worker node (join to existing master node):

```bash
chmod +x install.sh
# Run with defaults
sudo ./install.sh -node worker -address-master <ip-address-of-master-node>
# Set custom options
sudo ./install.sh --node worker --address-master 10.40.1.10 --token g1utv3.j0ehzl2roqi1yaok
sudo ./install.sh -n worker -a 10.40.1.10 -t g1utv3.j0ehzl2roqi1yaok
```



