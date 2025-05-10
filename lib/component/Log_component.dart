// ignore_for_file: file_names, use_super_parameters, library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 日志级别枚举
enum LogLevel {
  info,    // 信息级别，用于一般信息
  warning, // 警告级别，用于警告信息
  error,   // 错误级别，用于错误信息
  success, // 成功级别，用于成功信息
  debug,   // 调试级别，用于调试信息
}

/// 日志项模型
class LogItem {
  /// 日志内容
  final String message;
  
  /// 日志级别
  final LogLevel level;
  
  /// 时间戳
  final DateTime timestamp;
  
  /// 附加数据，可以是任意类型
  final dynamic data;
  
  /// 构造函数
  LogItem({
    required this.message,
    this.level = LogLevel.info,
    DateTime? timestamp,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// 创建信息级别日志
  static LogItem info(String message, {dynamic data}) {
    return LogItem(
      message: message,
      level: LogLevel.info,
      data: data,
    );
  }
  
  /// 创建警告级别日志
  static LogItem warning(String message, {dynamic data}) {
    return LogItem(
      message: message,
      level: LogLevel.warning,
      data: data,
    );
  }
  
  /// 创建错误级别日志
  static LogItem error(String message, {dynamic data}) {
    return LogItem(
      message: message,
      level: LogLevel.error,
      data: data,
    );
  }
  
  /// 创建成功级别日志
  static LogItem success(String message, {dynamic data}) {
    return LogItem(
      message: message,
      level: LogLevel.success,
      data: data,
    );
  }
  
  /// 创建调试级别日志
  static LogItem debug(String message, {dynamic data}) {
    return LogItem(
      message: message,
      level: LogLevel.debug,
      data: data,
    );
  }
  
  /// 转换为字符串
  @override
  String toString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final levelStr = level.toString().split('.').last.toUpperCase();
    
    return '[$timeStr] [$levelStr] $message';
  }
  
  /// 获取详细信息字符串
  String toDetailString() {
    final dateStr = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final levelStr = level.toString().split('.').last.toUpperCase();
    
    String result = '[$dateStr $timeStr] [$levelStr] $message';
    
    if (data != null) {
      result += '\n数据: ${data.toString()}';
    }
    
    return result;
  }
}

/// 日志组件配置
class LogConfig {
  /// 是否显示时间戳
  final bool showTimestamp;
  
  /// 是否显示级别
  final bool showLevel;
  
  /// 最大日志条数
  final int maxLogCount;
  
  /// 日志文字大小
  final double fontSize;
  
  /// 日志行高
  final double lineHeight;
  
  /// 是否自动滚动到最新日志
  final bool autoScroll;
  
  /// 是否显示边框
  final bool showBorder;
  
  /// 背景颜色
  final Color? backgroundColor;
  
  /// 不同级别日志的颜色
  final Map<LogLevel, Color> levelColors;
  
  /// 构造函数
  const LogConfig({
    this.showTimestamp = true,
    this.showLevel = true,
    this.maxLogCount = 1000,
    this.fontSize = 14.0,
    this.lineHeight = 1.5,
    this.autoScroll = true,
    this.showBorder = true,
    this.backgroundColor,
    Map<LogLevel, Color>? levelColors,
  }) : levelColors = levelColors ?? const {
          LogLevel.info: Colors.blue,
          LogLevel.warning: Colors.orange,
          LogLevel.error: Colors.red,
          LogLevel.success: Colors.green,
          LogLevel.debug: Colors.grey,
        };
}

/// 日志组件
/// 
/// 用于显示应用程序日志，支持不同级别的日志显示，可以复制和清空日志
class LogComponent extends StatefulWidget {
  /// 组件高度
  final double height;
  
  /// 组件宽度
  final double? width;
  
  /// 初始日志列表
  final List<LogItem> initialLogs;
  
  /// 组件配置
  final LogConfig config;
  
  /// 日志变化回调
  final Function(List<LogItem>)? onLogsChanged;
  
  /// 过滤日志回调
  final VoidCallback? onFilterLogs;
  
  /// 构造函数
  const LogComponent({
    Key? key,
    this.height = 300,
    this.width,
    this.initialLogs = const [],
    this.config = const LogConfig(),
    this.onLogsChanged,
    this.onFilterLogs,
  }) : super(key: key);

