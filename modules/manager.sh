#!/data/data/com.termux/files/usr/bin/bash
# Nexus 管理模块

# Nexus 管理菜单
nexus_management_menu() {
    clear
    show_header
    show_submenu_header "Nexus 管理"
    
    echo "  当前版本: v$NEXUS_VERSION"
    echo "  最新版本: v${CACHED_NEXUS_REMOTE:-检查中...}"
    
    if [ -n "$CACHED_NEXUS_REMOTE" ]; then
        if [ "$NEXUS_VERSION" == "$CACHED_NEXUS_REMOTE" ]; then
            echo ""
            show_success "已是最新版本"
        fi
    else
        show_warning "无法获取远程版本信息"
    fi
    
    echo ""
    echo "  [1] 更新 Nexus"
    echo "  [2] 卸载 Nexus"
    echo "  [3] 自启动管理"
    echo "  [0] 返回"
    echo ""
    
    read -p "$(colorize "请选择 [0-3]: " "$COLOR_CYAN")" choice
    
    case $choice in
        1) nexus_update ;;
        2) nexus_uninstall ;;
        3) nexus_autostart_menu ;;
        0) return ;;
    esac
}

# 更新设置菜单
nexus_settings_menu() {
    while true; do
        clear
        show_header
        show_submenu_header "更新设置"

        local cfg_label
        if [ "$AUTO_PRESERVE_CONFIG" == "true" ]; then
            cfg_label="$(colorize "已开启" "$COLOR_GREEN")"
        else
            cfg_label="$(colorize "已关闭" "$COLOR_GRAY")"
        fi

        echo -e "  [1] 更新/回退时自动保留 config.yaml  [$cfg_label]"
        echo ""
        show_info "config.yaml 包含：端口、白名单、密码等自定义配置"
        show_info "开启后 git 操作不会覆盖你的设置"
        echo ""
        echo "  [0] 返回"
        echo ""

        read -p "$(colorize "请选择 [0-1]: " "$COLOR_CYAN")" choice
        case $choice in
            1) _toggle_preserve_config ;;
            0) return ;;
            *) show_error "无效选项"; sleep 1 ;;
        esac
    done
}

_toggle_preserve_config() {
    local conf_file="$NEXUS_DIR/config/nexus.conf"
    if [ "$AUTO_PRESERVE_CONFIG" == "true" ]; then
        AUTO_PRESERVE_CONFIG=false
        sed -i 's/^AUTO_PRESERVE_CONFIG=.*/AUTO_PRESERVE_CONFIG=false/' "$conf_file"
        show_warning "已关闭：更新/回退时不再自动保留 config.yaml"
    else
        AUTO_PRESERVE_CONFIG=true
        sed -i 's/^AUTO_PRESERVE_CONFIG=.*/AUTO_PRESERVE_CONFIG=true/' "$conf_file"
        show_success "已开启：更新/回退时将自动保留 config.yaml"
    fi
    sleep 1
}

# 执行更新
nexus_update() {
    show_info "开始更新 Nexus..."
    cd "$NEXUS_DIR"
    
    # 强制丢弃本地修改
    show_info "正在重置本地修改..."
    git reset --hard HEAD > /dev/null 2>&1
    git clean -fd > /dev/null 2>&1
    
    # 拉取最新版本
    show_info "正在拉取最新版本..."
    if git pull origin main; then
        chmod +x nexus.sh
        
        # 清除版本缓存，强制下次启动时重新获取
        rm -f "$NEXUS_DIR/.cache/nexus_version"
        rm -f "$NEXUS_DIR/.cache/st_version"
        
        show_success "Nexus 更新完成！"
        show_info "请重新启动 Nexus 以应用更新"
        
        if confirm_action "是否立即重启？"; then
            exec "$NEXUS_DIR/nexus.sh"
        fi
    else
        show_error "更新失败，请检查网络"
        return 1
    fi
}

