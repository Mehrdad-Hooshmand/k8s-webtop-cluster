# 🖥️ Webtop Desktop Installer - Standalone Edition

نصب آسان دسکتاپ Ubuntu روی هر سرور با یک خط دستور!

## 🚀 نصب سریع

```bash
curl -fsSL https://raw.githubusercontent.com/Mehrdad-Hooshmand/webtop-installer/main/install-webtop-standalone.sh | sudo bash
```

یا اگر فایل را دانلود کرده‌اید:

```bash
sudo bash install-webtop-standalone.sh
```

## ✨ ویژگی‌ها

- ✅ نصب خودکار با یک دستور
- ✅ محیط دسکتاپ **KDE Plasma** (مدرن و سریع)
- ✅ پشتیبانی از **ArvanCloud** برای ایران
- ✅ **Let's Encrypt SSL** رایگان
- ✅ دسترسی از **مرورگر** (بدون نیاز به نرم‌افزار اضافی)
- ✅ رمز عبور **تصادفی امن**
- ✅ مدیریت آسان با اسکریپت‌های کمکی

## 📋 پیش‌نیازها

| مورد | حداقل | توصیه شده |
|------|-------|-----------|
| سیستم‌عامل | Ubuntu 20.04 | Ubuntu 22.04 |
| CPU | 1 Core | 2+ Cores |
| RAM | 2GB | 4GB |
| Storage | 10GB | 20GB |
| دسترسی | Root (sudo) | - |

## 🎯 انتخاب‌های نصب

### 1️⃣ موقعیت سرور

**گزینه 1: ایران**
- از ArvanCloud mirror استفاده می‌کند
- سرعت دانلود بالا در ایران
- دور زدن تحریم‌ها

**گزینه 2: بین‌المللی**
- اتصال مستقیم به Docker Hub
- برای سرورهای خارج

### 2️⃣ روش دسترسی

**گزینه 1: آدرس IP** (ساده‌تر)
```
✓ نصب سریع‌تر
✓ بدون نیاز به DNS
✓ HTTP (port 80)
⚠️ بدون رمزنگاری SSL
```
مناسب برای: تست، شبکه خصوصی، استفاده شخصی

**گزینه 2: دامنه** (حرفه‌ای‌تر)
```
✓ SSL رایگان Let's Encrypt
✓ HTTPS امن
✓ نام دامنه اختصاصی
⚠️ نیاز به تنظیم DNS
```
مناسب برای: استفاده عمومی، تیمی، تجاری

## 🔧 تنظیم DNS (فقط برای گزینه دامنه)

قبل از نصب، DNS را تنظیم کنید:

### Cloudflare
```
Type: A
Name: desktop (یا هر نام دیگر)
Content: IP_SERVER_SHOMA
Proxy: خاموش (DNS only)
TTL: Auto
```

### سایر سرویس‌ها
```
A    desktop.example.com    185.123.45.67
```

**چک کردن DNS:**
```bash
nslookup desktop.example.com
# یا
dig desktop.example.com
```

## 📝 مثال نصب

```bash
# دانلود اسکریپت
wget https://raw.githubusercontent.com/Mehrdad-Hooshmand/webtop-installer/main/install-webtop-standalone.sh

# اجرا
sudo bash install-webtop-standalone.sh

# سوالات:
# Select your server location: 1 (برای ایران)
# Select access method: 2 (برای دامنه)
# Enter your domain name: desktop.example.com
# Is DNS already configured: yes
```

## 🎉 پس از نصب

### اطلاعات دسترسی

```
URL:      http://YOUR_IP یا https://YOUR_DOMAIN
Username: admin
Password: [رمز تصادفی امن که نمایش داده می‌شود]
```

### فایل‌های مهم

```
/root/webtop/info.txt          # اطلاعات کامل
/root/webtop/password.txt      # رمز عبور
/root/webtop/data/             # فایل‌های شما
/root/webtop/docker-compose.yml # تنظیمات
```

### اسکریپت‌های مدیریتی

```bash
# مشاهده وضعیت
bash /root/webtop/status.sh

# ری‌استارت
bash /root/webtop/restart.sh

# توقف
bash /root/webtop/stop.sh

# شروع مجدد
bash /root/webtop/start.sh

# مشاهده اطلاعات
cat /root/webtop/info.txt
```

## 🛠️ مدیریت پیشرفته

### Docker Commands

```bash
# مشاهده لاگ‌ها
docker logs webtop-desktop

# دنبال کردن لاگ‌ها
docker logs -f webtop-desktop

# دسترسی Shell
docker exec -it webtop-desktop bash

# ری‌استارت
cd /root/webtop && docker compose restart

# حذف کامل
cd /root/webtop && docker compose down -v
```

### Nginx Commands

