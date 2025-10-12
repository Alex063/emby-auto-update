# 🧩 Emby Auto Update Script for Ubuntu

Автоматический Bash-скрипт для обновления **Emby Server** на **Ubuntu**.
Скрипт проверяет последнюю доступную версию на GitHub, сравнивает её с установленной, при необходимости обновляет Emby, перезапускает службу и отправляет уведомление в **Telegram**.

---

## ⚙️ Основные возможности

- Проверка последней версии Emby с GitHub (`MediaBrowser/Emby.Releases`)
- Сравнение с установленной версией
- Автоматическая загрузка и установка `.deb` пакета
- Перезапуск службы `emby-server`
- Проверка успешного запуска после обновления
- Уведомление в Telegram о результате
- Автоматическое удаление временных файлов
- Поддержка выполнения по расписанию через `cron`

---

## 🧰 Требования

- Ubuntu 22.04+ / 24.04+ / 25.04
- `curl`, `jq`, `dpkg`, `systemctl`, `bash`
- Установленный **Emby Server**
- Токен и chat_id для Telegram-бота

---

## 🚀 Установка

### 1. Клонируем репозиторий

```bash
git clone https://github.com/Alex063/emby-auto-update.git
cd emby-auto-update
```

### 2. Делаем скрипт исполняемым

```bash
chmod +x update_emby.sh
```

### 3. Устанавливаем зависимости

```bash
sudo apt update
sudo apt install -y curl jq
```

---

## 🔐 Настройка Telegram уведомлений

1. Создайте бота в Telegram через [@BotFather](https://t.me/BotFather):
   ```
   /newbot
   ```
   Получите токен, например:
   ```
   123456789:ABCDEF_your_token
   ```

2. Узнайте свой `chat_id`:
   - Напишите боту @idmyfind_bot любое сообщение

3. Создайте файл `.env` рядом со скриптом:

   ```bash
   TELEGRAM_TOKEN="123456789:ABCDEF_your_token"
   TELEGRAM_CHAT_ID="123456789"
   ```

4. Убедитесь, что `.env` не попадёт в Git:
   ```bash
   echo ".env" >> .gitignore
   ```

---

## 🕓 Настройка cron

Чтобы скрипт выполнялся **каждый понедельник в 04:00**, открой `crontab`:

```bash
sudo crontab -e
```

Добавьте строку:

```
0 4 * * 1 /usr/local/bin/update_emby.sh >> /var/log/cron_update_emby.log 2>&1
```

или, если запускаете прямо из репозитория:

```
0 4 * * 1 /root/emby-auto-update/update_emby.sh >> /var/log/cron_update_emby.log 2>&1
```

---

## 🔍 Проверка вручную

Можно запустить вручную для теста:

```bash
sudo ./update_emby.sh
```

Пример вывода:
```
Проверка обновлений Emby: Sun Oct 5 04:00:00 UTC 2025
Последняя версия на GitHub: 4.9.0.15
Текущая установленная версия: 4.8.10.0
Обнаружено обновление: 4.8.10.0 → 4.9.0.15
Emby обновлён и запущен успешно.
```

После успешного обновления в Telegram придёт уведомление:
> ✅ Emby обновлён до версии 4.9.0.15 на сервере myserver и успешно запущен ✅

---

## 🧩 Структура проекта

```
emby-auto-update/
├── update_emby.sh      # Основной скрипт
├── .env                # Переменные окружения (токен Telegram)
├── .gitignore
└── README.md
```

---

## 🧠 Примечания

- Лог обновлений сохраняется в `/var/log/emby_update.log`
- Лог выполнения задания cron сохраняется в `/var/log/cron_update_emby.log`
- Временные файлы — в `/tmp/emby_update/`
- Скрипт требует root-доступ (используется `dpkg`, `systemctl`)
- Можно использовать `sudo` или настроить cron для root
- В файле .env репозитория содержатся данные, которые не соответствуют действительности.
---

## 🧪 CI: Проверка синтаксиса Bash (GitHub Actions)

Добавьте файл `.github/workflows/shellcheck.yml`, чтобы GitHub автоматически проверял синтаксис скрипта при каждом коммите.

```yaml
name: ShellCheck

on: [push, pull_request]

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run ShellCheck
        uses: ludeeus/action-shellcheck@v2
```

Теперь при каждом `git push` GitHub проверит скрипт на ошибки и выдаст результат в Actions.

---

## 🪪 Лицензия

Этот проект распространяется под лицензией **MIT**.  
Вы можете свободно использовать и изменять его под свои нужды.

---
