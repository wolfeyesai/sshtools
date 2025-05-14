// ignore_for_file: file_names, unreachable_switch_default, use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';

/// 消息类型枚举
enum MessageType {
  success,  // 成功消息
  error,    // 错误消息
  info,     // 信息消息
  warning   // 警告消息
}

/// 全局悬浮消息显示方法
void showOverlayMessage(
  BuildContext context, {
  required String message,
  MessageType type = MessageType.info,
  int autoCloseDuration = 3,
  bool showCountdown = true,
  VoidCallback? onClose,
}) {
  final overlayState = Overlay.of(context);
  
  // 计算顶部安全区域高度
  final topPadding = MediaQuery.of(context).padding.top;
  
  OverlayEntry? entry;
  bool isRemoved = false;  // 添加标记，避免重复移除
  
  // 关闭消息的函数
  void closeMessage() {
    // 添加额外的检查，确保不会重复移除
    if (entry != null && !isRemoved) {
      try {
        entry.remove();
        isRemoved = true;  // 设置标记为已移除
        if (onClose != null) {
          onClose();
        }
      } catch (e) {
        // 捕获可能的异常，防止应用崩溃
        debugPrint('关闭消息时出错: $e');
      }
    }
  }
  
  // 创建一个OverlayEntry
  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: MessageComponent(
              message: message,
              type: type,
              autoCloseDuration: autoCloseDuration,
              showCountdown: showCountdown,
              onClose: closeMessage,
            ),
          ),
        ),
      ),
    ),
  );
  
  // 添加到Overlay
  overlayState.insert(entry);
  
  // 自动关闭
  if (autoCloseDuration > 0) {
    Future.delayed(Duration(seconds: autoCloseDuration), () {
      // 延迟操作中再次检查状态，确保不会在组件销毁后调用
      if (!isRemoved) {
        closeMessage();
      }
    });
  }
}

/// 顶部消息组件，用于显示操作结果、通知等信息
class MessageComponent extends StatefulWidget {
  /// 消息文本
  final String message;
  
  /// 消息类型
  final MessageType type;
  
  /// 是否显示关闭按钮
  final bool showCloseButton;
  
  /// 自动关闭时间（秒）
  final int autoCloseDuration;
  
  /// 关闭回调
  final VoidCallback? onClose;
  
  /// 是否显示倒计时
  final bool showCountdown;
  
  /// 构造函数
  const MessageComponent({
    Key? key,
    required this.message,
    this.type = MessageType.info,
    this.showCloseButton = true,
    this.autoCloseDuration = 1,
    this.onClose,
    this.showCountdown = true,
  }) : super(key: key);
  
  @override
  State<MessageComponent> createState() => _MessageComponentState();
}

class _MessageComponentState extends State<MessageComponent> with SingleTickerProviderStateMixin {
  Timer? _autoCloseTimer;
  late AnimationController _animationController;
  int _secondsRemaining = 0;
  Timer? _countdownTimer;
  bool _isClosed = false;  // 添加状态标记
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器，用于进度条动画
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.autoCloseDuration),
    );
    
    // 开始倒计时
    if (widget.autoCloseDuration > 0) {
      _secondsRemaining = widget.autoCloseDuration;
      
      // 启动动画控制器
      _animationController.forward();
      
      // 设置自动关闭定时器
      _autoCloseTimer = Timer(
        Duration(seconds: widget.autoCloseDuration), 
        () {
          if (!_isClosed && mounted) {
            _close();
          }
        }
      );
      
      // 设置倒计时更新定时器
      if (widget.showCountdown) {
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _secondsRemaining = widget.autoCloseDuration - timer.tick;
              if (_secondsRemaining <= 0) {
                _countdownTimer?.cancel();
              }
            });
          } else {
            timer.cancel();  // 如果组件已卸载，取消定时器
          }
        });
      }
    }
  }
  
  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _countdownTimer?.cancel();
    _animationController.dispose();
    _isClosed = true;  // 标记为已关闭
    super.dispose();
  }
  
  /// 关闭消息
  void _close() {
    if (!_isClosed && widget.onClose != null) {
      _isClosed = true;  // 标记为已关闭，防止重复调用
      widget.onClose!();
    }
  }
  
  /// 获取消息类型对应的颜色
  Color _getBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return Colors.green.shade100;
      case MessageType.error:
        return Colors.red.shade100;
      case MessageType.warning:
        return Colors.orange.shade100;
      case MessageType.info:
      default:
        return Colors.blue.shade100;
    }
  }
  
  /// 获取消息类型对应的图标颜色
  Color _getIconColor() {
    switch (widget.type) {
      case MessageType.success:
        return Colors.green.shade800;
      case MessageType.error:
        return Colors.red.shade800;
      case MessageType.warning:
        return Colors.orange.shade800;
      case MessageType.info:
      default:
        return Colors.blue.shade800;
    }
  }
  
  /// 获取消息类型对应的图标
  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.error;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.info:
      default:
        return Icons.info;
    }
  }
  
  /// 构建进度条
  Widget _buildProgressBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: 1.0 - _animationController.value,
            backgroundColor: Colors.transparent,
            color: _getIconColor().withOpacity(0.3),
            minHeight: 2,
          );
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: _getBackgroundColor(),
            child: Row(
              children: [
                Icon(
                  _getIcon(),
                  color: _getIconColor(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: _getIconColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.showCountdown && widget.autoCloseDuration > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getIconColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_secondsRemaining',
                      style: TextStyle(
                        color: _getIconColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (widget.showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _close,
                    color: _getIconColor(),
                  ),
              ],
            ),
          ),
          if (widget.autoCloseDuration > 0)
            _buildProgressBar(),
        ],
      ),
    );
  }
}

