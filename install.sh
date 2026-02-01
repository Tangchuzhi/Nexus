#!/data/data/com.termux/files/usr/bin/bash
# Nexus 安装脚本 - 优化版

set -e

# ============================================
# 颜色定义
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================
# 打印函数
# ============================================

print_info() { echo -e "${BLUE}[信息]${NC} $1"; }
print_success() { echo -e "${GREEN}[成功]${NC} $1"; }
print_error() { echo -e "${RED}[错误]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[警告]${NC} $1"; }

# ============================================
# 显示欢迎信息
# ============================================

show_welcome() {
    clear
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}🌟 Nexus 安装程序 🌟${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================
# 网络检测
# ============================================

check_network() {
    print_info "检测网络连接..."
    
    if ! ping -c 1 -W 3 223.5.5.5 &> /dev/null && \
       ! ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        print_error "网络连接失败，请检查网络设置"
        exit 1
    fi
    
    print_success "网络连接正常"
}

# ============================================
# 配置镜像源
# ============================================

setup_mirrors() {
    print_info "配置 Termux 镜像源..."
    
    # 检测地区（简单判断）
    local use_cn_mirror=false
    if ping -c 1 -W 2 mirrors.tuna.tsinghua.edu.cn &> /dev/null; then
        use_cn_mirror=true
    fi
    
    # 备份原配置
    [ -f "$PREFIX/etc/apt/sources.list" ] && \
        cp "$PREFIX/etc/apt/sources.list" "$PREFIX/etc/apt/sources.list.bak"
    
    if [ "$use_cn_mirror" = true ]; then
        print_info "使用国内镜像源（清华大学）"
        cat > "$PREFIX/etc/apt/sources.list" <<EOF
# 清华大学镜像源
deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main
EOF
    else
        print_info "使用官方镜像源"
        cat > "$PREFIX/etc/apt/sources.list" <<EOF
# Termux 官方源
deb https://packages-cf.termux.dev/apt/termux-main stable main
EOF
    fi
    
    print_success "镜像源配置完成"
}

# ============================================
# 检查并安装依赖
# ============================================

check_dependencies() {
    print_info "检查依赖..."
    
    local missing_deps=()
    
    # 检查命令是否存在
    command -v git &> /dev/null || missing_deps+=("git")
    command -v node &> /dev/null || missing_deps+=("nodejs")
    command -v jq &> /dev/null || missing_deps+=("jq")
    command -v curl &> /dev/null || missing_deps+=("curl")
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "缺少依赖: ${missing_deps[*]}"
        install_dependencies
    else
        print_success "所有依赖已满足"
    fi
}

install_dependencies() {
    print_info "正在安装依赖..."
    
    # 更新软件源
    print_info "更新软件源（可能需要 1-2 分钟）..."
    if ! pkg update -y 2>&1 | grep -E "(Reading|Get:|Fetched)" | tail -5; then
        print_error "软件源更新失败"
        
        # 尝试恢复备份
        if [ -f "$PREFIX/etc/apt/sources.list.bak" ]; then
            print_info "尝试恢复原镜像源..."
            mv "$PREFIX/etc/apt/sources.list.bak" "$PREFIX/etc/apt/sources.list"
            pkg update -y || {
                print_error "依然失败，请手动配置镜像源"
                exit 1
            }
        else
            exit 1
        fi
    fi
    
    # 升级已安装的包（避免依赖冲突）
    print_info "升级系统包（可能需要 2-3 分钟）..."
    pkg upgrade -y 2>&1 | grep -E "(Reading|Unpacking|Setting up)" | tail -5 || {
        print_warning "部分包升级失败，继续安装..."
    }
    
    # 安装依赖包
    print_info "安装依赖包..."
    if ! pkg install -y git nodejs jq curl 2>&1 | grep -E "(Unpacking|Setting up)" | tail -5; then
        print_error "依赖安装失败"
        exit 1
    fi
    
    print_success "依赖安装完成"
    
    # 验证安装
    print_info "验证安装..."
    for cmd in git node jq curl; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "$cmd 安装失败"
            exit 1
        fi
    done
    print_success "所有依赖验证通过"
}

# ============================================
# 安装 Nexus
# ============================================

install_nexus() {
    print_info "开始安装 Nexus..."
    
    local install_dir="$HOME/nexus"
    
    # 检查是否已安装
    if [ -d "$install_dir" ]; then
        print_warning "检测到已安装的 Nexus"
        read -p "是否覆盖安装？(y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_info "取消安装"
            exit 0
        fi
        rm -rf "$install_dir"
    fi
    
    # 克隆仓库
    print_info "正在下载 Nexus（可能需要 1-2 分钟）..."
    
    if ! git clone --depth=1 --progress \
        https://github.com/Tangchuzhi/Nexus.git "$install_dir" 2>&1 | \
        grep -E "(Cloning|Receiving|Resolving)"; then
        
        print_error "下载失败"
        
        # 尝试使用镜像
        print_info "尝试使用 GitHub 镜像..."
        if ! git clone --depth=1 --progress \
            https://ghproxy.com/https://github.com/Tangchuzhi/Nexus.git "$install_dir" 2>&1 | \
            grep -E "(Cloning|Receiving|Resolving)"; then
            
            print_error "下载失败，请检查网络或稍后重试"
            exit 1
        fi
    fi
    
    # 设置权限
    chmod +x "$install_dir/nexus.sh"
    chmod +x "$install_dir/install.sh"
    
    # 创建软链接
    ln -sf "$install_dir/nexus.sh" "$PREFIX/bin/nexus"
    
    print_success "Nexus 安装完成"
}

# ============================================
# 配置自启动
# ============================================

setup_autostart() {
    print_info "配置自启动..."
    
    local bashrc="$HOME/.bashrc"
    local autostart_marker="# Nexus Auto-Start"
    local autostart_code="$autostart_marker
if [ -f \"\$PREFIX/bin/nexus\" ]; then
    nexus
fi"
    
    # 检查是否已配置
    if grep -q "$autostart_marker" "$bashrc" 2>/dev/null; then
        print_warning "自启动已配置"
    else
        echo "" >> "$bashrc"
        echo "$autostart_code" >> "$bashrc"
        print_success "自启动配置完成"
    fi
    
    echo ""
    print_info "💡 提示："
    echo "  - 每次打开 Termux 将自动启动 Nexus"
    echo "  - 可在 Nexus 主菜单 → [4] Nexus 管理 → [3] 自启动管理 中关闭"
    echo ""
}

# ============================================
# 完成安装
# ============================================

finish_install() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}✅ 安装完成！${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    print_success "Nexus 已成功安装到: $HOME/nexus"
    echo ""
    print_info "使用方法："
    echo "  1. 输入 'nexus' 启动管理终端"
    echo "  2. 或重新打开 Termux 自动启动"
    echo ""
    
    read -p "是否立即启动 Nexus？(Y/n): " start_now
    if [[ ! "$start_now" =~ ^[Nn]$ ]]; then
        exec nexus
    fi
}

# ============================================
# 主流程
# ============================================

main() {
    show_welcome
    check_network
    setup_mirrors
    check_dependencies
    install_nexus
    setup_autostart
    finish_install
}

# 执行主流程
main
