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

# 显示版本信息（每次调用时动态获取，利用缓存机制）
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
    
    # 获取远程版本（会自动使用缓存或刷新）
    local st_remote=$(get_st_remote_version)
    if [ -n "$st_remote" ]; then
        echo "  最新版本: $st_remote"
    fi
    
    echo ""
    
    # Nexus 版本
    echo -n "  Nexus: v$NEXUS_VERSION"
    
    # 获取远程版本（会自动使用缓存或刷新）
    local nexus_remote=$(get_nexus_remote_version)
    if [ -n "$nexus_remote" ]; then
        if [ "$NEXUS_VERSION" == "$nexus_remote" ]; then
            colorize "  ✓ 最新" "$COLOR_GREEN"
        else
            colorize "  ⚠ 有更新 (v$nexus_remote)" "$COLOR_YELLOW"
        fi
    else
        echo ""
    fi
    
    # 显示缓存状态（调试用，可选）
    # local cache_time=$(get_cache_remaining_time "$CACHE_DIR/nexus_version")
    # echo -e "${COLOR_GRAY}  (缓存: $cache_time)${COLOR_RESET}"
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
