// ignore_for_file: library_private_types_in_public_api, sort_constructors_first, use_super_parameters

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// 背景类型枚举
enum BackgroundType {
  solid,       // 纯色背景
  gradient,    // 渐变背景
  image,       // 图片背景
  pattern,     // 图案背景
  shimmer,     // 闪光效果背景
}

/// 渐变类型枚举
enum GradientType {
  linear,      // 线性渐变
  radial,      // 径向渐变
  sweep,       // 扫描渐变
}

/// 背景组件类
/// 提供多种样式的UI背景效果
class BackgroundComponent extends StatefulWidget {
  /// 背景类型
  final BackgroundType type;
  
  /// 背景颜色（纯色背景时使用）
  final Color? backgroundColor;
  
  /// 渐变颜色列表（渐变背景时使用）
  final List<Color>? gradientColors;
  
  /// 渐变类型
  final GradientType gradientType;
  
  /// 渐变起始点（线性渐变时使用）
  final Alignment gradientBegin;
  
  /// 渐变结束点（线性渐变时使用）
  final Alignment gradientEnd;
  
  /// 背景图片路径（图片背景时使用）
  final String? imagePath;
  
  /// 网络图片URL（图片背景时使用）
  final String? imageUrl;
  
  /// 背景图片混合模式
  final BlendMode imageBlendMode;
  
  /// 背景图片颜色滤镜
  final Color? imageColorFilter;
  
  /// 图片背景模糊度
  final double? imageBlurLevel;
  
  /// 图案背景资源路径
  final String? patternAssetPath;
  
  /// 闪光效果颜色
  final Color? shimmerBaseColor;
  
  /// 闪光效果高亮颜色
  final Color? shimmerHighlightColor;
  
  /// 闪光效果方向
  final GFShimmerDirection shimmerDirection;
  
  /// 子组件
  final Widget child;
  
  /// 背景模糊度
  final double? blurLevel;
  
  /// 背景透明度
  final double opacity;
  
  /// 背景圆角
  final BorderRadius? borderRadius;
  
  /// 背景边框
  final BoxBorder? border;
  
  /// 背景阴影
  final List<BoxShadow>? boxShadow;
  
  /// 点击事件回调
  final VoidCallback? onTap;
  
  const BackgroundComponent({
    Key? key,
    required this.child,
    this.type = BackgroundType.solid,
    this.backgroundColor = Colors.white,
    this.gradientColors,
    this.gradientType = GradientType.linear,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.imagePath,
    this.imageUrl,
    this.imageBlendMode = BlendMode.srcOver,
    this.imageColorFilter,
    this.imageBlurLevel,
    this.patternAssetPath,
    this.shimmerBaseColor = const Color(0xFFEBEBF4),
    this.shimmerHighlightColor = const Color(0xFFF4F4F4),
    this.shimmerDirection = GFShimmerDirection.leftToRight,
    this.blurLevel,
    this.opacity = 1.0,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.onTap,
  }) : super(key: key);

  @override
  _BackgroundComponentState createState() => _BackgroundComponentState();
  
  /// 创建纯色背景
  static Widget createSolidBackground({
    required Widget child,
    Color backgroundColor = Colors.white,
    double opacity = 1.0,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
    VoidCallback? onTap,
  }) {
    return BackgroundComponent(
      type: BackgroundType.solid,
      backgroundColor: backgroundColor,
      opacity: opacity,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      onTap: onTap,
      child: child,
    );
  }
  
  /// 创建渐变背景
  static Widget createGradientBackground({
    required Widget child,
    required List<Color> gradientColors,
    GradientType gradientType = GradientType.linear,
    Alignment gradientBegin = Alignment.topLeft,
    Alignment gradientEnd = Alignment.bottomRight,
    double opacity = 1.0,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
    VoidCallback? onTap,
  }) {
    return BackgroundComponent(
      type: BackgroundType.gradient,
      gradientColors: gradientColors,
      gradientType: gradientType,
      gradientBegin: gradientBegin,
      gradientEnd: gradientEnd,
      opacity: opacity,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      onTap: onTap,
      child: child,
    );
  }
  
