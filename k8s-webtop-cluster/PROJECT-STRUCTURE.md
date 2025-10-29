# 📂 ساختار پروژه HaioCloud

این فایل ساختار کامل پروژه و توضیح هر فایل را ارائه می‌دهد.

---

## 📋 فهرست فایل‌ها

### 🔧 اسکریپت‌های نصب کلاستر

| فایل | حجم | توضیحات | استفاده |
|------|-----|---------|----------|
| `01-install-k3s-master.sh` | 3.8 KB | نصب K3s Master | `ssh k8s-master < 01-install-k3s-master.sh` |
| `02-install-k3s-worker.sh` | 3 KB | نصب K3s Workers | `ssh k8s-worker1 < 02-install-k3s-worker.sh` |
| `03-install-metallb.sh` | 2 KB | نصب MetalLB LoadBalancer | `ssh k8s-master < 03-install-metallb.sh` |
| `04-install-traefik.sh` | 3.4 KB | نصب Traefik Ingress | `ssh k8s-master < 04-install-traefik.sh` |
| `05-install-longhorn.sh` | 2.5 KB | نصب Longhorn Storage (اختیاری) | `ssh k8s-master < 05-install-longhorn.sh` |

### 👥 اسکریپت‌های مدیریت کاربر (روی کلاستر)

| فایل | حجم | توضیحات | استفاده |
|------|-----|---------|----------|
| `create-webtop.sh` | 5.4 KB | ساخت کاربر جدید | `bash create-webtop.sh USERNAME` |
| `delete-webtop.sh` | 1.3 KB | حذف کاربر | `bash delete-webtop.sh USERNAME` |
| `list-webtops.sh` | 1.8 KB | لیست تمام کاربران | `bash list-webtops.sh` |

### 🖥️ اسکریپت‌های Docker مستقل

| فایل | حجم | توضیحات | استفاده |
|------|-----|---------|----------|
| `install-webtop-standalone.sh` | 15.7 KB | نصب Webtop با Docker (مستقل) | `curl -fsSL URL \| bash` |
| `client-install-webtop.sh` | 10.1 KB | نسخه قدیمی نصب Docker | استفاده نشود |
| `remote-create-webtop.sh` | 9.6 KB | ساخت کاربر از راه دور | `bash remote-create-webtop.sh USER` |

### 📄 فایل‌های پیکربندی

| فایل | حجم | توضیحات | استفاده |
|------|-----|---------|----------|
| `webtop-template.yaml` | 3.4 KB | Template Kubernetes برای Webtop | استفاده توسط create-webtop.sh |
| `metallb-config.yaml` | 348 B | تنظیمات MetalLB IP Pool | `kubectl apply -f metallb-config.yaml` |

### 📚 مستندات

| فایل | حجم | توضیحات | مخاطب |
|------|-----|---------|--------|
| `README.md` | 7.8 KB | مستندات اصلی پروژه | همه کاربران |
| `INSTALLATION.md` | 14.3 KB | راهنمای نصب گام به گام | مدیران سیستم |
| `TROUBLESHOOTING.md` | 15.6 KB | راهنمای عیب‌یابی | مدیران سیستم |
| `USER-GUIDE.md` | 8.3 KB | راهنمای کاربران نهایی | کاربران نهایی |
| `STANDALONE-README.md` | 8.9 KB | راهنمای نصب Docker مستقل | کاربران Docker |
| `CLIENT-README.md` | 6 KB | راهنمای قدیمی Docker | استفاده نشود |
| `FINAL-SUMMARY.md` | 7 KB | خلاصه نهایی پروژه | مدیران |
| `STATUS.md` | 3.3 KB | وضعیت فعلی کلاستر | مدیران |
| `PROGRESS.md` | 2.2 KB | پیشرفت نصب | مدیران |

### 🔍 اسکریپت‌های کمکی

