#!/bin/bash

# Логирование
LOG_FILE="/var/log/fail2ban_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Проверка root-прав
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт с правами root (sudo)."
  exit 1
fi

# Обновление системы
echo "Обновляем систему..."
apt-get update || { echo "Ошибка при обновлении пакетов"; exit 1; }

# Установка Fail2Ban
echo "Устанавливаем Fail2Ban..."
apt-get install -y fail2ban || { echo "Ошибка при установке Fail2Ban"; exit 1; }

# Создаем резервную копию конфигурации
echo "Создаем резервную копию конфигурации..."
BACKUP_FILE="/etc/fail2ban/jail.local.bak_$(date +%Y%m%d_%H%M%S)"
if [ -f "/etc/fail2ban/jail.local" ]; then
  cp /etc/fail2ban/jail.local "$BACKUP_FILE"
  echo "Резервная копия сохранена в $BACKUP_FILE"
else
  cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local || { echo "Ошибка при копировании конфигурации"; exit 1; }
fi

# Настройка Fail2Ban (только если секции [sshd] нет)
echo "Настраиваем Fail2Ban..."
if ! grep -q "^\[sshd\]" /etc/fail2ban/jail.local; then
  cat >> /etc/fail2ban/jail.local <<EOL

[sshd]
enabled = true
maxretry = 3
bantime = 12h
findtime = 10m
ignoreip = 217.25.228.230
EOL
else
  echo "Секция [sshd] уже существует. Проверьте её параметры вручную."
fi

# Проверка синтаксиса перед перезапуском
echo "Проверяем синтаксис конфигурации..."
if ! fail2ban-client -t; then
  echo "Ошибка в конфигурации Fail2Ban. Откатываем изменения..."
  mv "$BACKUP_FILE" /etc/fail2ban/jail.local
  exit 1
fi

# Перезапуск Fail2Ban
echo "Перезапускаем Fail2Ban..."
systemctl restart fail2ban || { echo "Ошибка при перезапуске Fail2Ban"; exit 1; }

# Проверка статуса
echo "Проверяем статус Fail2Ban..."
systemctl status fail2ban --no-pager

# Итог
echo "Fail2Ban успешно настроен. Логи: $LOG_FILE"