  /// 创建图片背景
  static Widget createImageBackground({
    required Widget child,
    String? imagePath,
    String? imageUrl,
    BlendMode imageBlendMode = BlendMode.srcOver,
    Color? imageColorFilter,
    double? imageBlurLevel,
    double opacity = 1.0,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
    VoidCallback? onTap,
  }) {
    return BackgroundComponent(
      type: BackgroundType.image,
      imagePath: imagePath,
      imageUrl: imageUrl,
      imageBlendMode: imageBlendMode,
      imageColorFilter: imageColorFilter,
      imageBlurLevel: imageBlurLevel,
      opacity: opacity,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      onTap: onTap,
      child: child,
    );
  }
  
  /// 创建图案背景
  static Widget createPatternBackground({
    required Widget child,
    required String patternAssetPath,
    Color? backgroundColor,
    double opacity = 1.0,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
    VoidCallback? onTap,
  }) {
    return BackgroundComponent(
      type: BackgroundType.pattern,
      patternAssetPath: patternAssetPath,
      backgroundColor: backgroundColor,
      opacity: opacity,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      onTap: onTap,
      child: child,
    );
  }
  
  /// 创建闪光效果背景
  static Widget createShimmerBackground({
    required Widget child,
    Color shimmerBaseColor = const Color(0xFFEBEBF4),
    Color shimmerHighlightColor = const Color(0xFFF4F4F4),
    GFShimmerDirection shimmerDirection = GFShimmerDirection.leftToRight,
    double opacity = 1.0,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
    VoidCallback? onTap,
  }) {
    return BackgroundComponent(
      type: BackgroundType.shimmer,
      shimmerBaseColor: shimmerBaseColor,
      shimmerHighlightColor: shimmerHighlightColor,
      shimmerDirection: shimmerDirection,
      opacity: opacity,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      onTap: onTap,
      child: child,
    );
  }
}

class _BackgroundComponentState extends State<BackgroundComponent> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: widget.type == BackgroundType.solid ? widget.backgroundColor : null,
          borderRadius: widget.borderRadius,
          border: widget.border,
          boxShadow: widget.boxShadow,
          gradient: _buildGradient(),
          image: _buildDecorationImage(),
        ),
        child: _buildChildWithBackground(),
      ),
    );
  }
  
  /// 构建背景渐变
  Gradient? _buildGradient() {
    if (widget.type != BackgroundType.gradient || widget.gradientColors == null) {
      return null;
    }
    
    switch (widget.gradientType) {
      case GradientType.linear:
        return LinearGradient(
          begin: widget.gradientBegin,
          end: widget.gradientEnd,
          colors: widget.gradientColors!,
        );
      case GradientType.radial:
        return RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: widget.gradientColors!,
        );
      case GradientType.sweep:
        return SweepGradient(
          center: Alignment.center,
          colors: widget.gradientColors!,
        );
    }
  }
  
  /// 构建背景图片
  DecorationImage? _buildDecorationImage() {
    if (widget.type != BackgroundType.image && widget.type != BackgroundType.pattern) {
      return null;
    }
    
    ImageProvider? imageProvider;
    
    if (widget.type == BackgroundType.image) {
      if (widget.imagePath != null) {
        imageProvider = AssetImage(widget.imagePath!);
      } else if (widget.imageUrl != null) {
        imageProvider = NetworkImage(widget.imageUrl!);
      }
    } else if (widget.type == BackgroundType.pattern && widget.patternAssetPath != null) {
      imageProvider = AssetImage(widget.patternAssetPath!);
    }
    
    if (imageProvider == null) {
      return null;
    }
    
    return DecorationImage(
      image: imageProvider,
      fit: BoxFit.cover,
      opacity: widget.opacity,
      colorFilter: widget.imageColorFilter != null
          ? ColorFilter.mode(widget.imageColorFilter!, widget.imageBlendMode)
          : null,
    );
  }
  
  /// 根据背景类型构建子组件
  Widget _buildChildWithBackground() {
    // 应用背景模糊效果
    Widget result = widget.child;
    
    // 如果需要模糊效果
    if (widget.blurLevel != null && widget.blurLevel! > 0) {
      result = ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurLevel!,
            sigmaY: widget.blurLevel!,
          ),
          child: widget.child,
        ),
      );
    }
    
    // 闪光效果背景特殊处理
    if (widget.type == BackgroundType.shimmer) {
      result = GFShimmer(
        mainColor: widget.shimmerBaseColor!,
        secondaryColor: widget.shimmerHighlightColor!,
        direction: widget.shimmerDirection,
        child: Opacity(
          opacity: widget.opacity,
          child: result,
        ),
      );
    } else {
      // 其他背景类型直接应用透明度
      result = Opacity(
        opacity: widget.opacity,
        child: result,
      );
    }
    
    return result;
  }
} 

