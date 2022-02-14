#!/bin/bash

# This script creates an Istio Multi-cluster "Multi-primary on different networks" environment.
# It will be an environment for demo/development/testing purposes.
#
# Reference docs for this setup can be found in:
#   https://istio.io/latest/docs/setup/install/multicluster/multi-primary_multi-network/
#
# === WHAT YOU WILL GET?
#
# Two minikube clusters will be created.
# * The default "minikube" profile is NOT used. Instead, two named profiles will be created: "istio-east" and "istio-west".
# * The "ingress", "metallb" and "registry" addons will be enabled.
#
# Istio will be installed on each cluster:
# * The demo profile is used as a base.
# * Jaeger, Grafana and Prometheus addons will be installed.
# * Istio will be configured for multi-cluster using the "multi-primary on different networks" approach.
#   * Workloads on one cluster should be able to communicate to workloads on the other cluster.
#
# The bookinfo application will be installed on each cluster for demoing/validating that the setup works:
# * One cluster will have the productpage-v1, details-v1 and reviews-v1 workloads.
# * The other cluster will have the reviews-v2, reviews-v3 and ratings-v1 workloads.
# * The productpage application will be exposed through the Istio ingress gateway (the script
#     should find and provide the address that you can use on your browser to open the app). You should
#     be able to query the application and it should work normally as if it were installed on a single cluster.
#
# Kiali is not provided. If you need it, you will need to install it manually.
#
# === REQUIREMENTS
#
# In addition to this script (minikube-istio-multi-cluster.bash) you will also need:
# * Bash shell.
# * The `istio-mc-setup.bash` script, available in this same gist.
# * The `install-splitted-bookinfo.bash` script, available in this same gist.
# * VirtualBox. The tested version is 6.1. Feel free to try on your version and comment if it works.
# * minikube binary available in your $PATH.
# * kubectl binary available in your $PATH. It should be compatible with whatever Kubernetes version is installed by
#     default by minikube.
# * Istio package already uncompressed. The version tested is 1.9.0. Version 1.8 should also work, but is untested.
#     You can find and download an Istio package here: https://github.com/istio/istio/releases/.
# * 80 GB of free disk space (it could be less, because VM disk space is allocated dynamically).
# * 12 GB RAM (this is what I've found that works decently. Modify the script if you need more/less RAM assigned).
#
# These scripts were tested with minikube v1.17.1. It is possible that earlier minikube versions can
# work but you will need, at least, minikube v1.10.0-beta.2, because this is the minikube version
# where the "MetalLB" addon was introduced (or that's what I found on a blog post). If you want to use
# a minikube version prior to v1.10.0-beta.2, you will need to modify these scripts to do a manual installation of
# MetalLB (see: https://metallb.universe.tf/installation/#installation-by-manifest).
#
# These scripts are requiring virtualbox because, when using this driver, minikube uses the 192.168.99.0/24 CIDR to
# allocate IP addresses to virtual machines. Also, DHCP configuration is so-so predictable. This makes possible
# to do some assuptions that work most of the time and gives the chance to automate the setup.
#
# === HOW TO RUN THIS SCRIPT?
#
# * You must have this script and it's two dependant scripts (stio-mc-setup.bash, install-splitted-bookinfo.bash)
#    on the same directory. Change (cd) into this directory.
# * Make sure that the scripts have exec permissions.
# * Define the ISTIO_DIR environment variable pointing to your extracted Istio package.
# * Run the script.
#
# For example:
# $ cd multi-cluster-scripts
# $ chmod u+x minikube-istio-multi-cluster.bash istio-mc-setup.bash install-splitted-bookinfo.bash
# $ export ISTIO_DIR=$HOME/apps/istio-1.9.0
# $ ./minikube-istio-multi-cluster.bash
#
# Once everything is up, you may not want to turn off your device (the setup may not recover
# on restart, or it could; who knows?).
# 
# If something fails, please contribute for a fix ;) There is no support.
# 

set -e

: ${PROFILE_NAME1:="istio-east"}
: ${METAL_LB_ADDRESSES1:="'192.168.99.70-192.168.99.84'"}

: ${PROFILE_NAME2:="istio-west"}
: ${METAL_LB_ADDRESSES2:="'192.168.99.85-192.168.99.98'"}

: ${ISTIO_DIR:="$HOME/apps/istio-1.12.2"}
ISTIOCTL=$ISTIO_DIR/bin/istioctl

if [ ! -f $ISTIOCTL ]; then
  echo "Cannot find istioctl in \$ISTIO_DIR. Make sure you have correctly defined the ISTIO_DIR environment variable."
  exit 1
fi

start_minikube() {
  minikube start \
    --profile $1 \
    --addons registry \
    --addons ingress \
    --addons metallb \
    --disk-size 40G \
    --memory 6G \
    --driver virtualbox

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses: [$2]
EOF
}

start_minikube "$PROFILE_NAME1" "$METAL_LB_ADDRESSES1"
start_minikube "$PROFILE_NAME2" "$METAL_LB_ADDRESSES2"

export ISTIO_DIR
CTX=$PROFILE_NAME1 CLUSTER_NAME=$PROFILE_NAME1 NETWORK=$PROFILE_NAME1-network ./istio-mc-setup.bash
CTX=$PROFILE_NAME2 CLUSTER_NAME=$PROFILE_NAME2 NETWORK=$PROFILE_NAME2-network ./istio-mc-setup.bash

$ISTIOCTL x create-remote-secret \
  --context="${PROFILE_NAME1}" \
  --name=$PROFILE_NAME1 | \
  kubectl apply -f - --context="${PROFILE_NAME2}"

$ISTIOCTL x create-remote-secret \
  --context="${PROFILE_NAME2}" \
  --name=$PROFILE_NAME2 | \
  kubectl apply -f - --context="${PROFILE_NAME1}"

# Let's install bookinfo on both clusters and scale down a few workloads
# on each cluster to let Istio route traffic accross clusters depending
# on workload availability
# CTX1=$PROFILE_NAME1 CTX2=$PROFILE_NAME2 ./install-splitted-bookinfo.bash