  @override
  State<LogComponent> createState() => _LogComponentState();
}

class _LogComponentState extends State<LogComponent> {
  /// 日志列表
  late List<LogItem> _logs;
  
  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _logs = List.from(widget.initialLogs);
  }
  
  /// 添加日志
  void addLog(LogItem log) {
    setState(() {
      // 如果达到最大日志数量，移除最旧的日志
      if (_logs.length >= widget.config.maxLogCount) {
        _logs.removeAt(0);
      }
      
      _logs.add(log);
      
      // 通知日志变化
      widget.onLogsChanged?.call(_logs);
    });
    
    _scrollToBottom();
  }
  
  /// 批量添加日志
  void addLogs(List<LogItem> logs) {
    if (logs.isEmpty) return;
    
    setState(() {
      // 确保不超过最大日志数量
      if (_logs.length + logs.length > widget.config.maxLogCount) {
        final int removeCount = _logs.length + logs.length - widget.config.maxLogCount;
        if (removeCount >= _logs.length) {
          _logs = [];
        } else {
          _logs.removeRange(0, removeCount);
        }
      }
      
      _logs.addAll(logs);
      
      // 通知日志变化
      widget.onLogsChanged?.call(_logs);
    });
    
    _scrollToBottom();
  }
  
  /// 滚动到底部
  void _scrollToBottom() {
    // 自动滚动到底部
    if (widget.config.autoScroll) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
  
  /// 清空日志
  void clearLogs() {
    setState(() {
      _logs.clear();
      
      // 通知日志变化
      widget.onLogsChanged?.call(_logs);
    });
  }
  
  /// 复制所有日志到剪贴板
  void copyLogs() {
    final String logText = _logs.map((log) => log.toDetailString()).join('\n\n');
    Clipboard.setData(ClipboardData(text: logText));
    
    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('所有日志已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  /// 获取日志颜色
  Color _getLogColor(LogLevel level) {
    return widget.config.levelColors[level] ?? Colors.black;
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight > 0 ? constraints.maxHeight : widget.height,
          width: widget.width ?? constraints.maxWidth,
          decoration: BoxDecoration(
            color: widget.config.backgroundColor ?? Colors.black.withOpacity(0.03),
            border: widget.config.showBorder 
                ? Border.all(color: Colors.grey.withOpacity(0.5)) 
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 工具栏
              _buildToolbar(),
              
              // 日志内容
              Expanded(
                child: _buildLogContent(),
              ),
            ],
          ),
        );
      }
    );
  }
  
  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '日志',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 日志计数
          Text(
            '${_logs.length} 条记录',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 16),
          // 复制按钮
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: '复制所有日志',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _logs.isEmpty ? null : copyLogs,
          ),
          const SizedBox(width: 12),
          // 过滤按钮
          if (widget.onFilterLogs != null)
            IconButton(
              icon: const Icon(Icons.filter_list, size: 16),
              tooltip: '过滤日志',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: widget.onFilterLogs,
              color: Colors.grey.shade700,
            ),
          const SizedBox(width: 12),
          // 清空按钮
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            tooltip: '清空日志',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _logs.isEmpty ? null : clearLogs,
          ),
        ],
      ),
    );
  }
  
  /// 构建日志内容
  Widget _buildLogContent() {
    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          '暂无日志记录',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final LogItem log = _logs[index];
        return _buildLogItem(log, index);
      },
    );
  }
  
  /// 构建单个日志项
  Widget _buildLogItem(LogItem log, int index) {
    // 构建日志内容
    Widget messageWidget = Text(
      widget.config.showTimestamp 
          ? (widget.config.showLevel 
              ? log.toString() 
              : '[${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')} ${log.message}')
          : (widget.config.showLevel 
              ? '[${log.level.toString().split('.').last.toUpperCase()}] ${log.message}' 
              : log.message),
      style: TextStyle(
        color: _getLogColor(log.level),
        fontSize: widget.config.fontSize,
        height: widget.config.lineHeight,
      ),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
    
    // 对于带有数据的日志，显示数据内容
    Widget content;
    if (log.data != null) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              messageWidget,
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                ),
                child: Text(
                  log.data.toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: widget.config.fontSize - 1,
                    height: widget.config.lineHeight,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          );
        }
      );
    } else {
      content = messageWidget;
    }
    
    return InkWell(
      onTap: () {
        // 点击复制单条日志
        Clipboard.setData(ClipboardData(text: log.toDetailString()));
        
        // 显示提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('日志已复制到剪贴板'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          color: index % 2 == 0 ? Colors.transparent : Colors.grey.withOpacity(0.05),
        ),
        child: content,
      ),
    );
  }
}

