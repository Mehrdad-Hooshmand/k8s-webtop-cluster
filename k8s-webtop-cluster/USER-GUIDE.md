# 🎉 K8s Cluster haiocloud.com - راهنمای استفاده

## ✅ نصب کامل شد!

تبریک! کلاستر Kubernetes شما با موفقیت راه‌اندازی شد و آماده استفاده است.

---

## 📊 خلاصه کلاستر

### سرورها
- **Master:** 94.182.92.207
- **Worker-1:** 94.182.92.203
- **Worker-2:** 94.182.92.241
- **منابع کل:** 12 CPU، 12GB RAM، 150GB Storage

### نرم‌افزارهای نصب شده
- ✅ **K3s** v1.33.5+k3s1 (Kubernetes)
- ✅ **MetalLB** (LoadBalancer)
- ✅ **Traefik** (Ingress + Auto SSL)
- ✅ **local-path** Storage (پیش‌فرض)
- 🔄 **Longhorn** (در حال نصب - اختیاری)

### دامنه و DNS
- **Domain:** haiocloud.com
- **Wildcard:** *.apps.haiocloud.com → 94.182.92.207
- **SSL:** Let's Encrypt (خودکار)

---

## 🚀 استفاده سریع

### ساخت Webtop برای کاربر جدید

```bash
# SSH به Master
ssh -p 2280 root@94.182.92.207

# ساخت Webtop برای کاربر (مثال: user1)
./create-webtop.sh user1

# نتیجه:
# URL: https://user1.apps.haiocloud.com
# Username: admin
# Password: (نمایش داده می‌شود)
```

### لیست همه Webtop ها

```bash
ssh -p 2280 root@94.182.92.207
./list-webtops.sh
```

### حذف Webtop کاربر

```bash
ssh -p 2280 root@94.182.92.207
./delete-webtop.sh user1
```

---

## 🧪 تست اولیه

### کاربر تست فعلی

**✅ یک Webtop تست ایجاد شده:**

- **URL:** https://test1.apps.haiocloud.com
- **Username:** admin
- **Password:** `9scwqcVBZvtDjViY2tNoSA==`

**نحوه دسترسی:**
1. مرورگر را باز کنید
2. به آدرس بروید: https://test1.apps.haiocloud.com
3. منتظر بمانید تا SSL (1-2 دقیقه اول)
4. با username و password وارد شوید

---

## 📝 دستورات مفید

### مدیریت Webtop

```bash
# ساخت کاربر جدید
./create-webtop.sh <username>

# لیست کاربران
./list-webtops.sh

# حذف کاربر
./delete-webtop.sh <username>

# دیدن password کاربر
cat /root/webtop-<username>-password.txt

# دیدن لاگ کاربر
kubectl logs -n webtops -l user=<username>
```

### مدیریت کلاستر

```bash
# لیست تمام Nodes
kubectl get nodes -o wide

# لیست تمام Pods
kubectl get pods -A

# لیست Webtop ها
kubectl get pods -n webtops

# مصرف منابع
kubectl top nodes
kubectl top pods -n webtops

# وضعیت کلاستر
kubectl cluster-info
```

### چک کردن سرویس‌ها

```bash
# Traefik (Ingress)
kubectl get svc -n traefik

# MetalLB
kubectl get pods -n metallb-system

# Webtops
kubectl get ingress -n webtops
```

---

## 🔧 عیب‌یابی

### Webtop لود نمی‌شود

```bash
# چک کردن Pod
kubectl get pods -n webtops -l user=<username>

# دیدن لاگ
kubectl logs -n webtops -l user=<username>

# چک کردن Ingress
kubectl get ingress -n webtops

# چک کردن Service
kubectl get svc -n webtops
```

### SSL کار نمی‌کند

- SSL اولین بار 1-2 دقیقه طول می‌کشد
- مطمئن شوید DNS درست است: `nslookup test1.apps.haiocloud.com`
- چک کردن certificate: `kubectl get certificate -n webtops`

### Pod شروع نمی‌شود

```bash
# دیدن Events
kubectl describe pod -n webtops <pod-name>

# چک کردن Storage
kubectl get pvc -n webtops

# بررسی منابع
kubectl top nodes
```

---

## 📈 ظرفیت و محدودیت‌ها

### منابع هر Webtop

- **CPU Request:** 250m (0.25 core)
- **CPU Limit:** 1000m (1 core)
- **Memory Request:** 512Mi
- **Memory Limit:** 2Gi
- **Storage:** 5Gi per user

### تعداد کاربران همزمان

با منابع فعلی (12 CPU، 12GB RAM):
- **محافظه‌کارانه:** 10 کاربر
- **بهینه:** 8 کاربر (با فضای امن)

