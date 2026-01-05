#!/data/data/com.termux/files/usr/bin/bash
# SillyTavern 生命周期管理模块

ST_REPO="https://github.com/SillyTavern/SillyTavern.git"
SILLYTAVERN_DIR="$HOME/SillyTavern"

# SillyTavern 管理菜单
st_management_menu() {
    clear
    show_header
    show_submenu_header "SillyTavern 管理"
    
    if [ -d "$SILLYTAVERN_DIR" ]; then
        echo "  [1] 更新 SillyTavern"
        echo "  [2] 卸载 SillyTavern"
        echo "  [0] 返回"
        echo ""
        
        read -p "$(colorize "请选择 [0-2]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) st_update ;;
            2) st_uninstall ;;
            0) return ;;
            *) show_error "无效选项" ;;
        esac
    else
        echo "  [1] 首次安装"
        echo "  [0] 返回"
        echo ""
        
        read -p "$(colorize "请选择 [0-1]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) st_install ;;
            0) return ;;
            *) show_error "无效选项" ;;
        esac
    fi
    
    read -p "按任意键继续..." -n 1
}

# 安装 SillyTavern
st_install() {
    clear
    show_header
    show_submenu_header "安装 SillyTavern"
    
    show_info "开始安装..."
    echo ""
    
    # 检查网络
    show_info "检查 GitHub 连接..."
    if ! ping -c 1 -W 5 github.com &> /dev/null; then
        show_error "无法连接到 GitHub"
        show_error "请检查网络连接或稍后重试"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi
    show_success "网络连接正常"
    echo ""
    
    # 克隆仓库
    show_info "正在克隆仓库（可能需要几分钟）..."
    echo ""
    
    if ! git clone "$ST_REPO" "$SILLYTAVERN_DIR"; then
        echo ""
        show_error "克隆失败！"
        echo ""
        show_info "建议："
        echo "  - 检查网络连接"
        echo "  - 使用科学上网工具"
        echo "  - 稍后重试"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi
    
    echo ""
    show_success "仓库克隆完成"
    echo ""
    
    # 安装依赖
    show_info "正在安装依赖（可能需要几分钟）..."
    echo ""
    
    cd "$SILLYTAVERN_DIR" || {
        show_error "无法进入目录: $SILLYTAVERN_DIR"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    }
    
    if ! npm install; then
        echo ""
        show_error "依赖安装失败"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi
    
    echo ""
    show_success "SillyTavern 安装完成！"
    show_info "使用 [1] SillyTavern 启动 来运行"
    echo ""
    read -p "按任意键继续..." -n 1
}

# 更新 SillyTavern
st_update() {
    clear
    show_header
    show_submenu_header "更新 SillyTavern"
    
    show_info "开始更新..."
    echo ""
    
    cd "$SILLYTAVERN_DIR" || {
        show_error "SillyTavern 目录不存在"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    }
    
    # 检查网络
    show_info "检查 GitHub 连接..."
    if ! ping -c 1 -W 5 github.com &> /dev/null; then
        show_error "无法连接到 GitHub，请检查网络"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi
    echo ""
    
    # 拉取更新
    show_info "正在拉取最新代码..."
    echo ""
    
    if ! git pull; then
        echo ""
        show_error "更新失败，请检查网络连接"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi
    
    echo ""
    show_info "正在更新依赖..."
    echo ""
    
    if ! npm install; then
        echo ""
        show_error "依赖更新失败"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi
    
    echo ""
    show_success "SillyTavern 更新完成！"
    echo ""
    read -p "按任意键继续..." -n 1
}

# 卸载 SillyTavern
st_uninstall() {
    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        show_warning "SillyTavern 未安装"
        return
    fi
    
    show_warning "⚠️  即将卸载 SillyTavern"
    echo ""
    echo "  这将删除："
    echo "  - SillyTavern 程序文件"
    echo "  - 所有配置和数据"
    echo ""
    
    if confirm_action "是否先备份配置？"; then
        backup_create
        echo ""
    fi
    
    if safe_remove_dir "$SILLYTAVERN_DIR" "SillyTavern"; then
        show_success "SillyTavern 已完全卸载"
    fi
}
