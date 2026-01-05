#!/data/data/com.termux/files/usr/bin/bash
# 版本检查模块

CACHE_DIR="$NEXUS_DIR/.cache"
CACHE_TIMEOUT=3600  # 缓存1小时

# 初始化版本缓存
init_version_cache() {
    mkdir -p "$CACHE_DIR"
}

# ============================================
# 缓存工具函数（优化版）
# ============================================

# 检查缓存是否过期
is_cache_expired() {
    local cache_file="$1"
    [ ! -f "$cache_file" ] && return 0
    
    local now=$(date +%s)
    local mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    [ $((now - mtime)) -gt 3600 ] && return 0 || return 1
}

# ============================================
# SillyTavern 版本管理
# ============================================

# 获取 SillyTavern 本地版本（优化：减少jq调用）
get_st_local_version() {
    local st_dir="$SILLYTAVERN_DIR"
    local package_file="$st_dir/package.json"
    
    if [ ! -f "$package_file" ]; then
        echo "未安装"
        return
    fi
    
    # 使用 grep 替代 jq（更轻量）
    local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$package_file" 2>/dev/null | cut -d'"' -f4)
    
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "未安装"
    fi
}

# 获取 SillyTavern 远程版本（带智能缓存）
get_st_remote_version() {
    local cache_file="$CACHE_DIR/st_version"
    
    # 缓存未过期，直接返回
    if ! is_cache_expired "$cache_file"; then
        cat "$cache_file" 2>/dev/null || echo ""
        return
    fi
    
    # 缓存过期，同步更新（添加更严格的超时）
    local version=$(timeout 5 curl -s --connect-timeout 2 --max-time 4 \
        "https://api.github.com/repos/SillyTavern/SillyTavern/releases/latest" \
        2>/dev/null | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$version" ]; then
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

# 获取 Nexus 远程版本（带智能缓存）
get_nexus_remote_version() {
    local cache_file="$CACHE_DIR/nexus_version"
    
    # 缓存未过期，直接返回
    if ! is_cache_expired "$cache_file"; then
        cat "$cache_file" 2>/dev/null || echo ""
        return
    fi
    
    # 缓存过期，同步更新
    local version=$(timeout 5 curl -s --connect-timeout 2 --max-time 4 \
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

# 强制刷新版本缓存（仅此处绕过 CDN）
refresh_version_cache() {
    show_info "正在强制刷新版本信息..."
    
    # 删除本地缓存
    rm -f "$CACHE_DIR/st_version"
    rm -f "$CACHE_DIR/nexus_version"
    
    # 强制获取最新版本（添加时间戳绕过 GitHub CDN 缓存）
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
}

# 获取 SillyTavern 状态（仅在需要时调用）
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
    
    # 使用 find 获取文件年龄（分钟）
    local age=$(find "$cache_file" -mmin +0 -printf "%Cm\n" 2>/dev/null | head -1)
    local remaining=$((60 - age))
    
    if [ $remaining -le 0 ]; then
        echo "已过期"
    else
        echo "${remaining}分钟后刷新"
    fi
}
