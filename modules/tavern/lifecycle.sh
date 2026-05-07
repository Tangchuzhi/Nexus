#!/data/data/com.termux/files/usr/bin/bash
# SillyTavern 生命周期管理模块

ST_REPO="https://github.com/SillyTavern/SillyTavern.git"
SILLYTAVERN_DIR="$HOME/SillyTavern"

# ==========================================
# 新增：许可协议显示函数
# ==========================================
show_license_agreement() {
    clear
    # 定义局部颜色变量，确保颜色准确显示
    local C_RESET='\033[0m'
    local C_CYAN='\033[0;36m'
    local C_WHITE='\033[1;37m'
    local C_YELLOW='\033[1;33m'
    local C_BLUE='\033[1;34m'
    local C_RED='\033[1;31m'

    echo -e "${C_CYAN}===================================================${C_RESET}"
    echo -e "${C_WHITE}         Nexus Installer${C_RESET}"
    echo -e "${C_CYAN}===================================================${C_RESET}"
    echo ""
    echo -e "${C_YELLOW} 【开源协议说明】${C_RESET}"
    echo -e " 本封装/安装脚本采用 CC BY-NC-ND 4.0 协议发布："
    echo -e " - 署名(BY)：必须提到作者“唐初稚”，发布“游鹿小岛”。"
    echo -e " - 非商业(NC)：禁止任何形式的商业化销售或营利。"
    echo -e " - 禁止演绎(ND)：不允许分发修改后的二次封装版本。"
    echo ""
    echo -e "${C_BLUE} 【署名】${C_RESET}"
    echo -e " 作者：唐初稚 (Discord)"
    echo -e " 发布：游鹿小岛"
    echo ""
    echo -e "${C_RED} 【重要警告】${C_RESET}"
    echo -e " 本脚本完全免费！若你是购买所得，请立刻退款并举报。"
    echo ""
    echo -e "${C_CYAN}===================================================${C_RESET}"
    echo ""

    # 交互确认
    local choice
    read -p "是否接受上述协议并继续安装？[y/N]: " choice
    case "$choice" in 
        y|Y) return 0 ;; # 返回成功状态
        *) return 1 ;;   # 返回失败状态
    esac
}

# SillyTavern 管理菜单
st_management_menu() {
    clear
    show_header
    show_submenu_header "SillyTavern 管理"
    
    if [ -d "$SILLYTAVERN_DIR" ]; then
        echo "  [1] 更新 SillyTavern"
        echo "  [2] 回退到旧版本"
        echo "  [3] 更新设置"
        echo "  [4] 卸载 SillyTavern"
        echo "  [0] 返回"
        echo ""
        
        read -p "$(colorize "请选择 [0-4]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) st_update ;;
            2) st_rollback ;;
            3) nexus_settings_menu ;;
            4) st_uninstall ;;
            0) return ;;
            *) show_error "无效选项" ;;
        esac
    else
        echo "  [1] 首次安装"
        echo "  [0] 返回"
        echo ""
        
        read -p "$(colorize "请选择 [0-1]: " "$COLOR_CYAN")" choice
        
        case $choice in
            1) st_install ;;
            0) return ;;
            *) show_error "无效选项" ;;
        esac
    fi
}

# 安装 SillyTavern
st_install() {
    # ==========================================
    # 修改：在安装开始前插入协议检查
    # ==========================================
    if ! show_license_agreement; then
        echo ""
        show_warning "用户拒绝了协议，安装已取消。"
        echo ""
        read -p "按任意键返回..." -n 1
        return 1
    fi
    # ==========================================

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
    
    # 🔧 修复：切换到安全的工作目录
    cd "$HOME" || {
        show_error "无法切换到主目录"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    }
    
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
    show_info "返回主菜单，选择 [1] SillyTavern 启动 即可运行"
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
    
    # 🔧 修复：先切换到安全目录，再进入 ST 目录
    cd "$HOME" || {
        show_error "无法切换到主目录"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    }
    
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
    
    # 保存 config.yaml（如果开启了自动保留）
    local saved_config=""
    if [ "$AUTO_PRESERVE_CONFIG" == "true" ] && [ -f "$SILLYTAVERN_DIR/config.yaml" ]; then
        saved_config=$(cat "$SILLYTAVERN_DIR/config.yaml")
        show_info "已保存 config.yaml 配置"
        echo ""
    fi

    # 检测并修复分离 HEAD（版本回退后的状态）
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)
    if [ -z "$current_branch" ]; then
        show_warning "检测到「分离 HEAD」状态（版本回退后的正常现象）"
        show_info "正在从 GitHub 拉取最新代码并强制切换回主分支..."
        if ! git fetch origin; then
            show_error "fetch 失败，请检查网络连接"
            echo ""
            read -p "按任意键继续..." -n 1
            return 1
        fi
        if git checkout -f -B release origin/release 2>/dev/null; then
            current_branch="release"
        elif git checkout -f -B main origin/main 2>/dev/null; then
            current_branch="main"
        else
            show_error "远程仓库中未找到 release 或 main 分支"
            echo ""
            read -p "按任意键继续..." -n 1
            return 1
        fi
        show_success "已切换回 $current_branch 分支（已同步远程最新）"
        echo ""
    fi

    # 拉取更新
    show_info "正在同步最新代码 (git fetch + reset)..."
    echo ""

    if ! git fetch origin; then
        echo ""
        show_error "fetch 失败，请检查网络连接"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi

    if ! git reset --hard "origin/$current_branch"; then
        echo ""
        show_error "代码同步失败"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi

    # 还原 config.yaml
    if [ -n "$saved_config" ]; then
        echo "$saved_config" > "$SILLYTAVERN_DIR/config.yaml"
        show_success "✓ 已还原 config.yaml 自定义配置"
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

