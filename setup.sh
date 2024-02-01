#!/bin/bash

rm -rf .kube/config.vagrant
rm -rf kubeadm/init-worker.sh

vagrant up master --provider=virtualbox
cp -f .kube/config.vagrant ~/.kube/config.vagrant

for i in {1..3}
do 
    sleep 5
    vagrant up worker-$i &
done