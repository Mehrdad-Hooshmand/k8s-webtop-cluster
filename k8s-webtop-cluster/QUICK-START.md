# ⚡ راهنمای شروع سریع HaioCloud

این راهنما برای کسانی است که می‌خواهند **فوری** کلاستر را راه‌اندازی کنند.

---

## 🎯 در یک نگاه

**هدف:** 3 سرور → کلاستر K3s → دسکتاپ Ubuntu برای کاربران

**زمان:** ~30 دقیقه

**نیاز:** 3 سرور Ubuntu با SSH

---

## 📋 چک‌لیست سریع

### پیش از شروع:

- [ ] 3 سرور Ubuntu 20.04/22.04
- [ ] دسترسی SSH با کلید
- [ ] دامنه (مثلاً `haiocloud.com`)
- [ ] Cloudflare DNS دسترسی

---

## 🚀 نصب در 5 مرحله

### مرحله 1: آماده‌سازی SSH (2 دقیقه)

```bash
# ویرایش ~/.ssh/config
nano ~/.ssh/config
```

```
Host k8s-master
  HostName 94.182.92.207
  User root
  Port 2280
  IdentityFile ~/.ssh/id_rsa

Host k8s-worker1
  HostName 94.182.92.203
  User root
  Port 2280
  IdentityFile ~/.ssh/id_rsa

Host k8s-worker2
  HostName 94.182.92.241
  User root
  Port 2280
  IdentityFile ~/.ssh/id_rsa
```

**تست:**
```bash
ssh k8s-master "hostname"
```

---

### مرحله 2: نصب K3s Master (5 دقیقه)

```bash
ssh k8s-master < 01-install-k3s-master.sh
```

**انتظار:** پیام "K3s Master installed successfully"

---

### مرحله 3: اضافه کردن Workers (10 دقیقه)

```bash
# دریافت Token
TOKEN=$(ssh k8s-master "cat /var/lib/rancher/k3s/server/node-token")

# نصب Worker 1
ssh k8s-worker1 "K3S_TOKEN=$TOKEN K3S_URL=https://94.182.92.207:6443 bash" < 02-install-k3s-worker.sh

# نصب Worker 2
ssh k8s-worker2 "K3S_TOKEN=$TOKEN K3S_URL=https://94.182.92.207:6443 bash" < 02-install-k3s-worker.sh
```

**تست:**
```bash
ssh k8s-master "kubectl get nodes"
# باید 3 node در حالت Ready ببینید
```

---

### مرحله 4: نصب شبکه (MetalLB + Traefik) (5 دقیقه)

```bash
# MetalLB
ssh k8s-master < 03-install-metallb.sh

# Traefik
ssh k8s-master < 04-install-traefik.sh
```

**تست:**
```bash
ssh k8s-master "kubectl get svc -n kube-system traefik"
# باید EXTERNAL-IP = 94.182.92.207 ببینید
```

---

### مرحله 5: تنظیم DNS (5 دقیقه)

**در Cloudflare:**

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | * | 94.182.92.207 | OFF ❌ |
| A | @ | 94.182.92.207 | OFF ❌ |

**تست:**
```bash
nslookup test.haiocloud.com
# باید 94.182.92.207 برگردد
```

---

## 👤 ساخت اولین کاربر (2 دقیقه)

```bash
# کپی اسکریپت‌ها
scp create-webtop.sh k8s-master:/root/
scp webtop-template.yaml k8s-master:/root/

# ساخت کاربر
ssh k8s-master "bash /root/create-webtop.sh ali"
```

**خروجی:**
```
✅ Webtop created successfully!

📋 Access Information:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 URL: http://ali.haiocloud.com
👤 Username: admin
🔑 Password: xYz123AbC...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**دسترسی:** مرورگر باز کنید → `http://ali.haiocloud.com`

---

## 🎉 تمام!

حالا شما یک کلاستر Kubernetes کامل دارید!

---

## 📊 بررسی سلامت

### همه‌چیز OK است؟

```bash
ssh k8s-master "bash /root/check-cluster.sh"
```

**خروجی مورد انتظار:**
```
✅ All 3 nodes Ready
✅ All system pods Running
✅ MetalLB operational
✅ Traefik has external IP
✅ DNS resolves correctly
```

---

## 🔧 دستورات رایج

### مدیریت کاربران:

