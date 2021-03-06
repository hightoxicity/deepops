#!/usr/bin/env bash

# Install dependencies
. /etc/os-release
case "$ID_LIKE" in
    rhel*)
        type curl >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            sudo yum -y install curl
        fi
        ;;
    debian*)
        type curl >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            sudo apt -y install curl
        fi
        ;;
    *)
        echo "Unsupported Operating System $ID_LIKE"
        exit 1
        ;;
esac

# Grab kubernetes admin config file from kubernetes nodes
ansible gpu-servers -b -m fetch -a "src=/etc/kubernetes/admin.conf flat=yes dest=./"

# Grab kubectl binary
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin

# Merge or copy kubernetes config file
mkdir -p ~/.kube
KUBECONFIG=./admin.conf
if [ -f ~/.kube/config ] ; then
    mv ~/.kube/config{,.bak}
    KUBECONFIG=${KUBECONFIG}:~/.kube/config.bak 
fi
KUBECONFIG=${KUBECONFIG} kubectl config view --flatten | tee ~/.kube/config
rm ./admin.conf
