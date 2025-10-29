# 🚀 HaioCloud Kubernetes Platform

[![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s%20v1.33-326CE5?logo=kubernetes&logoColor=white)](https://k3s.io/)
[![Alpine](https://img.shields.io/badge/Alpine-KDE-0D597F?logo=alpine-linux&logoColor=white)](https://alpinelinux.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

پلتفرم Kubernetes برای ارائه دسکتاپ‌های مجازی با دسترسی از طریق مرورگر

[English](#) | [فارسی](#)

---

## 📋 فهرست

- [معرفی](#-معرفی)
- [معماری](#️-معماری)
- [ویژگی‌ها](#-ویژگیها)
- [نصب](#-نصب)
- [استفاده](#-استفاده)
- [مدیریت](#-مدیریت)
- [مانیتورینگ](#-مانیتورینگ)
- [Backup](#-backup)
- [عیب‌یابی](#-عیبیابی)

---

## 🎯 معرفی

**HaioCloud** یک پلتفرم Kubernetes است که دسکتاپ‌های مجازی Linux را از طریق مرورگر ارائه می‌دهد.

### چرا HaioCloud؟

✅ **راه‌اندازی آسان** - نصب خودکار با اسکریپت‌های آماده  
✅ **مقیاس‌پذیر** - پشتیبانی از صدها کاربر  
✅ **ایزوله** - هر کاربر محیط اختصاصی  
✅ **دسترسی آسان** - فقط مرورگر، بدون VPN  
✅ **مدیریت ساده** - اسکریپت‌های خودکار  

---

## 🏗️ معماری

### کلاستر

```
┌────────────────────────────────────────────┐
│         HaioCloud K8s Cluster              │
├────────────────────────────────────────────┤
│  Master          Worker1        Worker2    │
│  .207            .203            .241       │
│  • K3s           • Pods          • Pods    │
│  • MetalLB       • Storage       • Storage │
│  • Traefik                                 │
└────────────────────────────────────────────┘
```

### جریان درخواست

```
Browser → DNS → MetalLB → Traefik → Service → Pod → Desktop
```

### اجزا

| Component | Version | Purpose |
|-----------|---------|---------|
| K3s | v1.33.5 | Kubernetes |
| MetalLB | v0.14.8 | LoadBalancer |
| Traefik | v3.x | Ingress |
| local-path | Built-in | Storage |

---

## ✨ ویژگی‌ها

- 🖥️ **Desktop**: KDE Plasma on Alpine
- 💾 **Storage**: 5GB per user (قابل افزایش)
- 🔐 **Security**: Password تصادفی، Pod isolation
- 📊 **Resources**: 250m-1000m CPU, 512Mi-2Gi RAM

---

## 🚀 نصب

### پیش‌نیازها

- 3 سرور Ubuntu 20.04/22.04
- 4GB RAM per server
- دامنه با wildcard DNS

### نصب سریع

```bash
git clone https://github.com/Mehrdad-Hooshmand/haiocloud-k8s.git
cd haiocloud-k8s
bash auto-install.sh
```

### نصب دستی

```bash
# 1. K3s Master
ssh k8s-master < 01-install-k3s-master.sh

# 2. Get Token
K3S_TOKEN=$(ssh k8s-master "cat /var/lib/rancher/k3s/server/node-token")

# 3. Workers
ssh k8s-worker1 "K3S_TOKEN=$K3S_TOKEN K3S_URL=https://94.182.92.207:6443 bash" < 02-install-k3s-worker.sh
ssh k8s-worker2 "K3S_TOKEN=$K3S_TOKEN K3S_URL=https://94.182.92.207:6443 bash" < 02-install-k3s-worker.sh

# 4. MetalLB
ssh k8s-master < 03-install-metallb.sh

# 5. Traefik  
ssh k8s-master < 04-install-traefik.sh

# 6. DNS
# Cloudflare: A * → 94.182.92.207
```

---

## 💻 استفاده

### ساخت کاربر

```bash
ssh k8s-master "bash /root/create-webtop.sh USERNAME"
```

**خروجی:**
```
URL: http://USERNAME.haiocloud.com
Username: admin
Password: [random]
```

### لیست کاربران

```bash
ssh k8s-master "bash /root/list-webtops.sh"
```

### حذف کاربر

```bash
ssh k8s-master "bash /root/delete-webtop.sh USERNAME"
```

---

## 👥 مدیریت

### kubectl

```bash
# Pods
kubectl get pods -n webtops

# Logs
kubectl logs -n webtops webtop-USERNAME-xxxxx

# Shell
kubectl exec -it -n webtops webtop-USERNAME-xxxxx -- bash

# Restart
kubectl rollout restart deployment -n webtops webtop-USERNAME
```

### تغییر رمز

```bash
kubectl delete secret -n webtops webtop-USERNAME-secret
kubectl create secret generic webtop-USERNAME-secret \
  -n webtops --from-literal=password='NEW_PASS'
kubectl rollout restart deployment -n webtops webtop-USERNAME
```

---

## 📊 مانیتورینگ

```bash
# Nodes
kubectl get nodes
kubectl top nodes

# Pods  
kubectl top pods -n webtops

# Events
kubectl get events -n webtops --sort-by='.lastTimestamp'
```

---

## 💾 Backup

### کاربر

```bash
# Backup
kubectl exec -n webtops POD -- tar czf /tmp/backup.tar.gz /config
kubectl cp webtops/POD:/tmp/backup.tar.gz ./backup.tar.gz

# Restore
kubectl cp ./backup.tar.gz webtops/POD:/tmp/
kubectl exec -n webtops POD -- tar xzf /tmp/backup.tar.gz -C /
```

### کلاستر

```bash
# etcd snapshot
ssh k8s-master "k3s etcd-snapshot save"

# Resources
kubectl get all -A -o yaml > backup.yaml
```

---

## 🐛 عیب‌یابی

### Pod Pending

```bash
kubectl describe pod -n webtops POD
kubectl top nodes  # Check resources
```

### URL کار نمی‌کند

```bash
# DNS
nslookup USERNAME.haiocloud.com

# Ingress
kubectl get ingress -n webtops
kubectl describe ingress -n webtops webtop-USERNAME-ingress

# Traefik
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
```

### Performance

```bash
# Resources
kubectl top pod -n webtops POD

# Increase
kubectl patch deployment -n webtops webtop-USERNAME --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value": "2000m"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "4Gi"}
]'
```

---

## 📈 مقیاس‌پذیری

### Worker جدید

```bash
# روی سرور جدید
K3S_TOKEN="[TOKEN]"
K3S_URL="https://94.182.92.207:6443"
curl -sfL https://get.k3s.io | sh -s - agent --server $K3S_URL --token $K3S_TOKEN
```

---

## 🔧 تنظیمات

### ساختار فایل‌ها

```
haiocloud-k8s/
├── 01-install-k3s-master.sh
├── 02-install-k3s-worker.sh  
├── 03-install-metallb.sh
├── 04-install-traefik.sh
├── metallb-config.yaml
├── webtop-template.yaml
├── create-webtop.sh
├── delete-webtop.sh
├── list-webtops.sh
└── README.md
```

### SSH Config

```ssh
Host k8s-master
    HostName 94.182.92.207
    User root
    Port 2280
```

---

## ❓ FAQ

**چند کاربر؟**  
20-80 کاربر بسته به استفاده

**SSL؟**  
فعلاً HTTP، SSL به زودی

**رمز بازیابی؟**  
```bash
kubectl get secret -n webtops webtop-USER-secret -o jsonpath='{.data.password}' | base64 -d
```

**Backup خودکار؟**  
از CronJob استفاده کنید

---

## 📞 پشتیبانی

- **GitHub**: https://github.com/Mehrdad-Hooshmand/haiocloud-k8s
- **Email**: mehrdad@haiocloud.com
- **Telegram**: @Mehrdad_Hooshmand

---

## 📜 لایسنس

MIT License

---

## 🙏 منابع

- [K3s](https://k3s.io/)
- [LinuxServer.io](https://www.linuxserver.io/)
- [Traefik](https://traefik.io/)
- [MetalLB](https://metallb.universe.tf/)

---

**Version:** 1.0.0  
**Updated:** 2025-10-29  
**Author:** Mehrdad Hooshmand
