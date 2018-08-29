#!/bin/bash

## 安装helm和tiller ##
# 下载安装包，（无法下载时，需使用梯子） #
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz
# 解压安装包 #
tar -zxvf helm-v2.9.1-linux-amd64.tar.gz
# 安装helm #
mv linux-amd64/helm /usr/local/bin/helm
# 使用阿里源安装tiller #
# --local-repo-url http://127.0.0.1/charts\
helm init --upgrade\
 -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.9.1\
 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
# 创建tiller账号 #
kubectl create serviceaccount --namespace kube-system tiller
# 将cluster-admin角色绑定至tiller账号 #
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
# 将tiller账号更新至部署 #
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
# 删除残留文件 #
rm -rf helm-v2.9.1-linux-amd64.tar.gz
# 添加常用源 #
helm repo add incubator https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts-incubator

## 安装管理chart的UI ##
# 创建nfs pv文件，供mongodb使用 #
#storage需要大于mongodb需求，accessModes需要与mongodb需求一致
#每个minion上都需要安装rpcbind和nfs-utils，如此无论在那个node上启动mongodb的pod都可以正常挂载nfs
#nfs地址与路径必须存在且开放读写权限
cat << EOF > monocular-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
    name: nfs-monocular
spec:
    capacity:
      storage: 80Gi
    accessModes:
      - ReadWriteOnce
    persistentVolumeReclaimPolicy: Recycle
    nfs:
      path: /share/monocular
      server: 192.168.100.11
EOF
# 创建nfs pv #
kubectl create -f monocular-pv.yaml
# 删除残留文件 #
rm -rf monocular-pv.yaml

helm install stable/nginx-ingress\
 --name my-nginx-ingress\
 --set "controller.hostNetwork=true,rbac.create=true"

helm repo add monocular https://helm.github.io/monocular

helm install monocular/monocular --name my-monocular

#helm list
#helm delete my-monocular --purge
#helm fetch stable/nginx-ingress --untar



# 安装jenkins #
helm install --name helm-jenkins\
 --set Master.ServiceType=ClusterIP\
 stable/jenkins

# 安装gitlab-ce #
helm install --name helm-gitlab-ce\
 --set serviceType=ClusterIP,externalUrl=http://gitlab.tele-sing.com\
 stable/gitlab-ce

# 安装sonatype-nexus #
helm install --name helm-sonatype-nexus\
 --set service.type=ClusterIP\
 stable/sonatype-nexus






