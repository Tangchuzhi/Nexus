#!/data/data/com.termux/files/usr/bin/bash
# 系统设置模块

BACKUP_DIR="$HOME/.nexus/backups"
ST_BACKUP_DIR="$SILLYTAVERN_DIR/backups"

# 系统设置主菜单
settings_menu() {
    while true; do
        clear
        show_header
        show_submenu_header "系统设置"
        
        echo "  [1] 备份与恢复"
        echo "  [2] 卸载管理"
        echo "  [3] 自启动管理"
        echo "  [4] 故障排查"
        echo "  [0] 返回主菜单"
        echo ""
        
        read -p "$(colorize "请选择 [0-4]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) backup_menu ;;
            2) uninstall_menu ;;
            3) autostart_menu ;;
            4) troubleshoot_menu ;;
            0) return ;;
            *) show_error "无效选项" ;;
        esac
    done
}

# ============================================
# 备份与恢复
# ============================================

backup_menu() {
    clear
    show_header
    colorize "💾 备份与恢复" "$COLOR_BOLD"
    echo "───────────────────────────────────────"
    echo ""
    echo "  [1] 创建新备份"
    echo "  [2] 恢复备份"
    echo "  [3] 查看备份列表"
    echo "  [4] 删除备份"
    echo "  [0] 返回"
    echo ""
    
    read -p "$(colorize "请选择 [0-4]: " "$COLOR_CYAN")" choice
    
    case $choice in
        1) create_backup ;;
        2) restore_backup ;;
        3) view_backup_list ;;
        4) delete_backup ;;
        0) return ;;
    esac
    
    read -p "按任意键继续..." -n 1
}

# 获取用户账户列表
get_st_users() {
    local data_dir="$SILLYTAVERN_DIR/data"
    if [ ! -d "$data_dir" ]; then
        return 1
    fi
    
    # 排除缓存文件夹，只获取用户目录
    find "$data_dir" -mindepth 1 -maxdepth 1 -type d \
        ! -name "_cache" \
        ! -name "_storage" \
        ! -name "_uploads" \
        ! -name "_webpack" \
        -exec basename {} \;
}

