# BLWEB应用图标指南

## 图标要求

为确保最佳显示效果，请按照以下要求准备应用图标：

1. **主图标文件**：
   - 文件名：`app_icon.png`
   - 尺寸：1024x1024像素
   - 格式：PNG格式，支持透明度
   - 位置：放置在 `assets/icon/` 目录下

2. **图标设计建议**：
   - 使用方形设计，避免圆形或不规则形状
   - 确保图标在小尺寸下依然清晰可辨
   - 避免使用过细的线条和过小的文字
   - 图标应填满整个画布，不留过多透明边距
   - 使用明亮、对比鲜明的颜色

## 图标生成步骤

1. 将准备好的图标文件 `app_icon.png` 放置在 `assets/icon/` 目录
2. 执行以下命令生成各平台所需的图标：

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

3. 生成完成后，图标将自动应用于各平台：
   - Android: `android/app/src/main/res/mipmap-*/`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - Windows: `windows/runner/resources/`
   - Web: `web/icons/`
   - macOS: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

## 打包应用

图标生成完成后，使用以下命令打包应用：

```bash
# Android打包
flutter build apk --release

# iOS打包
flutter build ios --release

# Windows打包
flutter build windows --release

# macOS打包
flutter build macos --release

# Web打包
flutter build web --release
```

## 常见问题

1. **图标不显示**：确保图标尺寸正确且格式为PNG
2. **图标模糊**：原始图标可能分辨率太低，请使用高分辨率图标
3. **图标被裁剪**：某些平台会自动裁剪图标，请确保重要内容位于中心区域 