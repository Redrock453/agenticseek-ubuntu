# AgenticSeek Ubuntu Server - Полная инструкция по установке

🚸 **AgenticSeek Ubuntu Server** - полное руководство по установке AgenticSeek на Ubuntu сервер с возможностью удалённого управления через Termux.

## ✨ Возможности этой установки

- 🖥️ **Ubuntu Server** - стабильная серверная ОС
- 🐳 **Полный Docker стек** - все сервисы в контейнерах
- 📱 **Удалённый доступ** - управление через Android Termux
- 🔒 **Безопасность** - SSH ключи, firewall, автоматический перезапуск
- 🔄 **Надёжность** - systemd службы, tmux сессии
- 🌐 **Веб-интерфейс** - React frontend
- 🤖 **Мультипровайдерная поддержка** - OpenAI, Anthropic, Z.ai и другие

## 🚀 Автоматическая установка

### Шаг 1: Подготовка Ubuntu Server

```bash
# Скачайте установщик
wget https://raw.githubusercontent.com/yourusername/agenticseek-ubuntu/main/install_ubuntu.sh
chmod +x install_ubuntu.sh
./install_ubuntu.sh

# Перезагрузите систему
sudo reboot
```

### Шаг 2: Настройка AgenticSeek

```bash
# Клонируйте репозиторий
git clone https://github.com/yourusername/agenticseek-ubuntu.git
cd agenticseek-ubuntu

# Настройте переменные окружения
cp .env.template .env.zai
nano .env.zai
```

### Шаг 3: Запуск сервисов

```bash
# Запустите базовые сервисы
docker-compose up -d redis searxng

# Запустите AgenticSeek в tmux
tmux new -s agenticseek -d 'source agentic_seek_env/bin/activate && python cli.py'
```

## 🔧 Ручная установка

### 1. Установка системы

```bash
# Обновите систему
sudo apt update && sudo apt upgrade -y

# Установите базовые пакеты
sudo apt install -y curl wget git htop nano tmux ufw docker.io docker-compose-plugin python3.11 python3.11-venv python3.11-dev python3-pip

# Настройте firewall
sudo ufw allow ssh
sudo ufw enable

# Настройте Docker
sudo usermod -aG docker $USER
```

### 2. Настройка AgenticSeek

```bash
# Клонируйте репозиторий
git clone https://github.com/yourusername/agenticseek-ubuntu.git
cd agenticseek-ubuntu

# Создайте виртуальное окружение
python3.11 -m venv agentic_seek_env
source agentic_seek_env/bin/activate

# Установите зависимости
pip install -r requirements.txt
```

### 3. Настройка переменных окружения

Создайте файл `.env.zai`:

```bash
# Поисковая система и база данных
SEARXNG_BASE_URL="http://localhost:8080"
REDIS_BASE_URL="redis://redis:6379/0"
WORK_DIR="/home/ubuntu/agenticseek-ubuntu"

# Порты
OLLAMA_PORT="11434"
LM_STUDIO_PORT="1234"
BACKEND_PORT="7777"
CUSTOM_ADDITIONAL_LLM_PORT="11435"

# API ключи (замените на ваши)
ANTHROPIC_AUTH_TOKEN="ваш_zai_api_ключ"
ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
OPENAI_API_KEY="ваш_openai_ключ"
DEEPSEEK_API_KEY="ваш_deepseek_ключ"
OPENROUTER_API_KEY="ваш_openrouter_ключ"
TOGETHER_API_KEY="ваш_together_ключ"
GOOGLE_API_KEY="ваш_google_ключ"

# Таймауты
API_TIMEOUT_MS="3000000"
```

### 4. Настройка автоматического запуска

```bash
# Создайте systemd службу
sudo cp agenticseek.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable agenticseek
sudo systemctl start agenticseek
```

## 📱 Настройка Termux на Android

### Установка Termux

