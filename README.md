# BLUI - SSH工具

Flutter全平台游戏配置管理应用，提供SSH连接、终端操作、文件传输等功能。

## 项目结构

```
lib/
├── component/                 # UI组件 (通用)
│   ├── Button_component.dart        # 按钮组件
│   ├── card_component.dart          # 卡片组件
│   ├── card_manager_component.dart  # 卡片管理组件
│   ├── card_select_component.dart   # 卡片选择组件
│   ├── empty_terminal_widget.dart   # 空终端组件
│   ├── import_export_manager.dart   # 导入导出管理组件
│   ├── message_component.dart       # 消息提示和弹窗组件
│   ├── progress_bar_component.dart  # 进度条组件
│   ├── prompt_component.dart        # 提示组件
│   ├── remote_directory_browser.dart # 远程目录浏览组件
│   ├── scan_result_component.dart   # 扫描结果组件
│   ├── ssh_command_edit_dialog.dart # SSH命令编辑对话框
│   ├── ssh_connect_dialog.dart      # SSH连接对话框
│   ├── ssh_file_downloader.dart     # SSH文件下载组件
│   ├── ssh_file_uploader.dart       # SSH文件上传组件
│   ├── ssh_multi_terminal.dart      # SSH多终端组件
│   ├── ssh_session_edit_dialog.dart # SSH会话编辑对话框
│   ├── ssh_session_history.dart     # SSH会话历史记录组件
│   └── ssh_session_tab_manager.dart # SSH会话标签管理器
│
├── controllers/               # 控制器 (业务逻辑)
│   ├── ip_controller.dart          # IP管理控制器
│   ├── ssh_command_controller.dart # SSH命令控制器
│   ├── ssh_controller.dart         # SSH主控制器
│   └── ssh_session_controller.dart # SSH会话控制器
│
├── models/                    # 数据模型
│   ├── ip_model.dart               # IP数据模型
│   ├── message_model.dart          # 消息数据模型
│   ├── ssh_command_model.dart      # SSH命令数据模型
│   ├── ssh_model.dart              # SSH连接数据模型
│   └── ssh_saved_session_model.dart # SSH保存的会话数据模型
│
├── providers/                 # 状态提供者
│   └── sidebar_provider.dart       # 侧边栏状态管理提供者
│
├── utils/                     # 工具类
│   └── logger.dart                 # 日志工具
│
├── views/                     # 视图/页面
│   ├── ip_screen.dart              # IP管理页面
│   ├── side_controller.dart        # 侧边控制器
│   ├── sidebar_screen.dart         # 侧边栏组件，实现底部导航
│   ├── ssh_command_manager_screen.dart # SSH命令管理页面
│   └── ssh_terminal_screen.dart    # SSH终端页面
│
└── main.dart                  # 应用入口
```

## 功能模块

### 1. 主界面 (main.dart)
- 应用程序入口点
- 配置主题、路由和全局状态管理
- 实现底部导航栏，切换不同功能页面 (仪表盘、服务器、设置)

### 2. 模型层 (models/)

| 文件名 | 说明 |
|-------|------|
| ip_model.dart | IP地址管理模型，存储和处理IP地址信息 |
| message_model.dart | 消息模型，用于应用内通知和提示 |
| ssh_command_model.dart | SSH命令模型，存储常用命令及其分类 |
| ssh_model.dart | SSH连接模型，存储连接参数和状态 |
| ssh_saved_session_model.dart | 保存的SSH会话模型，管理会话持久化 |

### 3. 控制器层 (controllers/)

| 文件名 | 说明 |
|-------|------|
| ip_controller.dart | IP管理逻辑，包括IP扫描、保存、删除等 |
| ssh_command_controller.dart | SSH命令管理逻辑，包括命令执行、历史记录等 |
| ssh_controller.dart | SSH连接的核心控制逻辑，处理认证、连接状态等 |
| ssh_session_controller.dart | SSH会话管理，包括多会话切换、关闭等 |

### 4. 视图层 (views/)

| 文件名 | 说明 |
|-------|------|
| ip_screen.dart | IP管理界面，显示已保存IP及网络扫描 |
| side_controller.dart | 侧边控制器视图，用于导航和功能切换 |
| sidebar_screen.dart | 侧边栏组件，实现底部导航栏或抽屉菜单导航 |
| ssh_command_manager_screen.dart | SSH命令管理界面，组织和执行常用命令 |
| ssh_terminal_screen.dart | SSH终端界面，提供命令行交互环境 |

### 5. 提供者层 (providers/)

| 文件名 | 说明 |
|-------|------|
| sidebar_provider.dart | 侧边栏状态管理提供者，管理导航状态 |

### 6. 组件层 (component/)

| 文件名 | 说明 |
|-------|------|
| Button_component.dart | 自定义按钮组件 |
| card_component.dart | 卡片组件，显示信息块 |
| card_manager_component.dart | 卡片管理组件，管理多个卡片 |
| card_select_component.dart | 卡片选择组件，提供选择功能 |
| empty_terminal_widget.dart | 空终端组件，显示初始终端状态 |
| import_export_manager.dart | 导入导出管理组件，处理数据迁移 |
| message_component.dart | 消息组件，显示通知和警告 |
| progress_bar_component.dart | 进度条组件，显示操作进度 |
| prompt_component.dart | 提示组件，用于用户交互 |
| remote_directory_browser.dart | 远程目录浏览器，浏览服务器文件系统 |
| scan_result_component.dart | 扫描结果组件，显示网络扫描结果 |
| ssh_command_edit_dialog.dart | SSH命令编辑对话框 |
| ssh_connect_dialog.dart | SSH连接对话框，输入连接参数 |
| ssh_file_downloader.dart | SSH文件下载组件，从服务器下载文件 |
| ssh_file_uploader.dart | SSH文件上传组件，上传文件到服务器 |
| ssh_multi_terminal.dart | SSH多终端组件，管理多个终端会话 |
| ssh_session_edit_dialog.dart | SSH会话编辑对话框，编辑会话参数 |
| ssh_session_history.dart | SSH会话历史记录组件，查看历史会话 |
| ssh_session_tab_manager.dart | SSH会话标签管理器，切换多个会话 |

### 7. 工具层 (utils/)

| 文件名 | 说明 |
|-------|------|
| logger.dart | 日志工具，记录应用运行日志 |

## 技术栈

- Flutter框架，用于跨平台UI开发
- Provider状态管理
- SSH连接和终端模拟
- 文件传输功能
- 网络扫描工具

## 适用平台

- Android
- iOS
- Windows
- macOS
- Linux
- Web (部分功能在Web平台有限制)