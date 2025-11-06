#!/bin/bash

# Termux Setup Script for AgenticSeek Remote Access
# Version: 1.0

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Update packages
update_packages() {
    print_status "Обновление пакетов Termux..."
    pkg update && pkg upgrade -y
    print_success "Пакеты обновлены"
}

# Install required packages
install_packages() {
    print_status "Установка необходимых пакетов..."
    pkg install -y \
        openssh \
        git \
        python \
        tmux \
        curl \
        wget \
        nano \
        htop \
        tree

    print_success "Пакеты установлены"
}

# Configure SSH
configure_ssh() {
    print_status "Настройка SSH..."

    # Start SSH server
    sshd

    # Enable SSH on boot (in Termux)
    echo "sshd" >> ~/.bashrc

    print_success "SSH настроен"
}

# Generate SSH keys
generate_ssh_keys() {
    print_status "Генерация SSH ключей..."

    if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -C "termux@android"
        print_success "SSH ключи сгенерированы"
    else
        print_warning "SSH ключи уже существуют"
    fi
}

# Create connection script
create_connection_script() {
    print_status "Создание скрипта подключения..."

    tee ~/connect_agenticseek.sh > /dev/null <<'EOF'
#!/bin/bash

# AgenticSeek Connection Script
echo "🚀 Подключение к AgenticSeek серверу..."

# Server IP (замените на ваш IP)
SERVER_IP="YOUR_SERVER_IP_HERE"
SERVER_USER="ubuntu"

# Connect to server and attach to tmux session
ssh -t $SERVER_USER@$SERVER_IP "tmux attach -t agenticseek || tmux new -s agenticseek"
EOF

    chmod +x ~/connect_agenticseek.sh
    print_success "Скрипт подключения создан"
}

# Create utility functions
create_utils() {
    print_status "Создание утилит..."

    # Create agenticseek command in .bashrc
    tee -a ~/.bashrc > /dev/null <<'EOF'

# AgenticSeek aliases and functions
alias agenticseek="~/connect_agenticseek.sh"
alias agenticlogs="ssh -t ubuntu@YOUR_SERVER_IP_HERE 'sudo journalctl -u agenticseek -f'"
alias agenticstatus="ssh -t ubuntu@YOUR_SERVER_IP_HERE 'sudo systemctl status agenticseek'"

# Function to quickly check server status
check_agenticseek() {
    echo "📊 Статус AgenticSeek сервера:"
    ssh -t ubuntu@YOUR_SERVER_IP_HERE "docker-compose ps && echo '' && systemctl status agenticseek --no-pager"
}
EOF

    print_success "Утилиты созданы"
}

# Display setup info
display_info() {
    print_success "Настройка Termux завершена!"
    echo ""
    echo "📱 Следующие шаги:"
    echo "1. Отредактируйте скрипт подключения:"
    echo "   nano ~/connect_agenticseek.sh"
    echo "   Замените YOUR_SERVER_IP_HERE на IP вашего сервера"
    echo ""
    echo "2. Скоpyруйте SSH ключ на сервер:"
    echo "   ssh-copy-id ubuntu@ВАШ_IP_СЕРВЕРА"
    echo ""
    echo "3. Подключитесь к серверу:"
    echo "   ~/connect_agenticseek.sh"
    echo ""
    echo "4. Или используйте короткую команду:"
    echo "   agenticseek"
    echo ""
    echo "🔥 Полезные команды:"
    echo "- agenticseek - подключиться к AgenticSeek"
    echo "- agenticlogs - посмотреть логи"
    echo "- agenticstatus - проверить статус"
    echo "- check_agenticseek - проверка сервера"
    echo ""
    echo "💡 Для редактирования IP адреса:"
    echo "- nano ~/.bashrc"
    echo "- Замените YOUR_SERVER_IP_HERE на реальный IP"
}

# Main function
main() {
    echo "📱 Настройка Termux для AgenticSeek"
    echo "=================================="

    update_packages
    install_packages
    configure_ssh
    generate_ssh_keys
    create_connection_script
    create_utils
    display_info
}

# Run main function
main "$@"