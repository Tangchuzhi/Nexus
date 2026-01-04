#!/data/data/com.termux/files/usr/bin/bash
# 版本检查模块

CACHE_DIR="$NEXUS_DIR/.cache"
CACHE_TIMEOUT=3600  # 缓存1小时（3600秒）

# 初始化版本缓存
init_version_cache() {
    mkdir -p "$CACHE_DIR"
}

# ============================================
# 缓存工具函数
# ============================================

# 获取文件修改时间
get_file_mtime() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi
    
    # 尝试不同的 stat 命令格式
    local mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo "0")
    echo "$mtime"
}

# 检查缓存是否过期
is_cache_expired() {
    local cache_file="$1"
    
    if [ ! -f "$cache_file" ]; then
        return 0  # 文件不存在，视为过期
    fi
    
    local current_time=$(date +%s)
    local file_mtime=$(get_file_mtime "$cache_file")
    local cache_age=$((current_time - file_mtime))
    
    if [ $cache_age -ge $CACHE_TIMEOUT ]; then
        return 0  # 过期
    else
        return 1  # 未过期
    fi
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

# 获取 SillyTavern 远程版本（带智能缓存）
get_st_remote_version() {
    local cache_file="$CACHE_DIR/st_version"
    
    # 如果缓存未过期，直接返回
    if ! is_cache_expired "$cache_file"; then
        cat "$cache_file" 2>/dev/null || echo ""
        return
    fi
    
    # 缓存过期，同步更新
    local version=$(timeout 5 curl -s --connect-timeout 3 \
        "https://api.github.com/repos/SillyTavern/SillyTavern/releases/latest" \
        2>/dev/null | jq -r '.tag_name' 2>/dev/null)
    
    if [ -n "$version" ] && [ "$version" != "null" ]; then
        echo "$version" > "$cache_file"
        echo "$version"
    else
        # 网络失败，返回旧缓存
        cat "$cache_file" 2>/dev/null || echo ""
    fi
}

# ============================================
# Nexus 版本管理
# ============================================

# 获取 Nexus 远程版本
get_nexus_remote_version() {
    local cache_file="$CACHE_DIR/nexus_version"
    
    # 如果缓存未过期，直接返回
    if ! is_cache_expired "$cache_file"; then
        cat "$cache_file" 2>/dev/null || echo ""
        return
    fi
    
    # 缓存过期，同步更新
    local version=$(timeout 5 curl -s --connect-timeout 3 \
        "https://raw.githubusercontent.com/Tangchuzhi/Nexus/main/VERSION" \
        2>/dev/null | tr -d '[:space:]')
    
    if [ -n "$version" ]; then
        echo "$version" > "$cache_file"
        echo "$version"
    else
        # 网络失败，返回旧缓存
        cat "$cache_file" 2>/dev/null || echo ""
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
    
    # 重新获取（显示进度）
    echo -n "  检查 SillyTavern 版本..."
    get_st_remote_version > /dev/null 2>&1
    echo " ✓"
    
    echo -n "  检查 Nexus 版本..."
    get_nexus_remote_version > /dev/null 2>&1
    echo " ✓"
    
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

# 获取缓存剩余时间
get_cache_remaining_time() {
    local cache_file="$1"
    
    if [ ! -f "$cache_file" ]; then
        echo "无缓存"
        return
    fi
    
    local current_time=$(date +%s)
    local file_mtime=$(get_file_mtime "$cache_file")
    local cache_age=$((current_time - file_mtime))
    local remaining=$((CACHE_TIMEOUT - cache_age))
    
    if [ $remaining -le 0 ]; then
        echo "已过期"
    else
        local minutes=$((remaining / 60))
        echo "${minutes}分钟后刷新"
    fi
}
