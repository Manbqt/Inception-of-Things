#!/bin/bash

apk update
# Use environment variables to configure the installation
export INSTALL_K3S_EXEC="--flannel-iface=eth1"
export K3S_TOKEN_FILE=/vagrant_shared/token
export K3S_URL=https://$1:$2

curl -sfL https://get.k3s.io |  sh -
