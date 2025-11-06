#!/bin/bash

# AgenticSeek Ubuntu Server Installation Script
# Version: 1.0
# Author: AgenticSeek Community

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Не запускайте этот скрипт от root пользователя!"
        exit 1
    fi
}

# Check internet connection
check_internet() {
    print_status "Проверка интернет соединения..."
    if ping -c 1 google.com &> /dev/null; then
        print_success "Интернет соединение есть"
    else
        print_error "Нет интернет соединения!"
        exit 1
    fi
}

# Update system
update_system() {
    print_status "Обновление системы..."
    sudo apt update && sudo apt upgrade -y
    print_success "Система обновлена"
}

# Install basic packages
install_packages() {
    print_status "Установка базовых пакетов..."
    sudo apt install -y \
        curl \
        wget \
        git \
        htop \
        nano \
        tmux \
        ufw \
        docker.io \
        docker-compose-plugin \
        python3.11 \
        python3.11-venv \
        python3.11-dev \
        python3-pip \
        fail2ban \
        unzip \
        build-essential

    print_success "Базовые пакеты установлены"
}

# Configure firewall
configure_firewall() {
    print_status "Настройка firewall..."
    sudo ufw --force reset
    sudo ufw allow 22/tcp
    sudo ufw allow 3000/tcp
    sudo ufw allow 8000/tcp
    sudo ufw --force enable
    print_success "Firewall настроен"
}

# Configure Docker
configure_docker() {
    print_status "Настройка Docker..."
    sudo usermod -aG docker $USER

    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker

    print_success "Docker настроен"
}

# Create directories
create_directories() {
    print_status "Создание директорий..."
    mkdir -p ~/backups
    mkdir -p ~/logs
    mkdir -p ~/configs
    print_success "Директории созданы"
}

# Configure fail2ban
configure_fail2ban() {
    print_status "Настройка Fail2Ban..."

    # Create fail2ban configuration
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
EOF

    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban

    print_success "Fail2Ban настроен"
}

# Create systemd service
create_systemd_service() {
    print_status "Создание systemd службы..."

    sudo tee /etc/systemd/system/agenticseek.service > /dev/null <<EOF
[Unit]
Description=AgenticSeek Service
After=network.target docker.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/agenticseek-ubuntu
Environment=PATH=/home/ubuntu/agenticseek-ubuntu/agentic_seek_env/bin
ExecStart=/home/ubuntu/agenticseek-ubuntu/agentic_seek_env/bin/python /home/ubuntu/agenticseek-ubuntu/cli.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    print_success "Systemd служба создана"
}

# Create backup script
create_backup_script() {
    print_status "Создание скрипта резервного копирования..."

    tee ~/backup_agenticseek.sh > /dev/null <<'EOF'
#!/bin/bash

# Backup script for AgenticSeek
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="agenticseek_backup_$DATE.tar.gz"

# Create backup
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    agenticseek-ubuntu/ \
    .env.zai \
    config.ini \
    --exclude=agenticseek-ubuntu/agentic_seek_env \
    --exclude=agenticseek-ubuntu/__pycache__ \
    --exclude=agenticseek-ubuntu/.git \
    --exclude=agenticseek-ubuntu/node_modules

# Keep only last 7 backups
find "$BACKUP_DIR" -name "agenticseek_backup_*.tar.gz" -mtime +7 -delete

echo "Backup created: $BACKUP_DIR/$BACKUP_FILE"
EOF

    chmod +x ~/backup_agenticseek.sh
    print_success "Скрипт резервного копирования создан"
}

# Create update script
create_update_script() {
    print_status "Создание скрипта обновления..."

    tee ~/update_agenticseek.sh > /dev/null <<'EOF'
#!/bin/bash

# Update script for AgenticSeek
cd ~/agenticseek-ubuntu

# Stop services
tmux kill-session -t agenticseek 2>/dev/null || true
sudo systemctl stop agenticseek 2>/dev/null || true

# Backup current version
~/backup_agenticseek.sh

# Update from git
git pull origin main

# Update Python dependencies
source agentic_seek_env/bin/activate
pip install -r requirements.txt

# Update Docker services
docker-compose pull
docker-compose up -d

# Restart services
tmux new -s agenticseek -d 'source agentic_seek_env/bin/activate && python cli.py'
sudo systemctl start agenticseek

echo "AgenticSeek updated successfully!"
EOF

    chmod +x ~/update_agenticseek.sh
    print_success "Скрипт обновления создан"
}

# Create cron jobs
create_cron_jobs() {
    print_status "Настройка cron задач..."

    # Create crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * ~/backup_agenticseek.sh") | crontab -
    (crontab -l 2>/dev/null; echo "0 3 * * 0 ~/update_agenticseek.sh") | crontab -

    print_success "Cron задачи настроены"
}

# Display system info
display_system_info() {
    print_status "Информация о системе:"
    echo "----------------------------------------"
    echo "IP адрес: $(curl -s ifconfig.me)"
    echo "Локальный IP: $(hostname -I | awk '{print $1}')"
    echo "Версия Ubuntu: $(lsb_release -d | cut -f2)"
    echo "Версия Docker: $(docker --version)"
    echo "Версия Python: $(python3.11 --version)"
    echo "----------------------------------------"
}

# Display next steps
display_next_steps() {
    print_success "Установка завершена!"
    echo ""
    echo "🚀 Следующие шаги:"
    echo "1. Перезагрузите систему: sudo reboot"
    echo "2. После перезагрузки выполните:"
    echo "   cd agenticseek-ubuntu"
    echo "   git clone https://github.com/yourusername/agenticseek.git ."
    echo "   python3.11 -m venv agentic_seek_env"
    echo "   source agentic_seek_env/bin/activate"
    echo "   pip install -r requirements.txt"
    echo "   cp .env.template .env.zai"
    echo "   nano .env.zai  # настройте API ключи"
    echo "   docker-compose up -d redis searxng"
    echo "   tmux new -s agenticseek -d 'source agentic_seek_env/bin/activate && python cli.py'"
    echo ""
    echo "📱 Для подключения с Android:"
    echo "1. Установите Termux с F-Droid"
    echo "2. Выполните: pkg install openssh tmux"
    echo "3. Подключитесь: ssh ubuntu@$(curl -s ifconfig.me)"
    echo "4. Подключитесь к сессии: tmux attach -t agenticseek"
    echo ""
    echo "🔥 Полезные команды:"
    echo "- Проверить статус: sudo systemctl status agenticseek"
    echo "- Посмотреть логи: sudo journalctl -u agenticseek -f"
    echo "- Подключиться к сессии: tmux attach -t agenticseek"
    echo "- Создать бэкап: ~/backup_agenticseek.sh"
    echo "- Обновить: ~/update_agenticseek.sh"
}

# Main installation function
main() {
    echo "🚀 Установка AgenticSeek Ubuntu Server"
    echo "========================================"

    check_root
    check_internet
    update_system
    install_packages
    configure_firewall
    configure_docker
    create_directories
    configure_fail2ban
    create_systemd_service
    create_backup_script
    create_update_script
    create_cron_jobs
    display_system_info
    display_next_steps
}

# Run main function
main "$@"