# 回退到旧版本
st_rollback() {
    clear
    show_header
    show_submenu_header "回退 SillyTavern 版本"

    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        show_error "SillyTavern 未安装"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi

    # 检查网络
    show_info "检查 GitHub 连接..."
    if ! ping -c 1 -W 5 github.com &> /dev/null; then
        show_error "无法连接到 GitHub，请检查网络"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi
    show_success "网络连接正常"
    echo ""

    cd "$HOME" || return 1
    cd "$SILLYTAVERN_DIR" || {
        show_error "无法进入目录: $SILLYTAVERN_DIR"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    }

    # 显示当前版本
    local current_ver
    current_ver=$(git describe --tags --abbrev=0 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "未知")
    show_info "当前版本: $current_ver"
    echo ""

    # 拉取远端标签
    show_info "正在获取历史版本列表..."
    echo ""
    git fetch --tags --quiet 2>/dev/null

    local tags=()
    mapfile -t tags < <(git tag --sort=-version:refname 2>/dev/null | head -20)

    if [ ${#tags[@]} -eq 0 ]; then
        show_error "未能获取版本列表"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi

    # 显示版本列表
    show_info "可用历史版本 (最近 ${#tags[@]} 个):"
    echo ""
    local i=1
    for tag in "${tags[@]}"; do
        local date_str
        date_str=$(git log -1 --format="%ai" "$tag" 2>/dev/null | cut -d' ' -f1)
        echo "  [$i] $tag  $date_str"
        ((i++))
    done
    echo "  [0] 取消"
    echo ""

    read -p "$(colorize "请选择版本 [0-${#tags[@]}]: " "$COLOR_CYAN")" choice

    if [ "$choice" == "0" ] || [ -z "$choice" ]; then
        show_info "取消回退"
        echo ""
        read -p "按任意键继续..." -n 1
        return
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#tags[@]}" ]; then
        show_error "无效选项"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi

    local selected_tag="${tags[$((choice-1))]}"
    echo ""
    show_warning "将回退到版本: $selected_tag"
    echo ""

    # 建议备份
    if confirm_action "建议先备份当前数据，是否备份？"; then
        backup_create
        echo ""
    fi

    if ! confirm_action "确认回退到 $selected_tag？"; then
        show_info "取消回退"
        echo ""
        read -p "按任意键继续..." -n 1
        return
    fi

    echo ""
    show_info "正在切换到版本 $selected_tag..."
    echo ""

    # 回退前保存 config.yaml
    local saved_config_rb=""
    if [ "$AUTO_PRESERVE_CONFIG" == "true" ] && [ -f "$SILLYTAVERN_DIR/config.yaml" ]; then
        saved_config_rb=$(cat "$SILLYTAVERN_DIR/config.yaml")
        show_info "已保存 config.yaml 配置"
        echo ""
    fi

    if ! git checkout "$selected_tag"; then
        echo ""
        show_error "切换版本失败！"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi

    # 还原 config.yaml
    if [ -n "$saved_config_rb" ]; then
        echo "$saved_config_rb" > "$SILLYTAVERN_DIR/config.yaml"
        show_success "✓ 已还原 config.yaml 自定义配置"
    fi

    echo ""
    show_info "正在重新安装依赖..."
    echo ""

    if ! npm install; then
        echo ""
        show_error "依赖安装失败"
        echo ""
        read -p "按任意键继续..." -n 1
        return 1
    fi

    echo ""
    show_success "已成功回退到版本: $selected_tag"
    show_warning "当前处于「分离 HEAD」状态，这是正常现象"
    show_info "若要升级到最新版本，选择 SillyTavern 管理 → 更新"
    echo ""
    read -p "按任意键继续..." -n 1
}

# 卸载 SillyTavern
st_uninstall() {
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
        backup_create
        echo ""
    fi
    
    # 🔧 修复：卸载前先切换到安全目录
    cd "$HOME" || {
        show_error "无法切换到主目录"
        return 1
    }
    
    if safe_remove_dir "$SILLYTAVERN_DIR" "SillyTavern"; then
        show_success "SillyTavern 已完全卸载"
    fi
}
