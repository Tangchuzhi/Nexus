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
        read -p "请选择: " choice
        
        case $choice in
            1) st_update ;;
            2) st_reinstall ;;
            0) return ;;
        esac
    else
        st_install
    fi
}

# 安装 SillyTavern
st_install() {
    show_info "开始安装 SillyTavern..."
    
    git clone "$ST_REPO" "$SILLYTAVERN_DIR" || {
        show_error "克隆失败，请检查网络"
        return 1
    }
    
    cd "$SILLYTAVERN_DIR"
    npm install --no-audit --no-fund || {
        show_error "依赖安装失败"
        return 1
    }
    
    show_success "SillyTavern 安装完成！"
}

# 更新 SillyTavern
st_update() {
    show_info "开始更新 SillyTavern..."
    
    cd "$SILLYTAVERN_DIR"
    git pull || {
        show_error "更新失败"
        return 1
    }
    
    npm install --no-audit --no-fund
    show_success "SillyTavern 更新完成！"
}

# 重新安装
st_reinstall() {
    show_warning "这将删除现有的 SillyTavern"
    read -p "确认继续？(y/n): " confirm
    [ "$confirm" != "y" ] && return
    
    rm -rf "$SILLYTAVERN_DIR"
    st_install
}

# 启动 SillyTavern
st_start() {
    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        show_error "SillyTavern 未安装"
        return 1
    fi
    
    if [ "$(get_st_status)" == "running" ]; then
        show_warning "SillyTavern 已在运行"
        return 0
    fi
    
    show_info "正在启动 SillyTavern..."
    cd "$SILLYTAVERN_DIR"
    
    # 使用 termux 或后台运行
    if command -v tmux &> /dev/null; then
        tmux new-session -d -s sillytavern "node server.js"
        show_success "SillyTavern 已在 termux 中启动"
        show_info "使用 'tmux attach -t sillytavern' 查看"
    else
        nohup node server.js > /dev/null 2>&1 &
        show_success "SillyTavern 已在后台启动"
    fi
    
    show_info "访问地址: http://127.0.0.1:8000"
}

# 停止 SillyTavern
st_stop() {
    pkill -f "node.*SillyTavern"
    show_success "SillyTavern 已停止"
}
