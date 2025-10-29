# 📖 راهنمای نصب کامل HaioCloud

این راهنما مراحل دقیق نصب کلاستر Kubernetes HaioCloud را گام به گام توضیح میدهد.

---

## 📋 فهرست

1. [پیش‌نیازها](#1-پیشنیازها)
2. [آماده‌سازی سرورها](#2-آمادهسازی-سرورها)
3. [پیکربندی SSH](#3-پیکربندی-ssh)
4. [نصب K3s Master](#4-نصب-k3s-master)
5. [نصب K3s Workers](#5-نصب-k3s-workers)
6. [نصب MetalLB](#6-نصب-metallb)
7. [نصب Traefik](#7-نصب-traefik)
8. [تنظیم DNS](#8-تنظیم-dns)
9. [تست نصب](#9-تست-نصب)
10. [نصب اختیاری](#10-نصب-اختیاری)

---

## 1. پیش‌نیازها

### سرورها

| مورد | مشخصات |
|------|--------|
| تعداد | 3 سرور (1 Master + 2 Worker) |
| سیستم‌عامل | Ubuntu 20.04 / 22.04 LTS |
| CPU | حداقل 2 Core (توصیه 4 Core) |
| RAM | حداقل 4GB (توصیه 8GB) |
| Storage | حداقل 40GB (توصیه 100GB) |
| Network | IP عمومی ثابت |

### دسترسی‌ها

✅ Root access با SSH Key  
✅ دامنه با دسترسی به DNS  
✅ IP عمومی ثابت برای Master  
✅ پورت‌های باز: 22, 80, 443, 6443  

### کامپیوتر مدیر

- سیستم‌عامل: Windows / Linux / macOS
- SSH Client نصب شده
- Git نصب شده (اختیاری)
- kubectl نصب شده (اختیاری)

---

## 2. آماده‌سازی سرورها

### 2.1 آپدیت سیستم

روی **هر 3 سرور** اجرا کنید:

```bash
apt update && apt upgrade -y
apt install -y curl wget git openssl
```

### 2.2 تنظیم Hostname

**روی Master:**
```bash
hostnamectl set-hostname k8s-master
```

**روی Worker1:**
```bash
hostnamectl set-hostname k8s-worker1
```

**روی Worker2:**
```bash
hostnamectl set-hostname k8s-worker2
```

### 2.3 تنظیم /etc/hosts

روی **هر 3 سرور**:

```bash
cat >> /etc/hosts <<EOF
94.182.92.207 k8s-master
94.182.92.203 k8s-worker1
94.182.92.241 k8s-worker2
EOF
```

### 2.4 غیرفعال کردن Firewall (موقت)

```bash
ufw disable
```

*نکته: بعد از نصب میتوانید firewall را فعال و پورت‌های لازم را باز کنید.*

### 2.5 غیرفعال کردن Swap

```bash
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
```

---

## 3. پیکربندی SSH

### 3.1 ایجاد SSH Key (روی کامپیوتر مدیر)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/haiocloud_rsa
```

### 3.2 کپی کلید به سرورها

```bash
ssh-copy-id -i ~/.ssh/haiocloud_rsa.pub -p 2280 root@94.182.92.207
ssh-copy-id -i ~/.ssh/haiocloud_rsa.pub -p 2280 root@94.182.92.203
ssh-copy-id -i ~/.ssh/haiocloud_rsa.pub -p 2280 root@94.182.92.241
```

### 3.3 ایجاد SSH Config

ایجاد فایل `~/.ssh/config`:

```ssh
# HaioCloud K8s Cluster

Host k8s-master
    HostName 94.182.92.207
    User root
    Port 2280
    IdentityFile ~/.ssh/haiocloud_rsa
    StrictHostKeyChecking no

Host k8s-worker1
    HostName 94.182.92.203
    User root
    Port 2280
    IdentityFile ~/.ssh/haiocloud_rsa
    StrictHostKeyChecking no

Host k8s-worker2
    HostName 94.182.92.241
    User root
    Port 2280
    IdentityFile ~/.ssh/haiocloud_rsa
    StrictHostKeyChecking no
```

### 3.4 تست اتصال

```bash
ssh k8s-master "echo Master OK"
ssh k8s-worker1 "echo Worker1 OK"
ssh k8s-worker2 "echo Worker2 OK"
```

**خروجی مورد انتظار:**
```
Master OK
Worker1 OK
Worker2 OK
```

---

## 4. نصب K3s Master

### 4.1 دانلود فایل نصب

روی کامپیوتر مدیر:

```bash
curl -O https://raw.githubusercontent.com/Mehrdad-Hooshmand/haiocloud-k8s/main/01-install-k3s-master.sh
```

یا ایجاد دستی:

```bash
cat > 01-install-k3s-master.sh <<'EOF'
#!/bin/bash
set -e

# تنظیم ArvanCloud mirror برای ایران
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOD
{
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOD

# غیرفعال کردن swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# نصب K3s Server
curl -sfL https://get.k3s.io | sh -s - server \
  --disable traefik \
  --disable servicelb \
  --write-kubeconfig-mode 644 \
  --tls-san 94.182.92.207 \
  --node-name k8s-master

# تنظیم kubectl  
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config

# نمایش وضعیت
kubectl get nodes

echo "K3s Master installed successfully!"
EOF

chmod +x 01-install-k3s-master.sh
```

### 4.2 اجرا

```bash
ssh k8s-master < 01-install-k3s-master.sh
```

### 4.3 بررسی نصب

```bash
ssh k8s-master "kubectl get nodes"
```

**خروجی مورد انتظار:**
```
NAME         STATUS   ROLES                  AGE   VERSION
k8s-master   Ready    control-plane,master   1m    v1.33.5+k3s1
```

### 4.4 دریافت Token

```bash
K3S_TOKEN=$(ssh k8s-master "cat /var/lib/rancher/k3s/server/node-token")
echo "K3s Token: $K3S_TOKEN"
```

**Token را یادداشت کنید!** به شکل:
```
K1003670d0eca010452e89b39e986516e709735e2c33f5467345da9dac014447cad::server:7f5fd6b35077f92addb13fcc7ecaa578
```

---

## 5. نصب K3s Workers

### 5.1 دانلود فایل نصب

```bash
curl -O https://raw.githubusercontent.com/Mehrdad-Hooshmand/haiocloud-k8s/main/02-install-k3s-worker.sh
```

یا ایجاد دستی:

```bash
cat > 02-install-k3s-worker.sh <<'EOF'
#!/bin/bash
set -e

# چک کردن متغیرها
if [ -z "$K3S_TOKEN" ] || [ -z "$K3S_URL" ]; then
    echo "Error: K3S_TOKEN and K3S_URL must be set"
    exit 1
fi

# تنظیم ArvanCloud mirror
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOD
{
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOD

# غیرفعال کردن swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# نصب K3s Agent
curl -sfL https://get.k3s.io | sh -s - agent \
  --server $K3S_URL \
  --token $K3S_TOKEN \
  --node-name $(hostname)

echo "K3s Worker installed successfully!"
EOF

chmod +x 02-install-k3s-worker.sh
```

### 5.2 نصب Worker 1

```bash
ssh k8s-worker1 "export K3S_TOKEN='$K3S_TOKEN' && export K3S_URL='https://94.182.92.207:6443' && bash" < 02-install-k3s-worker.sh
```

### 5.3 نصب Worker 2

```bash
ssh k8s-worker2 "export K3S_TOKEN='$K3S_TOKEN' && export K3S_URL='https://94.182.92.207:6443' && bash" < 02-install-k3s-worker.sh
```

### 5.4 بررسی

```bash
ssh k8s-master "kubectl get nodes"
```

**خروجی مورد انتظار:**
```
NAME          STATUS   ROLES                  AGE   VERSION
k8s-master    Ready    control-plane,master   5m    v1.33.5+k3s1
k8s-worker1   Ready    <none>                 2m    v1.33.5+k3s1
k8s-worker2   Ready    <none>                 1m    v1.33.5+k3s1
```

---

## 6. نصب MetalLB

### 6.1 نصب MetalLB

```bash
cat > 03-install-metallb.sh <<'EOF'
#!/bin/bash
set -e

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml

echo "Waiting for MetalLB to be ready..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

echo "MetalLB installed successfully!"
EOF

chmod +x 03-install-metallb.sh
ssh k8s-master < 03-install-metallb.sh
```

### 6.2 پیکربندی IP Pool

```bash
ssh k8s-master "kubectl apply -f -" <<'EOF'
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 94.182.92.207/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
EOF
```

### 6.3 بررسی

```bash
ssh k8s-master "kubectl get pods -n metallb-system"
```

**خروجی مورد انتظار:**
```
NAME                          READY   STATUS    AGE
controller-xxxxx              1/1     Running   1m
speaker-xxxxx                 1/1     Running   1m
speaker-xxxxx                 1/1     Running   1m
speaker-xxxxx                 1/1     Running   1m
```

---

## 7. نصب Traefik

### 7.1 نصب

```bash
cat > 04-install-traefik.sh <<'EOF'
#!/bin/bash
set -e

kubectl create namespace traefik || true

kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

cat <<EOD | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik
rules:
  - apiGroups: [""]
    resources: ["services","endpoints","secrets"]
    verbs: ["get","list","watch"]
  - apiGroups: ["extensions","networking.k8s.io"]
    resources: ["ingresses","ingressclasses"]
    verbs: ["get","list","watch"]
  - apiGroups: ["extensions","networking.k8s.io"]
    resources: ["ingresses/status"]
    verbs: ["update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik
subjects:
  - kind: ServiceAccount
    name: traefik
    namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik
      containers:
      - name: traefik
        image: traefik:v3.0
        args:
          - --api.insecure=true
          - --providers.kubernetesingress
          - --entrypoints.web.address=:80
        ports:
        - name: web
          containerPort: 80
        - name: admin
          containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: kube-system
spec:
  type: LoadBalancer
  selector:
    app: traefik
  ports:
  - name: web
    port: 80
    targetPort: 80
  - name: admin
    port: 8080
    targetPort: 8080
EOD

kubectl wait --for=condition=ready pod -n kube-system -l app=traefik --timeout=60s

echo "Traefik installed successfully!"
EOF

chmod +x 04-install-traefik.sh
ssh k8s-master < 04-install-traefik.sh
```

### 7.2 بررسی

```bash
ssh k8s-master "kubectl get svc -n kube-system traefik"
```

**خروجی مورد انتظار:**
```
NAME      TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
traefik   LoadBalancer   10.43.x.x      94.182.92.207    80:xxxxx/TCP
```

---

## 8. تنظیم DNS

### 8.1 Cloudflare

1. وارد پنل Cloudflare شوید
2. Domain خود را انتخاب کنید
3. DNS → Add Record

```
Type: A
Name: *
IPv4: 94.182.92.207
Proxy status: DNS only (خاموش - خاکستری)
TTL: Auto
```

### 8.2 سایر DNS Providers

```
Type: A
Name: *.haiocloud.com
Value: 94.182.92.207
TTL: 300
```

### 8.3 تست DNS

```bash
nslookup test.haiocloud.com
nslookup ali.haiocloud.com
```

**خروجی مورد انتظار:**
```
Server:  8.8.8.8
Address: 8.8.8.8#53

Name:    test.haiocloud.com
Address: 94.182.92.207
```

---

## 9. تست نصب

### 9.1 ساخت اولین کاربر

```bash
ssh k8s-master "bash /root/create-webtop.sh test1"
```

### 9.2 چک وضعیت

```bash
ssh k8s-master "kubectl get pods -n webtops"
```

**خروجی مورد انتظار:**
```
NAME                           READY   STATUS    AGE
webtop-test1-xxxxx-xxxxx       1/1     Running   1m
```

### 9.3 دسترسی از مرورگر

1. مرورگر را باز کنید
2. آدرس: `http://test1.haiocloud.com`
3. Username: `admin`
4. Password: [از خروجی اسکریپت]

---

## 10. نصب اختیاری

### 10.1 Longhorn (Storage)

```bash
ssh k8s-master < 05-install-longhorn.sh
```

### 10.2 Metrics Server

```bash
ssh k8s-master <<'EOF'
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
EOF
```

### 10.3 Kubernetes Dashboard

```bash
ssh k8s-master <<'EOF'
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin
EOF
```

---

## ✅ چک لیست نصب

- [ ] 3 سرور Ubuntu آماده
- [ ] SSH Key ایجاد شده
- [ ] SSH Config تنظیم شده
- [ ] K3s Master نصب شده
- [ ] 2 Workers به کلاستر اضافه شده
- [ ] MetalLB نصب و پیکربندی شده
- [ ] Traefik نصب شده
- [ ] DNS تنظیم شده
- [ ] کاربر تست ساخته شده
- [ ] دسترسی از مرورگر تست شده

---

## 🔧 عیب‌یابی نصب

### K3s نصب نمیشود

```bash
# چک لاگ
journalctl -u k3s -xe

# نصب مجدد
curl -sfL https://get.k3s.io | sh -s - server --disable traefik --disable servicelb
```

### Worker به کلاستر وصل نمیشود

```bash
# چک token
cat /var/lib/rancher/k3s/server/node-token

# چک فایروال
ufw status
ufw allow 6443/tcp

# چک اتصال
curl -k https://94.182.92.207:6443
```

### MetalLB کار نمی‌کند

```bash
# چک Pods
kubectl get pods -n metallb-system

# چک Config
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system

# لاگ‌ها
kubectl logs -n metallb-system -l app=metallb,component=controller
```

---

**بعدی:** [راهنمای استفاده →](USAGE.md)