برای افزایش:
- اضافه کردن Worker Node جدید
- یا افزایش منابع Worker های موجود

---

## 🔐 امنیت

### SSH
- **Port:** 2280 (غیر استاندارد)
- **User:** root
- **Auth:** SSH Key

### K3s Token
```
K1003670d0eca010452e89b39e986516e709735e2c33f5467345da9dac014447cad::server:7f5fd6b35077f92addb13fcc7ecaa578
```
**⚠️ این token را محرمانه نگه دارید!**

### Webtop Passwords
- هر کاربر password منحصر به فرد دارد
- در `/root/webtop-<username>-password.txt` ذخیره می‌شود
- کاربران نمی‌توانند به هم دسترسی داشته باشند

---

## 🔄 Scale کردن

### اضافه کردن Worker جدید

```bash
# روی سرور جدید
curl -sfL https://get.k3s.io | K3S_URL=https://94.182.92.207:6443 \
  K3S_TOKEN=K1003670d0eca010452e89b39e986516e709735e2c33f5467345da9dac014447cad::server:7f5fd6b35077f92addb13fcc7ecaa578 \
  sh -

# چک از Master
kubectl get nodes
```

### افزایش منابع Webtop

فایل `/root/create-webtop.sh` را ویرایش کنید:
- `cpu: "500m"` (2x بیشتر)
- `memory: "1Gi"` (2x بیشتر)
- `storage: 10Gi` (2x بیشتر)

---

## 📁 فایل‌های مهم

### روی Master (94.182.92.207)

```
/root/
├── create-webtop.sh          # ساخت Webtop
├── delete-webtop.sh          # حذف Webtop
├── list-webtops.sh           # لیست Webtops
├── k3s-token.txt             # Token برای Worker ها
├── webtop-<user>-password.txt # Password هر کاربر
└── *.log                      # لاگ‌های نصب

/etc/rancher/k3s/
└── k3s.yaml                   # Kubeconfig
```

### روی Windows (Local)

```
c:\Users\Mehrdad\k8s-haiocloud\
├── *.sh                       # تمام اسکریپت‌ها
├── STATUS.md                  # وضعیت فعلی
├── README.md                  # راهنما
└── check-progress.ps1         # چک کردن پیشرفت
```

---

## 🎯 مثال‌های کاربردی

### ساخت 3 کاربر

```bash
ssh -p 2280 root@94.182.92.207

./create-webtop.sh ali
./create-webtop.sh reza
./create-webtop.sh sara

./list-webtops.sh
```

نتیجه:
- https://ali.apps.haiocloud.com
- https://reza.apps.haiocloud.com
- https://sara.apps.haiocloud.com

### مشاهده مصرف منابع

```bash
kubectl top nodes
kubectl top pods -n webtops
```

### Backup Password ها

```bash
# روی Master
tar -czf /root/webtop-passwords-backup.tar.gz /root/webtop-*-password.txt

# دانلود به Windows
scp -P 2280 root@94.182.92.207:/root/webtop-passwords-backup.tar.gz .
```

---

## 📞 پشتیبانی

### لاگ‌ها

```bash
# لاگ Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# لاگ MetalLB
kubectl logs -n metallb-system -l app=metallb

# لاگ Webtop خاص
kubectl logs -n webtops -l user=<username> -f
```

### رفع مشکل رایج

1. **Webtop بارگذاری نمی‌شود:** صبر کنید 2-3 دقیقه، سپس F5
2. **SSL Error:** اولین بار 1-2 دقیقه طول می‌کشد
3. **Password کار نمی‌کند:** دوباره چک کنید: `cat /root/webtop-<user>-password.txt`

---

## 🚀 مراحل بعدی (اختیاری)

### 1. نصب Longhorn (Storage بهتر)
اگر نیاز به replica و HA دارید

### 2. نصب MinIO (S3 Storage)
برای backup و object storage

### 3. نصب Prometheus + Grafana
برای monitoring کامل‌تر

### 4. اضافه کردن Worker بیشتر
برای ظرفیت بیشتر

---

## ✅ چک لیست راه‌اندازی

- [x] K3s Cluster (3 nodes)
- [x] MetalLB LoadBalancer
- [x] Traefik Ingress + SSL
- [x] DNS Configuration (*.apps.haiocloud.com)
- [x] Webtop Template
- [x] Automation Scripts
- [x] Test Webtop (test1)
- [x] مستندسازی کامل

**🎉 همه چیز آماده است! می‌توانید شروع کنید.**

---

**آخرین بروزرسانی:** 29 اکتبر 2025
**وضعیت:** ✅ Production Ready
