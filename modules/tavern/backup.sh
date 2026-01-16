#!/data/data/com.termux/files/usr/bin/bash
# 备份与恢复模块

BACKUP_DIR="$HOME/.nexus/backups"
ST_BACKUP_DIR="$SILLYTAVERN_DIR/backups"

# 备份与恢复菜单
backup_menu() {
    clear
    show_header
    show_submenu_header "备份与恢复"
    
    echo "  [1] 创建新备份"
    echo "  [2] 恢复备份"
    echo "  [3] 查看备份列表"
    echo "  [4] 删除备份"
    echo "  [0] 返回"
    echo ""
    
    read -p "$(colorize "请选择 [0-4]: " "$COLOR_CYAN")" choice
    
    case $choice in
        1) backup_create ;;
        2) backup_restore ;;
        3) backup_list ;;
        4) backup_delete ;;
        0) return ;;
    esac
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
backup_create() {
    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        show_error "SillyTavern 未安装"
        return 1
    fi
    
    clear
    show_header
    colorize "📦 创建备份" "$COLOR_CYAN"
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
backup_restore() {
    clear
    show_header
    colorize "♻️  恢复备份" "$COLOR_CYAN"
    echo ""
    
    # 列出所有备份
    backup_list_all
    
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
backup_list_all() {
    local has_backup=false
    local index=1
    
    # Nexus备份
    if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        colorize "📦 Nexus 备份" "$COLOR_GREEN"
        
        for backup in $(ls -t "$BACKUP_DIR" | grep "^Nexus_"); do
            local backup_path="$BACKUP_DIR/$backup"
            local size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
            local date=$(echo "$backup" | sed 's/Nexus_//' | sed 's/_/ /' | sed 's/$[0-9]\{8\}$ $[0-9]\{6\}$/\1 \2/')
            
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
backup_list() {
    clear
    show_header
    colorize "📋 备份列表" "$COLOR_BOLD"
    echo ""
    
    backup_list_all
    
    read -p "按任意键返回..." -n 1
}

# 删除备份
backup_delete() {
    clear
    show_header
    colorize "🗑️  删除备份" "$COLOR_BOLD"
    echo ""
    
    backup_list_all
    
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
