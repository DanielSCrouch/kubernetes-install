#!/bin/bash

CURRENT_USER=$(logname)
CLUSTER_NAME="factory1"
MASTER_WORKER_NODE=$1
CONTROLLER_IP=$2

requirements::install_docker(){

    # Update apt
    echo "[Docker-Install] Update apt"
    if ! apt -qq update  &> /dev/null; then
        echo  "[ERROR] Failed to update apt"
        exit 1
    fi


    # Install requirements for Docker
    echo "[Docker-Install] Install docker requirements"
    if ! apt install -qq -y apt-transport-https ca-certificates curl gnupg lsb-release  &> /dev/null; then
        echo  "[ERROR] Failed to install docker requirements"
        exit 1
    fi

    # Add Docker GPG key
    echo "[Docker-Install] Add docker gpg key"
    if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg  &> /dev/null; then
        echo "[ERROR] Failed to import docker gpg key"
        exit 1
    fi

    # Set up stable repo
    echo "[Docker-Install] Add docker gpg key to apt"
    if ! echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list  &> /dev/null; then
        echo "[ERROR] Failed to add gpg key to apt"
        exit 1
    fi

    # Install docker engine
    echo "[Docker-Install] Update apt"
    if ! apt -qq update  &> /dev/null; then
        echo  "[ERROR] Failed to update apt"
        exit 1
    fi

    # Install docker
    echo "[Docker-Install] Install docker engine using apt"
    if ! apt install -qq -y docker-ce docker-ce-cli containerd.io  &> /dev/null; then
        echo "[ERROR] Failed to install docker engine"
        exit 1
    fi

    # Configure Docker to use systemd
    echo "[Docker-Install] Condigure docker engine to use systemd"
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
    "max-size": "100m"
    },
    "storage-driver": "overlay2"
}
EOF
    mkdir -p /etc/systemd/system/docker.service.d


    # Start docker on boot
    echo "[Docker-Install] Enable docker services"
    if ! systemctl enable docker.service  &> /dev/null; then
        echo "[ERROR] Failed to enable docker service"
        exit 1
    fi

    # Unmask docker
    if ! systemctl unmask docker.service  &> /dev/null; then
        echo "[ERROR] Failed to unmask docker service"
        exit 1
    fi

    echo "[Docker-Install] Start docker services"
    if ! systemctl start docker.service  &> /dev/null; then
        echo "[ERROR] Failed to start docker service"
        exit 1
    fi

    # Add to docker user group
    echo "[Docker-Install] Add user to docker group"
    if ! usermod -aG docker $CURRENT_USER &> /dev/null; then
        echo "[ERROR] Failed to add user to docker group"
        exit 1
    fi

    # Restart docker
    echo "[Docker-Install] Restart docker service"
    if ! systemctl restart docker &> /dev/null; then
        echo "[ERROR] Failed to restart docker service"
        exit 1
    fi
}

