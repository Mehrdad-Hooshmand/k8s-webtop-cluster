# 🔧 راهنمای عیب‌یابی HaioCloud

راهنمای حل مشکلات رایج در کلاستر Kubernetes HaioCloud

---

## 📋 فهرست

1. [مشکلات Pod](#1-مشکلات-pod)
2. [مشکلات شبکه](#2-مشکلات-شبکه)
3. [مشکلات Storage](#3-مشکلات-storage)
4. [مشکلات Performance](#4-مشکلات-performance)
5. [مشکلات DNS](#5-مشکلات-dns)
6. [مشکلات Ingress](#6-مشکلات-ingress)
7. [مشکلات Node](#7-مشکلات-node)
8. [ابزارهای عیب‌یابی](#8-ابزارهای-عیبیابی)

---

## 1. مشکلات Pod

### 🔴 Pod در وضعیت Pending

**علامت:**
```bash
$ kubectl get pods -n webtops
NAME                      READY   STATUS    AGE
webtop-ali-xxx-xxx        0/1     Pending   5m
```

**بررسی:**
```bash
kubectl describe pod -n webtops webtop-ali-xxx-xxx
kubectl get events -n webtops --sort-by='.lastTimestamp'
```

**علل رایج:**

#### 1. کمبود منابع (CPU/Memory)

```bash
# چک منابع Nodes
kubectl top nodes

# خروجی مثال:
NAME          CPU   MEM%
k8s-master    98%   95%   ← مشکل!
k8s-worker1   45%   60%
```

**راه حل:**
```bash
# گزینه 1: کاهش resource limits
kubectl edit deployment -n webtops webtop-ali

# تغییر:
resources:
  limits:
    cpu: "500m"    # از 1000m
    memory: "1Gi"  # از 2Gi

# گزینه 2: اضافه کردن Worker جدید
```

#### 2. مشکل در PVC

```bash
kubectl get pvc -n webtops
```

**راه حل:**
```bash
# چک StorageClass
kubectl get sc

# اگر local-path نیست:
kubectl patch pvc -n webtops webtop-ali-pvc -p '{"spec":{"storageClassName":"local-path"}}'
```

#### 3. Node Selector اشتباه

```bash
kubectl get pod -n webtops webtop-ali-xxx -o yaml | grep -A 5 nodeSelector
```

**راه حل:**
```bash
kubectl patch deployment -n webtops webtop-ali --type='json' -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector"}]'
```

---

### 🔴 Pod در وضعیت CrashLoopBackOff

**علامت:**
```bash
$ kubectl get pods -n webtops
NAME                      READY   STATUS             RESTARTS   AGE
webtop-ali-xxx-xxx        0/1     CrashLoopBackOff   5          10m
```

**بررسی لاگ‌ها:**
```bash
# لاگ فعلی
kubectl logs -n webtops webtop-ali-xxx-xxx

# لاگ قبل از کرش
kubectl logs -n webtops webtop-ali-xxx-xxx --previous

# جزئیات Pod
kubectl describe pod -n webtops webtop-ali-xxx-xxx
```

**علل رایج:**

#### 1. Image Pull Error

```bash
kubectl get pod -n webtops webtop-ali-xxx -o jsonpath='{.status.containerStatuses[0].state}'
```

**راه حل:**
```bash
# در ایران: استفاده از ArvanCloud mirror
ssh k8s-master 'cat > /etc/docker/daemon.json' <<EOF
{
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOF

ssh k8s-master 'systemctl restart docker'
ssh k8s-master 'systemctl restart k3s'
```

#### 2. Environment Variables اشتباه

```bash
kubectl get pod -n webtops webtop-ali-xxx -o jsonpath='{.spec.containers[0].env}'
```

**راه حل:**
```bash
# چک Secret
kubectl get secret -n webtops webtop-ali-secret -o yaml

# ساخت مجدد Secret
kubectl delete secret -n webtops webtop-ali-secret
kubectl create secret generic webtop-ali-secret \
  -n webtops \
  --from-literal=password='NewPassword123'

# ری‌استارت
kubectl rollout restart deployment -n webtops webtop-ali
```

#### 3. Volume Mount مشکل دارد

```bash
kubectl describe pod -n webtops webtop-ali-xxx | grep -A 10 "Volumes:"
```

**راه حل:**
```bash
# چک PVC
kubectl get pvc -n webtops webtop-ali-pvc

# اگر Pending است:
kubectl describe pvc -n webtops webtop-ali-pvc

# حذف و ساخت مجدد
kubectl delete pvc -n webtops webtop-ali-pvc
# سپس ری‌استارت deployment
```

---

### 🔴 Pod در وضعیت ImagePullBackOff

**بررسی:**
```bash
kubectl describe pod -n webtops POD_NAME | grep -A 5 "Events:"
```

**راه حل:**
```bash
# تست دانلود دستی
ssh k8s-worker1 'docker pull lscr.io/linuxserver/webtop:alpine-kde'

# اگر خطا داد:
# 1. چک اتصال اینترنت
ping -c 3 8.8.8.8

# 2. چک DNS
nslookup lscr.io

# 3. استفاده از mirror (ایران)
ssh k8s-worker1 'cat > /etc/docker/daemon.json' <<EOF
{
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOF
```

---

## 2. مشکلات شبکه

### 🔴 Pod به Pod دسترسی ندارد

**تست:**
```bash
# Pod 1
POD1=$(kubectl get pod -n webtops -o name | head -1)
kubectl exec -n webtops $POD1 -- ping -c 3 8.8.8.8

# Pod 2
POD2=$(kubectl get pod -n webtops -o name | tail -1)
kubectl exec -n webtops $POD1 -- ping -c 3 $POD2_IP
```

**راه حل:**
```bash
# چک Network Plugin
kubectl get pods -n kube-system | grep -E "cni|flannel|calico"

# چک Network Policies
kubectl get networkpolicies -n webtops

# حذف موقت Network Policies
kubectl delete networkpolicy -n webtops --all
```

---

### 🔴 Service دسترسی ندارد

**تست:**
```bash
# لیست Services
kubectl get svc -n webtops

# تست از داخل Pod
kubectl exec -n webtops POD_NAME -- wget -O- http://SERVICE_NAME:3000
```

**راه حل:**
```bash
# چک Endpoints
kubectl get endpoints -n webtops

# اگر Endpoints خالی است:
kubectl describe svc -n webtops SERVICE_NAME

# چک Labels
kubectl get pod -n webtops --show-labels
kubectl get svc -n webtops SERVICE_NAME -o yaml | grep selector
```

---

## 3. مشکلات Storage

### 🔴 PVC در وضعیت Pending

**بررسی:**
```bash
kubectl get pvc -n webtops
kubectl describe pvc -n webtops PVC_NAME
```

**علل رایج:**

#### 1. StorageClass موجود نیست

```bash
kubectl get sc
```

**راه حل:**
```bash
# نصب local-path provisioner
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml

# تنظیم به عنوان default
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### 2. فضای کافی نیست

```bash
# چک فضای Nodes
ssh k8s-worker1 'df -h'
ssh k8s-worker2 'df -h'
```

**راه حل:**
```bash
# پاک کردن فایل‌های موقت
ssh k8s-worker1 'docker system prune -af'

# یا کاهش سایز PVC
kubectl edit pvc -n webtops PVC_NAME
# storage: 5Gi → 3Gi
```

---

### 🔴 Storage پر شده

**بررسی:**
```bash
kubectl exec -n webtops POD_NAME -- df -h /config
```

**راه حل:**
```bash
# پاک کردن فایل‌های موقت
kubectl exec -n webtops POD_NAME -- sh -c '
  rm -rf /config/tmp/*
  rm -rf /config/.cache/*
  rm -rf /config/Downloads/*
'

# افزایش سایز PVC
kubectl edit pvc -n webtops PVC_NAME
# storage: 5Gi → 10Gi

# ری‌استارت Pod
kubectl rollout restart deployment -n webtops DEPLOYMENT_NAME
```

---

## 4. مشکلات Performance

### 🔴 دسکتاپ کند است

**بررسی منابع:**
```bash
# مصرف فعلی
kubectl top pod -n webtops POD_NAME

# خروجی مثال:
NAME              CPU    MEMORY
webtop-ali-xxx    950m   1.9Gi   ← نزدیک به limit!
```

**راه حل:**
```bash
# افزایش منابع
kubectl patch deployment -n webtops DEPLOYMENT_NAME --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value": "2000m"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "4Gi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "500m"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "1Gi"}
]'
```

---

### 🔴 Node کند است

**بررسی:**
```bash
kubectl top nodes

# خروجی مثال:
NAME          CPU    MEMORY
k8s-worker1   95%    90%   ← مشکل!
```

**راه حل:**
```bash
# مهاجرت Pods به Node دیگر
kubectl drain k8s-worker1 --ignore-daemonsets --delete-emptydir-data

# چک کردن Pods روی Node
kubectl get pods -A -o wide | grep k8s-worker1

# بازگشت Node
kubectl uncordon k8s-worker1
```

---

## 5. مشکلات DNS

### 🔴 Domain resolve نمی‌شود

**تست DNS:**
```bash
nslookup test1.haiocloud.com
dig test1.haiocloud.com

# از سرور دیگر
nslookup test1.haiocloud.com 8.8.8.8
```

**علل رایج:**

#### 1. DNS تنظیم نشده

**راه حل:**
```bash
# در Cloudflare:
Type: A
Name: *
IPv4: 94.182.92.207
Proxy: OFF (خاکستری)
TTL: Auto
```

#### 2. DNS هنوز Propagate نشده

**تست:**
```bash
# چک از DNSهای مختلف
dig @8.8.8.8 test1.haiocloud.com
dig @1.1.1.1 test1.haiocloud.com
dig @208.67.222.222 test1.haiocloud.com
```

**راه حل:** صبر کنید! propagation معمولاً 5-30 دقیقه طول میکشد.

---

### 🔴 Internal DNS کار نمی‌کند

**تست:**
```bash
kubectl exec -n webtops POD_NAME -- nslookup kubernetes.default
```

**راه حل:**
```bash
# بررسی CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# ری‌استارت CoreDNS
kubectl rollout restart deployment -n kube-system coredns

# چک لاگ‌ها
kubectl logs -n kube-system -l k8s-app=kube-dns
```

---

## 6. مشکلات Ingress

### 🔴 URL باز نمی‌شود

**مراحل عیب‌یابی:**

#### مرحله 1: چک Ingress

```bash
kubectl get ingress -n webtops
kubectl describe ingress -n webtops INGRESS_NAME
```

#### مرحله 2: چک Traefik

```bash
# وضعیت Traefik
kubectl get pods -n kube-system -l app=traefik

# External IP
kubectl get svc -n kube-system traefik
# باید EXTERNAL-IP: 94.182.92.207 باشد

# لاگ‌ها
kubectl logs -n kube-system -l app=traefik --tail=50
```

#### مرحله 3: چک Service

```bash
kubectl get svc -n webtops
kubectl describe svc -n webtops SERVICE_NAME

# Endpoints
kubectl get endpoints -n webtops SERVICE_NAME
```

#### مرحله 4: تست مستقیم با Port Forward

```bash
kubectl port-forward -n webtops svc/SERVICE_NAME 8080:3000

# سپس در مرورگر: http://localhost:8080
```

---

### 🔴 502 Bad Gateway

**علل رایج:**

#### 1. Pod Running نیست

```bash
kubectl get pods -n webtops -l user=USERNAME
```

#### 2. Service به Pod وصل نیست

```bash
kubectl describe svc -n webtops SERVICE_NAME
kubectl get endpoints -n webtops SERVICE_NAME
```

#### 3. Port اشتباه

```bash
kubectl get svc -n webtops SERVICE_NAME -o yaml | grep -A 5 ports
```

**راه حل:**
```bash
# ری‌استارت همه چیز
kubectl rollout restart deployment -n webtops DEPLOYMENT_NAME
kubectl delete pod -n kube-system -l app=traefik
```

---

## 7. مشکلات Node

### 🔴 Node در وضعیت NotReady

**بررسی:**
```bash
kubectl get nodes
kubectl describe node NODE_NAME
```

**علل رایج:**

#### 1. K3s Agent متوقف شده

```bash
ssh NODE_NAME 'systemctl status k3s-agent'
```

**راه حل:**
```bash
ssh NODE_NAME 'systemctl restart k3s-agent'
```

#### 2. Network مشکل دارد

```bash
ssh NODE_NAME 'ping -c 3 94.182.92.207'
```

#### 3. Disk پر شده

```bash
ssh NODE_NAME 'df -h'
```

**راه حل:**
```bash
ssh NODE_NAME 'docker system prune -af --volumes'
```

---

## 8. ابزارهای عیب‌یابی

### 🔍 اسکریپت جامع Troubleshoot

```bash
#!/bin/bash
# save as: troubleshoot.sh

USERNAME=$1

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

echo "========================================="
echo "Troubleshooting for user: $USERNAME"
echo "========================================="
echo ""

echo "=== POD STATUS ==="
kubectl get pod -n webtops -l user=$USERNAME -o wide

echo ""
echo "=== POD DESCRIBE ==="
kubectl describe pod -n webtops -l user=$USERNAME | tail -50

echo ""
echo "=== POD LOGS (last 20 lines) ==="
kubectl logs -n webtops -l user=$USERNAME --tail=20

echo ""
echo "=== POD RESOURCES ==="
kubectl top pod -n webtops -l user=$USERNAME 2>/dev/null || echo "Metrics not available"

echo ""
echo "=== SERVICE ==="
kubectl get svc -n webtops webtop-$USERNAME-svc
kubectl describe svc -n webtops webtop-$USERNAME-svc | tail -20

echo ""
echo "=== INGRESS ==="
kubectl get ingress -n webtops webtop-$USERNAME-ingress
kubectl describe ingress -n webtops webtop-$USERNAME-ingress | tail -20

echo ""
echo "=== PVC ==="
kubectl get pvc -n webtops webtop-$USERNAME-pvc
kubectl describe pvc -n webtops webtop-$USERNAME-pvc | tail -20

echo ""
echo "=== EVENTS (last 10) ==="
kubectl get events -n webtops --sort-by='.lastTimestamp' | tail -10

echo ""
echo "=== DNS TEST ==="
nslookup $USERNAME.haiocloud.com 2>/dev/null || echo "DNS resolution failed"

echo ""
echo "=== HTTP TEST ==="
curl -I -m 5 http://$USERNAME.haiocloud.com 2>&1 | head -5

echo ""
echo "========================================="
echo "Troubleshooting complete!"
echo "========================================="
```

**استفاده:**
```bash
chmod +x troubleshoot.sh
./troubleshoot.sh ali
```

---

### 🔍 لاگ‌های کامل کلاستر

```bash
#!/bin/bash
# save as: cluster-logs.sh

echo "=== NODES ==="
kubectl get nodes -o wide

echo ""
echo "=== ALL PODS ==="
kubectl get pods -A -o wide

echo ""
echo "=== FAILED PODS ==="
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded

echo ""
echo "=== TRAEFIK ==="
kubectl logs -n kube-system -l app=traefik --tail=50

echo ""
echo "=== METALLB ==="
kubectl logs -n metallb-system -l app=metallb,component=controller --tail=30

echo ""
echo "=== COREDNS ==="
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=30

echo ""
echo "=== EVENTS ==="
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

echo ""
echo "=== NODE RESOURCES ==="
kubectl top nodes

echo ""
echo "=== POD RESOURCES ==="
kubectl top pods -A --sort-by=memory | head -20
```

---

### 🔍 دستورات سریع

```bash
# وضعیت کلی
alias k8s-status='kubectl get nodes; kubectl get pods -A | grep -v Running; kubectl top nodes'

# لاگ Traefik
alias traefik-logs='kubectl logs -n kube-system -l app=traefik -f'

# تمام Pods یک کاربر
alias user-pods='kubectl get all -n webtops -l user='

# ری‌استارت سریع
alias quick-restart='kubectl rollout restart deployment -n webtops'

# چک DNS
alias check-dns='nslookup'

# مصرف منابع
alias resources='kubectl top nodes; kubectl top pods -n webtops'
```

---

## 📞 دریافت کمک

اگر مشکل حل نشد:

1. اجرای اسکریپت troubleshoot.sh
2. ذخیره خروجی
3. ایجاد Issue در GitHub با:
   - خروجی troubleshoot
   - شرح مشکل
   - مراحل انجام شده

**GitHub Issues:**
https://github.com/Mehrdad-Hooshmand/haiocloud-k8s/issues

---

**بازگشت:** [← README اصلی](README.md)
