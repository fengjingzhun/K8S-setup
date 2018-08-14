#!/bin/bash

docker pull quay.io/prometheus/alertmanager:v0.7.1
docker pull grafana/grafana:4.2.0
docker pull giantswarm/tiny-tools
docker pull prom/prometheus:v1.7.0
docker pull dockermuenster/caddy:0.9.3
docker pull prom/node-exporter:v0.14.0

function PriorPull(){
    # 拉取、重打标记、删除 #
    for IMAGE in ${IMAGES[@]} ; do
      docker pull $FORMER_PREFIX$IMAGE
      docker tag $FORMER_PREFIX$IMAGE $LATER_PREFIX$IMAGE
      docker rmi $FORMER_PREFIX$IMAGE
    done
}
# 拉取地址 #
FORMER_PREFIX=registry.cn-hangzhou.aliyuncs.com/google_containers/
# 实际地址 #
LATER_PREFIX=k8s.gcr.io/
IMAGES=(
    kube-state-metrics:v0.5.0
)
# 执行拉取 #
PriorPull



kubectl create clusterrolebinding kube-state-metrics --clusterrole=cluster-admin --serviceaccount=monitoring:kube-state-metrics
kubectl create clusterrolebinding prometheus --clusterrole=cluster-admin --serviceaccount=monitoring:prometheus

kubectl create -f https://raw.githubusercontent.com/giantswarm/kubernetes-prometheus/master/manifests-all.yaml

##① grafana:3000 / admin / admin
##② Edit data source

