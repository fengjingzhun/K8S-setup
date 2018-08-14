#!/bin/bash

## 编写配置文件 ##
# 新建授权文件 #
cat << EOF > kubernetes-traefik.rbac.yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch

---

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
- kind: ServiceAccount
  name: traefik-ingress-controller
  namespace: kube-system
EOF
# 新建部署文件 #
cat << EOF > kubernetes-traefik.ds.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-ingress-controller
  namespace: kube-system

---

kind: DaemonSet
apiVersion: extensions/v1beta1
metadata:
  name: traefik-ingress-controller
  namespace: kube-system
  labels:
    k8s-app: traefik-ingress-lb
spec:
  template:
    metadata:
      labels:
        k8s-app: traefik-ingress-lb
        name: traefik-ingress-lb
    spec:
      serviceAccountName: traefik-ingress-controller
      terminationGracePeriodSeconds: 60
      containers:
      - image: traefik:v1.6.5
        name: traefik-ingress-lb
        ports:
        - name: http
          containerPort: 80
          hostPort: 80
        - name: admin
          containerPort: 8080
        securityContext:
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        args:
        - --api
        - --kubernetes
        - --logLevel=INFO

---

kind: Service
apiVersion: v1
metadata:
  name: traefik-ingress-service
  namespace: kube-system
spec:
  selector:
    k8s-app: traefik-ingress-lb
  ports:
    - protocol: TCP
      port: 80
      name: web
    - protocol: TCP
      port: 8080
      name: admin
EOF
# 新建界面文件 #
cat << EOF > kubernetes-traefik.ui.yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik-web-ui
  namespace: kube-system
spec:
  selector:
    k8s-app: traefik-ingress-lb
  ports:
  - port: 80
    targetPort: 8080

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: traefik-web-ui
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: traefik-ui
    http:
      paths:
      - backend:
          serviceName: traefik-web-ui
          servicePort: 80
EOF
echo 192.168.100.22 traefik-ui > /etc/hosts

## 执行配置文件 ##
# 授权 #
kubectl create -f kubernetes-traefik.rbac.yaml
# 部署 #
kubectl create -f kubernetes-traefik.ds.yaml
# 界面 #
kubectl create -f kubernetes-traefik.ui.yaml


cat << EOF > prometheus-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: grafana
  namespace: monitoring
spec:
  rules:
  - host: grafana-ui
    http:
      paths:
      - path:
        backend:
          serviceName: grafana
          servicePort: 3000
EOF
kubectl create -f prometheus-ingress.yaml
echo 192.168.100.23 grafana-ui > /etc/hosts

# traefik-ui.io -> VIP(IPVS+keepalived) -> Edge node(nodeSelector: edgenode: "true") -> traefik-web-ui -> traefik-ingress-service
# 如果在内网：将浏览器所在设备的hosts文件中添加：
# a.b.c.d traefik-ui.io


