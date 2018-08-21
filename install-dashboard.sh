#!/bin/bash
## 部署dashboard ##
# 下载安装文件 #
wget https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
# 使用阿里源 #
sed -i\
 's/        image: k8s.gcr.io\/kubernetes-dashboard-amd64:v1.8.3/        image: registry.cn-hangzhou.aliyuncs.com\/google_containers\/kubernetes-dashboard-amd64:v1.8.3/g'\
 kubernetes-dashboard.yaml
# 安装dashboard #
kubectl create -f kubernetes-dashboard.yaml
# 删除残留文件 #
rm -rf kubernetes-dashboard.yaml

## 授予Dashboard账户集群管理权限 ##
# 新建授权文件 #
cat << EOF > kubernetes-dashboard.rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
# 添加权限 #
kubectl create -f kubernetes-dashboard.rbac.yaml
# 删除残留文件 #
rm -rf kubernetes-dashboard.rbac.yaml

## 准备浏览器登录材料（token、p12证书文件、p12证书密码） ##
#①在浏览器上使用p12_pass导入p12文件
#②进入https://<ip/domain>:<port>/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
#③使用token登录
#对于生产系统，我们应该为每个用户应该生成自己的证书，因为不同的用户会有不同的命名空间访问权限。
# 创建并进入文件夹 #
mkdir admin-user && cd admin-user
# 记录token（默认是永久的） #
echo $(kubectl get secret -n kube-system | grep admin-user | cut -d " " -f1 | xargs -n 1 | xargs kubectl get secret  -o\
 'jsonpath={.data.token}' -n kube-system | base64 --decode) > admin-user.token
#echo $(kubectl -n kube-system describe secret\
# $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') | awk 'NR==13{print $2}') > admin-user.token
# 生成p12证书密码 #
export P12_PASS=KDC.2018.cert
# 记录p12证书密码 #
echo $P12_PASS > admin-user.pass
# 生成client-certificate-data #
grep 'client-certificate-data' /etc/kubernetes/admin.conf | head -n 1 | awk '{print $2}' | base64 -d >> admin-user.crt
# 生成client-key-data #
grep 'client-key-data' /etc/kubernetes/admin.conf | head -n 1 | awk '{print $2}' | base64 -d >> admin-user.key
# 生成p12 #
openssl pkcs12 -export -clcerts -inkey admin-user.key -in admin-user.crt -out admin-user.p12 -name "kubernetes-client" -password pass:$P12_PASS
