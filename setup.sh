#!/bin/bash

# Hızlı Kurulum Scripti
# Resource Monitor projesini kolayca kurmak için

echo "==================================="
echo "Resource Monitor - Hızlı Kurulum"
echo "==================================="

# 1. Config dosyası kontrol
if [ ! -f "config.conf" ]; then
    echo "✓ Config dosyası oluşturuluyor..."
    cp config.conf.example config.conf
    echo ""
    echo "⚠️  ÖNEMLI: config.conf dosyasını düzenlemeniz gerekiyor!"
    echo "   nano config.conf"
    echo ""
else
    echo "✓ Config dosyası mevcut"
fi

# 2. Script iznini kontrol
if [ ! -x "monitor.sh" ]; then
    echo "✓ Script çalıştırılabilir yapılıyor..."
    chmod +x monitor.sh
else
    echo "✓ Script zaten çalıştırılabilir"
fi

echo ""
echo "Sonraki Adımlar:"
echo "1. Config dosyasını düzenleyin:     nano config.conf"
echo "2. Email testi yapın:               ./monitor.sh --test-email"
echo "3. Manuel kontrol yapın:            ./monitor.sh --check"
echo "4. Cron job kurun:                  sudo ./monitor.sh --setup-cron"
echo ""
echo "Detaylı bilgi için: cat README.md"
