#!/data/data/com.termux/files/usr/bin/bash
# UI 显示模块

# 颜色定义
COLOR_RESET='\033[0m'
COLOR_BOLD='\033[1m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_GRAY='\033[0;90m'

# 颜色输出
colorize() {
    local text="$1"
    local color="$2"
    echo -e "${color}${text}${COLOR_RESET}"
}

# 显示消息
show_info() { echo -e "${COLOR_BLUE}[信息]${COLOR_RESET} $1"; }
show_success() { echo -e "${COLOR_GREEN}[成功]${COLOR_RESET} $1"; }
show_error() { echo -e "${COLOR_RED}[错误]${COLOR_RESET} $1"; }
show_warning() { echo -e "${COLOR_YELLOW}[警告]${COLOR_RESET} $1"; }

# 显示头部
show_header() {
    colorize "╔════════════════════════════════════════╗" "$COLOR_CYAN"
    colorize "║      🌟 Nexus - SillyTavern 一键部署 🌟    ║" "$COLOR_CYAN"
    colorize "╚════════════════════════════════════════╝" "$COLOR_CYAN"
}

# 全局变量存储版本信息（避免重复查询）
ST_REMOTE_VERSION=""
NEXUS_REMOTE_VERSION=""

# 预加载版本信息（仅在启动时调用一次）
preload_version_info() {
    ST_REMOTE_VERSION=$(get_st_remote_version)
    NEXUS_REMOTE_VERSION=$(get_nexus_remote_version)
}

# 显示版本信息
show_version_info() {
    echo ""
    colorize "📊 版本信息" "$COLOR_BOLD"
    echo "───────────────────────────────────────"
    
    # SillyTavern 状态
    local st_status=$(get_st_status)
    if [ "$st_status" == "running" ]; then
        echo -n "  SillyTavern: "
        colorize "[运行中]" "$COLOR_GREEN"
    else
        echo -n "  SillyTavern: "
        colorize "[已停止]" "$COLOR_GRAY"
    fi
    
    # SillyTavern 版本
    local st_local=$(get_st_local_version)
    echo "  本地版本: $st_local"
    
    if [ -n "$ST_REMOTE_VERSION" ]; then
        echo "  最新版本: $ST_REMOTE_VERSION"
    fi
    
    echo ""
    
    # Nexus 版本
    echo -n "  Nexus: v$NEXUS_VERSION"
    
    if [ -n "$NEXUS_REMOTE_VERSION" ]; then
        if [ "$NEXUS_VERSION" == "$NEXUS_REMOTE_VERSION" ]; then
            colorize "  ✓ 最新" "$COLOR_GREEN"
        else
            colorize "  ⚠ 有更新 (v$NEXUS_REMOTE_VERSION)" "$COLOR_YELLOW"
        fi
    else
        echo ""
    fi
}

# 显示菜单选项
show_menu_options() {
    colorize "📋 功能菜单" "$COLOR_BOLD"
    echo "───────────────────────────────────────"
    echo "  [1] SillyTavern 安装/更新"
    echo "  [2] SillyTavern 启动"
    echo "  [3] Nexus 更新/重装"
    echo "  [4] Nexus 系统设置"
    echo "  [0] 退出"
}

# 显示加载动画
show_loading() {
    local message="$1"
    echo -n "$message"
    for i in {1..3}; do
        echo -n "."
        sleep 0.3
    done
    echo ""
}