```bash
# تست تنظیمات
nginx -t

# ری‌استارت
systemctl restart nginx

# مشاهده خطاها
tail -f /var/log/nginx/error.log
```

### SSL Management (فقط دامنه)

```bash
# تمدید دستی
certbot renew

# تست تمدید
certbot renew --dry-run

# مشاهده گواهی‌ها
certbot certificates
```

## 🔒 امنیت

### تغییر رمز عبور

```bash
# ویرایش فایل
nano /root/webtop/docker-compose.yml

# خط PASSWORD را تغییر دهید
- PASSWORD=YOUR_NEW_PASSWORD

# ری‌استارت
cd /root/webtop && docker compose restart
```

### باز کردن فایروال

**UFW:**
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp  # فقط برای HTTPS
sudo ufw reload
```

**iptables:**
```bash
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo service iptables save
```

## 🐛 عیب‌یابی

### کانتینر اجرا نمیشود

```bash
# مشاهده لاگ‌ها
docker logs webtop-desktop

# چک منابع
docker stats

# ری‌استارت
cd /root/webtop && docker compose restart
```

### صفحه باز نمیشود

```bash
# چک کانتینر
docker ps | grep webtop

# چک Nginx
systemctl status nginx

# چک پورت
netstat -tlnp | grep 3000
```

### مشکلات SSL

```bash
# بررسی گواهی
certbot certificates

# تمدید
certbot renew --force-renewal

# مشاهده لاگ‌های Certbot
tail -f /var/log/letsencrypt/letsencrypt.log
```

### دانلود کند (ایران)

```bash
# تنظیم ArvanCloud
sudo mkdir -p /etc/docker
sudo cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOF
sudo systemctl restart docker
```

## 📊 مانیتورینگ

### مصرف منابع

```bash
# استفاده فعلی
docker stats webtop-desktop --no-stream

# مانیتور زنده
docker stats webtop-desktop

# فضای دیسک
du -sh /root/webtop/data/
```

### لاگ‌ها

```bash
# 50 خط آخر
docker logs --tail 50 webtop-desktop

# از زمان مشخص
docker logs --since 1h webtop-desktop

# خطاها فقط
docker logs webtop-desktop 2>&1 | grep -i error
```

## 🔄 Backup & Restore

### Backup

```bash
# Backup فایل‌های کاربر
tar -czf webtop-backup-$(date +%Y%m%d).tar.gz /root/webtop/data/

# Backup تنظیمات
cp /root/webtop/docker-compose.yml /root/webtop-compose-backup.yml
cp /root/webtop/password.txt /root/webtop-password-backup.txt
```

### Restore

```bash
# Restore فایل‌ها
tar -xzf webtop-backup-20250129.tar.gz -C /

# ری‌استارت
cd /root/webtop && docker compose restart
```

## ⚙️ تنظیمات پیشرفته

### افزایش منابع

ویرایش `/root/webtop/docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'        # 2 → 4
      memory: 4G       # 2G → 4G
    reservations:
      cpus: '1'
      memory: 1G
```

سپس:
```bash
cd /root/webtop && docker compose up -d
```

### تغییر Timezone

```yaml
environment:
  - TZ=Asia/Tehran  # یا Europe/London, America/New_York
```

### نصب نرم‌افزار اضافی

```bash
# دسترسی به Shell
docker exec -it webtop-desktop bash

# نصب (مثال)
apk add firefox chromium git
```

## 🆘 پشتیبانی

### اطلاعات سیستم

```bash
# نسخه Docker
docker --version

# نسخه سیستم‌عامل
cat /etc/os-release

# منابع سیستم
free -h
df -h
```

### گزارش مشکل

هنگام گزارش مشکل، این اطلاعات را ارسال کنید:

```bash
# وضعیت کانتینر
docker ps -a | grep webtop

# لاگ‌ها
docker logs --tail 100 webtop-desktop

# تنظیمات Nginx
cat /etc/nginx/sites-available/webtop

# اطلاعات نصب
cat /root/webtop/info.txt
```

## 🔗 لینک‌های مفید

- [Webtop Documentation](https://docs.linuxserver.io/images/docker-webtop)
- [Docker Documentation](https://docs.docker.com/)
- [Let's Encrypt](https://letsencrypt.org/)
- [ArvanCloud Docker Mirror](https://www.arvancloud.ir/fa/dev/docker)

## 📜 لایسنس

این پروژه تحت لایسنس MIT منتشر شده است.

## 🤝 مشارکت

برای گزارش باگ یا پیشنهاد، Issue ایجاد کنید.

---

**ساخته شده با ❤️ برای HaioCloud Platform**

**نسخه:** 2.0.0 - Standalone Edition  
**تاریخ:** 2025-10-29