# 创建新备份
create_backup() {
    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        show_error "SillyTavern 未安装"
        return 1
    fi
    
    clear
    show_header
    colorize "📦 创建备份" "$COLOR_CYAN"
    echo "───────────────────────────────────────"
    echo ""
    
    # 获取用户列表
    local users=($(get_st_users))
    
    if [ ${#users[@]} -eq 0 ]; then
        show_warning "未检测到用户数据"
        return 1
    fi
    
    # 显示用户列表
    show_info "检测到以下用户账户："
    echo ""
    local index=1
    for user in "${users[@]}"; do
        echo "  [$index] $user"
        ((index++))
    done
    echo "  [0] 备份所有账户"
    echo ""
    
    read -p "$(colorize "请选择要备份的账户 [0-${#users[@]}]: " "$COLOR_CYAN")" choice
    
    # 确定要备份的账户
    local selected_users=()
    if [ "$choice" == "0" ]; then
        selected_users=("${users[@]}")
        show_info "将备份所有账户"
    elif [ "$choice" -ge 1 ] && [ "$choice" -le "${#users[@]}" ]; then
        selected_users=("${users[$((choice-1))]}")
        show_info "将备份账户: ${selected_users[0]}"
    else
        show_error "无效选择"
        return 1
    fi
    
    # 创建备份
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="Nexus_${timestamp}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    show_info "开始备份..."
    safe_mkdir "$backup_path"
    
    # 备份用户数据
    for user in "${selected_users[@]}"; do
        local user_data="$SILLYTAVERN_DIR/data/$user"
        if [ -d "$user_data" ]; then
            mkdir -p "$backup_path/data"
            cp -r "$user_data" "$backup_path/data/"
            show_success "✓ 备份用户: $user"
        fi
    done
    
    # 备份公共插件
    local extensions_dir="$SILLYTAVERN_DIR/public/scripts/extensions/third-party"
    if [ -d "$extensions_dir" ]; then
        mkdir -p "$backup_path/extensions"
        cp -r "$extensions_dir" "$backup_path/extensions/"
        show_success "✓ 备份公共插件"
    fi
    
    # 备份全局配置
    if [ -f "$SILLYTAVERN_DIR/config.yaml" ]; then
        cp "$SILLYTAVERN_DIR/config.yaml" "$backup_path/"
        show_success "✓ 备份全局配置"
    fi
    
    # 创建备份信息文件
    cat > "$backup_path/backup_info.txt" << EOF
备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份来源: Nexus 自动备份
SillyTavern 版本: $(get_st_local_version)
备份账户: ${selected_users[*]}

备份内容:
  - 用户数据 (data/)
  - 公共插件 (extensions/third-party/)
  - 全局配置 (config.yaml)
EOF
    
    local backup_size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
    echo ""
    show_success "备份完成！"
    show_info "备份位置: $backup_path"
    show_info "备份大小: $backup_size"
}

# 恢复备份
restore_backup() {
    clear
    show_header
    colorize "♻️  恢复备份" "$COLOR_CYAN"
    echo "───────────────────────────────────────"
    echo ""
    
    # 列出所有备份
    list_all_backups
    
    echo ""
    read -p "请输入要恢复的备份编号 (0取消): " choice
    
    if [ "$choice" == "0" ]; then
        return
    fi
    
    # 获取备份信息
    local all_backups=($(get_all_backup_names))
    local selected_backup="${all_backups[$((choice-1))]}"
    
    if [ -z "$selected_backup" ]; then
        show_error "无效的备份编号"
        return 1
    fi
    
    # 确定备份路径
    local backup_path=""
    if [[ "$selected_backup" == Nexus_* ]]; then
        backup_path="$BACKUP_DIR/$selected_backup"
    else
        backup_path="$ST_BACKUP_DIR/$selected_backup"
    fi
    
    if [ ! -d "$backup_path" ]; then
        show_error "备份不存在"
        return 1
    fi
    
    # 显示备份信息
    echo ""
    if [ -f "$backup_path/backup_info.txt" ]; then
        colorize "📋 备份信息:" "$COLOR_YELLOW"
        cat "$backup_path/backup_info.txt"
        echo ""
    fi
    
    if ! confirm_action "确认恢复此备份？当前配置将被覆盖"; then
        show_info "取消恢复"
        return
    fi
    
    show_info "正在恢复备份..."
    
    # 恢复用户数据
    if [ -d "$backup_path/data" ]; then
        cp -r "$backup_path/data"/* "$SILLYTAVERN_DIR/data/"
        show_success "✓ 恢复用户数据"
    fi
    
    # 恢复公共插件
    if [ -d "$backup_path/extensions/third-party" ]; then
        mkdir -p "$SILLYTAVERN_DIR/public/scripts/extensions"
        cp -r "$backup_path/extensions/third-party" "$SILLYTAVERN_DIR/public/scripts/extensions/"
        show_success "✓ 恢复公共插件"
    fi
    
    # 恢复全局配置
    if [ -f "$backup_path/config.yaml" ]; then
        cp "$backup_path/config.yaml" "$SILLYTAVERN_DIR/"
        show_success "✓ 恢复全局配置"
    fi
    
    echo ""
    show_success "恢复完成！"
}

# 获取所有备份名称
get_all_backup_names() {
    # Nexus备份
    [ -d "$BACKUP_DIR" ] && ls -t "$BACKUP_DIR" 2>/dev/null | grep "^Nexus_"
    
    # ST自带备份
    [ -d "$ST_BACKUP_DIR" ] && ls -t "$ST_BACKUP_DIR" 2>/dev/null
}

# 列出所有备份
list_all_backups() {
    local has_backup=false
    local index=1
    
    # Nexus备份
    if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        colorize "📦 Nexus 备份" "$COLOR_GREEN"
        echo "───────────────────────────────────────"
        
        for backup in $(ls -t "$BACKUP_DIR" | grep "^Nexus_"); do
            local backup_path="$BACKUP_DIR/$backup"
            local size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
            local date=$(echo "$backup" | sed 's/Nexus_//' | sed 's/_/ /' | sed 's/\([0-9]\{8\}\) \([0-9]\{6\}\)/\1 \2/')
            
            echo "  [$index] $date (大小: $size)"
            
            if [ -f "$backup_path/backup_info.txt" ]; then
                grep "备份账户:" "$backup_path/backup_info.txt" | sed 's/^/      /'
            fi
            
            ((index++))
            has_backup=true
        done
        echo ""
    fi
    
    # ST自带备份
    if [ -d "$ST_BACKUP_DIR" ] && [ -n "$(ls -A "$ST_BACKUP_DIR" 2>/dev/null)" ]; then
        colorize "🎭 SillyTavern 自带备份" "$COLOR_CYAN"
        echo "───────────────────────────────────────"
        
        for backup in $(ls -t "$ST_BACKUP_DIR"); do
            local backup_path="$ST_BACKUP_DIR/$backup"
            local size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
            
            echo "  [$index] $backup (大小: $size)"
            ((index++))
            has_backup=true
        done
        echo ""
    fi
    
    if [ "$has_backup" == false ]; then
        show_warning "暂无备份"
    fi
}

# 查看备份列表
view_backup_list() {
    clear
    show_header
    colorize "📋 备份列表" "$COLOR_BOLD"
    echo "───────────────────────────────────────"
    echo ""
    
    list_all_backups
    
    read -p "按任意键返回..." -n 1
}

# 删除备份
delete_backup() {
    clear
    show_header
    colorize "🗑️  删除备份" "$COLOR_BOLD"
    echo "───────────────────────────────────────"
    echo ""
    
    list_all_backups
    
    echo ""
    read -p "请输入要删除的备份编号 (0取消): " choice
    
    if [ "$choice" == "0" ]; then
        return
    fi
    
    local all_backups=($(get_all_backup_names))
    local selected_backup="${all_backups[$((choice-1))]}"
    
    if [ -z "$selected_backup" ]; then
        show_error "无效的备份编号"
        return 1
    fi
    
    # 确定备份路径
    local backup_path=""
    if [[ "$selected_backup" == Nexus_* ]]; then
        backup_path="$BACKUP_DIR/$selected_backup"
    else
        backup_path="$ST_BACKUP_DIR/$selected_backup"
    fi
    
    if ! confirm_action "确认删除备份 $selected_backup？"; then
        show_info "取消删除"
        return
    fi
    
    rm -rf "$backup_path"
    show_success "备份已删除"
}

# ============================================
# 卸载管理
# ============================================

uninstall_menu() {
    clear
    show_header
    colorize "🗑️  卸载管理" "$COLOR_BOLD"
    echo "───────────────────────────────────────"
    echo ""
    echo "  [1] 卸载 SillyTavern"
    echo "  [2] 卸载 Nexus"
    echo "  [0] 返回"
    echo ""
    
    read -p "$(colorize "请选择 [0-2]: " "$COLOR_CYAN")" choice
    
    case $choice in
        1) uninstall_sillytavern ;;
        2) uninstall_nexus ;;
        0) return ;;
    esac
    
    read -p "按任意键继续..." -n 1
}

# 卸载 SillyTavern
uninstall_sillytavern() {
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
        create_backup
        echo ""
    fi
    
    if safe_remove_dir "$SILLYTAVERN_DIR" "SillyTavern"; then
        show_success "SillyTavern 已完全卸载"
    fi
}

# 卸载 Nexus
uninstall_nexus() {
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

# ============================================
# 自启动管理
# ============================================

autostart_menu() {
    clear
    show_header
    colorize "🚀 自启动管理" "$COLOR_BOLD"
    echo "───────────────────────────────────────"
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
    echo "───────────────────────────────────────"
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
                disable_autostart
            else
                enable_autostart
            fi
            ;;
        0) return ;;
    esac
    
    read -p "按任意键继续..." -n 1
}

# 启用自启动
enable_autostart() {
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
disable_autostart() {
    local bashrc="$HOME/.bashrc"
    local autostart_marker="# Nexus Auto-Start"
    
    # 检查是否存在
    if ! grep -q "$autostart_marker" "$bashrc" 2>/dev/null; then
        show_warning "自启动未启用"
        return
    fi
    
    # 删除自启动代码（删除标记行及其后3行）
    sed -i "/$autostart_marker/,+3d" "$bashrc"
    
    show_success "自启动用"
    show_info "下次打开 Termux 需要手动输入 'nexus' 启动"
}


# ============================================
# 故障排查
# ============================================

troubleshoot_menu() {
    clear
    show_header
    colorize "🔧 故障排查" "$COLOR_BOLD"
    echo "───────────────────────────────────────"
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
    
    echo "───────────────────────────────────────"
    echo ""
    echo "  [1] 设置 Termux 存储权限"
    echo "  [2] 强制刷新版本信息"
    echo "  [3] 重新安装依赖"
    echo "  [0] 返回"
    echo ""
    
    read -p "$(colorize "请选择 [0-3]: " "$COLOR_CYAN")" choice
    
    case $choice in
        1) setup_storage ;;
        2) refresh_version_cache ;;
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
    
    local st_cache_time=$(get_cache_remaining_time "$CACHE_DIR/st_version")
    local nexus_cache_time=$(get_cache_remaining_time "$CACHE_DIR/nexus_version")
    
    echo "  SillyTavern: $st_cache_time"
    echo "  Nexus: $nexus_cache_time"
    echo ""
    echo "  缓存有效期: 1小时"
}
