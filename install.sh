#!/data/data/com.termux/files/usr/bin/bash
# Nexus - SillyTavern-Termux 一键安装脚本

set -e

NEXUS_DIR="$HOME/nexus"
REPO_URL="https://github.com/Tangchuzhi/Nexus.git"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

clear
echo "╔════════════════════════════════════════╗"
echo "║       🌟 Nexus 安装程序 v1.0.0 🌟       ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 检查是否已安装
if [ -d "$NEXUS_DIR" ]; then
    print_warning "检测到已安装 Nexus"
    read -p "是否重新安装？(y/N): " reinstall
    if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
        print_info "取消安装"
        exit 0
    fi
    rm -rf "$NEXUS_DIR"
fi

# 更新软件包
print_info "更新软件包列表..."
pkg update -y

# 安装依赖
print_info "安装依赖..."
pkg install -y git nodejs jq curl

# 克隆仓库
print_info "下载 Nexus..."
git clone "$REPO_URL" "$NEXUS_DIR"

# 设置权限
chmod +x "$NEXUS_DIR/nexus.sh"

# 创建软链接
print_info "创建全局命令..."
ln -sf "$NEXUS_DIR/nexus.sh" "$PREFIX/bin/nexus"

# 配置自启动
print_info "配置自启动..."
BASHRC="$HOME/.bashrc"

# 检查是否已配置
if ! grep -q "# Nexus Auto Start" "$BASHRC" 2>/dev/null; then
    cat >> "$SHRC" << 'EOF'

# Nexus Auto Start
if [ -z "$NEXUS_STARTED" ]; then
    export NEXUS_STARTED=1
    nexus
fi
EOF
    print_success "自启动配置完成"
else
    print_info "自启动已配置，跳过"
fi

echo ""
print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "  Nexus 安装完成！"
print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "使用方法："
echo "  1. 输入 'nexus' 启动管理终端"
echo "  2. 重新打开 Termux 自动启动"
echo ""
print_info "如需禁用自启动，编辑 ~/.bashrc 删除相关配置"
echo ""

read -p "是否立即启动 Nexus？(Y/n): " start_now
if [[ ! "$start_now" =~ ^[Nn]$ ]]; then
    exec nexus
fi
