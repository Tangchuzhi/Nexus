#!/data/data/com.termux/files/usr/bin/bash
# SillyTavern 管理模块

ST_REPO="https://github.com/SillyTavern/SillyTavern.git"
SILLYTAVERN_DIR="$HOME/SillyTavern"

# 安装/更新 SillyTavern
st_install_update() {
    clear
    show_header
    
    if [ -d "$SILLYTAVERN_DIR" ]; then
        colorize "🔄 检测到已安装 SillyTavern" "$COLOR_YELLOW"
        echo ""
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
    show_info "开始安装 SillyTavern..."
    echo ""
    
    # 克隆仓库
    show_info "正在克隆仓库..."
    if ! git clone "$ST_REPO" "$SILLYTAVERN_DIR"; then
        show_error "克隆失败，请检查网络连接"
        return 1
    fi
    
    # 安装依赖
    show_info "正在安装依赖（可能需要几分钟）..."
    cd "$SILLYTAVERN_DIR" || {
        show_error "无法进入目录"
        return 1
    }
    
    if ! npm install --no-audit --no-fund; then
        show_error "依赖安装失败"
        show_warning "可能原因："
        echo "  1. 网络连接问题"
        echo "  2. Node.js 版本不兼容"
        echo "  3. 磁盘空间不足"
        return 1
    fi
    
    echo ""
    show_success "SillyTavern 安装完成！"
    show_info "使用 [2] SillyTavern 启动 来运行"
}

# 更新 SillyTavern
st_update() {
    show_info "开始更新 SillyTavern..."
    echo ""
    
    cd "$SILLYTAVERN_DIR" || {
        show_error "SillyTavern 目录不存在"
        return 1
    }
    
    # 拉取更新
    show_info "正在拉取最新代码..."
    if ! git pull; then
        show_error "更新失败"
        show_warning "可能原因："
        echo "  1. 网络连接问题"
        echo "  2. 本地有未提交的修改"
        echo ""
        show_info "建议：选择 [2] 重新安装"
        return 1
    fi
    
    # 更新依赖
    show_info "正在更新依赖..."
    npm install --no-audit --no-fund
    
    echo ""
    show_success "SillyTavern 更新完成！"
}

# 重新安装
st_reinstall() {
    show_warning "⚠️  即将重新安装 SillyTavern"
    echo ""
    echo "  这将删除："
    echo "  - SillyTavern 程序文件"
    echo "  - 所有配置和数据"
    echo ""
    
    if ! confirm_action "确认重新安装？"; then
        show_info "取消重新安装"
        return
    fi
    
    # 询问是否备份
    if confirm_action "是否先备份配置？"; then
        create_backup
        echo ""
    fi
    
    show_info "正在删除旧版本..."
    rm -rf "$SILLYTAVERN_DIR"
    
    # 重新安装
    st_install
}

# 启动 SillyTavern（简化版）
st_start() {
    clear
    show_header
    
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
    
    # 直接在前台运行（用户关闭 Termux 即停止）
    node server.js
    
    # 如果执行到这里，说明服务已停止
    show_info "SillyTavern 已停止"
}
