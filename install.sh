#!/bin/bash

# Логирование
LOG_FILE="/var/log/fail2ban_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Проверка, запущен ли скрипт от root
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт с правами root (sudo)."
  exit 1
fi

# Обновляем систему
echo "Обновляем систему..."
sudo apt-get update || { echo "Ошибка при обновлении пакетов"; exit 1; }

# Устанавливаем Fail2Ban
echo "Устанавливаем Fail2Ban..."
sudo apt-get install -y fail2ban || { echo "Ошибка при установке Fail2Ban"; exit 1; }

# Создаем локальную копию конфигурации
echo "Создаем локальную копию конфигурации..."
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local || { echo "Ошибка при копировании конфигурации"; exit 1; }

# Настраиваем базовые параметры Fail2Ban
echo "Настраиваем Fail2Ban..."

# Конфигурация для SSH
sudo tee -a /etc/fail2ban/jail.local > /dev/null <<EOL

[sshd]
enabled = true
maxretry = 3
bantime = 12h
findtime = 10m
ignoreip = 217.25.228.230
EOL

# Конфигурация для защиты других служб (например, Apache, Nginx)
# Раскомментируйте, если нужно:
# sudo tee -a /etc/fail2ban/jail.local > /dev/null <<EOL
# [apache]
# enabled = true
# maxretry = 5
# bantime = 24h
# findtime = 10m

# [nginx-http-auth]
# enabled = true
# maxretry = 3
# bantime = 1h
# findtime = 10m
# EOL

# Перезапускаем Fail2Ban для применения настроек
echo "Перезапускаем Fail2Ban..."
sudo systemctl restart fail2ban || { echo "Ошибка при перезапуске Fail2Ban"; exit 1; }

# Проверяем статус Fail2Ban
echo "Проверяем статус Fail2Ban..."
sudo systemctl status fail2ban --no-pager

# Выводим информацию о настройках
echo "Fail2Ban успешно установлен и настроен."
echo "Текущие блокировки:"
sudo fail2ban-client status

# Все готово
echo "Настройка Fail2Ban завершена. Логи доступны в $LOG_FILE."