```bash
# ساخت کاربر جدید
ssh k8s-master "bash /root/create-webtop.sh USERNAME"

# لیست کاربران
ssh k8s-master "bash /root/list-webtops.sh"

# حذف کاربر
ssh k8s-master "bash /root/delete-webtop.sh USERNAME"
```

### بررسی وضعیت:

```bash
# Nodes
ssh k8s-master "kubectl get nodes"

# Pods
ssh k8s-master "kubectl get pods -n webtops"

# مصرف منابع
ssh k8s-master "kubectl top nodes"
ssh k8s-master "kubectl top pods -n webtops"
```

### لاگ‌ها:

```bash
# لاگ Pod خاص
ssh k8s-master "kubectl logs -n webtops webtop-USERNAME"

# لاگ Traefik
ssh k8s-master "kubectl logs -n kube-system -l app.kubernetes.io/name=traefik"
```

---

## ⚠️ مشکلات رایج

### Pod در حالت Pending:

```bash
ssh k8s-master "kubectl describe pod -n webtops webtop-USERNAME"
# بررسی Events برای دلیل
```

**راه‌حل:** معمولاً مربوط به منابع کافی نبودن است:
```bash
ssh k8s-master "kubectl top nodes"
```

---

### 502 Bad Gateway:

**علل احتمالی:**
1. Pod هنوز Running نیست
2. DNS تنظیم نشده
3. Traefik مشکل دارد

**بررسی:**
```bash
# Pod Ready است؟
ssh k8s-master "kubectl get pod -n webtops webtop-USERNAME"

# DNS OK است؟
nslookup USERNAME.haiocloud.com

# Traefik OK است؟
ssh k8s-master "kubectl get svc -n kube-system traefik"
```

---

### Pod در CrashLoopBackOff:

```bash
# لاگ کامل
ssh k8s-master "kubectl logs -n webtops webtop-USERNAME --previous"
```

**راه‌حل رایج:** حذف و ساخت مجدد
```bash
ssh k8s-master "bash /root/delete-webtop.sh USERNAME"
ssh k8s-master "bash /root/create-webtop.sh USERNAME"
```

---

## 📚 مراحل بعدی

### اکنون که کلاستر راه افتاد:

1. ✅ **مستندات کامل:** [README.md](README.md)
2. ✅ **عیب‌یابی پیشرفته:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. ✅ **راهنمای کاربر:** [USER-GUIDE.md](USER-GUIDE.md)
4. ✅ **نصب پیشرفته:** [INSTALLATION.md](INSTALLATION.md)

### ویژگی‌های اضافی:

```bash
# Longhorn Storage (اختیاری)
ssh k8s-master < 05-install-longhorn.sh

# Metrics Server (برای monitoring)
# به زودی...

# Backup خودکار
# به زودی...
```

---

## 🆘 کمک نیاز دارید؟

### منابع:

- 📖 **مستندات:** همین پوشه
- 🐛 **باگ:** [GitHub Issues](https://github.com/Mehrdad-Hooshmand/haiocloud-k8s/issues)
- 💬 **سوال:** [GitHub Discussions](https://github.com/Mehrdad-Hooshmand/haiocloud-k8s/discussions)
- 📧 **ایمیل:** mehrdad@haiocloud.com

---

## 🎯 خلاصه دستورات

```bash
# نصب
ssh k8s-master < 01-install-k3s-master.sh
TOKEN=$(ssh k8s-master "cat /var/lib/rancher/k3s/server/node-token")
ssh k8s-worker1 "K3S_TOKEN=$TOKEN K3S_URL=https://MASTER_IP:6443 bash" < 02-install-k3s-worker.sh
ssh k8s-worker2 "K3S_TOKEN=$TOKEN K3S_URL=https://MASTER_IP:6443 bash" < 02-install-k3s-worker.sh
ssh k8s-master < 03-install-metallb.sh
ssh k8s-master < 04-install-traefik.sh

# DNS در Cloudflare: A record * -> MASTER_IP

# ساخت کاربر
scp create-webtop.sh k8s-master:/root/
scp webtop-template.yaml k8s-master:/root/
ssh k8s-master "bash /root/create-webtop.sh USERNAME"

# بررسی
ssh k8s-master "kubectl get nodes"
ssh k8s-master "kubectl get pods -n webtops"
```

---

**موفق باشید! 🚀**

---

**نسخه:** 1.0.0  
**تاریخ:** 2025-10-29  
**زمان خواندن:** 5 دقیقه  
**زمان اجرا:** 30 دقیقه
