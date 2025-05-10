# SSH工具图标统一管理指南

## 推荐图标网站

以下是一些优质图标网站，您可以在这些网站上搜索并下载SSH/终端相关图标：

1. **免费图标网站**:
   - [Flaticon](https://www.flaticon.com/search?word=ssh&type=icon) - 搜索"ssh"或"terminal"
   - [Icons8](https://icons8.com/icons/set/ssh) - 提供多种风格的SSH和终端图标
   - [Iconscout](https://iconscout.com/icons/ssh) - 多种格式和风格可选
   - [SVG Repo](https://www.svgrepo.com/vectors/ssh/) - 提供可编辑的SVG格式

2. **高质量图标集**:
   - [Noun Project](https://thenounproject.com/search/icons/?q=ssh) - 简约风格的图标
   - [Iconfinder](https://www.iconfinder.com/search/?q=ssh) - 部分免费，部分付费
   - [Material Design Icons](https://materialdesignicons.com/) - 搜索"ssh"或"console"

3. **图标格式转换工具**:
   - [ConvertICO](https://convertico.com/) - 将PNG转换为ICO格式(Windows图标)
   - [ICO Convert](https://icoconvert.com/) - 生成带多种尺寸的ICO文件
   - [Favicon.io](https://favicon.io/favicon-converter/) - 简单易用的图标转换器

## 统一图标管理流程

### 一键配置所有平台图标

1. **准备图标文件**:
   - 从上方推荐的网站下载SSH/终端图标
   - **所有平台共用一个目录**: `assets/icon/`
   - **Android/iOS图标**: 确保准备1024x1024像素PNG图片，命名为 `ssh_icon.png`
   - **Windows图标**: 可选准备ICO格式图标，命名为 `ssh_icon.ico`

2. **配置pubspec.yaml**:
   - 已经配置完成，指向 "assets/icon/ssh_icon.png"

3. **生成所有平台图标**:
   - **一键生成**: 运行run.cmd脚本选项8，然后运行选项2
   - 或分开执行:
     * Android/iOS图标: `flutter pub run flutter_launcher_icons`
     * Windows图标: 使用run.cmd脚本的选项8

### Windows图标特殊说明

Windows平台支持两种图标格式:
1. **PNG格式**: 放置在 `assets/icon/ssh_icon.png`
2. **ICO格式**: 放置在 `assets/icon/ssh_icon.ico`（可选，但推荐）

当运行选项8时:
- 脚本会自动检测和使用这两个文件
- 如果同时存在PNG和ICO文件，会优先使用ICO文件
- 脚本会自动将图标文件复制到Windows资源目录

## 便捷命令

在项目根目录执行:

```
# 更新依赖
flutter pub get

# 生成Android和iOS图标
flutter pub run flutter_launcher_icons

# 设置Windows图标并构建应用
# 使用run.cmd脚本的选项8和选项2
```

## 测试图标显示

构建后，检查不同设备上的图标显示:
- Android: 检查应用启动器
- iOS: 检查主屏幕
- Windows: 检查任务栏、开始菜单和桌面快捷方式 