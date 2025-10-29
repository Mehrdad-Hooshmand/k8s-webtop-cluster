# 🖥️ راهنمای نصب دسکتاپ Ubuntu - سرور اختصاصی

این اسکریپت به شما اجازه میدهد یک دسکتاپ Ubuntu کامل را **روی سرور خودتان** نصب کنید.

## 📋 پیش‌نیازها

- سرور Ubuntu 20.04 یا 22.04
- دسترسی Root (sudo)
- حداقل 2GB RAM
- حداقل 10GB فضای خالی
- اتصال اینترنت

## 🚀 نصب سریع

### روش 1: دانلود و اجرا

```bash
# دانلود اسکریپت
wget https://raw.githubusercontent.com/YOUR_REPO/client-install-webtop.sh

# اجرای اسکریپت
sudo bash client-install-webtop.sh
```

### روش 2: کپی مستقیم

1. فایل `client-install-webtop.sh` را به سرور خود کپی کنید
2. اجرا کنید:
```bash
sudo bash client-install-webtop.sh
```

## 📝 مراحل نصب

اسکریپت از شما سوالاتی میپرسد:

### 1️⃣ انتخاب موقعیت
```
1) Iran (uses ArvanCloud Docker mirror)     ← برای سرورهای ایران
2) International (direct Docker Hub)        ← برای سرورهای خارج
```

### 2️⃣ انتخاب نام کاربری
```
Enter your desired username: ali
```
- فقط حروف کوچک انگلیسی و اعداد
- مثال: `ali`, `user1`, `test123`

### 3️⃣ انتخاب روش دسترسی

**گزینه 1: آدرس IP (ساده‌تر)**
```
Access: http://YOUR_SERVER_IP
```
- نیازی به تنظیمات DNS ندارد
- فوری آماده است
- HTTP (بدون SSL)

**گزینه 2: دامنه (حرفه‌ای‌تر)**
```
Access: https://desktop.example.com
```
- نیاز به تنظیم DNS دارد
- SSL رایگان Let's Encrypt
- HTTPS امن

## 🔧 تنظیم DNS (فقط برای گزینه دامنه)

قبل از نصب، یک رکورد A اضافه کنید:

```
Type: A
Name: desktop (یا هر نام دلخواه)
Value: IP_ADDRESS_OF_YOUR_SERVER
TTL: 300
```

مثال در Cloudflare:
```
A    desktop    185.123.45.67    Auto    DNS only (خاموش)
```

## ✅ پس از نصب

### اطلاعات دسترسی

اسکریپت اطلاعات زیر را نمایش میدهد:

```
Access URL: http://YOUR_IP یا https://YOUR_DOMAIN
Username: admin
Password: [رمز تصادفی امن]
```

### فایل‌های مهم

```
/root/webtop/info.txt          ← اطلاعات کامل نصب
/root/webtop/password.txt      ← رمز عبور
/root/webtop/docker-compose.yml ← تنظیمات Docker
/root/webtop/data/             ← فایل‌های شما
```

## 🛠️ دستورات مدیریتی

### وضعیت سرویس
```bash
docker ps
```

### مشاهده لاگ‌ها
```bash
docker logs webtop-USERNAME
```

### ری‌استارت
```bash
cd /root/webtop
docker compose restart
```

### توقف موقت
```bash
cd /root/webtop
docker compose stop
```

### شروع مجدد
```bash
cd /root/webtop
docker compose start
```

### حذف کامل
```bash
cd /root/webtop
docker compose down -v
```

## 🔐 امنیت

### تغییر رمز عبور

1. ویرایش فایل docker-compose.yml:
```bash
nano /root/webtop/docker-compose.yml
```

2. خط `PASSWORD` را تغییر دهید:
```yaml
- PASSWORD=YOUR_NEW_PASSWORD
```

3. ری‌استارت:
```bash
cd /root/webtop
docker compose restart
```

### تمدید SSL (فقط برای دامنه)

SSL به صورت خودکار تمدید میشود. برای تست:
```bash
certbot renew --dry-run
```

## 🌍 دسترسی از خارج

### باز کردن فایروال

**UFW:**
```bash
ufw allow 80/tcp
ufw allow 443/tcp
```

**iptables:**
```bash
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

## 🐛 عیب‌یابی

### کانتینر اجرا نمیشود
```bash
docker logs webtop-USERNAME
docker compose -f /root/webtop/docker-compose.yml up
```

### Nginx خطا میدهد
```bash
nginx -t
tail -f /var/log/nginx/error.log
```

### صفحه باز نمیشود
```bash
# چک کردن پورت 3000
netstat -tlnp | grep 3000

# چک کردن وضعیت کانتینر
docker ps -a
```

### دانلود تصویر Docker کند است

برای ایران از mirror ArvanCloud استفاده کنید:
```bash
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOF
systemctl restart docker
```

## 💡 نکات مهم

1. ✅ **رمز عبور را ذخیره کنید** - در `/root/webtop/password.txt`
2. ✅ **Backup منظم** - پوشه `/root/webtop/data/`
3. ✅ **مانیتور منابع** - با `docker stats`
4. ⚠️ **DNS باید قبل از نصب آماده باشد** - برای گزینه دامنه
5. 🔒 **HTTPS فقط با دامنه** - IP فقط HTTP

## 🆘 پشتیبانی

مشکل دارید؟ این موارد را چک کنید:

```bash
# وضعیت کلی
docker ps
systemctl status nginx
docker logs webtop-USERNAME

# مصرف منابع
docker stats
free -h
df -h
```

## 📊 مشخصات سیستم

| مورد | حداقل | توصیه شده |
|------|-------|-----------|
| CPU | 1 Core | 2+ Cores |
| RAM | 2GB | 4GB+ |
| Storage | 10GB | 20GB+ |
| Network | 10Mbps | 100Mbps+ |

## 🎯 ویژگی‌های دسکتاپ

- 🖥️ محیط KDE Plasma
- 🐧 Alpine Linux (سبک و سریع)
- 🌐 دسترسی از مرورگر
- 📁 فضای ذخیره‌سازی اختصاصی
- 🔊 پشتیبانی از صدا
- 📋 Clipboard مشترک
- 🖱️ کنترل کامل ماوس و کیبورد

## 📞 تماس با پشتیبانی

مشکل فنی دارید؟
- Telegram: @YOUR_SUPPORT
- Email: support@haiocloud.com

---

**ساخته شده با ❤️ برای HaioCloud Platform**
