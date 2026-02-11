# Linux Resource Monitor 🖥️

Sistem kaynaklarını (CPU, Memory, Disk) izleyen ve belirlenen eşik değerlerini aştığında email ile uyarı gönderen Bash scripti.

## 🎯 Özellikler

- **Otomatik İzleme**: Her 30 dakikada bir kaynak kullanımını kontrol eder
- **Email Uyarıları**: Eşik değerleri aşıldığında anında bildirim
- **Detaylı Loglama**: Tüm kontrolleri `ResourceMonitor.log` dosyasına kaydeder
- **Güvenli Config**: SMTP bilgileri ayrı config dosyasında saklanır
- **Kolay Kurulum**: Tek komutla cron job kurulumu

## 📋 Gereksinimler

- Linux/Unix işletim sistemi
- Bash 4.0 veya üzeri
- Root erişimi (cron job kurulumu için)
- curl 8.14.1

## 🚀 Kurulum

1. **Repoyu klonlayın:**
```bash
git clone https://github.com/kullaniciadi/resource-monitor.git
cd resource-monitor
```

2. **Config dosyasını oluşturun:**
```bash
cp config.conf.example config.conf
```

3. **Config dosyasını düzenleyin:**
```bash
nano config.conf
```

Kendi SMTP bilgilerinizi girin:
```bash
SMTP_SERVER="mail.sunucunuz.com"
SMTP_PORT="587"
SMTP_USER="kullanici@domain.com"
SMTP_PASS="şifreniz"
ALERT_EMAIL="uyari@domain.com"
```

4. **Scripti çalıştırılabilir yapın:**
```bash
chmod +x monitor.sh
```

5. **Email ayarlarını test edin:**
```bash
./monitor.sh --test-email
```

6. **Cron job kurun (otomatik çalışma için):**
```bash
sudo ./monitor.sh --setup-cron
```

## 📖 Kullanım

### Manuel Kontrol
```bash
./monitor.sh --check
```

### Cron Job Yönetimi
```bash
# Cron job kur
sudo ./monitor.sh --setup-cron

# Cron job kaldır
sudo ./monitor.sh --remove-cron
```

### Test Email Gönder
```bash
./monitor.sh --test-email
```

### Yardım
```bash
./monitor.sh --help
```

## ⚙️ Eşik Değerleri

Varsayılan eşik değerleri:
- **CPU Kullanımı**: %90
- **Memory Kullanımı**: %90
- **Disk Kullanımı**: %90

Bu değerleri `monitor.sh` dosyasının başındaki değişkenleri düzenleyerek değiştirebilirsiniz:

```bash
MEMORY_THRESHOLD=90
DISK_THRESHOLD=90
CPU_THRESHOLD=90
```

## 📊 Log Formatı

Log dosyası (`ResourceMonitor.log`) her kontrolde şu formatta kayıt tutar:

```
[2025-02-10 14:30:00] CPU: 45% | Memory: 62% | Disk: 78%
[2025-02-10 15:00:00] CPU: 92% | Memory: 88% | Disk: 81%
[2025-02-10 15:00:01] Email gönderildi: 🚨 Kaynak Kullanım Uyarısı - hostname
```

## 🔧 Troubleshooting

### Email gelmiyor
1. Config dosyasındaki SMTP bilgilerini kontrol edin
2. SMTP port numarasını doğrulayın (587 TLS, 465 SSL)
3. Firewall kurallarını kontrol edin
4. Test emaili gönderin: `./monitor.sh --test-email`
5. Curl kurulu mu kontrol et. `curl --version.`

### Permission hatası
```bash
# Script dosyasına çalıştırma izni ver
chmod +x monitor.sh

# Cron job için root yetkisi kullan
sudo ./monitor.sh --setup-cron
```

## 🎓 Öğrenme Notları

Bu proje aşağıdaki konuları öğrenmek için hazırlanmıştır:

### Bash Scripting Kavramları
- Fonksiyon tanımlama ve kullanımı
- Config dosyası yönetimi (`source` komutu)
- Komut satırı argümanları (`case` statement)
- Hata kontrolü ve exit kodları

### Linux Sistem Komutları
- **CPU**: `top` komutu ile CPU idle değerini okuma
- **Memory**: `free` komutu ile bellek kullanımı hesaplama
- **Disk**: `df` komutu ile disk doluluk oranı
- **Cron**: `/etc/cron.d/` dizininde job tanımlama

### Email İşlemleri
- `sendmail` kullanarak SMTP üzerinden email gönderme
- Email header formatı (From, To, Subject)
- SMTP authentication

### Güvenlik
- Hassas bilgileri (şifre) ayrı dosyada saklama
- `.gitignore` ile config dosyasını versiyon kontrolünden çıkarma
- File permissions yönetimi

## 📁 Dosya Yapısı

```
resource-monitor/
├── monitor.sh              # Ana script
├── config.conf.example     # Örnek config (GitHub'da)
├── config.conf             # Gerçek config (gitignore'da)
├── .gitignore              # Güvenlik için
├── README.md               # Dokümantasyon
├── ResourceMonitor.log  # Log dosyası (oluşturulacak)
└── cron.log               # Cron çalışma logları (oluşturulacak)
```

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/yeniOzellik`)
3. Commit edin (`git commit -m 'Yeni özellik eklendi'`)
4. Push edin (`git push origin feature/yeniOzellik`)
5. Pull Request açın

## 📝 Lisans

Bu proje eğitim amaçlı geliştirilmiştir ve açık kaynak olarak paylaşılmıştır.

## 📧 İletişim

Sorularınız için GitHub Issues kullanabilirsiniz.

---

**Not**: `config.conf` dosyanızı asla GitHub'a pushlamamaya dikkat edin. `.gitignore` dosyası bunu engeller ama yine de kontrol etmekte fayda var.
