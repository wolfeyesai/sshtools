import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 日志级别枚举
enum LogLevel {
  /// 调试信息
  debug,
  
  /// 普通信息
  info,
  
  /// 警告信息
  warning,
  
  /// 错误信息
  error,
  
  /// 致命错误
  fatal,
}

/// 一个漂亮的日志管理工具
/// 
/// 支持不同日志级别的彩色输出，时间戳和格式化
class Logger {
  /// 单例实例
  static final Logger _instance = Logger._internal();
  
  /// 日志级别，默认为 debug
  LogLevel _logLevel = LogLevel.debug;
  
  /// 是否显示日志
  bool _showLogs = true;
  
  /// 是否在生产环境显示日志
  bool _showLogsInRelease = false;
  
  /// 是否显示文件名和行号
  bool _showFileInfo = true;
  
  /// 日期格式
  final DateFormat _dateFormat = DateFormat('HH:mm:ss.SSS');
  
  /// 上次日志时间记录，用于限制频率
  final Map<String, DateTime> _lastLogTimes = {};
  
  /// 默认日志间隔时间（秒）
  int _defaultLogInterval = 15;
  
  /// 心跳日志间隔时间（秒）
  int _heartbeatLogInterval = 30;
  
  /// 工厂构造函数
  factory Logger() {
    return _instance;
  }
  
  /// 私有构造函数
  Logger._internal();
  
  /// 设置日志级别
  void setLogLevel(LogLevel level) {
    _logLevel = level;
  }
  
  /// 启用或禁用日志
  void enableLogs(bool enable) {
    _showLogs = enable;
  }
  
  /// 在生产环境中启用或禁用日志
  void enableLogsInRelease(bool enable) {
    _showLogsInRelease = enable;
  }
  
  /// 设置是否显示文件信息
  void showFileInfo(bool show) {
    _showFileInfo = show;
  }
  
  /// 设置默认日志间隔时间（秒）
  void setDefaultLogInterval(int seconds) {
    _defaultLogInterval = seconds;
  }
  
  /// 设置心跳日志间隔时间（秒）
  void setHeartbeatLogInterval(int seconds) {
    _heartbeatLogInterval = seconds;
  }
  
  /// 检查是否应该记录该日志（限流逻辑）
  bool _shouldLogMessage(String tag, String message, [int? interval]) {
    // 获取当前时间
    final now = DateTime.now();
    
    // 默认间隔时间
    final int logInterval = interval ?? _defaultLogInterval;
    
    // 心跳日志特殊处理
    if (_isHeartbeatLog(message)) {
      // 心跳日志使用更长间隔
      return _checkLogTimeInterval(tag, message, now, _heartbeatLogInterval);
    }
    
    // 普通日志
    return _checkLogTimeInterval(tag, message, now, logInterval);
  }
  
  /// 检查日志时间间隔
  bool _checkLogTimeInterval(String tag, String message, DateTime now, int intervalSeconds) {
    // 创建唯一键来区分不同的日志消息
    final String logKey = '$tag-${message.hashCode}';
    
    if (_lastLogTimes.containsKey(logKey)) {
      final lastTime = _lastLogTimes[logKey]!;
      final diff = now.difference(lastTime).inSeconds;
      
      // 如果间隔不够，不记录日志
      if (diff < intervalSeconds) {
        return false;
      }
    }
    
    // 更新最后记录时间
    _lastLogTimes[logKey] = now;
    return true;
  }
  
