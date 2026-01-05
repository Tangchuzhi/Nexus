#!/data/data/com.termux/files/usr/bin/bash
# Nexus - SillyTavern 管理终端

# 获取脚本真实路径
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
NEXUS_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# 从 VERSION 文件读取版本号
NEXUS_VERSION=$(cat "$NEXUS_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || echo "未知版本")

# 使用 Nexus 内部目录存储锁文件
LOCK_FILE="$NEXUS_DIR/.lock"

# 检查是否已有实例在运行
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    
    # 检查进程是否真的存在
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        echo -e "\033[0;31m[错误]\033[0m Nexus 已在运行 (PID: $LOCK_PID)"
        echo ""
        echo "如果确认没有运行，请执行："
        echo "  rm -f $LOCK_FILE"
        exit 1
    else
        # 锁文件存在但进程已死，清理锁文件
        rm -f "$LOCK_FILE"
    fi
fi

# 创建锁文件
echo $ > "$LOCK_FILE"

# 设置退出时自动清理锁文件
trap "rm -f $LOCK_FILE" EXIT INT TERM

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