/// 消息管理器
class MessageManager {
  /// 单例实例
  static final MessageManager _instance = MessageManager._internal();
  
  /// 私有构造函数
  MessageManager._internal();
  
  /// 获取单例实例
  factory MessageManager() => _instance;
  
  /// 全局键，用于访问 ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  /// 显示消息
  void showMessage({
    required String message,
    MessageType type = MessageType.info,
    int durationInSeconds = 5,
    bool showCountdown = true,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    
    // 隐藏当前消息
    messenger.hideCurrentSnackBar();
    
    // 显示新消息
    messenger.showSnackBar(
      SnackBar(
        content: MessageComponent(
          message: message,
          type: type,
          autoCloseDuration: durationInSeconds,
          showCountdown: showCountdown,
          onClose: () {
            messenger.hideCurrentSnackBar();
          },
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(seconds: durationInSeconds),
      ),
    );
  }
  
  /// 显示成功消息
  void showSuccess(String message, {int durationInSeconds = 5, bool showCountdown = true}) {
    showMessage(
      message: message,
      type: MessageType.success,
      durationInSeconds: durationInSeconds,
      showCountdown: showCountdown,
    );
  }
  
  /// 显示错误消息
  void showError(String message, {int durationInSeconds = 5, bool showCountdown = true}) {
    showMessage(
      message: message,
      type: MessageType.error,
      durationInSeconds: durationInSeconds,
      showCountdown: showCountdown,
    );
  }
  
  /// 显示警告消息
  void showWarning(String message, {int durationInSeconds = 5, bool showCountdown = true}) {
    showMessage(
      message: message,
      type: MessageType.warning,
      durationInSeconds: durationInSeconds,
      showCountdown: showCountdown,
    );
  }
  
  /// 显示信息消息
  void showInfo(String message, {int durationInSeconds = 5, bool showCountdown = true}) {
    showMessage(
      message: message,
      type: MessageType.info,
      durationInSeconds: durationInSeconds,
      showCountdown: showCountdown,
    );
  }
}

/// 消息组件工厂
/// 提供创建各种类型消息的静态方法
class MessageComponentFactory {
  /// 创建消息组件（用于内嵌在界面中）
  /// 
  /// [message] - 消息内容
  /// [type] - 消息类型
  /// [showCloseButton] - 是否显示关闭按钮
  /// [autoCloseDuration] - 自动关闭时间（秒）
  /// [showCountdown] - 是否显示倒计时
  /// [onClose] - 关闭回调函数
  static Widget create({
    required String message,
    MessageType type = MessageType.info,
    bool showCloseButton = true,
    int autoCloseDuration = 5,
    bool showCountdown = true,
    VoidCallback? onClose,
  }) {
    return MessageComponent(
      message: message,
      type: type,
      showCloseButton: showCloseButton,
      autoCloseDuration: autoCloseDuration,
      showCountdown: showCountdown,
      onClose: onClose,
    );
  }
  
  /// 显示悬浮消息（显示在界面顶部，不占用布局空间）
  /// 
  /// [context] - 上下文
  /// [message] - 消息内容
  /// [type] - 消息类型
  /// [autoCloseDuration] - 自动关闭时间（秒）
  /// [showCountdown] - 是否显示倒计时
  /// [onClose] - 关闭回调函数
  static void show(
    BuildContext context, {
    required String message,
    MessageType type = MessageType.info,
    int autoCloseDuration = 3,
    bool showCountdown = true,
    VoidCallback? onClose,
  }) {
    showOverlayMessage(
      context,
      message: message,
      type: type,
      autoCloseDuration: autoCloseDuration,
      showCountdown: showCountdown,
      onClose: onClose,
    );
  }
  
  /// 显示成功消息
  static void showSuccess(
    BuildContext context, {
    required String message,
    int autoCloseDuration = 3,
    bool showCountdown = true,
    VoidCallback? onClose,
  }) {
    show(
      context,
      message: message,
      type: MessageType.success,
      autoCloseDuration: autoCloseDuration,
      showCountdown: showCountdown,
      onClose: onClose,
    );
  }
  
  /// 显示错误消息
  static void showError(
    BuildContext context, {
    required String message,
    int autoCloseDuration = 3,
    bool showCountdown = true,
    VoidCallback? onClose,
  }) {
    show(
      context,
      message: message,
      type: MessageType.error,
      autoCloseDuration: autoCloseDuration,
      showCountdown: showCountdown,
      onClose: onClose,
    );
  }
  
  /// 显示警告消息
  static void showWarning(
    BuildContext context, {
    required String message,
    int autoCloseDuration = 3,
    bool showCountdown = true,
    VoidCallback? onClose,
  }) {
    show(
      context,
      message: message,
      type: MessageType.warning,
      autoCloseDuration: autoCloseDuration,
      showCountdown: showCountdown,
      onClose: onClose,
    );
  }
  
  /// 显示信息消息
  static void showInfo(
    BuildContext context, {
    required String message,
    int autoCloseDuration = 3,
    bool showCountdown = true,
    VoidCallback? onClose,
  }) {
    show(
      context,
      message: message,
      type: MessageType.info,
      autoCloseDuration: autoCloseDuration,
      showCountdown: showCountdown,
      onClose: onClose,
    );
  }
} 