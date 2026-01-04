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
    
    # 克隆仓库
    show_loading "正在克隆仓库"
    if ! git clone "$ST_REPO" "$SILLYTAVERN_DIR" 2>&1 | grep -v "^Cloning"; then
        show_error "克隆失败，请检查网络连接"
        return 1
    fi
    
    # 安装依赖
    show_loading "正在安装依赖（可能需要几分钟）"
    cd "$SILLYTAVERN_DIR" || {
        show_error "无法进入目录"
        return 1
    }
    
    if ! npm install --no-audit --no-fund --silent 2>&1 | grep -E "error|warn"; then
        :  # 静默安装
    fi
    
    echo ""
    show_success "SillyTavern 安装完成！"
    show_info "使用 [2] SillyTavern 启动 来运行"
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
        return 1
    }
    
    # 拉取更新
    show_loading "正在拉取最新代码"
    if ! git pull 2>&1 | grep -v "^Already"; then
        show_error "更新失败"
        return 1
    fi
    
    # 更新依赖
    show_loading "正在更新依赖"
    npm install --no-audit --no-fund --silent 2>&1 | grep -E "error|warn"
    
    echo ""
    show_success "SillyTavern 更新完成！"
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
        return 1
    fi
    
    # 检查是否已运行
    if [ "$(get_st_status)" == "running" ]; then
        show_warning "SillyTavern 已在运行"
        echo ""
        show_success "访问地址: http://127.0.0.1:8000"
        return 0
    fi
    
    # 启动服务
    show_info "正在启动 SillyTavern..."
    echo ""
    
    cd "$SILLYTAVERN_DIR" || {
        show_error "无法进入目录"
        return 1
    }
    
    # 前台运行
    node server.js
    
    # 如果执行到这里，说明服务已停止
    show_info "SillyTavern 已停止"
}
