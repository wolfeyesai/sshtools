// 封装的进度条组件，基于GetWidget库

// ignore_for_file: unreachable_switch_default

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// 进度条类型枚举
enum ProgressBarType {
  linear,   // 线性进度条
  circular, // 圆形进度条
}

/// 进度条样式枚举
enum ProgressBarStyle {
  determinate,   // 确定进度（有具体数值）
  indeterminate, // 不确定进度（无具体数值，只显示加载动画）
}

/// 进度条尺寸枚举
enum ProgressBarSize {
  small,  // 小尺寸
  medium, // 中等尺寸
  large,  // 大尺寸
}

/// 进度条组件，封装了GFProgressBar
class ProgressBarComponent {
  /// 创建进度条
  /// 
  /// [type] 进度条类型，线性或圆形
  /// [progress] 当前进度值，0.0到1.0之间
  /// [style] 进度条样式，确定进度或不确定进度
  /// [size] 进度条尺寸
  /// [width] 进度条宽度（仅用于圆形进度条）
  /// [radius] 圆形进度条半径
  /// [lineHeight] 线性进度条高度
  /// [backgroundColor] 背景颜色
  /// [progressColor] 进度颜色
  /// [animation] 是否启用动画
  /// [animationDuration] 动画持续时间（毫秒）
  /// [showPercentage] 是否显示百分比文本（仅用于圆形进度条）
  /// [textStyle] 百分比文本样式（仅用于圆形进度条）
  /// [leading] 进度条前部小部件
  /// [trailing] 进度条尾部小部件
  /// [padding] 内边距
  /// [margin] 外边距
  static Widget create({
    ProgressBarType type = ProgressBarType.linear,
    double progress = 0.0,
    ProgressBarStyle style = ProgressBarStyle.determinate,
    ProgressBarSize size = ProgressBarSize.medium,
    double? width,
    double? radius,
    double? lineHeight,
    Color? backgroundColor,
    Color? progressColor,
    bool animation = true,
    int animationDuration = 1000,
    bool showPercentage = true,
    TextStyle? textStyle,
    Widget? leading,
    Widget? trailing,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    // 进度值限制在0.0到1.0之间
    final double safeProgress = progress.clamp(0.0, 1.0);
    
    // 不确定进度时，将进度设为-1.0（表示不确定进度）
    final double finalProgress = 
        style == ProgressBarStyle.indeterminate ? -1.0 : safeProgress;
    
    // 根据尺寸设置线性进度条高度
    final double defaultLineHeight = _getLineHeightBySize(size);
    
    // 根据尺寸设置圆形进度条半径
    final double defaultRadius = _getRadiusBySize(size);
    
    // 默认颜色
    final Color defaultBackgroundColor = Colors.grey.shade200;
    final Color defaultProgressColor = Colors.blue;
    
    // 创建进度条
    if (type == ProgressBarType.circular) {
      return _createCircularProgressBar(
        progress: finalProgress,
        radius: radius ?? defaultRadius,
        width: width ?? (radius ?? defaultRadius) / 5,
        backgroundColor: backgroundColor ?? defaultBackgroundColor,
        progressColor: progressColor ?? defaultProgressColor,
        animation: animation,
        animationDuration: animationDuration,
        showPercentage: showPercentage,
        textStyle: textStyle,
        padding: padding,
        margin: margin,
      );
    } else {
      return _createLinearProgressBar(
        progress: finalProgress,
        lineHeight: lineHeight ?? defaultLineHeight,
        backgroundColor: backgroundColor ?? defaultBackgroundColor,
        progressColor: progressColor ?? defaultProgressColor,
        animation: animation,
        animationDuration: animationDuration,
        leading: leading,
        trailing: trailing,
        padding: padding,
        margin: margin,
      );
    }
  }
  
  /// 创建线性进度条
  static Widget _createLinearProgressBar({
    required double progress,
    required double lineHeight,
    required Color backgroundColor,
    required Color progressColor,
    required bool animation,
    required int animationDuration,
    required Widget? leading,
    required Widget? trailing,
    required EdgeInsetsGeometry? padding,
    required EdgeInsetsGeometry? margin,
  }) {
    // 处理未确定进度的情况
    final bool isIndeterminate = progress < 0;
    
    // 创建进度条或加载指示器
    if (isIndeterminate) {
      return Container(
        padding: padding,
        margin: margin,
        child: GFLoader(
          type: GFLoaderType.android,
          loaderColorOne: progressColor,
          loaderColorTwo: progressColor,
          loaderColorThree: progressColor,
        ),
      );
    }
    
    return Container(
      padding: padding,
      margin: margin,
      child: GFProgressBar(
        percentage: progress,
        lineHeight: lineHeight,
        backgroundColor: backgroundColor,
        progressBarColor: progressColor,
        animation: animation,
        animationDuration: animationDuration,
        leading: leading,
        trailing: trailing,
        child: Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  /// 创建圆形进度条
  static Widget _createCircularProgressBar({
    required double progress,
    required double radius,
    required double width,
    required Color backgroundColor,
    required Color progressColor,
    required bool animation,
    required int animationDuration,
    required bool showPercentage,
    required TextStyle? textStyle,
    required EdgeInsetsGeometry? padding,
    required EdgeInsetsGeometry? margin,
  }) {
    // 处理未确定进度的情况
    final bool isIndeterminate = progress < 0;
    
    // 创建进度条或加载指示器
    if (isIndeterminate) {
      return Container(
        padding: padding,
        margin: margin,
        child: GFLoader(
          type: GFLoaderType.circle,
          loaderColorOne: progressColor,
          loaderColorTwo: progressColor,
          loaderColorThree: progressColor,
          size: radius * 2,
        ),
      );
    }
    
    return Container(
      padding: padding,
      margin: margin,
      child: GFProgressBar(
        percentage: progress,
        radius: radius,
        circleWidth: width,
        backgroundColor: backgroundColor,
        progressBarColor: progressColor,
        animation: animation,
        animationDuration: animationDuration,
        type: GFProgressType.circular,
        child: !showPercentage ? null : Center(
          child: Text(
            '${(progress * 100).toInt()}%',
            style: textStyle ?? const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  /// 根据尺寸获取线性进度条高度
  static double _getLineHeightBySize(ProgressBarSize size) {
    switch (size) {
      case ProgressBarSize.small:
        return 5.0;
      case ProgressBarSize.large:
        return 15.0;
      case ProgressBarSize.medium:
      default:
        return 10.0;
    }
  }
  
  /// 根据尺寸获取圆形进度条半径
  static double _getRadiusBySize(ProgressBarSize size) {
    switch (size) {
      case ProgressBarSize.small:
        return 30.0;
      case ProgressBarSize.large:
        return 70.0;
      case ProgressBarSize.medium:
      default:
        return 50.0;
    }
  }
  
  /// 创建不确定进度的加载指示器
  static Widget createIndeterminateLoader({
    ProgressBarType type = ProgressBarType.circular,
    ProgressBarSize size = ProgressBarSize.medium,
    Color? color,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    final Color loaderColor = color ?? Colors.blue;
    
    // 根据尺寸获取加载指示器尺寸
    final double loaderSize = _getLoaderSizeBySize(size);
    
    return Container(
      padding: padding,
      margin: margin,
      child: type == ProgressBarType.circular
          ? GFLoader(
              type: GFLoaderType.circle,
              loaderColorOne: loaderColor,
              loaderColorTwo: loaderColor,
              loaderColorThree: loaderColor,
              size: loaderSize,
            )
          : GFLoader(
              type: GFLoaderType.android,
              loaderColorOne: loaderColor,
              loaderColorTwo: loaderColor,
              loaderColorThree: loaderColor,
              size: loaderSize,
            ),
    );
  }
  
  /// 根据尺寸获取加载指示器尺寸
  static double _getLoaderSizeBySize(ProgressBarSize size) {
    switch (size) {
      case ProgressBarSize.small:
        return GFSize.SMALL;
      case ProgressBarSize.large:
        return GFSize.LARGE;
      case ProgressBarSize.medium:
      default:
        return GFSize.MEDIUM;
    }
  }
} 