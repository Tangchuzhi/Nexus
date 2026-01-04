#!/data/data/com.termux/files/usr/bin/bash
# UI 模块 - 界面显示与颜色

# 颜色定义
COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_CYAN="\033[36m"
COLOR_BOLD="\033[1m"

# 颜色输出函数
colorize() {
    echo -e "${2}${1}${COLOR_RESET}"
}

# 显示头部
show_header() {
    colorize "╔════════════════════════════════════════╗" "$COLOR_CYAN"
    colorize "║     Nexus - SillyTavern-Termux 终端     ║" "$COLOR_CYAN"
    colorize "╚════════════════════════════════════════╝" "$COLOR_CYAN"
}

# 显示版本信息
show_version_info() {
    local st_status=$(get_st_status)
    local st_local=$(get_st_local_version)
    local st_remote=$(get_st_remote_version)
    local nexus_remote=$(get_nexus_remote_version)
    
    echo ""
    colorize "📊 版本信息" "$COLOR_BOLD"
    echo "───────────────────────────────────────"
    
    # SillyTavern 状态
    echo -n "  SillyTavern: "
    if [ "$st_status" == "running" ]; then
        colorize "[运行中]" "$COLOR_GREEN"
    else
        colorize "[已停止]" "$COLOR_YELLOW"
    fi
    
    # SillyTavern 版本
    echo -n "  本地版本: $st_local  "
    if [ "$st_local" != "$st_remote" ] && [ -n "$st_remote" ]; then
        colorize "→ 可更新: $st_remote" "$COLOR_YELLOW"
    else
        colorize "✓ 最新" "$COLOR_GREEN"
    fi
    
    echo ""
    
    # Nexus 版本
    echo -n "  Nexus: v$NEXUS_VERSION  "
    if [ "$NEXUS_VERSION" != "$nexus_remote" ] && [ -n "$nexus_remote" ]; then
        colorize "→ 可更新: v$nexus_remote" "$COLOR_YELLOW"
    else
        colorize "✓ 最新" "$COLOR_GREEN"
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

# 成功提示
show_success() {
    colorize "✓ $1" "$COLOR_GREEN"
}

# 错误提示
show_error() {
    colorize "✗ $1" "$COLOR_RED"
}

# 警告提示
show_warning() {
    colorize "⚠ $1" "$COLOR_YELLOW"
}

# 信息提示
show_info() {
    colorize "ℹ $1" "$COLOR_BLUE"
}