| فایل | حجم | توضیحات | استفاده |
|------|-----|---------|----------|
| `check-cluster.sh` | 1.7 KB | بررسی وضعیت کلاستر | `bash check-cluster.sh` |
| `check-progress.ps1` | 1.5 KB | بررسی پیشرفت (Windows) | `.\check-progress.ps1` |
| `quick-check.ps1` | 736 B | بررسی سریع (Windows) | `.\quick-check.ps1` |

---

## 📂 ساختار پیشنهادی برای GitHub

```
haiocloud-k8s/
├── README.md                           ← شروع اینجا
├── LICENSE                             ← لایسنس MIT
│
├── docs/                               ← مستندات
│   ├── INSTALLATION.md                 ← راهنمای نصب
│   ├── TROUBLESHOOTING.md              ← عیب‌یابی
│   ├── USER-GUIDE.md                   ← راهنمای کاربر
│   └── ARCHITECTURE.md                 ← معماری (اختیاری)
│
├── scripts/                            ← اسکریپت‌های نصب
│   ├── cluster/                        ← نصب کلاستر
│   │   ├── 01-install-k3s-master.sh
│   │   ├── 02-install-k3s-worker.sh
│   │   ├── 03-install-metallb.sh
│   │   ├── 04-install-traefik.sh
│   │   └── 05-install-longhorn.sh
│   │
│   ├── management/                     ← مدیریت کاربر
│   │   ├── create-webtop.sh
│   │   ├── delete-webtop.sh
│   │   └── list-webtops.sh
│   │
│   └── standalone/                     ← Docker مستقل
│       └── install-webtop-standalone.sh
│
├── configs/                            ← فایل‌های پیکربندی
│   ├── webtop-template.yaml
│   ├── metallb-config.yaml
│   └── traefik-config.yaml
│
├── tools/                              ← ابزارهای کمکی
│   ├── check-cluster.sh
│   └── troubleshoot.sh
│
└── examples/                           ← مثال‌ها
    ├── ssh-config-example
    └── user-manifest-example.yaml
```

---

## 🎯 فایل‌های ضروری برای GitHub

### حتماً باید باشند:

