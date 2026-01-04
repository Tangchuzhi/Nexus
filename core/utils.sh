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

# 检查依赖（简单版，仅用于初始化）
check_dependencies() {
    local missing_deps=()
    
    for cmd in git node npm jq curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        show_error "缺少依赖: ${missing_deps[*]}"
        show_info "正在自动安装依赖..."
        
        pkg update -y || show_error "pkg update 失败"
        pkg install -y git nodejs jq curl || {
            show_error "依赖安装失败"
            show_warning "请手动执行: pkg install git nodejs jq curl"
            exit 1
        }
        
        show_success "依赖安装完成"
    fi
}

# 详细检查依赖（供故障排查使用）
check_dependencies_detailed() {
    colorize "📦 依赖检查" "$COLOR_CYAN"
    
    local all_ok=true
    
    # Git
    if command -v git &> /dev/null; then
        show_success "✓ Git: $(git --version | cut -d' ' -f3)"
    else
        show_error "✗ Git: 未安装"
        show_warning "  原因: 缺少 Git 工具，无法克隆仓库"
        show_info "  解决: 选择 [3] 重新安装依赖"
        all_ok=false
    fi
    
    # Node.js
    if command -v node &> /dev/null; then
        show_success "✓ Node.js: $(node --version)"
    else
        show_error "✗ Node.js: 未安装"
        show_warning "  原因: 缺少 Node.js 运行环境"
        show_info "  解决: 选择 [3] 重新安装依赖"
        all_ok=false
    fi
    
    # npm
    if command -v npm &> /dev/null; then
        show_success "✓ npm: $(npm --version)"
    else
        show_error "✗ npm: 未安装"
        show_warning "  原因: 缺少 npm 包管理器"
        show_info "  解决: 选择 [3] 重新安装依赖"
        all_ok=false
    fi
    
    # jq
    if command -v jq &> /dev/null; then
        show_success "✓ jq: $(jq --version | cut -d'-' -f2)"
    else
        show_error "✗ jq: 未安装"
        show_warning "  原因: 缺少 JSON 解析工具"
        show_info "  解决: 选择 [3] 重新安装依赖"
        all_ok=false
    fi
    
    # curl
    if command -v curl &> /dev/null; then
        show_success "✓ curl: $(curl --version | head -1 | cut -d' ' -f2)"
    else
        show_error "✗ curl: 未安装"
        show_warning "  原因: 缺少网络请求工具"
        show_info "  解决: 选择 [3] 重新安装依赖"
        all_ok=false
    fi
    
    if [ "$all_ok" == false ]; then
        echo ""
        show_error "发现缺失依赖，请重新安装"
    fi
}

# 重新安装依赖
reinstall_dependencies() {
    show_info "开始重新安装依赖..."
    
    pkg update -y
    pkg install -y git nodejs jq curl
    
    show_success "依赖安装完成"
    show_info "请重新运行故障排查"
}

# 设置存储权限
setup_storage() {
    show_info "正在请求存储权限..."
    termux-setup-storage
    sleep 2
    
    if [ -d "/sdcard" ] && [ -r "/sdcard" ]; then
        show_success "存储权限设置成功"
    else
        show_error "存储权限设置失败"
        show_warning "请在手机设置中手动授予 Termux 存储权限"
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

# 安全创建目录
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

# 打开 URL（Termux）
open_url() {
    local url="$1"
    if command -v termux-open-url &> /dev/null; then
        termux-open-url "$url"
    else
        show_info "请手动访问: $url"
    fi
}
