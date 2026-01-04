#!/data/data/com.termux/files/usr/bin/bash
# Nexus - SillyTavern-Termux 管理终端

NEXUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 从 VERSION 文件读取版本号
NEXUS_VERSION=$(cat "$NEXUS_DIR/VERSION" 2>/dev/null || echo "未知版本")

# 加载核心模块
source "$NEXUS_DIR/core/ui.sh"
source "$NEXUS_DIR/core/utils.sh"
source "$NEXUS_DIR/core/version.sh"

# 加载功能模块
source "$NEXUS_DIR/modules/sillytavern.sh"
source "$NEXUS_DIR/modules/settings.sh"

# 加载配置
source "$NEXUS_DIR/config/nexus.conf"

# 主菜单
main_menu() {
    while true; do
        clear
        show_header
        show_version_info
        echo ""
        show_menu_options
        echo ""
        
        read -p "$(colorize "请选择操作 [1-4]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) st_install_update ;;
            2) st_start ;;
            3) nexus_update ;;
            4) settings_menu ;;
            0) exit 0 ;;
            *) show_error "无效选项" ;;
        esac
        
        read -p "按任意键继续..." -n 1
    done
}

# 启动程序
init_nexus
main_menu