1. ✅ **README.md** - نقطه شروع
2. ✅ **LICENSE** - لایسنس MIT
3. ✅ **docs/INSTALLATION.md** - راهنمای نصب
4. ✅ **scripts/cluster/*.sh** - اسکریپت‌های نصب
5. ✅ **scripts/management/*.sh** - مدیریت کاربر
6. ✅ **configs/webtop-template.yaml** - Template

### اختیاری اما مفید:

- **TROUBLESHOOTING.md** - عیب‌یابی
- **CONTRIBUTING.md** - راهنمای مشارکت
- **CHANGELOG.md** - تاریخچه تغییرات
- **.github/workflows/** - CI/CD
- **examples/** - مثال‌های کاربردی

---

## 📝 توضیح فایل‌های کلیدی

### 01-install-k3s-master.sh

**نقش:** نصب K3s روی Master Node

**ویژگی‌ها:**
- ✅ تنظیم ArvanCloud mirror برای ایران
- ✅ غیرفعال کردن Swap
- ✅ نصب K3s با disable traefik/servicelb
- ✅ تنظیم kubectl

**پیش‌نیازها:**
- Ubuntu 20.04/22.04
- دسترسی Root
- اتصال اینترنت

**خروجی:**
- K3s Master آماده
- kubeconfig در `/etc/rancher/k3s/k3s.yaml`
- Token در `/var/lib/rancher/k3s/server/node-token`

---

### 02-install-k3s-worker.sh

**نقش:** اضافه کردن Worker Node به کلاستر

**متغیرهای لازم:**
- `K3S_TOKEN`: از Master
- `K3S_URL`: آدرس Master (https://IP:6443)

**استفاده:**
```bash
ssh worker "K3S_TOKEN=$TOKEN K3S_URL=$URL bash" < 02-install-k3s-worker.sh
```

---

### 03-install-metallb.sh

**نقش:** نصب MetalLB LoadBalancer

**کاربرد:** تخصیص IP خارجی به Services

**پس از نصب:**
```bash
kubectl apply -f metallb-config.yaml
```

---

### 04-install-traefik.sh

**نقش:** نصب Traefik Ingress Controller

**کاربرد:** Routing HTTP بر اساس Domain

**پورت‌ها:**
- 80: HTTP
- 8080: Dashboard

---

### create-webtop.sh

**نقش:** ساخت کاربر جدید در کلاستر

**جریان کار:**
1. بررسی username (الفبایی کوچک فقط)
2. ایجاد Secret با password تصادفی
3. ساخت Deployment, Service, PVC, Ingress
4. انتظار برای Ready شدن Pod
5. نمایش اطلاعات دسترسی

**مثال:**
```bash
bash create-webtop.sh ali
# URL: http://ali.haiocloud.com
# Pass: [random]
```

---

### webtop-template.yaml

**نقش:** Template Kubernetes برای هر کاربر

**شامل:**
- Namespace: webtops
- Deployment: webtop container
- PVC: 5GB storage
- Service: ClusterIP port 3000
- Ingress: HTTP routing

**متغیرها (جایگزین توسط اسکریپت):**
- `USERNAME`: نام کاربر
- `PASSWORD`: رمز عبور

---

## 🚀 نحوه استفاده (Quick Start)

### 1. کلون پروژه

```bash
git clone https://github.com/Mehrdad-Hooshmand/haiocloud-k8s.git
cd haiocloud-k8s
```

### 2. نصب کلاستر

```bash
# Master
ssh k8s-master < scripts/cluster/01-install-k3s-master.sh

# Get Token
TOKEN=$(ssh k8s-master "cat /var/lib/rancher/k3s/server/node-token")

# Workers
ssh k8s-worker1 "K3S_TOKEN=$TOKEN K3S_URL=https://MASTER_IP:6443 bash" < scripts/cluster/02-install-k3s-worker.sh
ssh k8s-worker2 "K3S_TOKEN=$TOKEN K3S_URL=https://MASTER_IP:6443 bash" < scripts/cluster/02-install-k3s-worker.sh

# MetalLB & Traefik
ssh k8s-master < scripts/cluster/03-install-metallb.sh
ssh k8s-master < scripts/cluster/04-install-traefik.sh
```

### 3. ساخت کاربر

```bash
ssh k8s-master "bash /root/create-webtop.sh USERNAME"
```

---

## 📊 آمار پروژه

| مورد | تعداد/حجم |
|------|-----------|
| **تعداد فایل‌ها** | 25 |
| **اسکریپت‌های Bash** | 13 |
| **فایل‌های Markdown** | 10 |
| **فایل‌های YAML** | 2 |
| **حجم کل** | ~170 KB |
| **خطوط کد (تقریبی)** | ~3,500 |

---

## 🔄 تاریخچه نسخه‌ها

### نسخه 1.0.0 (2025-10-29)

**اضافه شده:**
- ✅ نصب خودکار کلاستر K3s
- ✅ MetalLB LoadBalancer
- ✅ Traefik Ingress Controller
- ✅ اسکریپت‌های مدیریت کاربر
- ✅ Webtop Alpine-KDE
- ✅ مستندات کامل

**شناخته شده:**
- ⚠️ SSL موقتاً غیرفعال (Let's Encrypt rate limit)
- ⚠️ Longhorn در حال نصب
- ⚠️ Metrics Server نیاز به پیکربندی دارد

---

## 📞 پشتیبانی

**مستندات:**
- README.md - شروع
- INSTALLATION.md - نصب
- TROUBLESHOOTING.md - عیب‌یابی

**تماس:**
- GitHub: https://github.com/Mehrdad-Hooshmand/haiocloud-k8s
- Email: mehrdad@haiocloud.com

---

**نسخه:** 1.0.0  
**تاریخ:** 2025-10-29  
**نویسنده:** Mehrdad Hooshmand
