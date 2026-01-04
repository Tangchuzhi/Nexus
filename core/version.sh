#!/data/data/com.termux/files/usr/bin/bash
# 版本检查模块

CACHE_DIR="$NEXUS_DIR/.cache"
CACHE_TIMEOUT=3600  # 缓存1小时

# 初始化缓存目录
init_version_cache() {
    mkdir -p "$CACHE_DIR"
}

# 获取 SillyTavern 本地版本
get_st_local_version() {
    local st_dir="$SILLYTAVERN_DIR"
    if [ -f "$st_dir/package.json" ]; then
        jq -r '.version' "$st_dir/package.json" 2>/dev/null || echo "未安装"
    else
        echo "未安装"
    fi
}

# 获取 SillyTavern 远程版本（带缓存）
get_st_remote_version() {
    local cache_file="$CACHE_DIR/st_version"
    
    # 检查缓存
    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file")))
        if [ $cache_age -lt $CACHE_TIMEOUT ]; then
            cat "$cache_file"
            return
        fi
    fi
    
    # 异步获取远程版本
    (
        local version=$(curl -s "https://api.github.com/repos/SillyTavern/SillyTavern/releases/latest" | jq -r '.tag_name' 2>/dev/null)
        [ -n "$version" ] && echo "$version" > "$cache_file"
    ) &
    
    # 返回缓存或空
    [ -f "$cache_file" ] && cat "$cache_file" || echo ""
}

# 获取 Nexus 远程版本
get_nexus_remote_version() {
    local cache_file="$CACHE_DIR/nexus_version"
    
    # 检查缓存
    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file")))
        if [ $cache_age -lt $CACHE_TIMEOUT ]; then
            cat "$cache_file"
            return
        fi
    fi
    
    # 异步获取远程版本（直接读取 VERSION 文件）
    (
        local version=$(curl -s "https://raw.githubusercontent.com/Tangchuzhi/Nexus/main/VERSION" | tr -d '[:space:]')
        [ -n "$version" ] && echo "$version" > "$cache_file"
    ) &
    
    # 返回缓存或空
    [ -f "$cache_file" ] && cat "$cache_file" || echo ""
}


# 强制刷新版本缓存
refresh_version_cache() {
    rm -f "$CACHE_DIR"/*
    show_info "正在刷新版本信息..."
    get_st_remote_version > /dev/null
    get_nexus_remote_version > /dev/null
    sleep 2
    show_success "版本信息已刷新"
}

# 获取 SillyTavern 状态
get_st_status() {
    if pgrep -f "node.*SillyTavern" > /dev/null; then
        echo "running"
    else
        echo "stopped"
    fi
}
