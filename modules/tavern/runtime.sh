#!/data/data/com.termux/files/usr/bin/bash
# SillyTavern 运行时管理模块

# 启动 SillyTavern
st_start() {
    clear
    show_header
    show_submenu_header "启动 SillyTavern"
    
    # 检查是否已安装
    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        show_error "SillyTavern 未安装"
        echo ""
        show_info "请先选择 [2] SillyTavern 管理 → [1] 首次安装"
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

# 获取 SillyTavern 状态
get_st_status() {
    if pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "running"
    else
        echo "stopped"
    fi
}
