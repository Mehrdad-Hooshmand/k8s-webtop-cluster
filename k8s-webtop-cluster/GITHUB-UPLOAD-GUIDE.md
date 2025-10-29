# 🚀 راهنمای آپلود پروژه به GitHub

این راهنما شما را برای آپلود پروژه HaioCloud K8s به GitHub راهنمایی می‌کند.

---

## 📋 فهرست

1. [نصب Git](#نصب-git)
2. [ساخت Repository در GitHub](#ساخت-repository-در-github)
3. [آپلود فایل‌ها](#آپلود-فایلها)
4. [تنظیمات Repository](#تنظیمات-repository)
5. [به‌روزرسانی‌های بعدی](#بهروزرسانیهای-بعدی)

---

## 1️⃣ نصب Git

### Windows:

**دانلود:**
- https://git-scm.com/download/win

**نصب:**
1. دانلود و اجرای installer
2. تنظیمات پیش‌فرض OK هستند
3. بعد از نصب، PowerShell را restart کنید

**تنظیمات اولیه:**
```powershell
git config --global user.name "Mehrdad Hooshmand"
git config --global user.email "mehrdad@haiocloud.com"
```

---

## 2️⃣ ساخت Repository در GitHub

### مرحله 1: ورود به GitHub

- برو به: https://github.com
- اگر اکانت نداری، **Sign Up** کن
- اگر داری، **Sign In** کن

### مرحله 2: ساخت Repository جدید

1. کلیک روی دکمه **+** (گوشه بالا راست)
2. انتخاب **New repository**

### مرحله 3: تنظیمات Repository

**وارد کنید:**

| فیلد | مقدار |
|------|-------|
| **Repository name** | `haiocloud-k8s` |
| **Description** | Kubernetes cluster for multi-user Ubuntu desktop environments |
| **Visibility** | 🔘 Public (توصیه می‌شود) یا 🔘 Private |
| **Initialize repository** | ❌ هیچکدام (ما خودمان init می‌کنیم) |

**نکته:** ✅ **Initialize with README** را **تیک نزنید** (چون خودمان README داریم)

3. کلیک روی **Create repository**

---

## 3️⃣ آپلود فایل‌ها

### مرحله 1: باز کردن PowerShell

```powershell
cd c:\Users\Mehrdad\k8s-haiocloud
```

### مرحله 2: Initialize Git Repository

```powershell
git init
```

**خروجی:**
```
Initialized empty Git repository in C:/Users/Mehrdad/k8s-haiocloud/.git/
```

### مرحله 3: اضافه کردن فایل‌ها

```powershell
git add .
```

**نکته:** `.gitignore` خودکار فایل‌های حساس را فیلتر می‌کند

### مرحله 4: اولین Commit

```powershell
git commit -m "Initial commit: Complete K8s cluster setup for HaioCloud"
```

**خروجی:**
```
[master (root-commit) abc1234] Initial commit: Complete K8s cluster setup...
 30 files changed, 3500 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 README.md
 ...
```

### مرحله 5: اضافه کردن Remote

**جایگزین کنید:**
```powershell
# با username خودتان جایگزین کنید
git remote add origin https://github.com/Mehrdad-Hooshmand/haiocloud-k8s.git
```

### مرحله 6: تغییر نام Branch به main

```powershell
git branch -M main
```

### مرحله 7: Push کردن

```powershell
git push -u origin main
```

**نکته:** ممکن است از شما username/password بخواهد:

**برای GitHub (بعد از 2021):**
- Username: `Mehrdad-Hooshmand`
- Password: **Personal Access Token** (نه پسورد معمولی!)

#### ساخت Personal Access Token:

1. GitHub → Settings (گوشه بالا راست آواتار)
2. Developer settings (پایین سایدبار چپ)
3. Personal access tokens → Tokens (classic)
4. Generate new token (classic)
5. Scopes: تیک بزنید روی `repo`
6. Generate token
7. **کپی کنید و جایی ذخیره کنید!** (فقط یکبار نشان داده می‌شود)

---

## 4️⃣ تنظیمات Repository

### بعد از آپلود موفق:

1. برو به: `https://github.com/Mehrdad-Hooshmand/haiocloud-k8s`

### افزودن Topics (اختیاری اما توصیه می‌شود):

کلیک روی **⚙️ Settings** → پایین صفحه **Topics:**

افزودن Topics:
```
kubernetes
k3s
metallb
traefik
webtop
ubuntu-desktop
iran
persian
cloud
devops
```

### ویرایش About:

**Description:**
```
🚀 Complete Kubernetes cluster setup for providing browser-based Ubuntu desktop environments to multiple users. Built with K3s, MetalLB, Traefik, and Webtop.
```

**Website:**
```
http://haiocloud.com
```

### افزودن README Badges (اختیاری):

ویرایش `README.md` و اضافه کردن در بالای فایل:

```markdown
# HaioCloud Kubernetes Cluster

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![K3s](https://img.shields.io/badge/K3s-v1.33.5-green.svg)
![MetalLB](https://img.shields.io/badge/MetalLB-v0.14.8-orange.svg)
![Traefik](https://img.shields.io/badge/Traefik-v3-cyan.svg)
![Platform](https://img.shields.io/badge/platform-Ubuntu-red.svg)

... (ادامه README)
```

بعد:
```powershell
git add README.md
git commit -m "Add badges to README"
git push
```

---

## 5️⃣ به‌روزرسانی‌های بعدی

### وقتی فایلی را تغییر دادید:

```powershell
# بررسی تغییرات
git status

# اضافه کردن فایل‌های تغییر یافته
git add FILENAME.md
# یا همه فایل‌ها:
git add .

# Commit
git commit -m "توضیح تغییرات"

# Push
git push
```

### مثال:

```powershell
# ویرایش TROUBLESHOOTING.md
git add TROUBLESHOOTING.md
git commit -m "Update TROUBLESHOOTING: Add SSL certificate renewal guide"
git push
```

---

## 🌳 کار با Branches (پیشرفته)

### ساخت Branch برای ویژگی جدید:

```powershell
# ساخت branch جدید
git checkout -b feature/ssl-support

# تغییرات...
git add .
git commit -m "Add automatic SSL certificate management"

# Push branch
git push -u origin feature/ssl-support
```

### بعد در GitHub:

1. برو به repository
2. کلیک روی **Pull requests**
3. کلیک **New pull request**
4. انتخاب branch: `feature/ssl-support`
5. کلیک **Create pull request**
6. بعد از review → **Merge pull request**

---

## 📦 ساخت Release

### وقتی نسخه جدیدی آماده شد:

1. برو به GitHub repository
2. کلیک روی **Releases** (سایدبار راست)
3. کلیک **Create a new release**

**تنظیمات:**
- **Tag version:** `v1.0.0`
- **Release title:** `v1.0.0 - Initial Release`
- **Description:**
  ```markdown
  ## 🎉 اولین نسخه رسمی HaioCloud K8s
  
  ### ویژگی‌ها:
  - ✅ نصب خودکار کلاستر K3s
  - ✅ MetalLB LoadBalancer
  - ✅ Traefik Ingress Controller
  - ✅ مدیریت کاربران با Webtop
  - ✅ مستندات کامل فارسی
  
  ### فایل‌های ضروری:
  - 📄 README.md
  - 📄 INSTALLATION.md
  - 📄 QUICK-START.md
  
  ### نصب:
  ```bash
  git clone https://github.com/Mehrdad-Hooshmand/haiocloud-k8s.git
  cd haiocloud-k8s
  # ادامه نصب در INSTALLATION.md
  ```
  ```

4. کلیک **Publish release**

---

## 🔒 نکات امنیتی

### ✅ چیزهایی که نباید در Git باشند:

- ❌ Passwords
- ❌ SSH Private Keys
- ❌ Kubernetes Tokens
- ❌ API Keys
- ❌ IP های واقعی (در مستندات عمومی)

### ✅ فایل `.gitignore` شما:

خوشبختانه `.gitignore` ساخته شده این موارد را فیلتر می‌کند:
```
*.key
*.token
kubeconfig
k3s.yaml
passwords.txt
.env
```

### ⚠️ قبل از Push:

```powershell
# بررسی فایل‌های staged
git status

# بررسی محتوای فایل‌ها
git diff --cached

# اگر فایل حساسی دیدید:
git reset FILENAME
```

---

## 📊 آمار Repository

### بعد از آپلود موفق، می‌توانید ببینید:

**در صفحه اصلی:**
- ⭐ Stars
- 👁️ Watchers
- 🔀 Forks
- 📈 Contributors
- 📊 Commit history

**Insights:**
- Traffic: بازدیدکنندگان
- Commits: تاریخچه
- Code frequency: فعالیت

---

## 🎯 Checklist نهایی

قبل از آپلود، بررسی کنید:

- [ ] ✅ README.md کامل است
- [ ] ✅ LICENSE فایل وجود دارد
- [ ] ✅ .gitignore تنظیم شده
- [ ] ✅ هیچ اطلاعات حساسی در فایل‌ها نیست
- [ ] ✅ IP های واقعی سرورها در مستندات عمومی نیستند
- [ ] ✅ تمام اسکریپت‌ها تست شده‌اند
- [ ] ✅ مستندات به‌روز است
- [ ] ✅ لینک‌ها کار می‌کنند

---

## 🆘 مشکلات رایج

### Push رد می‌شود:

**خطا:**
```
! [rejected] main -> main (fetch first)
```

**راه‌حل:**
```powershell
git pull origin main --rebase
git push
```

---

### Username/Password اشتباه:

**راه‌حل:** Personal Access Token استفاده کنید (توضیح بالا)

---

### فایل بزرگ:

**خطا:**
```
remote: error: File large-file.bin is 150 MB; this exceeds GitHub's file size limit of 100 MB
```

**راه‌حل:**
```powershell
# حذف فایل از Git
git rm --cached large-file.bin

# اضافه به .gitignore
echo "large-file.bin" >> .gitignore

# Commit
git add .gitignore
git commit -m "Remove large file"
git push
```

---

## 📞 پشتیبانی

### راهنماهای GitHub:

- [Git Basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)
- [GitHub Docs](https://docs.github.com)
- [GitHub Learning Lab](https://lab.github.com/)

### ویدیوها (فارسی):

جستجو در YouTube:
- "آموزش Git فارسی"
- "آموزش GitHub فارسی"

---

## 🎉 تبریک!

پروژه شما الان روی GitHub است! 🚀

**لینک Repository:**
```
https://github.com/Mehrdad-Hooshmand/haiocloud-k8s
```

**Share کنید:**
```markdown
[![GitHub](https://img.shields.io/badge/GitHub-HaioCloud-blue?logo=github)](https://github.com/Mehrdad-Hooshmand/haiocloud-k8s)
```

---

**نسخه:** 1.0.0  
**تاریخ:** 2025-10-29  
**موفق باشید!** 💖
