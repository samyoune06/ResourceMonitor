#!/bin/bash

#############################################
# Resource Monitor Script
# Monitors CPU, Memory, and Disk usage
# Sends email alerts when thresholds exceeded
#############################################

# Script dizinini al
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
LOG_FILE="$SCRIPT_DIR/ResourceMonitor.log"
CRON_FILE="/etc/cron.d/resource-monitor"

# Eşik değerleri
MEMORY_THRESHOLD=90
DISK_THRESHOLD=90
CPU_THRESHOLD=90

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#############################################
# Config dosyasını yükle
#############################################
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}HATA: Config dosyası bulunamadı: $CONFIG_FILE${NC}"
        echo "Lütfen config.conf.example dosyasını config.conf olarak kopyalayın ve düzenleyin."
        exit 1
    fi
    
    source "$CONFIG_FILE"
    
    # Gerekli değişkenleri kontrol et
    if [ -z "$SMTP_SERVER" ] || [ -z "$SMTP_PORT" ] || [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ] || [ -z "$ALERT_EMAIL" ]; then
        echo -e "${RED}HATA: Config dosyasında eksik değişkenler var!${NC}"
        exit 1
    fi
}

#############################################
# Log fonksiyonu
#############################################
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

#############################################
# CPU kullanımını ölç (1 dakikalık ortalama)
#############################################
get_cpu_usage() {
    local cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/')
    local cpu_usage=$(echo "100 - $cpu_idle" | bc | cut -d'.' -f1)
    # Boş değer kontrolü
    [ -z "$cpu_usage" ] && cpu_usage=0
    echo "$cpu_usage"
}

#############################################
# Memory kullanımını ölç
#############################################
get_memory_usage() {
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')
    echo "$mem_usage"
}

#############################################
# Disk kullanımını ölç (root partition)
#############################################
get_disk_usage() {
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "$disk_usage"
}

#############################################
# Email gönder
#############################################
send_email() {
    local subject="$1"
    local body="$2"
    
    # Port'a göre protokol seç
    local curl_opts=""
    if [ "$SMTP_PORT" -eq 465 ]; then
        curl_opts="--ssl-reqd --url smtps://$SMTP_SERVER:$SMTP_PORT"
    else
        curl_opts="--ssl --url smtp://$SMTP_SERVER:$SMTP_PORT"
    fi
    
    curl --silent $curl_opts \
        --user "$SMTP_USER:$SMTP_PASS" \
        --mail-from "$SMTP_USER" \
        --mail-rcpt "$ALERT_EMAIL" \
        --upload-file - <<EOF
From: $SMTP_USER
To: $ALERT_EMAIL
Subject: $subject
Content-Type: text/plain; charset=UTF-8

$body

---
Bu otomatik bir uyarı mesajıdır.
Sunucu: $(hostname)
Tarih: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    if [ $? -eq 0 ]; then
        log_message "Email gönderildi: $subject"
    else
        log_message "Email gönderilemedi: $subject"
    fi
}

