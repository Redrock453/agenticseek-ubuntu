#!/usr/bin/env python3
"""
AgenticSeek CLI Interface
Simplified CLI for Ubuntu Server installation
"""

import os
import sys
import asyncio
import logging
from pathlib import Path

# Add the sources directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "sources"))

try:
    from sources.interaction import Interaction
except ImportError:
    print("❌ Ошибка: Модули AgenticSeek не найдены!")
    print("Пожалуйста, убедитесь что все зависимости установлены:")
    print("pip install -r requirements.txt")
    print("Или выполните полную установку AgenticSeek")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/home/ubuntu/logs/agenticseek.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

async def main():
    """Main CLI function"""
    print("🤖 Запуск AgenticSeek...")
    print("=====================================")

    try:
        # Load environment variables
        from dotenv import load_dotenv
        env_path = Path(__file__).parent / ".env.zai"
        load_dotenv(env_path)

        # Check if essential environment variables are set
        if not os.getenv("ANTHROPIC_AUTH_TOKEN"):
            print("⚠️ Внимание: ANTHROPIC_AUTH_TOKEN не настроен в .env.zai")
            print("Пожалуйста, настройте API ключи в файле .env.zai")

        # Initialize interaction
        interaction = Interaction()

        # Start interaction loop
        await interaction.start()

    except KeyboardInterrupt:
        print("\n👋 До свидания! AgenticSeek остановлен.")
    except Exception as e:
        logger.error(f"Ошибка запуска AgenticSeek: {e}")
        print(f"❌ Ошибка: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())