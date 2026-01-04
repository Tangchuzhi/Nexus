#!/data/data/com.termux/files/usr/bin/bash
# 版本检查模块

CACHE_DIR="$NEXUS_DIR/.cache"
CACHE_TIMEOUT=3600  # 缓存1小时

# 初始化版本缓存
init_version_cache() {
    mkdir -p "$CACHE_DIR"
}

# ============================================
# SillyTavern 版本管理
# ============================================

# 获取 SillyTavern 本地版本
get_st_local_version() {
    local st_dir="$SILLYTAVERN_DIR"
    if [ -f "$st_dir/package.json" ]; then
        jq -r '.version' "$st_dir/package.json" 2>/dev/null || echo "未安装"
    else
        echo "未安装"
    fi
}

# 获取 SillyTavern 远程版本（同步，带缓存）
get_st_remote_version() {
    local cache_file="$CACHE_DIR/st_version"
    
    # 检查缓存
    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [ $cache_age -lt $CACHE_TIMEOUT ]; then
            cat "$cache_file"
            return
        fi
    fi
    
    # 同步获取远程版本
    local version=$(curl -s --connect-timeout 3 --max-time 5 "https://api.github.com/repos/SillyTavern/SillyTavern/releases/latest" | jq -r '.tag_name' 2>/dev/null)
    
    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version" > "$cache_file"
        echo "$version"
    else
        # 返回缓存或空
        [ -f "$cache_file" ] && cat "$cache_file" || echo ""
    fi
}

# ============================================
# Nexus 版本管理
# ============================================

# 获取 Nexus 远程版本（同步，带缓存）
get_nexus_remote_version() {
    local cache_file="$CACHE_DIR/nexus_version"
    
    # 检查缓存
    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [ $cache_age -lt $CACHE_TIMEOUT ]; then
            cat "$cache_file"
            return
        fi
    fi
    
    # 同步获取远程版本
    local version=$(curl -s --connect-timeout 3 --max-time 5 "https://raw.githubusercontent.com/Tangchuzhi/Nexus/main/VERSION" | tr -d '[:space:]')
    
    if [ -n "$version" ]; then
        echo "$version" > "$cache_file"
        echo "$version"
    else
        # 返回缓存或空
        [ -f "$cache_file" ] && cat "$cache_file" || echo ""
    fi
}

# ============================================
# 工具函数
# ============================================

# 强制刷新版本缓存
refresh_version_cache() {
    show_info "正在刷新版本信息..."
    
    rm -f "$CACHE_DIR/st_version"
    rm -f "$CACHE_DIR/nexus_version"
    
    # 重新获取
    get_st_remote_version > /dev/null 2>&1
    get_nexus_remote_version > /dev/null 2>&1
    
    show_success "版本信息已刷新"
}

# 获取 SillyTavern 状态
get_st_status() {
    if pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "running"
    else
        echo "stopped"
    fi
}
