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

# 获取文件大小
get_readable_size() {
    local size=$1
    if [ $size -lt 1024 ]; then
        echo "${size}B"
    elif [ $size -lt 1048576 ]; then
        echo "$((size / 1024))KB"
    else
        echo "$((size / 1048576))MB"
    fi
}

# 检查磁盘空间（MB）
check_disk_space() {
    local required_mb=$1
    local available_mb=$(df "$HOME" | awk 'NR==2 {print int($4/1024)}')
    
    if [ $available_mb -lt $required_mb ]; then
        show_error "磁盘空间不足，需要 ${required_mb}MB，可用 ${available_mb}MB"
        return 1
    fi
    return 0
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

# 打开 URL（Termux）
open_url() {
    local url="$1"
    if command -v termux-open-url &> /dev/null; then
        termux-open-url "$url"
    else
        show_info "请手动访问: $url"
    fi
}
