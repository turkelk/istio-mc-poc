#!/bin/bash

set -e

: ${CTX:="kubernetes-admin@kukulcan"}

: ${ISTIO_DIR:="$HOME/apps/istio-1.12.2"}
ISTIOCTL=$ISTIO_DIR/bin/istioctl

: ${CLUSTER_NAME:="kukulcan"}
: ${MESH_ID:="istio-mesh"}
: ${NETWORK:="netOne"}

# Create secrets for shared trust
mkdir -p $ISTIO_DIR/_certs
pushd $ISTIO_DIR/_certs
make -f $ISTIO_DIR/tools/certs/Makefile.selfsigned.mk root-ca
make -f ../tools/certs/Makefile.selfsigned.mk $CLUSTER_NAME-cacerts
popd

# Create istio-system namespace
cat <<EOF | kubectl --context="${CTX}" apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
  labels:
    topology.istio.io/network: $NETWORK
EOF

# Install certificate for cluster1 for shared trust
kubectl --context="${CTX}" create secret generic cacerts -n istio-system --dry-run=client -o yaml \
  --from-file=$ISTIO_DIR/_certs/$CLUSTER_NAME/ca-cert.pem \
  --from-file=$ISTIO_DIR/_certs/$CLUSTER_NAME/ca-key.pem \
  --from-file=$ISTIO_DIR/_certs/$CLUSTER_NAME/root-cert.pem \
  --from-file=$ISTIO_DIR/_certs/$CLUSTER_NAME/cert-chain.pem \
  | kubectl --context="${CTX}" apply -f -

# Let's install Istio with multi-cluster turned on.
# This is using the demo profile as a base, because it's assumed that
# this is for a development/testing environment.
cat <<EOF | $ISTIOCTL install --context="${CTX}" -y -f $ISTIO_DIR/manifests/profiles/demo.yaml -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
    - name: istio-eastwestgateway
      enabled: true
      label:
        istio: eastwestgateway
        app: istio-eastwestgateway
        topology.istio.io/network: $NETWORK
      k8s:
        env:
          # sni-dnat adds the clusters required for AUTO_PASSTHROUGH mode
          - name: ISTIO_META_ROUTER_MODE
            value: "sni-dnat"
          # traffic through this gateway should be routed inside the network
          - name: ISTIO_META_REQUESTED_NETWORK_VIEW
            value: $NETWORK
        resources:
          requests:
            cpu: 10m
            memory: 40Mi
        service:
          ports:
            - name: status-port
              port: 15021
              targetPort: 15021
            - name: mtls
              port: 15443
              targetPort: 15443
            - name: tcp-istiod
              port: 15012
              targetPort: 15012
            - name: tcp-webhook
              port: 15017
              targetPort: 15017
  values:
    global:
      # Multi-cluster properties
      meshID: $MESH_ID
      multiCluster:
        clusterName: $CLUSTER_NAME
      network: $NETWORK
EOF

# Expose services
# kubectl --context="${CTX}" apply -n istio-system -f $ISTIO_DIR/samples/multicluster/expose-services.yaml

# Install add-ons
# kubectl --context="${CTX}" apply -f $ISTIO_DIR/samples/addons/prometheus.yaml
# kubectl --context="${CTX}" apply -f $ISTIO_DIR/samples/addons/jaeger.yaml
# kubectl --context="${CTX}" apply -f $ISTIO_DIR/samples/addons/grafana.yaml


kubectl --context="${CTX}" create ns banking
kubectl --context="${CTX}" label ns banking istio-injection=enabled  
kubectl --context="${CTX}" create ns argocd
kubectl --context="${CTX}" apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -n argocd
kubectl --context="${CTX}" apply -f gateway.yaml -n banking

