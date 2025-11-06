#!/bin/bash

# Ubuntu Client Setup for AgenticSeek Remote Access
# Version: 1.0

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Ubuntu
check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_warning "Этот скрипт оптимизирован для Ubuntu"
        read -p "Продолжить? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Update packages
update_packages() {
    print_status "Обновление пакетов..."
    sudo apt update && sudo apt upgrade -y
    print_success "Пакеты обновлены"
}

# Install required packages
install_packages() {
    print_status "Установка необходимых пакетов..."
    sudo apt install -y \
        openssh-client \
        git \
        python3 \
        python3-pip \
        tmux \
        curl \
        wget \
        nano \
        htop \
        tree \
        build-essential \
        python3-venv

    print_success "Пакеты установлены"
}

# Generate SSH keys
generate_ssh_keys() {
    print_status "Генерация SSH ключей..."

    if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -C "ubuntu-client@$(hostname)"
        print_success "SSH ключи сгенерированы"
    else
        print_warning "SSH ключи уже существуют"
    fi
}

# Create connection scripts
create_connection_scripts() {
    print_status "Создание скриптов подключения..."

    # Main connection script
    tee ~/connect_agenticseek.sh > /dev/null <<'EOF'
#!/bin/bash

# AgenticSeek Connection Script for Ubuntu Client
echo "🚀 Подключение к AgenticSeek серверу..."

# Server configuration
SERVER_IP="YOUR_SERVER_IP_HERE"
SERVER_USER="ubuntu"

# Function to check connection
check_connection() {
    if ping -c 1 "$SERVER_IP" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if server is reachable
if ! check_connection; then
    echo "❌ Сервер $SERVER_IP недоступен!"
    echo "Проверьте:"
    echo "1. IP адрес сервера"
    echo "2. Сетевое подключение"
    echo "3. Firewall на сервере"
    exit 1
fi

echo "✅ Сервер доступен, подключение..."

# Connect to server and attach to tmux session
ssh -t "$SERVER_USER@$SERVER_IP" "tmux attach -t agenticseek || tmux new -s agenticseek"
EOF

    chmod +x ~/connect_agenticseek.sh

    # Management scripts
    tee ~/agenticseek_tools.sh > /dev/null <<'EOF'
#!/bin/bash

# AgenticSeek Management Tools
SERVER_IP="YOUR_SERVER_IP_HERE"
SERVER_USER="ubuntu"

case "$1" in
    "status")
        echo "📊 Статус AgenticSeek:"
        ssh -t "$SERVER_USER@$SERVER_IP" "sudo systemctl status agenticseek --no-pager"
        ;;
    "logs")
        echo "📋 Логи AgenticSeek:"
        ssh -t "$SERVER_USER@$SERVER_IP" "sudo journalctl -u agenticseek -f"
        ;;
    "restart")
        echo "🔄 Перезапуск AgenticSeek:"
        ssh -t "$SERVER_USER@$SERVER_IP" "sudo systemctl restart agenticseek"
        ;;
    "docker")
        echo "🐳 Статус Docker сервисов:"
        ssh -t "$SERVER_USER@$SERVER_IP" "docker-compose ps"
        ;;
    "update")
        echo "⬆️ Обновление AgenticSeek:"
        ssh -t "$SERVER_USER@$SERVER_IP" "~/update_agenticseek.sh"
        ;;
    "backup")
        echo "💾 Создание бэкапа:"
        ssh -t "$SERVER_USER@$SERVER_IP" "~/backup_agenticseek.sh"
        ;;
    "ssh")
        echo "🔌 SSH подключение к серверу:"
        ssh "$SERVER_USER@$SERVER_IP"
        ;;
    *)
        echo "🛠️ AgenticSeek Management Tools"
        echo "Использование: $0 {status|logs|restart|docker|update|backup|ssh}"
        echo ""
        echo "Commands:"
        echo "  status  - Показать статус службы"
        echo "  logs    - Показать логи"
        echo "  restart - Перезапустить службу"
        echo "  docker  - Статус Docker контейнеров"
        echo "  update  - Обновить систему"
        echo "  backup  - Создать резервную копию"
        echo "  ssh     - Подключиться по SSH"
        ;;
esac
EOF

    chmod +x ~/agenticseek_tools.sh
    print_success "Скрипты подключений созданы"
}

