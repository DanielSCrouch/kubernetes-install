
# Kubernetes Installation Script

A shell installation script for installing Kubernetes onto a Linux Ubuntu virtual machine. The script will automatically configure the host, install Docker, Kubernetes, and deploy a Flannel based CNI with a common **default Kubeadm cluster token**. 

Install controller node:

```bash 
chmod +x install.sh
./install.sh -m
```

Install worker node (join to existing controller node):

```bash
chmod +x install.sh
./install.sh -w <ip-address-of-controller-node>
```

