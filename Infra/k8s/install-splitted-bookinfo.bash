#!/bin/bash

set -e

: ${ISTIO_DIR:="$HOME/apps/istio-1.12.2"}
ISTIOCTL=$ISTIO_DIR/bin/istioctl

: ${BOOKINFO_NS:=bookinfo}

: ${CTX1:=kukulcan}
: ${CTX2:=tzotz}

install_bookinfo() {
  kubectl --context=$1 create ns $BOOKINFO_NS
  kubectl --context=$1 label namespace $BOOKINFO_NS istio-injection=enabled
  kubectl --context=$1 apply -f $ISTIO_DIR/samples/bookinfo/platform/kube/bookinfo.yaml -n $BOOKINFO_NS
  kubectl --context=$1 apply -f $ISTIO_DIR/samples/bookinfo/networking/bookinfo-gateway.yaml -n $BOOKINFO_NS
}

install_bookinfo $CTX1
kubectl --context $CTX1 scale deploy -n $BOOKINFO_NS reviews-v2 --replicas=0
kubectl --context $CTX1 scale deploy -n $BOOKINFO_NS reviews-v3 --replicas=0
kubectl --context $CTX1 scale deploy -n $BOOKINFO_NS ratings-v1 --replicas=0

install_bookinfo $CTX2
kubectl --context $CTX2 scale deploy -n $BOOKINFO_NS productpage-v1 --replicas=0
kubectl --context $CTX2 scale deploy -n $BOOKINFO_NS details-v1 --replicas=0
kubectl --context $CTX2 scale deploy -n $BOOKINFO_NS reviews-v1 --replicas=0

INGRESS_HOST=$(kubectl --context $CTX1 -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Bookinfo application will be available soon at http://$INGRESS_HOST/productpage"

