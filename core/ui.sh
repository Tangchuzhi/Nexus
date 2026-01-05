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
    echo ""
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""
    echo -e "  ${COLOR_BOLD}${COLOR_CYAN}Nexus${COLOR_RESET} ${COLOR_GRAY}·${COLOR_RESET} SillyTavern 管理终端"
    echo ""
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

# 显示分隔线
show_separator() {
    echo ""
    echo -e "${COLOR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""
}

# 显示版本信息
show_version_info_cached() {
    echo ""
    colorize "📦 版本信息" "$COLOR_BOLD"
    echo ""
    
    # SillyTavern 版本
    echo -n "  SillyTavern: "
    if [ "$CACHED_ST_LOCAL" == "未安装" ]; then
        colorize "$CACHED_ST_LOCAL" "$COLOR_GRAY"
    else
        echo -n "$CACHED_ST_LOCAL"
        if [ -n "$CACHED_ST_REMOTE" ] && [ "$CACHED_ST_LOCAL" != "$CACHED_ST_REMOTE" ]; then
            colorize " → $CACHED_ST_REMOTE" "$COLOR_YELLOW"
        else
            colorize " ✓" "$COLOR_GREEN"
        fi
    fi
    
    # Nexus 版本
    echo -n "  Nexus: v$NEXUS_VERSION"
    
    if [ -n "$CACHED_NEXUS_REMOTE" ]; then
        if [ "$NEXUS_VERSION" == "$CACHED_NEXUS_REMOTE" ]; then
            colorize " ✓" "$COLOR_GREEN"
        else
            colorize " → v$CACHED_NEXUS_REMOTE" "$COLOR_YELLOW"
        fi
    else
        echo ""
    fi
}

# 显示菜单选项
show_menu_options() {
    echo ""
    colorize "📋 功能菜单" "$COLOR_BOLD"
    echo ""
    echo "  [1] SillyTavern 安装/更新"
    echo "  [2] SillyTavern 启动"
    echo "  [3] Nexus 更新/重装"
    echo "  [4] Nexus 系统设置"
    echo "  [0] 退出"
}

# 显示子菜单头部
show_submenu_header() {
    local title="$1"
    echo ""
    colorize "🔹 $title" "$COLOR_CYAN"
    echo ""
}

# 显示加载动画
show_loading() {
    local message="$1"
    echo -n "$message"
    echo " ..."
}
