### 说明 ###
#service：docker @ master & minion
#service：kubelet @ master & minion
#pod：kube-proxy @ master & minion
#pod：flannel @ master & minion
#pod：coredns @ maste
#pod：etcd @ master
#pod：kube-scheduler @ master
#pod：kube-apiserver @ master
#pod：kube-controller-manager @ master

journalctl -u kubelet -f

kubectl logs my-artifactory-postgresql-7dcdbbd6d-hngnb

kubectl cluster-info

# 预拉取镜像 #
kubeadm config images pull --config kubeadm-master.config

## 允许在master节点部署pod ##
kubectl taint nodes --all node-role.kubernetes.io/master-

# 查看集群运行在那些ip上
kubectl cluster-info
# 查看master的各种token
kubectl get secret -n kube-system
# 查看某一个特定的资源
kubectl describe secret [secret name]
# 编辑某一个特定的资源
kubectl edit secret [secret name]

######################################################################################################################################
# 查询token #
kubeadm token list
# （或者）创建token #
kubeadm token create
# 获得discovery-token-ca-cert-hash #
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'

kubectl api-resources
######################################################################################################################################
# --namespace=kube-system
# --all-namespaces
 kubectl get rc #replicationcontroller
 kubectl get po #pod
 kubectl get svc #service
 kubectl get no #node
 kubectl get ns #namespace
 kubectl get pv #persistentvolume
 kubectl get pvc #persistentvolumeclaims
 kubectl get cm #configmap
 kubectl get secret
 kubectl get deploy #deployment
 kubectl get ep #endpoints
 kubectl get ing #ingresses
 kubectl get rs #replicaset
 kubectl get ds #daemonset
 kubectl get statefulset
 kubectl get hpa #horizontalpodautoscaler

######################################################################################################################################
# 下载flannel0.10.0安装配置 #
wget https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
# 替换为阿里云源 #
sed -i 's/image: quay.io\/coreos\/flannel:v0.10.0-amd64/image: registry.cn-shanghai.aliyuncs.com\/gcr-k8s\/flannel:v0.10.0-amd64/g' kube-flannel.yml
# 安装 #
kubectl apply -f kube-flannel.yml
# 删除文件 #
rm -rf kube-flannel.yml

# 预拉取镜像 #
kubeadm config images pull --kubernetes-version=1.11.2

## 修改kubelet，only have to do that if the cgroup driver of your CRI is not cgroupfs##
# 使kubelet的cgroup与docker一致 #
cat << EOF > /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS="--cgroup-driver=$(docker info | grep 'Cgroup' | cut -d' ' -f3)"
EOF
# 重载所有修改过的配置文件 #
systemctl daemon-reload
# 开启kubelet服务并重启 #
systemctl enable kubelet && systemctl restart kubelet
