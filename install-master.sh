#!/bin/bash

#-----------------------------------------------------------------------------------------------------------------------
## 基础配置 ##
# 配置hosts解析，用于区分主机（node） #
cat << EOF >> /etc/hosts
192.168.100.21 vm1
192.168.100.22 vm2
192.168.100.23 vm3
192.168.100.24 vm4
192.168.100.25 vm5
192.168.100.26 vm6
EOF
# 关闭SELinux服务并停止 #
sed -i 's/SELINUX=permissive/SELINUX=disabled/' /etc/sysconfig/selinux && setenforce 0
# 关闭Firewall服务并停止 #
systemctl disable firewalld && systemctl stop firewalld
# 关闭swap服务并停止 #
sed -i '/swap/s/^/#/' /etc/fstab && swapoff -a
# 配置转发相关参数 #
cat << EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
# 修改运行时内核参数(从所有系统配置文件加载设置) #
sysctl --system

#-----------------------------------------------------------------------------------------------------------------------
## 安装Docker ##
# 安装yum工具 #
yum install -y yum-utils\
 device-mapper-persistent-data\
 lvm2
# 使用官方源 #
yum-config-manager\
 --add-repo\
 https://download.docker.com/linux/centos/docker-ce.repo
# 安装17.03.2版本 #
yum install -y --setopt=obsoletes=0\
 docker-ce-17.03.2.ce-1.el7.centos\
 docker-ce-selinux-17.03.2.ce-1.el7.centos
# 开启Docker服务并启动 #
systemctl enable docker && systemctl start docker
# 开启forward：Docker从1.13版本开始调整了默认的防火墙规则，禁用了iptables filter表中FOWARD链，会引起K8S集群中跨Node的Pod无法通信
iptables -P FORWARD ACCEPT

#-----------------------------------------------------------------------------------------------------------------------
## 安装 kubeadm，kubelet和kubectl ##
# 配置阿里云源 #
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
# 安装1.11.1版本 #
yum install -y kubeadm-1.11.1-0.x86_64 kubelet-1.11.1-0.x86_64 kubectl-1.11.1-0.x86_64 --disableexcludes=kubernetes

#-----------------------------------------------------------------------------------------------------------------------
## 初始化节点 ##
# 定义kubelet使用阿里云镜像 #
cat >/etc/sysconfig/kubelet<<EOF
KUBELET_EXTRA_ARGS="--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1"
EOF
# 定义master init配置文件 #
#K8S版本为1.11.1
#镜像库为阿里源
#Pod网络的范围为10.244.0.0~10.244.255.255
cat << EOF > kubeadm-master.config
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
kubernetesVersion: v1.11.1
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
networking:
  podSubnet: 10.244.0.0/16
EOF
# 初始化master #
kubeadm init --config kubeadm-master.config
# 删除残留文件 #
rm -rf kubeadm-master.config
# 开启kubelet服务 #
systemctl enable kubelet
# To make kubectl work（IS root） #
cat << EOF >> /etc/profile
export KUBECONFIG=/etc/kubernetes/admin.conf
EOF
source /etc/profile
## To make kubectl work（NOT root） #
#mkdir -p $HOME/.kube
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#sudo chown $(id -u):$(id -g) $HOME/.kube/config
# 部署覆盖网络（overlay network） #
#kubeadm只支持CNI(Container Network Interface)协议网络
#安装flannel0.10.0
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
