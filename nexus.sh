#!/data/data/com.termux/files/usr/bin/bash
# Nexus - SillyTavern 管理终端

# 获取脚本真实路径
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
NEXUS_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# 从 VERSION 文件读取版本号
NEXUS_VERSION=$(cat "$NEXUS_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || echo "未知版本")

# 加载核心模块
source "$NEXUS_DIR/core/ui.sh" || { echo "错误: 无法加载 ui.sh"; exit 1; }
source "$NEXUS_DIR/core/utils.sh" || { echo "错误: 无法加载 utils.sh"; exit 1; }
source "$NEXUS_DIR/core/version.sh" || { echo "错误: 无法加载 version.sh"; exit 1; }

# 加载功能模块
source "$NEXUS_DIR/modules/sillytavern.sh" || { echo "错误: 无法加载 sillytavern.sh"; exit 1; }
source "$NEXUS_DIR/modules/settings.sh" || { echo "错误: 无法加载 settings.sh"; exit 1; }

# 加载配置
source "$NEXUS_DIR/config/nexus.conf" || { echo "错误: 无法加载 nexus.conf"; exit 1; }

# 主菜单
main_menu() {
    while true; do
        clear
        show_header
        show_version_info  # 每次显示时自动检查缓存，过期则刷新
        echo ""
        show_menu_options
        echo ""
        
        read -p "$(colorize "请选择操作 [0-4]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) st_install_update ;;
            2) st_start ;;
            3) nexus_update ;;
            4) settings_menu ;;
            0) exit 0 ;;
            *) show_error "无效选项" ;;
        esac
        
        read -p "按任意键继续..." -n 1
    done
}

# Nexus 更新/重装
nexus_update() {
    clear
    show_header
    colorize "🔄 Nexus 更新" "$COLOR_CYAN"
    echo "───────────────────────────────────────"
    echo ""
    echo "  当前版本: v$NEXUS_VERSION"
    
    # 强制刷新远程版本
    show_info "正在检查更新..."
    rm -f "$NEXUS_DIR/.cache/nexus_version"
    local remote_version=$(get_nexus_remote_version)
    
    if [ -n "$remote_version" ]; then
        echo "  最新版本: v$remote_version"
        
        if [ "$NEXUS_VERSION" == "$remote_version" ]; then
            echo ""
            show_success "已是最新版本"
        fi
    else
        show_warning "无法获取远程版本信息"
    fi
    
    echo ""
    echo "  [1] 更新到最新版本"
    echo "  [2] 重新安装"
    echo "  [0] 返回"
    echo ""
    
    read -p "$(colorize "请选择 [0-2]: " "$COLOR_CYAN")" choice
    
    case $choice in
        1) nexus_do_update ;;
        2) nexus_reinstall ;;
        0) return ;;
    esac
}

# 执行更新
nexus_do_update() {
    show_info "开始更新 Nexus..."
    cd "$NEXUS_DIR"
    git pull origin main || {
        show_error "更新失败，请检查网络"
        return 1
    }
    chmod +x nexus.sh
    show_success "Nexus 更新完成！"
    show_info "请重新启动 Nexus 以应用更新"
    if confirm_action "是否立即重启？"; then
        exec "$NEXUS_DIR/nexus.sh"
    fi
}

# 重新安装
nexus_reinstall() {
    show_warning "这将重新下载 Nexus，当前配置将保留"
    if ! confirm_action "确认重新安装？"; then
        return
    fi
    local backup_conf="/tmp/nexus.conf.bak"
    [ -f "$NEXUS_DIR/config/nexus.conf" ] && cp "$NEXUS_DIR/config/nexus.conf" "$backup_conf"
    cd "$HOME"
    rm -rf "$NEXUS_DIR"
    git clone https://github.com/Tangchuzhi/Nexus.git "$NEXUS_DIR"
    [ -f "$backup_conf" ] && cp "$backup_conf" "$NEXUS_DIR/config/nexus.conf"
    chmod +x "$NEXUS_DIR/nexus.sh"
    ln -sf "$NEXUS_DIR/nexus.sh" "$PREFIX/bin/nexus"
    show_success "Nexus 重新安装完成！"
    if confirm_action "是否立即重启？"; then
        exec "$NEXUS_DIR/nexus.sh"
    fi
}

# 启动程序
init_nexus
main_menu