#############################################
# Kaynak kontrolü yap
#############################################
check_resources() {
    local cpu_usage=$(get_cpu_usage)
    local mem_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    
    # Log'a yaz
    log_message "CPU: ${cpu_usage}% | Memory: ${mem_usage}% | Disk: ${disk_usage}%"
    
    # Uyarı mesajı
    local alert_message=""
    local alert_triggered=0
    
    # CPU kontrolü
    if [ "$cpu_usage" -ge "$CPU_THRESHOLD" ]; then
        alert_message+="⚠️ CPU Kullanımı: ${cpu_usage}% (Eşik: ${CPU_THRESHOLD}%)\n"
        alert_triggered=1
    fi
    
    # Memory kontrolü
    if [ "$mem_usage" -ge "$MEMORY_THRESHOLD" ]; then
        alert_message+="⚠️ Memory Kullanımı: ${mem_usage}% (Eşik: ${MEMORY_THRESHOLD}%)\n"
        alert_triggered=1
    fi
    
    # Disk kontrolü
    if [ "$disk_usage" -ge "$DISK_THRESHOLD" ]; then
        alert_message+="⚠️ Disk Kullanımı: ${disk_usage}% (Eşik: ${DISK_THRESHOLD}%)\n"
        alert_triggered=1
    fi
    
    # Eğer herhangi bir eşik aşıldıysa email gönder
    if [ $alert_triggered -eq 1 ]; then
        echo -e "${RED}UYARI: Kaynak eşik değerleri aşıldı!${NC}"
        local email_body="Kaynak kullanımı kritik seviyelere ulaştı:\n\n${alert_message}\nLütfen sistemi kontrol edin."
        send_email "🚨 Kaynak Kullanım Uyarısı - $(hostname)" "$email_body"
    else
        echo -e "${GREEN}✓ Tüm kaynaklar normal seviyelerde${NC}"
    fi
}

#############################################
# Cron job kur
#############################################
setup_cron() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Cron job kurmak için root yetkisi gerekiyor.${NC}"
        echo "Şu komutu çalıştırın: sudo $0 --setup-cron"
        return 1
    fi
    
    if [ -f "$CRON_FILE" ]; then
        echo -e "${YELLOW}Cron job zaten kurulu.${NC}"
        read -p "Yeniden kurmak ister misiniz? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Cron job dosyasını oluştur
    cat > "$CRON_FILE" << EOF
# Resource Monitor - Her 30 dakikada bir çalışır
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

*/30 * * * * root $SCRIPT_DIR/monitor.sh --check >> $SCRIPT_DIR/cron.log 2>&1
EOF
    
    chmod 644 "$CRON_FILE"
    
    echo -e "${GREEN}✓ Cron job başarıyla kuruldu: $CRON_FILE${NC}"
    echo "Script her 30 dakikada bir otomatik olarak çalışacak."
    
    return 0
}

#############################################
# Cron job'u kaldır
#############################################
remove_cron() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Cron job kaldırmak için root yetkisi gerekiyor.${NC}"
        echo "Şu komutu çalıştırın: sudo $0 --remove-cron"
        return 1
    fi
    
    if [ -f "$CRON_FILE" ]; then
        rm -f "$CRON_FILE"
        echo -e "${GREEN}✓ Cron job kaldırıldı.${NC}"
    else
        echo -e "${YELLOW}Cron job bulunamadı.${NC}"
    fi
}

#############################################
# Yardım mesajı
#############################################
show_help() {
    cat << EOF
Kaynak Monitör Script

Kullanım:
    $0 [OPTION]

Seçenekler:
    --check         Kaynak kontrolü yap (manuel)
    --setup-cron    Cron job kur (sudo gerektirir)
    --remove-cron   Cron job kaldır (sudo gerektirir)
    --test-email    Test emaili gönder
    --help          Bu yardım mesajını göster

Örnekler:
    $0 --check                  # Manuel kontrol
    sudo $0 --setup-cron        # Otomatik çalışmayı aktifleştir
    $0 --test-email             # Email ayarlarını test et

EOF
}

#############################################
# Test email gönder
#############################################
test_email() {
    load_config
    echo "Test emaili gönderiliyor..."
    send_email "Test - Kaynak Monitör" "Bu bir test mesajıdır. Email ayarlarınız düzgün çalışıyor."
}

#############################################
# Ana program
#############################################
main() {
    # Log dosyası yoksa oluştur
    touch "$LOG_FILE"
    
    case "$1" in
        --check)
            load_config
            check_resources
            ;;
        --setup-cron)
            setup_cron
            ;;
        --remove-cron)
            remove_cron
            ;;
        --test-email)
            test_email
            ;;
        --help)
            show_help
            ;;
        *)
            show_help
            ;;
    esac
}

main "$@"
