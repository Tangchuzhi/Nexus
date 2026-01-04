#!/data/data/com.termux/files/usr/bin/bash
# 核心工具函数

# 初始化 Nexus
init_nexus() {
    # 创建必要目录
    mkdir -p "$NEXUS_DIR/.cache"
    mkdir -p "$HOME/.nexus/backups"
    
    # 初始化版本缓存
    init_version_cache
    
    # 检查核心依赖
    check_dependencies
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    for cmd in git node npm jq curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        show_error "缺少依赖: ${missing_deps[*]}"
        show_info "正在安装依赖..."
        pkg install -y git nodejs jq curl || {
            show_error "依赖安装失败，请手动执行: pkg install git nodejs jq curl"
            exit 1
        }
    fi
}

# 确认提示
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$default" == "y" ]; then
        read -p "$(colorize "$message (Y/n): " "$COLOR_YELLOW")" answer
        answer=${answer:-y}
    else
        read -p "$(colorize "$message (y/N): " "$COLOR_YELLOW")" answer
        answer=${answer:-n}
    fi
    
    [[ "$answer" =~ ^[Yy]$ ]]
}

# 创建目录（安全）
safe_mkdir() {
    mkdir -p "$1" 2>/dev/null || {
        show_error "无法创建目录: $1"
        return 1
    }
}

# 安全删除目录
safe_remove_dir() {
    local dir="$1"
    local name="${2:-该目录}"
    
    if [ ! -d "$dir" ]; then
        show_warning "$name 不存在"
        return 0
    fi
    
    if confirm_action "确认删除 $name？此操作不可恢复"; then
        rm -rf "$dir"
        show_success "$name 已删除"
        return 0
    else
        show_info "取消删除"
        return 1
    fi
}