# 卸载 Nexus
nexus_uninstall() {
    show_warning "⚠️  即将完全卸载 Nexus"
    echo ""
    echo "  这将删除："
    echo "  - Nexus 程序文件"
    echo "  - 所有配置和缓存"
    echo "  - Nexus 备份文件（可选）"
    echo ""
    
    if ! confirm_action "确认卸载 Nexus？此操作不可恢复"; then
        show_info "取消卸载"
        return
    fi
    
    # 询问是否保留备份
    local keep_backups=false
    if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        if confirm_action "是否保留 Nexus 备份文件？"; then
            keep_backups=true
        fi
    fi
    
    show_info "正在卸载 Nexus..."
    
    # 删除软链接
    rm -f "$PREFIX/bin/nexus"
    
    # 删除自启动配置
    local bashrc="$HOME/.bashrc"
    local autostart_marker="# Nexus Auto-Start"
    if grep -q "$autostart_marker" "$bashrc" 2>/dev/null; then
        sed -i "/$autostart_marker/,+3d" "$bashrc"
    fi
    
    # 删除备份（如果用户选择）
    if [ "$keep_backups" == false ]; then
        rm -rf "$HOME/.nexus"
    fi
    
    # 删除主程序
    rm -rf "$NEXUS_DIR"
    
    show_success "Nexus 已完全卸载"
    show_info "感谢使用 Nexus，晚安！"
    exit 0
}

# 自启动管理菜单
nexus_autostart_menu() {
    clear
    show_header
    colorize "🚀 自启动管理" "$COLOR_BOLD"
    echo ""
    
    # 检查当前状态
    local bashrc="$HOME/.bashrc"
    local autostart_marker="# Nexus Auto-Start"
    local is_enabled=false
    
    if grep -q "$autostart_marker" "$bashrc" 2>/dev/null; then
        is_enabled=true
    fi
    
    # 显示状态
    if [ "$is_enabled" == true ]; then
        show_success "当前状态: 已启用"
        echo ""
        echo "  每次打开 Termux 将自动启动 Nexus"
    else
        show_warning "当前状态: 已禁用"
        echo ""
        echo "  需要手动输入 'nexus' 启动"
    fi
    
    echo ""
    echo ""
    
    if [ "$is_enabled" == true ]; then
        echo "  [1] 禁用自启动"
    else
        echo "  [1] 启用自启动"
    fi
    echo "  [0] 返回"
    echo ""
    
    read -p "$(colorize "请选择 [0-1]: " "$COLOR_CYAN")" choice
    
    case $choice in
        1)
            if [ "$is_enabled" == true ]; then
                nexus_disable_autostart
            else
                nexus_enable_autostart
            fi
            ;;
        0) return ;;
    esac
}

# 启用自启动
nexus_enable_autostart() {
    local bashrc="$HOME/.bashrc"
    local autostart_marker="# Nexus Auto-Start"
    local autostart_code="$autostart_marker
if [ -f \"$PREFIX/bin/nexus\" ]; then
    nexus
fi"
    
    # 检查是否已存在
    if grep -q "$autostart_marker" "$bashrc" 2>/dev/null; then
        show_warning "自启动已启用"
        return
    fi
    
    # 添加自启动代码
    echo "" >> "$bashrc"
    echo "$autostart_code" >> "$bashrc"
    
    show_success "自启动已启用"
    show_info "下次打开 Termux 将自动启动 Nexus"
}

# 禁用自启动
nexus_disable_autostart() {
    local bashrc="$HOME/.bashrc"
    local autostart_marker="# Nexus Auto-Start"
    
    # 检查是否存在
    if ! grep -q "$autostart_marker" "$bashrc" 2>/dev/null; then
        show_warning "自启动未启用"
        return
    fi
    
    # 删除自启动代码（删除标记行及其后3行）
    sed -i "/$autostart_marker/,+3d" "$bashrc"
    
    show_success "自启动已禁用"
    show_info "下次打开 Termux 需要手动输入 'nexus' 启动"
}