1. Скачайте **Termux.apk** с [F-Droid](https://f-droid.org/)
2. Установите на Android устройство

### Базовая настройка

```bash
# Обновите пакеты
pkg update && pkg upgrade -y

# Установите необходимые пакеты
pkg install -y openssh git python tmux curl wget nano htop

# Сгенерируйте SSH ключи
ssh-keygen -t ed25519 -C "termux@android"
```

### Подключение к серверу

```bash
# Скопируйте ключ на сервер
ssh-copy-id ubuntu@your_server_ip

# Подключитесь к серверу
ssh ubuntu@your_server_ip

# Подключитесь к сессии AgenticSeek
tmux attach -t agenticseek
```

## 🏗️ Архитектура системы

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Android       │    │   Ubuntu Server │    │   AgenticSeek   │
│   (Termux)      │◄──►│   (SSH/Tmux)    │◄──►│   (AI Platform) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌────────┴────────┐
                       ▼                 ▼
                ┌─────────────┐   ┌─────────────┐
                │   Docker    │   │   SystemD   │
                │   Services  │   │   Services  │
                └─────────────┘   └─────────────┘
```

## 🖥️ Использование

### Управление через tmux

```bash
# Подключиться к сессии
tmux attach -t agenticseek

# Отключиться (программа продолжит работать)
# Ctrl+B, затем D

# Посмотреть все сессии
tmux ls

# Создать новую сессию
tmux new -s session_name
```

### Управление через systemd

```bash
# Проверить статус
sudo systemctl status agenticseek

# Перезапустить службу
sudo systemctl restart agenticseek

# Посмотреть логи
sudo journalctl -u agenticseek -f

# Остановить службу
sudo systemctl stop agenticseek
```

### Управление Docker сервисами

```bash
# Запустить все сервисы
docker-compose up -d

# Остановить все сервисы
docker-compose down

# Проверить статус
docker-compose ps

# Посмотреть логи
docker-compose logs -f
```

## 🔒 Безопасность

### Настройка SSH

```bash
# Измените порт SSH
sudo nano /etc/ssh/sshd_config

# Запретите вход по паролю
PasswordAuthentication no
PermitRootLogin no

# Перезапустите SSH
sudo systemctl restart ssh
```

### Настройка Firewall

```bash
# Разрешите только необходимые порты
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 3000/tcp  # Frontend
sudo ufw allow 8000/tcp  # API Gateway
sudo ufw enable
```

### Настройка Fail2Ban

```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## 📊 Мониторинг

### Системные ресурсы

```bash
# CPU и память
htop

# Дисковое пространство
df -h

# Сетевые подключения
netstat -tlnp

# Процессы
ps aux
```

### Логи

```bash
# Логи AgenticSeek
sudo journalctl -u agenticseek -f

# Docker логи
docker-compose logs -f redis
docker-compose logs -f searxng

# Системные логи
sudo journalctl -xe
```

## 🛠️ Устранение проблем

### Частые проблемы

**1. Ошибка аутентификации API**
```bash
# Проверьте .env.zai файл
cat .env.zai
# Убедитесь что API ключи верные
```

**2. Порт уже используется**
```bash
# Найти процесс
sudo lsof -i :8000
# Убить процесс
sudo kill -9 <PID>
```

**3. Проблемы с Docker**
```bash
# Перезапустить Docker
sudo systemctl restart docker
# Очистить кэш
docker system prune -a
```

**4. Проблемы с tmux**
```bash
# Убить все сессии
tmux kill-server

# Создать новую сессию
tmux new -s agenticseek
```

## 📋 Полный список команд для быстрого старта

```bash
# 1. Установка системы
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git htop nano tmux ufw docker.io docker-compose-plugin python3.11 python3.11-venv python3.11-dev python3-pip
sudo usermod -aG docker $USER
sudo ufw allow ssh && sudo ufw enable

# 2. Настройка AgenticSeek
git clone https://github.com/yourusername/agenticseek-ubuntu.git
cd agenticseek-ubuntu
python3.11 -m venv agentic_seek_env
source agentic_seek_env/bin/activate
pip install -r requirements.txt

# 3. Конфигурация
cp .env.template .env.zai
nano .env.zai  # настройте API ключи

# 4. Системные службы
sudo cp agenticseek.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable agenticseek

# 5. Запуск
docker-compose up -d redis searxng
tmux new -s agenticseek -d 'source agentic_seek_env/bin/activate && python cli.py'
sudo systemctl start agenticseek
```

## 🤝 Вклад в проект

1. Fork репозиторий
2. Создайте ветку (`git checkout -b feature/AmazingFeature`)
3. Commit изменения (`git commit -m 'Add some AmazingFeature'`)
4. Push в ветку (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

## 📄 Лицензия

Этот проект лицензирован под MIT License.

## 🙏 Благодарности

- **AgenticSeek** - основная платформа
- **Z.ai** - API провайдер
- **Docker** - контейнеризация
- **Termux** - Android терминал

## 📞 Поддержка

- **Issues**: [GitHub Issues](https://github.com/yourusername/agenticseek-ubuntu/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/agenticseek-ubuntu/discussions)

---

**⭐ Если этот проект полезен, поставьте звёздочку!**

## 📱 QR-код для быстрого доступа

[QR-код для скачивания Termux и подключения]

## 🌟 Особенности этой установки

- ✅ **Полностью автоматическая** установка
- ✅ **Безопасная** конфигурация
- ✅ **Мобильный доступ** через Termux
- ✅ **Автоматический перезапуск** при сбоях
- ✅ **Мониторинг** и логирование
- ✅ **Резервное копирование** конфигураций
- ✅ **Обновления** в один клик