#!/data/data/com.termux/files/usr/bin/bash
# Nexus - SillyTavern 管理工具

set -e

# ============================================
# 路径配置
# ============================================

# 🔧 获取脚本真实路径
SCRIPT_PATH="${BASH_SOURCE[0]}"

# 如果是软链接，解析到真实路径
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    # 如果是相对路径，需要拼接目录
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done

# 获取脚本所在的真实目录
NEXUS_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"

# 从 VERSION 文件读取版本号
if [ -f "$NEXUS_DIR/VERSION" ]; then
    NEXUS_VERSION=$(cat "$NEXUS_DIR/VERSION" | tr -d '[:space:]')
else
    NEXUS_VERSION="unknown"
fi

# ============================================
# 🔒 进程锁 - 防止多次启动
# ============================================

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

# ============================================
# 加载模块
# ============================================

source "$NEXUS_DIR/core/ui.sh"
source "$NEXUS_DIR/core/utils.sh"
source "$NEXUS_DIR/core/version.sh"
source "$NEXUS_DIR/modules/tavern/lifecycle.sh"
source "$NEXUS_DIR/modules/tavern/runtime.sh"
source "$NEXUS_DIR/modules/tavern/backup.sh"
source "$NEXUS_DIR/modules/manager.sh"
source "$NEXUS_DIR/modules/diagnose.sh"

# ============================================
# 初始化
# ============================================

init_nexus

# 🔧 优化：仅在启动时检测一次版本，避免阻塞
CACHED_ST_LOCAL=$(get_st_local_version)
CACHED_ST_REMOTE=$(get_st_remote_version)
CACHED_NEXUS_REMOTE=$(get_nexus_remote_version)

# ============================================
# 主菜单
# ============================================

main_menu() {
    clear
    show_header
    
    # 显示状态信息
    show_status_info
    
    echo ""
    colorize "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$COLOR_CYAN"
    echo ""
    
    # SillyTavern 工具区
    colorize "  🍺 SillyTavern 工具" "$COLOR_BOLD"
    echo ""
    echo "  [1] SillyTavern 启动"
    echo "  [2] SillyTavern 管理"
    echo "  [3] 备份与恢复"
    echo ""
    
    colorize "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$COLOR_CYAN"
    echo ""
    
    # Nexus 工具区
    colorize "  🔧 Nexus 工具" "$COLOR_BOLD"
    echo ""
    echo "  [4] Nexus 管理"
    echo "  [5] 故障诊断"
    echo ""
    
    colorize "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$COLOR_CYAN"
    echo ""
    echo "  [0] 退出"
    echo ""
    
    read -p "$(colorize "请选择 [0-5]: " "$COLOR_CYAN")" choice
    
    case $choice in
        1) st_start ;;
        2) st_management_menu ;;
        3) backup_menu ;;
        4) nexus_management_menu ;;
        5) troubleshoot_menu ;;
        0) 
            colorize "👋 再见！" "$COLOR_GREEN"
            rm -f "$LOCK_FILE"  # 手动清理锁文件
            exit 0
            ;;
        *) 
            show_error "无效选项"
            sleep 1
            ;;
    esac
}

# ============================================
# 主循环
# ============================================

while true; do
    main_menu
done
