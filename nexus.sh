#!/data/data/com.termux/files/usr/bin/bash
# Nexus - SillyTavern 管理终端

# 获取脚本真实路径
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
NEXUS_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# 从 VERSION 文件读取版本号
NEXUS_VERSION=$(cat "$NEXUS_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || echo "未知版本")

# 加载核心模块
source "$NEXUS_DIR/core/ui.sh" || { echo "错误: 无法加载 ui.sh"; exit 1; }
source "$NEXUS_DIR/core/utils.sh" || { echo "错误: 无法加载 utils.sh"; exit 1; }
source "$NEXUS_DIR/core/version.sh" || { echo "错误: 无法加载 version.sh"; exit 1; }

# 加载功能模块
source "$NEXUS_DIR/modules/tavern/lifecycle.sh" || { echo "错误: 无法加载 lifecycle.sh"; exit 1; }
source "$NEXUS_DIR/modules/tavern/backup.sh" || { echo "错误: 无法加载 backup.sh"; exit 1; }
source "$NEXUS_DIR/modules/tavern/runtime.sh" || { echo "错误: 无法加载 runtime.sh"; exit 1; }
source "$NEXUS_DIR/modules/diagnose.sh" || { echo "错误: 无法加载 diagnose.sh"; exit 1; }
source "$NEXUS_DIR/modules/manager.sh" || { echo "错误: 无法加载 manager.sh"; exit 1; }

# 加载配置
source "$NEXUS_DIR/config/nexus.conf" || { echo "错误: 无法加载 nexus.conf"; exit 1; }

# 全局变量：缓存版本信息（启动时获取一次）
CACHED_ST_LOCAL=""
CACHED_ST_REMOTE=""
CACHED_NEXUS_REMOTE=""

# 启动时获取版本信息（仅一次）
fetch_version_info() {
    CACHED_ST_LOCAL=$(get_st_local_version)
    CACHED_ST_REMOTE=$(get_st_remote_version)
    CACHED_NEXUS_REMOTE=$(get_nexus_remote_version)
}

# 主菜单
main_menu() {
    while true; do
        clear
        show_header
        show_version_info_cached
        echo ""
        show_menu_options
        echo ""
        
        read -p "$(colorize "请选择操作 [0-5]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) st_start ;;
            2) st_management_menu ;;
            3) backup_menu ;;
            4) nexus_management_menu ;;
            5) troubleshoot_menu ;;
            0) exit 0 ;;
            *) show_error "无效选项" ;;
        esac
        
        read -p "按任意键继续..." -n 1
    done
}

# 启动程序
init_nexus
fetch_version_info
main_menu