  /// 判断是否为心跳日志
  bool _isHeartbeatLog(String message) {
    // 心跳日志通常包含这些关键词
    final List<String> heartbeatKeywords = [
      'heartbeat', '心跳', 'ping', 'alive', 'polling', '轮询', 'checking', '检查'
    ];
    
    // 检查消息中是否包含心跳关键词
    for (final keyword in heartbeatKeywords) {
      if (message.toLowerCase().contains(keyword)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// 记录调试级别日志
  void d(String tag, String message, [dynamic data]) {
    if (_shouldLogMessage(tag, message)) {
      _log(LogLevel.debug, tag, message, data);
    }
  }
  
  /// 记录信息级别日志
  void i(String tag, String message, [dynamic data]) {
    if (_shouldLogMessage(tag, message)) {
      _log(LogLevel.info, tag, message, data);
    }
  }
  
  /// 记录警告级别日志
  void w(String tag, String message, [dynamic data]) {
    if (_shouldLogMessage(tag, message)) {
      _log(LogLevel.warning, tag, message, data);
    }
  }
  
  /// 记录错误级别日志（错误日志不受限流影响，始终记录）
  void e(String tag, String message, [dynamic data, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message, data, stackTrace);
  }
  
  /// 记录致命错误级别日志（致命错误日志不受限流影响，始终记录）
  void f(String tag, String message, [dynamic data, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, tag, message, data, stackTrace);
  }
  
  /// 获取当前调用的文件信息
  String _getCallerInfo() {
    try {
      final stackTrace = StackTrace.current;
      final frames = stackTrace.toString().split('\n');
      
      // 跳过前几个堆栈帧，这些是Logger类内部的调用
      // 通常第4个帧是实际调用日志方法的地方
      if (frames.length > 3) {
        final callerFrame = frames[3];
        
        // 解析文件名和行号
        // 格式通常是：#3      main (package:pid_config/main.dart:7:17)
        final match = RegExp(r'package:(.*):(\d+):(\d+)\)').firstMatch(callerFrame);
        if (match != null && match.groupCount >= 2) {
          final filePath = match.group(1);
          final lineNumber = match.group(2);
          return '$filePath:$lineNumber';
        }
      }
    } catch (e) {
      // 如果解析失败，忽略错误
    }
    
    return '未知位置';
  }
  
  /// 内部日志记录方法
  void _log(LogLevel level, String tag, String message, [dynamic data, StackTrace? stackTrace]) {
    // 检查是否应该显示日志
    if (!_showLogs || (!kDebugMode && !_showLogsInRelease)) {
      return;
    }
    
    // 检查日志级别
    if (level.index < _logLevel.index) {
      return;
    }
    
    // 获取当前时间戳
    final String timestamp = _dateFormat.format(DateTime.now());
    
    // 获取文件信息
    final String fileInfo = _showFileInfo ? _getCallerInfo() : '';
    
    // 日志级别对应的符号和颜色代码
    String levelSymbol;
    String colorCode;
    
    switch (level) {
      case LogLevel.debug:
        levelSymbol = '🐛 D';
        colorCode = '\x1B[36m'; // 青色
        break;
      case LogLevel.info:
        levelSymbol = '💡 I';
        colorCode = '\x1B[32m'; // 绿色
        break;
      case LogLevel.warning:
        levelSymbol = '! W';
        colorCode = '\x1B[33m'; // 黄色
        break;
      case LogLevel.error:
        levelSymbol = '❌ E';
        colorCode = '\x1B[31m'; // 红色
        break;
      case LogLevel.fatal:
        levelSymbol = '☠️ F';
        colorCode = '\x1B[35m'; // 紫色
        break;
    }
    
    // 重置颜色代码
    const String resetCode = '\x1B[0m';
    
    // 格式化日志信息
    final StringBuffer logMessage = StringBuffer();
    logMessage.write('$colorCode[$timestamp] $levelSymbol [$tag]');
    
    // 添加文件信息
    if (_showFileInfo && fileInfo.isNotEmpty) {
      logMessage.write(' ($fileInfo)');
    }
    
    // 添加消息
    logMessage.write(' $message$resetCode');
    
    // 如果有附加数据，添加到日志中
    if (data != null) {
      logMessage.write(' $colorCode-> $data$resetCode');
    }
    
    // 输出日志
    debugPrint(logMessage.toString());
    
    // 如果有堆栈信息，输出堆栈信息
    if (stackTrace != null) {
      debugPrint('$colorCode堆栈信息: $stackTrace$resetCode');
    }
  }
}

/// 全局日志实例，方便直接使用
final log = Logger(); 