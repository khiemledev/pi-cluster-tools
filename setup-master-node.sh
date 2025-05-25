#!/bin/bash

echo "Disable swap"
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "=============================="
echo "\n\n\n"
echo "Forwarding IPv4 and letting iptables see bridged traffic"

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Verify that the br_netfilter, overlay modules are loaded by running the following commands:
lsmod | grep br_netfilter
lsmod | grep overlay

# Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

echo "=============================="
echo "\n\n\n"
echo "Install contianer runtime"

curl -LO https://github.com/containerd/containerd/releases/download/v2.1.1/containerd-2.1.1-linux-arm64.tar.gz
sudo tar Cxzvf /usr/local containerd-2.1.1-linux-arm64.tar.gz
curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir -p /usr/local/lib/systemd/system/
sudo mv containerd.service /usr/local/lib/systemd/system/
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Check that containerd service is up and running
systemctl status containerd

echo "=============================="
echo "\n\n\n"
echo "Install runc"
curl -LO https://github.com/opencontainers/runc/releases/download/v1.3.0/runc.arm64
sudo install -m 755 runc.arm64 /usr/local/sbin/runc

echo "=============================="
echo "\n\n\n"
echo "Install cni plugin"
curl -LO https://github.com/containernetworking/plugins/releases/download/v1.7.1/cni-plugins-linux-arm64-v1.7.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-arm64-v1.7.1.tgz

echo "=============================="
echo "\n\n\n"
echo "Install kubeadm, kubelet and kubectl"

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=1.32.5-1.1 kubeadm=1.32.5-1.1 kubectl=1.32.5-1.1 --allow-downgrades --allow-change-held-packages
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version
kubelet --version
kubectl version --client

echo "=============================="
echo "\n\n\n"
echo "Setup aliases for kubectl"
cp ./kubectl_aliases $HOME/
chmod +x kubectl_aliases
printf "\n\nsource $HOME/kubectl_aliases\n" >> $HOME/.bashrc

echo "=============================="
echo "\n\n\n"
echo "Configure crictl to work with containerd"
sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock

echo "=============================="
echo "\n\n\n"
echo "Start master node"

sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$(hostname -I) --node-name master

echo "=============================="
echo "\n\n\n"
echo "Copy admin config to ~/.kube"

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "=============================="
echo "\n\n\n"
echo "Allow inbound for APIServer (6443)"

sudo ufw allow 6443