requirements::install_kubernetes(){
    # Update apt
    echo "[Kubernetes-Install] Update apt"
    if ! apt -qq update  &> /dev/null; then
        echo  "[ERROR] Failed to update apt"
        exit 1
    fi

    # # Upgrade apt
    # echo "[Kubernetes-Install] Upgrade apt"
    # if ! apt -qq -y upgrade  &> /dev/null; then
    #     echo  "[ERROR] Failed to upgrade apt"
    #     exit 1
    # fi

    # Add keys
    echo "[Kubernetes-Install] Install Requirements"
    if ! apt -y install curl apt-transport-https  &> /dev/null; then
        echo  "[ERROR] Failed to install requirements"
        exit 1
    fi

    echo "[Kubernetes-Install] Get Kubernetes gpg key"
    if ! curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -  &> /dev/null; then
        echo  "[ERROR] Failed to get gpg key"
        exit 1
    fi

    echo "[Kubernetes-Install] Add Kubernetes gpg key to apt"
    if ! echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list  &> /dev/null; then
        echo  "[ERROR] Failed to add gpg key to apt"
        exit 1
    fi

    # Update apt
    echo "[Kubernetes-Install] Update apt"
    if ! apt -qq update  &> /dev/null; then
        echo  "[ERROR] Failed to update apt"
        exit 1
    fi

    echo "[Kubernetes-Install] Install kubernetes packages"
    if ! apt -y install vim git curl wget kubelet kubeadm kubectl  &> /dev/null; then
        echo  "[ERROR] Failed to install kubernetes packages"
        exit 1
    fi

    echo "[Kubernetes-Install] Mark kubernetes packages"
    if ! apt-mark hold kubelet kubeadm kubectl  &> /dev/null; then
        echo  "[ERROR] Failed to update apt"
        exit 1
    fi

    echo "[Kubernetes-Install] Turn swap off"
    if ! sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab  &> /dev/null; then
        echo "[ERROR] Failed to turn swap off in /etc/fstab"
        exit 1
    fi

    if ! swapoff -a  &> /dev/null; then
        echo "[ERROR] Failed to turn swap off"
        exit 1
    fi

    echo "[Kubernetes-Install] Load kernel modules"
    if ! modprobe overlay  &> /dev/null; then
        echo "[ERROR] Failed to load overlay module"
        exit 1
    fi

    if ! modprobe br_netfilter  &> /dev/null; then
        echo "[ERROR] Failed to load overlay module"
        exit 1
    fi

    echo "[Kubernetes-Install] Create sysctl kubernetes file"
    # Configure sysctl
    tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to create kubernetes sysctl file"
        exit 1
    fi

    echo "[Kubernetes-Install] Reload sysctl"
    if ! sysctl --system  &> /dev/null; then
        echo "[ERROR] Failed to reload sysctl"
        exit 1
    fi
    # Configure persistent loading of modules
    echo "[Kubernetes-Install] Create persistent loading of containerd modules"
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to create persistent loading of containerd modules"
        exit 1
    fi

    # Load at runtime
    echo "[Kubernetes-Install] Load kernel modules"
    if ! modprobe overlay  &> /dev/null; then
        echo "[ERROR] Failed to load overlay module"
        exit 1
    fi

    if ! modprobe br_netfilter  &> /dev/null; then
        echo "[ERROR] Failed to load overlay module"
        exit 1
    fi

    echo "[Kubernetes-Install] Install containerd requirements"
    if ! apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates  &> /dev/null; then
        echo  "[ERROR] Failed to install containerd requirements"
        exit 1
    fi

    echo "[Kubernetes-Install] Setup containerd configs"
    if ! mkdir -p /etc/containerd  &> /dev/null; then
        echo  "[ERROR] Failed to create /etc/containerd"
        exit 1
    fi

    rm -rf /etc/containerd/config.toml

    if ! touch /etc/containerd/config.toml  &> /dev/null; then
        echo  "[ERROR] Failed to create /etc/containerd/config.toml"
        exit 1
    fi

    if ! containerd config default > /etc/containerd/config.toml; then
        echo  "[ERROR] Failed to create containerd config"
        exit 1
    fi


    # Configure toml file to load correct driver
    echo "[Kubernetes-Install] Configure containerd driver"
    if ! sed -i '/^.*\[plugins\.\"io\.containerd\.grpc\.v1\.cri\"\.containerd\.runtimes\.runc\.options\]/a \\t\ \tSystemdCgroup = true' /etc/containerd/config.toml; then
        echo  "[ERROR] Failed to configure containerd driver"
        exit 1
    fi

    echo "[Kubernetes-Install] Restart and enable containerd"
    if ! systemctl restart containerd  &> /dev/null; then
        echo  "[ERROR] Failed to restart containerd"
        exit 1
    fi

    if ! systemctl enable containerd  &> /dev/null; then
        echo  "[ERROR] Failed to enable containerd"
        exit 1
    fi

        # Configure kubernetes to use driver
    cat <<EOF | sudo tee /etc/containerd/kubeadm_config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
    podSubnet: 10.244.0.0/16 # --pod-network-cidr
    serviceSubnet: "172.16.0.0/12"
clusterName: $CLUSTER_NAME
---
apiversion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
  - token: g1utv3.j0ehzl2roqi1yaok
    description: "kubeadm boostrap token"
    ttl: "24h"
    usages:
      - authentication
      - signing
    groups:
      - system:bootstrappers:kubeadm:default-node-token
EOF

}

#################################################
# MAIN
#################################################

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] This script must be run as root"
   exit 1
fi

# Install docker if it is not already installed
if ! command -v ctr &> /dev/null
then
    echo "[Docker-Install] Installing docker"
    requirements::install_docker
else
    echo "[WARN] Docker is already installed, skipping installation"
fi

# Install kubernetes if it is not already installed
if ! command -v kubectl &> /dev/null
then
    echo "[Docker-Install] Installing kubernetes components"
    requirements::install_kubernetes
else
    echo "[WARN] Kubernetes is already installed, skipping installation..."
fi

# Install kubernetes if it is not already installed
if ! command -v kubectl &> /dev/null
then
    echo "[Docker-Install] Installing kubernetes components"
    requirements::install_kubernetes
else
    echo "[WARN] Kubernetes is already installed, skipping installation..."
fi

# Configure kubernetes as controller node 
if [[ $1 == "-m" ]]; then
    echo "[Kubernetes-Initialise] Initialising controller node"
    sudo kubeadm init --config=/etc/containerd/kubeadm_config.yaml --ignore-preflight-errors="NumCPU"

    echo "[Kubernetes-Initialise] Setting kubeconfig cluster authentication file"
    CURRENT_USER=$(logname)
    mkdir -p /home/$CURRENT_USER/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/$CURRENT_USER/.kube/config
    sudo chown $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.kube/config
    # Set the kubeconfig var if running as sudo
    KUBECONFIG="/etc/kubernetes/admin.conf"

    echo "[Kubernetes-Initialise] Deploy the overlay network (flannel)"
    kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    kubectl --kubeconfig /home/$CURRENT_USER/.kube/config config set-cluster $CLUSTER_NAME --insecure-skip-tls-verify=true
fi

# Configure kubernetes as worker node 
if [[ $1 == "-w" ]]; then
    CONTROLLER_IP=$2
    echo "[Kubernetes-Initialise] Initialising worker node with controller IP $CONTROLLER_IP"
    sudo kubeadm join $CONTROLLER_IP:6443 --token g1utv3.j0ehzl2roqi1yaok --discovery-token-unsafe-skip-ca-verification
fi


# https://kubernetes.io/docs/reference/setup-tools/kubeadm/implementation-details/ 
# https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta2/
