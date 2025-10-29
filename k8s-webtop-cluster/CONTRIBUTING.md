# 🤝 راهنمای مشارکت در پروژه HaioCloud

از اینکه علاقه‌مند به بهبود این پروژه هستید، متشکریم! 🎉

---

## 📋 فهرست مطالب

- [چگونه مشارکت کنیم](#چگونه-مشارکت-کنیم)
- [گزارش باگ](#گزارش-باگ)
- [پیشنهاد ویژگی جدید](#پیشنهاد-ویژگی-جدید)
- [ارسال Pull Request](#ارسال-pull-request)
- [استانداردهای کدنویسی](#استانداردهای-کدنویسی)
- [تست کردن](#تست-کردن)

---

## چگونه مشارکت کنیم

### 1. Fork کردن Repository

```bash
# کلیک روی دکمه Fork در GitHub
```

### 2. کلون کردن

```bash
git clone https://github.com/YOUR-USERNAME/haiocloud-k8s.git
cd haiocloud-k8s
```

### 3. ساخت Branch جدید

```bash
git checkout -b feature/your-feature-name
# یا برای باگ فیکس:
git checkout -b fix/bug-description
```

### 4. اعمال تغییرات

```bash
# کدنویسی کنید...
git add .
git commit -m "توضیح واضح تغییرات"
```

### 5. Push کردن

```bash
git push origin feature/your-feature-name
```

### 6. ایجاد Pull Request

از صفحه GitHub پروژه خود، روی **New Pull Request** کلیک کنید.

---

## 🐛 گزارش باگ

### قبل از گزارش باگ:

1. ✅ بررسی کنید که در [Issues](https://github.com/Mehrdad-Hooshmand/haiocloud-k8s/issues) قبلاً گزارش نشده باشد
2. ✅ [TROUBLESHOOTING.md](TROUBLESHOOTING.md) را بخوانید
3. ✅ اطمینان حاصل کنید از آخرین نسخه استفاده می‌کنید

### هنگام گزارش باگ:

**عنوان واضح:**
```
❌ بد: برنامه کار نمی‌کند
✅ خوب: Pod در حالت CrashLoopBackOff می‌ماند هنگام استفاده از Alpine-KDE
```

**محتوای گزارش:**

```markdown
## توضیح مشکل
[توضیح کوتاه و واضح]

## مراحل بازتولید
1. اجرای دستور X
2. انتظار برای Y
3. مشاهده خطای Z

## رفتار مورد انتظار
[چه چیزی باید اتفاق بیفتد]

## رفتار واقعی
[چه چیزی اتفاق افتاد]

## محیط
- OS: Ubuntu 22.04
- K3s Version: v1.33.5+k3s1
- MetalLB Version: 0.14.8

## لاگ‌ها
```bash
kubectl logs pod-name -n namespace
```

## تلاش‌های انجام شده
- تست کردن X
- بررسی Y
```

---

## ✨ پیشنهاد ویژگی جدید

### قالب پیشنهاد:

```markdown
## عنوان ویژگی
[نام کوتاه]

## مشکل/نیاز
[چرا این ویژگی لازم است؟]

## راه‌حل پیشنهادی
[چگونه باید پیاده‌سازی شود؟]

## جایگزین‌ها
[آیا راه دیگری هم هست؟]

## اطلاعات اضافی
[تصاویر، لینک‌ها، مثال‌ها]
```

---

## 📤 ارسال Pull Request

### چک‌لیست قبل از ارسال:

- [ ] کد تست شده است
- [ ] مستندات به‌روز شده‌اند
- [ ] Commit message‌ها واضح هستند
- [ ] کد از استانداردها پیروی می‌کند
- [ ] تغییرات backward-compatible هستند

### قالب PR:

```markdown
## تغییرات

- ✅ اضافه شدن X
- ✅ رفع باگ Y
- ✅ بهبود عملکرد Z

## نوع تغییر

- [ ] Bug fix (non-breaking)
- [ ] New feature (non-breaking)
- [ ] Breaking change
- [ ] Documentation update

## تست شده در:

- [ ] Ubuntu 20.04
- [ ] Ubuntu 22.04
- [ ] K3s v1.33.x
- [ ] با MetalLB
- [ ] با Traefik

## مستندات:

- [ ] README.md به‌روز شد
- [ ] INSTALLATION.md به‌روز شد
- [ ] TROUBLESHOOTING.md به‌روز شد
- [ ] کامنت‌های کد اضافه شد

## Screenshots/Logs:

[در صورت نیاز]
```

---

## 📝 استانداردهای کدنویسی

### Bash Scripts:

```bash
#!/bin/bash

# 1. Header با توضیحات
# Purpose: Install K3s master node
# Author: Name
# Date: 2025-10-29

# 2. Exit on error
set -e

# 3. متغیرها با حروف بزرگ
MASTER_IP="94.182.92.207"

# 4. توابع با نام‌های واضح
install_k3s() {
    echo "Installing K3s..."
    # کد
}

# 5. Error handling
command || {
    echo "Error: Command failed"
    exit 1
}

# 6. کامنت‌های فارسی یا انگلیسی
# Check cluster status
kubectl get nodes
```

### YAML Files:

```yaml
# 1. Indentation: 2 spaces
apiVersion: v1
kind: Pod
metadata:
  # 2. نام‌های واضح
  name: webtop-username
  # 3. Labels معنی‌دار
  labels:
    app: webtop
    user: username
spec:
  # 4. ترتیب منطقی
  containers:
    - name: webtop
      image: lscr.io/linuxserver/webtop:alpine-kde
      # 5. Resource limits همیشه
      resources:
        limits:
          memory: "2Gi"
          cpu: "1000m"
```

### Markdown:

```markdown
# 1. عناوین سلسله‌مراتبی
## سطح 2
### سطح 3

# 2. کدها با Syntax Highlighting
```bash
kubectl get pods
```

# 3. لیست‌های منظم
- آیتم 1
- آیتم 2

# 4. جداول خوانا
| ستون 1 | ستون 2 |
|--------|--------|
| داده 1 | داده 2 |

# 5. لینک‌ها
[متن لینک](URL)
```

---

## 🧪 تست کردن

### تست محلی:

```bash
# 1. نصب در محیط تست
./scripts/cluster/01-install-k3s-master.sh

# 2. بررسی خروجی
kubectl get nodes
kubectl get pods -A

# 3. تست عملکرد
bash create-webtop.sh testuser

# 4. بررسی لاگ‌ها
kubectl logs -n webtops webtop-testuser

# 5. دسترسی به URL
curl http://testuser.haiocloud.com
```

### تست خودکار (آینده):

```bash
# Unit tests
./tests/unit/test-create-webtop.sh

# Integration tests
./tests/integration/test-full-deployment.sh
```

---

## 🎨 بهترین روش‌ها

### برای اسکریپت‌ها:

1. ✅ **Idempotent باشند** - اجرای چند بار مشکل ایجاد نکند
2. ✅ **خروجی واضح** - هر مرحله چاپ شود
3. ✅ **Error handling** - خطاها مدیریت شوند
4. ✅ **Validation** - ورودی‌ها بررسی شوند
5. ✅ **Cleanup** - در صورت خطا، cleanup انجام شود

### برای مستندات:

1. ✅ **مثال‌های کاربردی** - کد واقعی نشان دهید
2. ✅ **توضیحات گام‌به‌گام** - مرحله به مرحله
3. ✅ **Troubleshooting** - مشکلات رایج را پوشش دهید
4. ✅ **به‌روز بودن** - با کد همخوانی داشته باشد
5. ✅ **فارسی و انگلیسی** - هر دو زبان پشتیبانی شوند

---

## 🏆 نکات برای Contributor‌های خوب

### برای پذیرفته شدن سریع‌تر:

1. 🎯 **یک موضوع در هر PR** - تغییرات را جدا کنید
2. 📝 **مستندات کامل** - همه چیز را توضیح دهید
3. 🧪 **تست شده** - قبل از ارسال تست کنید
4. 💬 **پاسخگو باشید** - به نظرات پاسخ دهید
5. 🤝 **محترمانه** - رفتار مودبانه داشته باشید

### نمونه‌هایی از مشارکت‌های خوب:

- ✅ رفع باگ در `create-webtop.sh` که username با `-` را قبول نمی‌کرد
- ✅ افزودن پشتیبانی از Ubuntu-MATE به webtop template
- ✅ بهبود عملکرد `list-webtops.sh` با caching
- ✅ ترجمه TROUBLESHOOTING.md به انگلیسی
- ✅ افزودن CI/CD pipeline با GitHub Actions

---

## 📬 ارتباط با تیم

### سوال دارید؟

- 💬 **GitHub Discussions**: برای سوالات عمومی
- 🐛 **GitHub Issues**: برای باگ‌ها و پیشنهادات
- 📧 **Email**: mehrdad@haiocloud.com (برای موارد حساس)

### زمان پاسخ:

- Issues: معمولاً 1-3 روز
- Pull Requests: معمولاً 3-7 روز
- Emails: معمولاً 1 هفته

---

## 🎓 یادگیری بیشتر

### منابع مفید:

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [MetalLB Documentation](https://metallb.universe.tf/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Bash Best Practices](https://google.github.io/styleguide/shellguide.html)

### تمرین‌های پیشنهادی:

1. نصب کلاستر در محیط تست
2. ساخت کاربر و تست عملکرد
3. خواندن کل کد موجود
4. رفع یک باگ ساده
5. نوشتن یک test script

---

## 📜 Code of Conduct

### رفتار مورد انتظار:

- ✅ احترام به همه افراد
- ✅ پذیرش نقد سازنده
- ✅ تمرکز بر بهبود پروژه
- ✅ کمک به newcomers
- ✅ شفاف بودن در ارتباطات

### رفتار غیرقابل قبول:

- ❌ زبان توهین‌آمیز
- ❌ حملات شخصی
- ❌ هرزه‌نگاری یا trolling
- ❌ نقض حریم خصوصی
- ❌ رفتار غیرحرفه‌ای

---

## 🙏 سپاسگزاری

از تمام کسانی که به این پروژه کمک می‌کنند، صمیمانه سپاسگزاریم!

### Contributors:

<!-- این لیست خودکار به‌روز می‌شود -->

- [@Mehrdad-Hooshmand](https://github.com/Mehrdad-Hooshmand) - Creator & Maintainer

---

**نکته:** این یک پروژه آزاد است. مشارکت شما با هر سطح تجربه، ارزشمند است! 💖

---

**تاریخ به‌روزرسانی:** 2025-10-29  
**نسخه:** 1.0.0
