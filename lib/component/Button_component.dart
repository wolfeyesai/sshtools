// ignore_for_file: file_names, library_private_types_in_public_api, unreachable_switch_default, unused_local_variable, avoid_unnecessary_containers, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// 按钮类型枚举
enum ButtonType {
  standard,   // 标准按钮
  outline,    // 轮廓按钮
  primary,    // 主要按钮
  secondary,  // 次要按钮
  warning,    // 警告按钮
  danger,     // 危险按钮
  success,    // 成功按钮
  info,       // 信息按钮
  disabled,   // 禁用按钮
  custom,     // 自定义按钮
}

/// 按钮尺寸枚举
enum ButtonSize {
  small,      // 小尺寸
  medium,     // 中等尺寸
  large,      // 大尺寸
}

/// 按钮形状枚举
enum ButtonShape {
  standard,   // 标准形状
  pill,       // 药丸形
  circle,     // 圆形
}

/// 按钮组件类
/// 提供基于GetWidget库的按钮功能
class ButtonComponent {
  // 按钮默认颜色映射表
  static final Map<ButtonType, Color> _defaultColors = {
    ButtonType.standard: Colors.blue,
    ButtonType.primary: Colors.blue,
    ButtonType.secondary: Colors.grey,
    ButtonType.warning: Colors.orange,
    ButtonType.danger: Colors.red,
    ButtonType.success: Colors.green,
    ButtonType.info: Colors.lightBlue,
    ButtonType.outline: Colors.blue,
    ButtonType.disabled: Colors.grey.shade300,
    ButtonType.custom: Colors.indigo,
  };

  // 按钮默认文本颜色映射表
  static final Map<ButtonType, Color> _defaultTextColors = {
    ButtonType.standard: Colors.white,
    ButtonType.primary: Colors.white,
    ButtonType.secondary: Colors.white,
    ButtonType.warning: Colors.white,
    ButtonType.danger: Colors.white,
    ButtonType.success: Colors.white,
    ButtonType.info: Colors.white,
    ButtonType.outline: Colors.blue,
    ButtonType.disabled: Colors.grey.shade700,
    ButtonType.custom: Colors.white,
  };

  /// 创建按钮
  /// 
  /// [type] 按钮类型
  /// [label] 按钮文字
  /// [onPressed] 点击回调
  /// [size] 按钮尺寸
  /// [shape] 按钮形状
  /// [icon] 按钮图标
  /// [fullWidth] 是否占满宽度
  /// [elevation] 按钮阴影高度
  /// [textColor] 文字颜色（覆盖默认颜色）
  /// [backgroundColor] 背景颜色（覆盖默认颜色）
  /// [borderColor] 边框颜色（覆盖默认颜色）
  /// [borderWidth] 边框宽度
  static Widget create({
    ButtonType type = ButtonType.standard,
    required String label,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    ButtonShape shape = ButtonShape.standard,
    Icon? icon,
    bool fullWidth = false,
    double elevation = 0,
    Color? textColor,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 1.0,
  }) {
    // 获取按钮默认颜色
    final Color defaultColor = _defaultColors[type] ?? Colors.blue;
    
    // 获取按钮默认文本颜色
    final Color defaultTextColor = _defaultTextColors[type] ?? Colors.white;
    
    // 最终按钮颜色
    final Color buttonColor = backgroundColor ?? defaultColor;
    
    // 最终文本颜色
    final Color buttonTextColor = textColor ?? defaultTextColor;
    
    // 最终边框颜色
    final Color buttonBorderColor = borderColor ?? 
        (type == ButtonType.outline || type == ButtonType.secondary ? 
        buttonColor : Colors.transparent);
    
    // 转换尺寸
    final double gfSize = _convertButtonSize(size);
    
    // 处理禁用状态
    final VoidCallback? buttonOnPressed = 
        (type == ButtonType.disabled) ? null : onPressed;
    
    // 根据形状创建不同的按钮
    if (shape == ButtonShape.circle) {
      return _createCircleButton(
        type: type,
        icon: icon,
        onPressed: buttonOnPressed,
        size: gfSize,
        color: buttonColor,
        borderColor: buttonBorderColor,
        borderWidth: borderWidth,
        elevation: elevation,
      );
    } else {
      // 获取按钮形状
      final GFButtonShape gfShape = _convertButtonShape(shape);
      
      // 获取按钮类型
      final GFButtonType gfType = _getButtonType(type);
      
      // 创建按钮
      return GFButton(
        onPressed: buttonOnPressed,
        text: label,
        icon: icon,
        size: gfSize,
        shape: gfShape,
        type: gfType,
        fullWidthButton: fullWidth,
        textColor: buttonTextColor,
        color: buttonColor,
        borderSide: BorderSide(
          color: buttonBorderColor,
          width: borderWidth,
        ),
        elevation: elevation,
        disabledColor: _defaultColors[ButtonType.disabled],
        disabledTextColor: _defaultTextColors[ButtonType.disabled],
      );
    }
  }
  
  /// 创建圆形按钮
  static Widget _createCircleButton({
    required ButtonType type,
    required Icon? icon,
    required VoidCallback? onPressed,
    required double size,
    required Color color,
    required Color borderColor,
    required double borderWidth,
    required double elevation,
  }) {
    return GFIconButton(
      onPressed: onPressed,
      icon: icon ?? const Icon(Icons.add),
      type: _getButtonType(type),
      shape: GFIconButtonShape.circle,
      size: size,
      color: color,
      boxShadow: borderColor != Colors.transparent 
          ? BoxShadow(
              color: borderColor.withOpacity(0.5),
              blurRadius: borderWidth,
              spreadRadius: borderWidth / 2,
            ) 
          : null,
      disabledColor: _defaultColors[ButtonType.disabled],
    );
  }
  
  /// 转换按钮尺寸
  static double _convertButtonSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return GFSize.SMALL;
      case ButtonSize.large:
        return GFSize.LARGE;
      case ButtonSize.medium:
      default:
        return GFSize.MEDIUM;
    }
  }
  
  /// 转换按钮形状
  static GFButtonShape _convertButtonShape(ButtonShape shape) {
    switch (shape) {
      case ButtonShape.pill:
        return GFButtonShape.pills;
      case ButtonShape.standard:
      default:
        return GFButtonShape.standard;
    }
  }

  /// 获取按钮类型对应的GFButtonType
  static GFButtonType _getButtonType(ButtonType type) {
    switch (type) {
      case ButtonType.outline:
        return GFButtonType.outline;
      case ButtonType.secondary:
        return GFButtonType.outline2x;
      case ButtonType.disabled:
        return GFButtonType.transparent;
      case ButtonType.standard:
      case ButtonType.primary:
      case ButtonType.warning:
      case ButtonType.danger:
      case ButtonType.success:
      case ButtonType.info:
      case ButtonType.custom:
      default:
        return GFButtonType.solid;
    }
  }
}