// --------------------- 使用示例 ---------------------
/*
  // 1. 创建简单的纯色背景
  BackgroundComponent.createSolidBackground(
    backgroundColor: Colors.blue.shade100,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('这是纯色背景示例'),
    ),
  ),
  
  // 2. 创建线性渐变背景
  BackgroundComponent.createGradientBackground(
    gradientColors: [Colors.purple.shade300, Colors.pink.shade200],
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('这是渐变背景示例'),
    ),
  ),
  
  // 3. 创建径向渐变背景
  BackgroundComponent.createGradientBackground(
    gradientColors: [Colors.blue.shade300, Colors.green.shade200],
    gradientType: GradientType.radial,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('这是径向渐变背景示例'),
    ),
  ),
  
  // 4. 创建本地图片背景
  BackgroundComponent.createImageBackground(
    imagePath: 'assets/images/background.jpg',
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        '这是图片背景示例',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
  
  // 5. 创建网络图片背景
  BackgroundComponent.createImageBackground(
    imageUrl: 'https://picsum.photos/800/400',
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        '这是网络图片背景示例',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
  
  // 6. 创建带图片滤镜的背景
  BackgroundComponent.createImageBackground(
    imageUrl: 'https://picsum.photos/800/401',
    imageColorFilter: Colors.blue.withOpacity(0.5),
    imageBlendMode: BlendMode.overlay,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        '这是图片滤镜背景示例',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
  
  // 7. 创建带模糊效果的背景
  BackgroundComponent(
    type: BackgroundType.image,
    imageUrl: 'https://picsum.photos/800/402',
    blurLevel: 5.0,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        '这是模糊背景示例',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
  
  // 8. 创建闪光效果背景（适用于加载状态）
  BackgroundComponent.createShimmerBackground(
    shimmerBaseColor: Colors.grey.shade300,
    shimmerHighlightColor: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('这是闪光效果背景示例'),
    ),
  ),
  
  // 9. 创建带边框和阴影的背景
  BackgroundComponent(
    type: BackgroundType.solid,
    backgroundColor: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.blue.shade300, width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.shade100,
        blurRadius: 10,
        offset: Offset(0, 5),
      ),
    ],
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('这是带边框和阴影的背景示例'),
    ),
  ),
  
  // 10. 创建可点击的背景
  BackgroundComponent(
    type: BackgroundType.gradient,
    gradientColors: [Colors.orange.shade200, Colors.deepOrange.shade200],
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.orange.withOpacity(0.3),
        blurRadius: 8,
        offset: Offset(0, 3),
      ),
    ],
    onTap: () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('你点击了背景！'))
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('点击此背景触发事件'),
    ),
  ),
  
  // 11. 在登录界面中使用背景组件
  Scaffold(
    body: Center(
      child: BackgroundComponent.createGradientBackground(
        gradientColors: [Colors.blue.shade100, Colors.lightBlue.shade50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        child: Container(
          width: 400,
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('登录', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextField(decoration: InputDecoration(labelText: '用户名')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: '密码'), obscureText: true),
              SizedBox(height: 20),
              ElevatedButton(onPressed: () {}, child: Text('登录')),
            ],
          ),
        ),
      ),
    ),
  ),
  
  // 12. 在列表项中使用背景组件
  ListView.builder(
    itemCount: 10,
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: BackgroundComponent.createSolidBackground(
          backgroundColor: index % 2 == 0 ? Colors.blue.shade50 : Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('列表项 ${index + 1}'),
            subtitle: Text('这是列表项描述'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
      );
    },
  ),
*/ 