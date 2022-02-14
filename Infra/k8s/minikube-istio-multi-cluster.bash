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

kubectl --context="${PROFILE_NAME1}" apply -f vs-east.yaml -n banking
kubectl --context="${PROFILE_NAME2}" apply -f vs-west.yaml -n banking    

