
# Nexus - SillyTavern 一键部署与管理工具

**专为 Termux 打造的轻量级、模块化 SillyTavern 管理框架**

---

## 📖 项目简介

Nexus 是一个基于纯 Shell 语言编写的轻量级管理工具，旨在为 Android (Termux) 用户提供最流畅的 SillyTavern（酒馆）部署、维护和管理体验。它摒弃了臃肿的运行库，回归最纯粹的命令行交互，确保每一分算力都留给你的 AI。

## 🚀 快速开始

在 Termux 中复制并执行以下命令：

```bash
pkg update -y && pkg upgrade -y && pkg install curl git nodejs jq -y && curl -L https://raw.githubusercontent.com/Tangchuzhi/Nexus/main/install.sh | bash
```

---

## ✨ 项目亮点

### 1. ⚡ 极致轻量 (Lightweight)
- **纯 Shell 编写**：不依赖 Python 或其他重型环境，几乎不占用额外的系统资源。
- **零延迟交互**：全新的扁平化菜单设计，操作逻辑更符合直觉，响应极快。对手机电池友好，由内而外的“绿色”软件。

### 2. 🧩 模块化架构 (Modular Design)
- **即插即用**：采用模块化设计，各个功能区独立运行，互不干扰。
- **高扩展性**：清晰的代码逻辑使得功能扩展变得异常简单。

### 3. 🛠️ 强大的工具箱 (All-in-One Tools)
Nexus 不仅仅是安装器，更是你的全能管家：

- **📦 备份与恢复**：
  - 专为版本更新设计，一键备份用户数据（聊天记录、角色卡、配置）。
  - 酒馆更新或重装后一键无损恢复，数据永不丢失。
  
- **🗑️ 扁平化管理**：
  - 支持独立卸载酒馆或 Nexus 自身，甚至可以选择是否保留备份数据。
  - 内置自启动配置向导，让 Nexus 随 Termux 启动而自动运行。
  
- **🚑 故障诊断系统**：
  - **全链路检查**：从 Termux 存储权限、核心依赖 (Git/Node/JQ) 到安装路径的自动检测。
  - **稳定版本检测**：采用 Raw File 直连检测机制，强制同步最新代码。

---

## 🏗️ 整体架构

Nexus 采用清晰的分层目录结构：

```text
Nexus/
├── core/                   # [核心层]
│   ├── ui.sh               # 界面渲染与交互逻辑
│   ├── utils.sh            # 通用工具函数库
│   └── version.sh          # 版本控制与更新检测 (Raw直连版)
│
├── modules/                # [功能层]
│   ├── tavern/             # 🍺 酒馆专项管理
│   │   ├── lifecycle.sh    # 生命周期 (安装/更新/卸载)
│   │   ├── backup.sh       # 数据安全 (备份与恢复)
│   │   └── runtime.sh      # 运行时 (启动/状态监测)
│   │
│   ├── diagnose.sh         # 🔍 故障诊断与修复模块
│   └── manager.sh          # 🔧 Nexus 管理 (自启动/更新/卸载)
│
├── config/                 # [配置层]
│   └── nexus.conf          # 用户个性化配置文件
├── VERSION                 # 版本号
├── install.sh              # 引导安装程序
└── nexus.sh                # 主程序入口
```

---

## 🤝 致谢 (Acknowledgments)

- **[SillyTavern](https://github.com/SillyTavern/SillyTavern)**: 感谢官方团队。
- **[随行终端](https://discord.com/channels/1291925535324110879/1385183883540303872)**: 感谢随行终端提供的灵感。

---

## 🛡️ 开源协议 (License)

本项目采用 **CC BY-NC-ND 4.0 (署名-非商业性使用-禁止演绎)** 国际许可协议。

这意味着：
1. **禁止修改**：你 **不能** 修改本项目的源代码并重新发布。
2. **禁止商用**：你 **不能** 将本项目用于任何商业用途或通过其获利。
3. **署名分享**：你可以自由复制和分发本项目的原版拷贝，但必须保留原作者署名。

> ⚠️ **警告**：任何违反上述协议的行为（包括但不限于修改代码后二次打包发布、去除版权信息等）均将被视为侵权。

Copyright © 2024 Tangchuzhi. All Rights Reserved.
