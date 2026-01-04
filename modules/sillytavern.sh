#!/data/data/com.termux/files/usr/bin/bash
# SillyTavern 管理模块

ST_REPO="https://github.com/SillyTavern/SillyTavern.git"
SILLYTAVERN_DIR="$HOME/SillyTavern"

# 安装/更新 SillyTavern
st_install_update() {
    clear
    show_header
    
    if [ -d "$SILLYTAVERN_DIR" ]; then
        show_submenu_header "SillyTavern 管理"
        
        echo "  [1] 更新到最新版本"
        echo "  [2] 重新安装"
        echo "  [0] 返回"
        echo ""
        
        read -p "$(colorize "请选择 [0-2]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) st_update ;;
            2) st_reinstall ;;
            0) return ;;
            *) show_error "无效选项" ;;
        esac
    else
        st_install
    fi
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
    show_info "使用 [2] SillyTavern 启动 来运行"
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

# 重新安装
st_reinstall() {
    clear
    show_header
    show_submenu_header "重新安装 SillyTavern"
    
    show_warning "即将重新安装 SillyTavern"
    echo ""
    echo "  这将删除："
    echo "  - SillyTavern 程序文件"
    echo "  - 所有配置和数据"
    echo ""
    
    if ! confirm_action "确认重新安装？"; then
        show_info "取消重新安装"
        echo ""
        read -p "按任意键继续..." -n 1
        return
    fi
    
    show_info "正在删除旧版本..."
    rm -rf "$SILLYTAVERN_DIR"
    
    # 重新安装
    st_install
}

# 启动 SillyTavern
st_start() {
    clear
    show_header
    show_submenu_header "启动 SillyTavern"
    
    # 检查是否已安装
    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        show_error "SillyTavern 未安装"
        echo ""
        show_info "请先选择 [1] 安装 SillyTavern"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi
    
    # 检查是否已运行
    if [ "$(get_st_status)" == "running" ]; then
        show_warning "SillyTavern 已在运行"
        echo ""
        show_success "访问地址: http://127.0.0.1:8000"
        echo ""
        read -p "按任意键继续..." -n 1
        return 0
    fi
    
    # 启动服务
    show_info "正在启动 SillyTavern..."
    echo ""
    
    cd "$SILLYTAVERN_DIR" || {
        show_error "无法进入目录"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    }
    
    # 前台运行
    node server.js
    
    # 如果执行到这里，说明服务已停止
    echo ""
    show_info "SillyTavern 已停止"
    echo ""
    read -p "按任意键继续..." -n 1
}
