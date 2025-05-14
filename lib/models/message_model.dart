// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// 消息类型枚举
enum MessageType {
  info,
  success,
  warning,
  error,
}

/// 消息位置枚举
enum MessagePosition {
  top,
  center,
  bottom,
}

/// 消息模型
class MessageModel {
  /// 消息内容
  final String content;
  
  /// 消息类型
  final MessageType type;
  
  /// 是否显示图标
  final bool showIcon;
  
  /// 自定义图标
  final IconData? icon;
  
  /// 显示时长(毫秒)
  final int duration;
  
  /// 消息位置
  final MessagePosition position;
  
  /// 是否可关闭
  final bool closable;
  
  /// 是否显示背景
  final bool showBackground;
  
  /// 标题（可选）
  final String? title;
  
  /// 唯一ID
  final String id;

  /// 构造函数
  MessageModel({
    required this.content,
    this.type = MessageType.info,
    this.showIcon = true,
    this.icon,
    this.duration = 3000,
    this.position = MessagePosition.top,
    this.closable = true,
    this.showBackground = true,
    this.title,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();

  /// 复制模型并应用新值
  MessageModel copyWith({
    String? content,
    MessageType? type,
    bool? showIcon,
    IconData? icon,
    int? duration,
    MessagePosition? position,
    bool? closable,
    bool? showBackground,
    String? title,
  }) {
    return MessageModel(
      content: content ?? this.content,
      type: type ?? this.type,
      showIcon: showIcon ?? this.showIcon,
      icon: icon ?? this.icon,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      closable: closable ?? this.closable,
      showBackground: showBackground ?? this.showBackground,
      title: title ?? this.title,
    );
  }

  /// 获取消息图标
  IconData getIcon() {
    if (icon != null) return icon!;
    
    switch (type) {
      case MessageType.info:
        return Icons.info_outline;
      case MessageType.success:
        return Icons.check_circle_outline;
      case MessageType.warning:
        return Icons.warning_amber_outlined;
      case MessageType.error:
        return Icons.error_outline;
    }
  }

  /// 获取消息颜色
  Color getColor(BuildContext context) {
    switch (type) {
      case MessageType.info:
        return Colors.blue;
      case MessageType.success:
        return Colors.green;
      case MessageType.warning:
        return Colors.orange;
      case MessageType.error:
        return Colors.red;
    }
  }

  /// 获取消息背景颜色
  Color getBackgroundColor() {
    switch (type) {
      case MessageType.info:
        return Colors.blue.withOpacity(0.1);
      case MessageType.success:
        return Colors.green.withOpacity(0.1);
      case MessageType.warning:
        return Colors.orange.withOpacity(0.1);
      case MessageType.error:
        return Colors.red.withOpacity(0.1);
    }
  }

  /// 获取定位偏移
  double getPositionOffset() {
    switch (position) {
      case MessagePosition.top:
        return 20.0;
      case MessagePosition.center:
        return 0.0;
      case MessagePosition.bottom:
        return 20.0;
    }
  }

  /// 获取消息类型名称
  String getTypeName() {
    switch (type) {
      case MessageType.info:
        return '提示';
      case MessageType.success:
        return '成功';
      case MessageType.warning:
        return '警告';
      case MessageType.error:
        return '错误';
    }
  }
} 