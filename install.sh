#!/data/data/com.termux/files/usr/bin/bash

set -e

NEXUS_DIR="$HOME/nexus"
REPO_URL="https://github.com/Tangchuzhi/Nexus.git"

echo "🚀 Nexus 安装程序"
echo "=================="

# 检查并安装依赖
echo "📦 检查依赖..."
pkg update -y
pkg install -y git nodejs jq curl

# 克隆仓库
echo "📥 下载 Nexus..."
if [ -d "$NEXUS_DIR" ]; then
    echo "⚠️  检测到已存在的 Nexus 目录"
    read -p "是否覆盖安装？(y/n): " confirm
    [[ "$confirm" != "y" ]] && exit 0
    rm -rf "$NEXUS_DIR"
fi

git clone "$REPO_URL" "$NEXUS_DIR"
cd "$NEXUS_DIR"
chmod +x nexus.sh

# 创建软链接
ln -sf "$NEXUS_DIR/nexus.sh" "$PREFIX/bin/nexus"

echo "✅ 安装完成！"
echo "💡 使用 'nexus' 命令启动"
