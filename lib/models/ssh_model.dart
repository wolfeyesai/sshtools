// SSH模型类，用于存储SSH连接和终端会话相关信息

import 'package:dartssh2/dartssh2.dart';

/// SSH连接状态枚举
enum SSHConnectionState {
  connecting,
  connected,
  disconnected,
  failed,
}

/// 文件传输状态枚举
enum FileTransferState {
  starting,
  inProgress,
  completed,
  failed,
}

/// SSH命令执行结果
class SSHCommandResult {
  final int exitCode;
  final String output;
  final String error;
  
  SSHCommandResult({
    required this.exitCode,
    required this.output,
    required this.error,
  });
  
  bool get isSuccess => exitCode == 0;
}

/// SSH连接配置
class SSHConnectionConfig {
  final String host;
  final int port;
  final String username;
  final String password;
  final int timeout;
  
  SSHConnectionConfig({
    required this.host,
    this.port = 22,
    required this.username,
    required this.password,
    this.timeout = 10,
  });
}

/// SSH会话模型
class SSHSessionModel {
  /// 会话ID
  final String id;
  
  /// 连接配置
  final SSHConnectionConfig config;
  
  /// SSH客户端实例
  SSHClient? client;
  
  /// SSH会话实例
  SSHSession? session;
  
  /// 连接状态
  SSHConnectionState connectionState;
  
  /// 终端输出历史
  final List<String> outputHistory;
  
  /// 命令执行历史
  final List<String> commandHistory;
  
  /// 会话创建时间
  final DateTime createdAt;
  
  /// 最后活动时间
  DateTime lastActivityAt;
  
  SSHSessionModel({
    required this.id,
    required this.config,
    this.client,
    this.session,
    this.connectionState = SSHConnectionState.disconnected,
    List<String>? outputHistory,
    List<String>? commandHistory,
    DateTime? createdAt,
    DateTime? lastActivityAt,
  }) : 
    outputHistory = outputHistory ?? [],
    commandHistory = commandHistory ?? [],
    createdAt = createdAt ?? DateTime.now(),
    lastActivityAt = lastActivityAt ?? DateTime.now();
  
  /// 检查是否已连接
  bool get isConnected => connectionState == SSHConnectionState.connected && client != null;
  
  /// 检查是否有活动会话
  bool get hasActiveSession => isConnected && session != null;
  
  /// 添加输出到历史记录
  void addOutput(String output) {
    outputHistory.add(output);
    lastActivityAt = DateTime.now();
  }
  
  /// 清除输出历史
  void clearOutputHistory() {
    outputHistory.clear();
  }
  
  /// 添加命令到历史记录
  void addCommandToHistory(String command) {
    // 不添加重复的命令（如果最后一个命令与新命令相同）
    if (commandHistory.isNotEmpty && commandHistory.last == command) {
      return;
    }
    
    // 限制历史记录长度为50
    if (commandHistory.length >= 50) {
      commandHistory.removeAt(0);
    }
    
    commandHistory.add(command);
    lastActivityAt = DateTime.now();
  }
  
  /// 清除命令历史
  void clearCommandHistory() {
    commandHistory.clear();
  }
}

/// SSH文件传输信息
class SSHFileTransferInfo {
  final String localPath;
  final String remotePath;
  FileTransferState state;
  double progress;
  DateTime startTime;
  DateTime? endTime;
  String? errorMessage;
  
  SSHFileTransferInfo({
    required this.localPath,
    required this.remotePath,
    this.state = FileTransferState.starting,
    this.progress = 0.0,
    DateTime? startTime,
    this.endTime,
    this.errorMessage,
  }) : startTime = startTime ?? DateTime.now();
  
  /// 检查传输是否完成
  bool get isCompleted => state == FileTransferState.completed;
  
  /// 检查传输是否失败
  bool get isFailed => state == FileTransferState.failed;
  
  /// 计算传输耗时（秒）
  double get elapsedTime {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMilliseconds / 1000;
  }
}

/// SSH连接异常
class SSHException implements Exception {
  final String message;
  
  SSHException(this.message);
  
  @override
  String toString() => 'SSHException: $message';
} 