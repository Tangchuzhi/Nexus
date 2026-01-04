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
        # 调用备份功能（需要在 settings.sh 中实现）
        create_backup
        echo ""
    fi
    
    show_info "正在删除旧版本..."
    rm -rf "$SILLYTAVERN_DIR"
    
    # 重新安装
    st_install
}

# 启动 SillyTavern
st_start() {
    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        show_error "SillyTavern 未安装"
        show_info "请先选择 [1] 安装 SillyTavern"
        return 1
    fi
    
    # 检查是否已运行
    if [ "$(get_st_status)" == "running" ]; then
        show_warning "SillyTavern 已在运行"
        echo ""
        echo "  [1] 重启 SillyTavern"
        echo "  [2] 停止 SillyTavern"
        echo "  [0] 返回"
        echo ""
        
        read -p "$(colorize "请选择 [0-2]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) st_stop; sleep 1; st_do_start ;;
            2) st_stop ;;
            0) return ;;
        esac
        return
    fi
    
    st_do_start
}

# 执行启动
st_do_start() {
    show_info "正在启动 SillyTavern..."
    cd "$SILLYTAVERN_DIR" || return 1
    
    # 检查是否安装了 termux
    if command -v tmux &> /dev/null; then
        # 使用 termux 启动
        tmux new-session -d -s sillytavern "node server.js"
        show_success "SillyTavern 已在 tmux 会话中启动"
        echo ""
        show_info "管理命令："
        echo "  查看日志: tmux attach -t sillytavern"
        echo "  退出查看: 按 Ctrl+B 然后按 D"
        echo "  停止服务: 在 Nexus 中选择停止"
    else
        # 后台启动
        nohup node server.js > "$HOME/.nexus/st.log" 2>&1 &
        show_success "SillyTavern 已在后台启动"
        echo ""
        show_info "查看日志: cat ~/.nexus/st.log"
    fi
    
    echo ""
    show_success "访问地址: http://127.0.0.1:8000"
}

# 停止 SillyTavern
st_stop() {
    show_info "正在停止 SillyTavern..."
    
    # 停止进程
    pkill -f "node.*server.js"
    
    # 停止 tmux 会话
    tmux kill-session -t sillytavern 2>/dev/null
    
    sleep 1
    
    if [ "$(get_st_status)" == "stopped" ]; then
      show_success "SillyTavern 已停止"
    else
        show_warning "停止失败，可能需要手动终止进程"
    fi
}