/// 日志管理器
/// 
/// 提供管理日志的全局方法，可以为多个日志组件提供统一的日志源
class LogManager {
  /// 单例实例
  static final LogManager _instance = LogManager._internal();
  
  /// 私有构造函数
  LogManager._internal();
  
  /// 获取单例实例
  factory LogManager() => _instance;
  
  /// 日志组件引用Map，用于存储被注册的LogComponent
  final Map<String, GlobalKey<_LogComponentState>> _logComponents = {};
  
  /// 注册日志组件
  void registerComponent(String id, GlobalKey<_LogComponentState> key) {
    _logComponents[id] = key;
  }
  
  /// 取消注册日志组件
  void unregisterComponent(String id) {
    _logComponents.remove(id);
  }
  
  /// 添加日志到所有已注册组件
  void addLog(LogItem log) {
    _updateComponents((state) => state.addLog(log));
  }
  
  /// 批量添加日志到所有已注册组件
  void addLogs(List<LogItem> logs) {
    if (logs.isEmpty) return;
    _updateComponents((state) => state.addLogs(logs));
  }
  
  /// 更新所有组件状态的辅助方法
  void _updateComponents(Function(_LogComponentState state) updateFunction) {
    _logComponents.forEach((_, key) {
      if (key.currentState != null) {
        // 使用addPostFrameCallback确保在构建完成后再更新状态
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (key.currentState != null) {
            updateFunction(key.currentState!);
          }
        });
      }
    });
  }
  
  /// 添加信息日志
  void info(String message, {dynamic data}) {
    addLog(LogItem.info(message, data: data));
  }
  
  /// 添加警告日志
  void warning(String message, {dynamic data}) {
    addLog(LogItem.warning(message, data: data));
  }
  
  /// 添加错误日志
  void error(String message, {dynamic data}) {
    addLog(LogItem.error(message, data: data));
  }
  
  /// 添加成功日志
  void success(String message, {dynamic data}) {
    addLog(LogItem.success(message, data: data));
  }
  
  /// 添加调试日志
  void debug(String message, {dynamic data}) {
    addLog(LogItem.debug(message, data: data));
  }
  
  /// 清空所有已注册组件的日志
  void clearLogs() {
    _updateComponents((state) => state.clearLogs());
  }
}

/// 创建一个可以被LogManager管理的LogComponent
/// 
/// [id] - 组件唯一标识
/// [height] - 组件高度
/// [width] - 组件宽度
/// [initialLogs] - 初始日志列表
/// [config] - 组件配置
/// [onLogsChanged] - 日志变化回调
/// [onFilterLogs] - 过滤日志回调
class ManagedLogComponent extends StatefulWidget {
  /// 组件唯一标识
  final String id;
  
  /// 组件高度
  final double height;
  
  /// 组件宽度
  final double? width;
  
  /// 初始日志列表
  final List<LogItem> initialLogs;
  
  /// 组件配置
  final LogConfig config;
  
  /// 日志变化回调
  final Function(List<LogItem>)? onLogsChanged;
  
  /// 过滤日志回调
  final VoidCallback? onFilterLogs;
  
  /// 构造函数
  const ManagedLogComponent({
    Key? key,
    required this.id,
    this.height = 300,
    this.width,
    this.initialLogs = const [],
    this.config = const LogConfig(),
    this.onLogsChanged,
    this.onFilterLogs,
  }) : super(key: key);

  @override
  State<ManagedLogComponent> createState() => _ManagedLogComponentState();
}

class _ManagedLogComponentState extends State<ManagedLogComponent> {
  /// 组件全局key
  final GlobalKey<_LogComponentState> _componentKey = GlobalKey<_LogComponentState>();
  
  @override
  void initState() {
    super.initState();
    // 注册到管理器
    LogManager().registerComponent(widget.id, _componentKey);
  }
  
  @override
  void dispose() {
    // 取消注册
    LogManager().unregisterComponent(widget.id);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return LogComponent(
      key: _componentKey,
      height: widget.height,
      width: widget.width,
      initialLogs: widget.initialLogs,
      config: widget.config,
      onLogsChanged: widget.onLogsChanged,
      onFilterLogs: widget.onFilterLogs,
    );
  }
} 