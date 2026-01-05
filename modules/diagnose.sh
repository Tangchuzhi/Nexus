#!/data/data/com.termux/files/usr/bin/bash
# 故障诊断模块

# 故障排查菜单
troubleshoot_menu() {
    clear
    show_header
    colorize "🔧 故障诊断" "$COLOR_BOLD"
    echo ""
    
    # 检查存储权限
    check_storage_permission
    echo ""
    
    # 检查依赖状态
    check_dependencies_detailed
    echo ""
    
    # 显示路径信息
    show_path_info
    echo ""

    # 显示缓存状态
    show_cache_status
    echo ""
    
    echo ""
    echo "  [1] 设置 Termux 存储权限"
    echo "  [2] 强制刷新版本信息"
    echo "  [3] 重新安装依赖"
    echo "  [0] 返回"
    echo ""
    
    read -p "$(colorize "请选择 [0-3]: " "$COLOR_CYAN")" choice
    
    case $choice in
        1) setup_storage ;;
        2) refresh_version_cache 
           show_info "版本信息已更新，将在下次启动 Nexus 时生效"
           ;;
        3) reinstall_dependencies ;;
        0) return ;;
    esac
    
    read -p "按任意键继续..." -n 1
}

# 检查存储权限
check_storage_permission() {
    colorize "📁 存储权限检查" "$COLOR_CYAN"
    
    if [ -d "/sdcard" ] && [ -r "/sdcard" ]; then
        show_success "✓ 存储权限正常"
    else
        show_error "✗ 未授予存储权限"
        show_warning "  原因: Termux 无法访问手机存储"
        show_info "  解决: 选择 [1] 设置存储权限"
    fi
}

# 详细检查依赖
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

# 显示路径信息
show_path_info() {
    colorize "📂 安装路径" "$COLOR_CYAN"
    
    echo "  Nexus: $NEXUS_DIR"
    
    if [ -d "$SILLYTAVERN_DIR" ]; then
        echo "  SillyTavern: $SILLYTAVERN_DIR"
    else
        echo "  SillyTavern: 未安装"
    fi
    
    echo "  备份: $BACKUP_DIR"
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

# 重新安装依赖
reinstall_dependencies() {
    show_info "开始重新安装依赖..."
    
    pkg update -y
    pkg install -y git nodejs jq curl
    
    show_success "依赖安装完成"
    show_info "请重新运行故障排查"
}

# 显示缓存状态
show_cache_status() {
    colorize "🕐 版本缓存状态" "$COLOR_CYAN"
    
    if [ -f "$CACHE_DIR/st_version" ]; then
        echo "  SillyTavern: 已缓存"
    else
        echo "  SillyTavern: 未缓存"
    fi
    
    if [ -f "$CACHE_DIR/nexus_version" ]; then
        echo "  Nexus: 已缓存"
    else
        echo "  Nexus: 未缓存"
    fi
}
