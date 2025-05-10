// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use, sort_child_properties_last, unreachable_switch_default

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// 消息类型枚举
enum MessageType {
  info,     // 信息提示
  success,  // 成功提示
  warning,  // 警告提示
  error,    // 错误提示
}

/// 消息位置枚举
enum MessagePosition {
  top,      // 顶部显示
  center,   // 中间显示
  bottom,   // 底部显示
}

/// 消息组件类
/// 提供基于GetWidget库的消息提示功能
class MessageComponent {
  // 消息类型对应的颜色映射表
  static final Map<MessageType, Color> _typeColors = {
    MessageType.info: Colors.blue,
    MessageType.success: Colors.green,
    MessageType.warning: Colors.orange,
    MessageType.error: Colors.red,
  };

  // 消息类型对应的图标映射表
  static final Map<MessageType, IconData> _typeIcons = {
    MessageType.info: Icons.info_outline,
    MessageType.success: Icons.check_circle_outline,
    MessageType.warning: Icons.warning_amber_outlined,
    MessageType.error: Icons.error_outline,
  };

  /// 显示Toast消息
  /// 
  /// [context] 上下文
  /// [message] 消息内容
  /// [type] 消息类型
  /// [duration] 显示时长（秒）
  /// [position] 显示位置
  /// [toastBorderRadius] Toast边框圆角
  /// [backgroundColor] 背景颜色（覆盖默认颜色）
  /// [textColor] 文字颜色
  /// [fontSize] 字体大小
  /// [trailing] 尾部组件
  static void showToast({
    required BuildContext context,
    required String message,
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
    MessagePosition position = MessagePosition.bottom,
    double toastBorderRadius = 12.0,
    Color? backgroundColor,
    Color textColor = Colors.white,
    double fontSize = 16.0,
    Widget? trailing,
  }) {
    // 获取颜色
    final Color bgColor = backgroundColor ?? _typeColors[type]!;
    
    // 获取位置
    final GFToastPosition toastPosition = _getToastPosition(position);
    
    // 将Duration转换为秒数（int类型）
    final int durationInSeconds = duration.inSeconds;
    
    // 显示Toast
    GFToast.showToast(
      message,
      context,
      toastDuration: durationInSeconds,
      toastPosition: toastPosition,
      backgroundColor: bgColor,
      textStyle: TextStyle(
        color: textColor,
        fontSize: fontSize,
      ),
      toastBorderRadius: toastBorderRadius,
      trailing: trailing,
    );
  }

  /// 显示带图标的Toast消息
  /// 
  /// [context] 上下文
  /// [message] 消息内容
  /// [type] 消息类型
  /// [duration] 显示时长
  /// [position] 显示位置
  static void showIconToast({
    required BuildContext context,
    required String message,
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
    MessagePosition position = MessagePosition.bottom,
  }) {
    // 获取颜色和图标
    final Color bgColor = _typeColors[type]!;
    final IconData iconData = _typeIcons[type]!;
    
    // 创建尾部图标组件
    final Widget trailing = Icon(
      iconData,
      color: Colors.white,
      size: 20,
    );
    
    // 显示Toast
    showToast(
      context: context,
      message: message,
      type: type,
      duration: duration,
      position: position,
      backgroundColor: bgColor,
      trailing: trailing,
    );
  }

  /// 显示浮动消息卡片
  /// 
  /// [context] 上下文
  /// [title] 标题
  /// [message] 消息内容
  /// [type] 消息类型
  /// [duration] 显示时长
  /// [position] 显示位置
  /// [onDismiss] 消失回调
  static void showFloatingMessage({
    required BuildContext context,
    required String title,
    required String message,
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
    MessagePosition position = MessagePosition.top,
    VoidCallback? onDismiss,
  }) {
    // 获取颜色和图标
    final Color bgColor = _typeColors[type]!;
    final IconData iconData = _typeIcons[type]!;
    
    // 创建自定义内容
    final Widget customContent = ListTile(
      leading: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor.withOpacity(0.1),
        ),
        child: Icon(
          iconData,
          color: bgColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(message),
      dense: true,
    );
    
    // 计算垂直位置
    double verticalPosition;
    switch (position) {
      case MessagePosition.top:
        verticalPosition = MediaQuery.of(context).size.height * 0.1;
        break;
      case MessagePosition.center:
        verticalPosition = MediaQuery.of(context).size.height * 0.4;
        break;
      case MessagePosition.bottom:
        verticalPosition = MediaQuery.of(context).size.height * 0.7;
        break;
    }
    
    // 显示自定义消息
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          // 设置定时器自动关闭
          Future.delayed(duration, () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              if (onDismiss != null) {
                onDismiss();
              }
            }
          });
          
          return GFFloatingWidget(
            verticalPosition: verticalPosition,
            horizontalPosition: 0,
            showBlurness: true,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                if (onDismiss != null) {
                  onDismiss();
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4.0,
                  child: customContent,
                ),
              ),
            ),
            body: Container(),
          );
        },
      ),
    );
  }

  /// 转换Toast位置
  static GFToastPosition _getToastPosition(MessagePosition position) {
    switch (position) {
      case MessagePosition.top:
        return GFToastPosition.TOP;
      case MessagePosition.center:
        return GFToastPosition.CENTER;
      case MessagePosition.bottom:
      default:
        return GFToastPosition.BOTTOM;
    }
  }
}

/// 消息组件使用示例：
/// 
/// 1. 显示简单的Toast提示：
/// ```dart
/// MessageComponent.showToast(
///   context: context,
///   message: '操作已完成',
///   type: MessageType.success,
/// );
/// ```
/// 
/// 2. 显示带图标的Toast提示：
/// ```dart
/// MessageComponent.showIconToast(
///   context: context,
///   message: '发生错误，请重试',
///   type: MessageType.error,
/// );
/// ```
/// 
/// 3. 显示浮动消息：
/// ```dart
/// MessageComponent.showFloatingMessage(
///   context: context,
///   title: '新消息',
///   message: '您有一条新消息',
///   type: MessageType.info,
///   duration: const Duration(seconds: 5),
/// );
/// ```
