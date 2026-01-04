#!/data/data/com.termux/files/usr/bin/bash
# Nexus 安装脚本

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
# 检查依赖
# ============================================

check_dependencies() {
    print_info "检查依赖..."
    
    local missing_deps=()
    for cmd in git node npm jq curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "缺少依赖: ${missing_deps[*]}"
        print_info "正在安装依赖..."
        
        pkg update -y || {
            print_error "更新软件源失败"
            exit 1
        }
        
        pkg install -y git nodejs jq curl || {
            print_error "依赖安装失败"
            exit 1
        }
        
        print_success "依赖安装完成"
    else
        print_success "所有依赖已满足"
    fi
}

# ============================================
# 安装 Nexus
# ============================================

install_nexus() {
    print_info "开始安装 Nexus..."
    echo ""
    
    local install_dir="$HOME/nexus"
    
    # 检查是否已安装
    if [ -d "$install_dir" ]; then
        print_warning "检测到已安装的 Nexus"
        echo ""
        echo "  安装目录: $install_dir"
        echo ""
        echo "  [1] 覆盖安装（删除旧版本）"
        echo "  [2] 仅修复软链接"
        echo "  [0] 取消安装"
        echo ""
        
        read -p "请选择 [0-2]: " choice
        
        case $choice in
            1)
                print_info "正在删除旧版本..."
                rm -rf "$install_dir"
                ;;
            2)
                print_info "跳过下载，仅修复软链接..."
                setup_symlink
                finish_install
                return 0
                ;;
            *)
                print_info "取消安装"
                exit 0
                ;;
        esac
    fi
    
    # 克隆仓库
    print_info "正在下载 Nexus..."
    if ! git clone https://github.com/Tangchuzhi/Nexus.git "$install_dir"; then
        print_error "下载失败，请检查网络"
        exit 1
    fi
    
    print_success "下载完成"
    
    # 设置权限和软链接
    setup_symlink
}

# ============================================
# 设置软链接
# ============================================

setup_symlink() {
    local install_dir="$HOME/nexus"
    local nexus_script="$install_dir/nexus.sh"
    local bin_link="$PREFIX/bin/nexus"
    
    print_info "配置 Nexus..."
    
    # 检查脚本是否存在
    if [ ! -f "$nexus_script" ]; then
        print_error "找不到 nexus.sh 文件"
        exit 1
    fi
    
    # 设置执行权限
    chmod +x "$nexus_script"
    print_success "设置执行权限"
    
    # 删除旧的软链接
    if [ -L "$bin_link" ] || [ -f "$bin_link" ]; then
        rm -f "$bin_link"
    fi
    
    # 创建新的软链接
    if ln -sf "$nexus_script" "$bin_link"; then
        print_success "创建软链接: $bin_link"
    else
        print_error "创建软链接失败"
        exit 1
    fi
    
    # 验证软链接
    if [ -L "$bin_link" ] && [ -x "$bin_link" ]; then
        print_success "软链接验证成功"
    else
        print_error "软链接验证失败"
        exit 1
    fi
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
    print_info "自启动说明："
    echo "  - 每次打开 Termux 将自动启动 Nexus"
    echo "  - 可在 [系统设置] → [自启动管理] 中关闭"
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
    print_success "Nexus 已成功安装"
    echo ""
    print_info "安装信息："
    echo "  安装目录: $HOME/nexus"
    echo "  命令路径: $PREFIX/bin/nexus"
    echo ""
    print_info "使用方法："
    echo "  1. 输入 'nexus' 启动管理终端"
    echo "  2. 或重新打开 Termux 自动启动"
    echo ""
    
    # 验证命令
    if command -v nexus &> /dev/null; then
        print_success "命令验证成功"
        echo ""
        read -p "是否立即启动 Nexus？(Y/n): " start_now
        if [[ ! "$start_now" =~ ^[Nn]$ ]]; then
            echo ""
            exec nexus
        fi
    else
        print_error "命令验证失败"
        echo ""
        print_info "请尝试手动修复："
        echo "  ln -sf ~/nexus/nexus.sh \$PREFIX/bin/nexus"
        echo "  nexus"
    fi
}

# ============================================
# 主流程
# ============================================

main() {
    show_welcome
    check_dependencies
    install_nexus
    setup_autostart
    finish_install
}

# 执行主流程
main