# Create desktop shortcuts
create_desktop_shortcuts() {
    print_status "Создание ярлыков на рабочем столе..."

    DESKTOP_DIR="$HOME/Desktop"
    if [ ! -d "$DESKTOP_DIR" ]; then
        mkdir -p "$DESKTOP_DIR"
    fi

    # Main connection shortcut
    tee "$DESKTOP_DIR/Connect to AgenticSeek.desktop" > /dev/null <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Connect to AgenticSeek
Comment=Connect to AgenticSeek Server
Exec=$HOME/connect_agenticseek.sh
Icon=utilities-terminal
Terminal=true
Categories=Network;RemoteAccess;
EOF

    chmod +x "$DESKTOP_DIR/Connect to AgenticSeek.desktop"

    print_success "Ярлыки созданы"
}

# Setup aliases
setup_aliases() {
    print_status "Настройка aliases..."

    # Backup existing .bashrc
    cp ~/.bashrc ~/.bashrc.backup

    # Add aliases to .bashrc
    tee -a ~/.bashrc > /dev/null <<'EOF'

# AgenticSeek aliases and functions
alias agenticseek="~/connect_agenticseek.sh"
alias agentic="~/agenticseek_tools.sh"

# Quick status function
agentic_status() {
    ~/agenticseek_tools.sh status
}

# Quick logs function
agentic_logs() {
    ~/agenticseek_tools.sh logs
}

# Quick connect function
agentic_connect() {
    ~/connect_agenticseek.sh
}

# Show AgenticSeek menu
agentic_menu() {
    echo "🤖 AgenticSeek Menu"
    echo "=================="
    echo "1. Подключиться к AgenticSeek"
    echo "2. Показать статус"
    echo "3. Показать логи"
    echo "4. Перезапустить"
    echo "5. Статус Docker"
    echo "6. Обновить"
    echo "7. Создать бэкап"
    echo "8. SSH подключение"
    echo "9. Выход"
    echo ""
    read -p "Выберите опцию (1-9): " choice

    case $choice in
        1) agentic_connect ;;
        2) agentic_status ;;
        3) agentic_logs ;;
        4) ~/agenticseek_tools.sh restart ;;
        5) ~/agenticseek_tools.sh docker ;;
        6) ~/agenticseek_tools.sh update ;;
        7) ~/agenticseek_tools.sh backup ;;
        8) ~/agenticseek_tools.sh ssh ;;
        9) echo "До свидания!"; exit 0 ;;
        *) echo "Неверный выбор"; return 1 ;;
    esac
}

# Show welcome message
echo "🤖 AgenticSeek клиент настроен!"
echo "Используйте 'agentic_menu' для быстрого доступа"
EOF

    print_success "Aliases настроены"
}

# Create local development environment (optional)
create_dev_env() {
    print_status "Создание локального окружения разработки..."

    # Create development directory
    mkdir -p ~/agenticseek-dev
    cd ~/agenticseek-dev

    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate

    # Install development tools
    pip install --upgrade pip
    pip install black flake8 pytest python-dotenv

    print_success "Локальное окружение разработки создано"
}

# Display setup info
display_info() {
    print_success "Настройка Ubuntu клиента завершена!"
    echo ""
    echo "🚀 Следующие шаги:"
    echo "1. Отредактируйте скрипты подключения:"
    echo "   nano ~/connect_agenticseek.sh"
    echo "   nano ~/agenticseek_tools.sh"
    echo "   Замените YOUR_SERVER_IP_HERE на IP вашего сервера"
    echo ""
    echo "2. Скоpyруйте SSH ключ на сервер:"
    echo "   ssh-copy-id ubuntu@ВАШ_IP_СЕРВЕРА"
    echo ""
    echo "3. Подключитесь к серверу:"
    echo "   ~/connect_agenticseek.sh"
    echo "   или просто: agenticseek"
    echo ""
    echo "4. Управляйте сервером:"
    echo "   ~/agenticseek_tools.sh status"
    echo "   ~/agenticseek_tools.sh logs"
    echo "   ~/agenticseek_tools.sh restart"
    echo "   или: agentic status"
    echo "       agentic logs"
    echo "       agentic restart"
    echo ""
    echo "5. Используйте меню для удобства:"
    echo "   agentic_menu"
    echo ""
    echo "🖥️ Ярлыки на рабочем столе:"
    echo "- 'Connect to AgenticSeek' для быстрого подключения"
    echo ""
    echo "🔥 Дополнительные возможности:"
    echo "- Автоматическое завершение команд"
    echo "- История подключений"
    echo "- Мониторинг состояния"
    echo "- Графический интерфейс через файловый менеджер"
}

# Main function
main() {
    echo "🖥️ Настройка Ubuntu клиента для AgenticSeek"
    echo "========================================"

    check_ubuntu
    update_packages
    install_packages
    generate_ssh_keys
    create_connection_scripts
    create_desktop_shortcuts
    setup_aliases
    create_dev_env
    display_info
}

# Run main function
main "$@"