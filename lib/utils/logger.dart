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
  
  /// 是否使用简化文件路径（只显示文件名而不是完整路径）
  bool _useShortFilePath = true;
  
  /// 日期格式
  final DateFormat _dateFormat = DateFormat('HH:mm:ss.SSS');
  
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
  
  /// 设置是否使用简化文件路径
  void useShortFilePath(bool useShort) {
    _useShortFilePath = useShort;
  }
  
  /// 记录调试级别日志
  void d(String tag, String message, [dynamic data]) {
    _log(LogLevel.debug, tag, message, data);
  }
  
  /// 记录信息级别日志
  void i(String tag, String message, [dynamic data]) {
    _log(LogLevel.info, tag, message, data);
  }
  
  /// 记录警告级别日志
  void w(String tag, String message, [dynamic data]) {
    _log(LogLevel.warning, tag, message, data);
  }
  
  /// 记录错误级别日志
  void e(String tag, String message, [dynamic data, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message, data, stackTrace);
  }
  
  /// 记录致命错误级别日志
  void f(String tag, String message, [dynamic data, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, tag, message, data, stackTrace);
  }
  
  /// 打印当前堆栈跟踪，用于调试
  void printStackTrace(String tag, [String message = '当前堆栈跟踪']) {
    final stackTrace = StackTrace.current;
    final frames = stackTrace.toString().split('\n');
    
    // 记录信息级别日志
    i(tag, message);
    
    // 只输出前10个堆栈帧
    final framesToShow = frames.length > 10 ? 10 : frames.length;
    
    for (int i = 0; i < framesToShow; i++) {
      final frame = frames[i].trim();
      if (frame.isNotEmpty) {
        // 以调试级别输出堆栈帧
        d(tag, '堆栈帧 #$i', frame);
      }
    }
  }
  
  /// 获取当前调用的文件信息
  String _getCallerInfo() {
    try {
      final stackTrace = StackTrace.current;
      final frames = stackTrace.toString().split('\n');
      
      // 跳过前几个堆栈帧，这些是Logger类内部的调用
      // 需要找到第一个非Logger类的调用
      int frameIndex = 0;
      for (int i = 0; i < frames.length; i++) {
        // 跳过Logger内部调用
        if (!frames[i].contains('logger.dart') && !frames[i].contains('_log') && i > 2) {
          frameIndex = i;
          break;
        }
      }
      
      if (frameIndex > 0 && frameIndex < frames.length) {
        final callerFrame = frames[frameIndex];
        
        // 尝试不同的正则表达式匹配格式
        var match = RegExp(r'package:(.*):(\d+):(\d+)\)').firstMatch(callerFrame);
        if (match != null && match.groupCount >= 2) {
          final filePath = match.group(1);
          final lineNumber = match.group(2);
          
          if (_useShortFilePath && filePath != null) {
            // 只使用文件名而不是完整路径
            final fileName = filePath.split('/').last;
            return '$fileName:$lineNumber';
          }
          
          return '$filePath:$lineNumber';
        }
        
        // 尝试匹配Flutter引擎生成的堆栈跟踪格式
        match = RegExp(r'\((.+?):(\d+):(\d+)\)').firstMatch(callerFrame);
        if (match != null && match.groupCount >= 2) {
          final filePath = match.group(1);
          final lineNumber = match.group(2);
          
          if (_useShortFilePath && filePath != null) {
            // 只使用文件名而不是完整路径
            final fileName = filePath.split('/').last;
            return '$fileName:$lineNumber';
          }
          
          return '$filePath:$lineNumber';
        }
        
        // 尝试从整行提取有用信息
        final parts = callerFrame.trim().split(' ');
        if (parts.length > 1) {
          // 可能是方法名或类名
          return parts.last;
        }
      }
    } catch (e) {
      // 如果解析失败，返回异常信息
      return 'parser_error: ${e.toString()}';
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