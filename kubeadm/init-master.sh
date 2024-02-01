#!/bin/bash

echo ">>> INIT MASTER NODE"
sudo systemctl enable kubelet

kubeadm init \
  --apiserver-advertise-address=$MASTER_NODE_IP \
  --control-plane-endpoint $MASTER_NODE_IP \
  --pod-network-cidr=$K8S_POD_NETWORK_CIDR \
  --skip-phases=addon/kube-proxy \
  --ignore-preflight-errors=NumCPU \
  --v=5

echo ">>> CONFIGURE KUBECTL"
sudo mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown $(id -u):$(id -g) /home/vagrant/.kube/config

sudo chown -R vagrant /home/vagrant/.kube
sudo chgrp -R vagrant /home/vagrant/.kube

echo ">>> FIX KUBELET NODE IP"
echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$MASTER_NODE_IP\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo ">>> INSTALL NETWORK ADDON (CANAL)"
envsubst < /vagrant/cni/canal/canal.yaml | kubectl apply -f -

echo ">>> EXPORT KUBECONFIG"
sudo cp -f /home/vagrant/.kube/config /vagrant/.kube/config.vagrant

#https://github.com/kubernetes/kubeadm/issues/2699#issuecomment-1280098175
echo ">>> INIT KUBE-PROXY ADDON"
kubeadm init phase addon kube-proxy \
  --control-plane-endpoint $MASTER_NODE_IP \
  --pod-network-cidr=$K8S_POD_NETWORK_CIDR 

echo ">>> GET WORKER JOIN COMMAND "
rm -f /vagrant/kubeadm/init-worker.sh
kubeadm token create --print-join-command >> /vagrant/kubeadm/init-worker.sh
