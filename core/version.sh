#!/data/data/com.termux/files/usr/bin/bash
# 版本检查模块

CACHE_DIR="$NEXUS_DIR/.cache"

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
    local package_file="$st_dir/package.json"
    
    if [ ! -f "$package_file" ]; then
        echo "未安装"
        return
    fi
    
    local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$package_file" 2>/dev/null | cut -d'"' -f4)
    
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "未安装"
    fi
}

# 获取 SillyTavern 远程版本（仅从缓存读取，不自动刷新）
get_st_remote_version() {
    local cache_file="$CACHE_DIR/st_version"
    
    # 如果缓存存在，直接返回
    if [ -f "$cache_file" ]; then
        cat "$cache_file" 2>/dev/null || echo ""
        return
    fi
    
    # 缓存不存在，获取一次并保存
    local version=$(timeout 5 curl -s --connect-timeout 2 --max-time 4 \
        "https://api.github.com/repos/SillyTavern/SillyTavern/releases/latest" \
        2>/dev/null | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$version" ]; then
        echo "$version" > "$cache_file"
        echo "$version"
    else
        echo ""
    fi
}

# ============================================
# Nexus 版本管理
# ============================================

# 获取 Nexus 远程版本（仅从缓存读取，不自动刷新）
get_nexus_remote_version() {
    local cache_file="$CACHE_DIR/nexus_version"
    
    # 如果缓存存在，直接返回
    if [ -f "$cache_file" ]; then
        cat "$cache_file" 2>/dev/null || echo ""
        return
    fi
    
    # 缓存不存在，获取一次并保存
    local version=$(timeout 5 curl -s --connect-timeout 2 --max-time 4 \
        "https://raw.githubusercontent.com/Tangchuzhi/Nexus/main/VERSION" \
        2>/dev/null | tr -d '[:space:]')
    
    if [ -n "$version" ]; then
        echo "$version" > "$cache_file"
        echo "$version"
    else
        echo ""
    fi
}

# ============================================
# 工具函数
# ============================================

# 强制刷新版本缓存（仅在设置中调用）
refresh_version_cache() {
    show_info "正在强制刷新版本信息..."
    
    # 删除本地缓存
    rm -f "$CACHE_DIR/st_version"
    rm -f "$CACHE_DIR/nexus_version"
    
    # 强制获取最新版本（添加时间戳绕过 CDN）
    local timestamp=$(date +%s)
    
    # SillyTavern 版本
    local st_ver=$(timeout 5 curl -s --connect-timeout 2 --max-time 4 \
        "https://api.github.com/repos/SillyTavern/SillyTavern/releases/latest?t=${timestamp}" \
        2>/dev/null | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$st_ver" ]; then
        echo "$st_ver" > "$CACHE_DIR/st_version"
    fi
    
    # Nexus 版本
    local nexus_ver=$(timeout 5 curl -s --connect-timeout 2 --max-time 4 \
        "https://raw.githubusercontent.com/Tangchuzhi/Nexus/main/VERSION?t=${timestamp}" \
        2>/dev/null | tr -d '[:space:]')
    
    if [ -n "$nexus_ver" ]; then
        echo "$nexus_ver" > "$CACHE_DIR/nexus_version"
    fi
    
    show_success "版本信息已刷新"
    show_info "SillyTavern 最新版: ${st_ver:-获取失败}"
    show_info "Nexus 最新版: ${nexus_ver:-获取失败}"
    
    # 更新全局变量
    CACHED_ST_LOCAL=$(get_st_local_version)
    CACHED_ST_REMOTE="$st_ver"
    CACHED_NEXUS_REMOTE="$nexus_ver"
}

# 获取 SillyTavern 状态
get_st_status() {
    if pgrep -f "node.*server.js" > /dev/null 2>&1; then
        echo "running"
    else
        echo "stopped"
    fi
}
