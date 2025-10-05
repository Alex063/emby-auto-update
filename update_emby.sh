#!/bin/bash

# ======================================================
# Автообновление Emby Server с GitHub (через curl)
# Автор: Alex063
# ======================================================

# === Настройки ===
REPO_API="https://api.github.com/repos/MediaBrowser/Emby.Releases/releases/latest"
TMP_DIR="/tmp/emby_update"
VERSION_FILE="/var/lib/emby/.emby_version.txt"
TELEGRAM_TOKEN="ТОКЕН_БОТА"        # <-- вставь свой
TELEGRAM_CHAT_ID="ID_ЧАТА"         # <-- вставь свой
LOG_FILE="/var/log/emby_update.log"

# === Подготовка окружения ===
mkdir -p "$TMP_DIR"
touch "$LOG_FILE"
exec >> "$LOG_FILE" 2>&1

echo "=============================="
echo "Проверка обновлений Emby: $(date)"
echo "=============================="

# Проверяем, что запущено от root
if [ "$EUID" -ne 0 ]; then
    echo "Скрипт должен выполняться с правами root!"
    exit 1
fi

# Проверяем необходимые утилиты
for cmd in curl jq dpkg systemctl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Ошибка: не найдено $cmd. Установите перед запуском."
        exit 1
    fi
done

# === Получаем последнюю версию с GitHub ===
LATEST_VERSION=$(curl -s "$REPO_API" | jq -r '.tag_name')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    echo "Не удалось получить последнюю версию с GitHub."
    exit 1
fi

echo "Последняя версия на GitHub: $LATEST_VERSION"

# === Определяем установленную версию Emby ===
LOCAL_VERSION=$(dpkg -s emby-server 2>/dev/null | grep '^Version:' | awk '{print $2}')

if [ -z "$LOCAL_VERSION" ]; then
    echo "Emby не установлен. Считаю версию none."
    LOCAL_VERSION="none"
fi

echo "Текущая установленная версия: $LOCAL_VERSION"

# === Сравниваем версии ===
if [ "$LOCAL_VERSION" == "$LATEST_VERSION" ]; then
    echo "Обновлений нет."
    exit 0
fi

echo "Обнаружено обновление: $LOCAL_VERSION → $LATEST_VERSION"

# === Ищем ссылку на .deb пакет ===
ASSET_URL=$(curl -s "$REPO_API" | jq -r '.assets[] | select(.name | endswith("amd64.deb")) | .browser_download_url' | head -n 1)

if [ -z "$ASSET_URL" ]; then
    echo "Не удалось найти .deb файл на GitHub."
    exit 1
fi

echo "Ссылка на скачивание: $ASSET_URL"

# === Скачиваем .deb ===
DEB_FILE="$TMP_DIR/emby-server_${LATEST_VERSION}_amd64.deb"

echo "Скачиваю $DEB_FILE..."
curl -L -o "$DEB_FILE" "$ASSET_URL"

if [ $? -ne 0 ] || [ ! -f "$DEB_FILE" ]; then
    echo "Ошибка загрузки файла!"
    exit 1
fi

# === Устанавливаем обновление ===
echo "Устанавливаю Emby $LATEST_VERSION..."
dpkg -i "$DEB_FILE"

if [ $? -ne 0 ]; then
    echo "Ошибка установки!"
    MESSAGE="❌ Ошибка при установке Emby версии $LATEST_VERSION на сервере $(hostname)"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
         -d "chat_id=${TELEGRAM_CHAT_ID}" \
         -d "text=${MESSAGE}" >/dev/null
    exit 1
fi

# === Проверяем статус службы Emby ===
echo "Проверка статуса Emby..."
systemctl daemon-reload
systemctl restart emby-server
sleep 5

STATUS=$(systemctl is-active emby-server)
if [ "$STATUS" == "active" ]; then
    echo "Emby запущен успешно."
    MESSAGE="✅ Emby обновлён до версии *${LATEST_VERSION}* на сервере *$(hostname)* и успешно запущен ✅"
else
    echo "Emby не запущен!"
    MESSAGE="⚠️ Emby обновлён до версии *${LATEST_VERSION}*, но служба не запущена! Проверьте вручную."
fi

# === Удаляем .deb файл ===
rm -f "$DEB_FILE"
echo "Удалён временный файл: $DEB_FILE"

# === Сохраняем новую версию ===
echo "$LATEST_VERSION" > "$VERSION_FILE"

# === Отправляем уведомление в Telegram ===
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
     -d "chat_id=${TELEGRAM_CHAT_ID}" \
     -d "parse_mode=Markdown" \
     -d "text=${MESSAGE}" >/dev/null

echo "Завершено успешно: $(date)"
