// SSH控制器，用于管理SSH连接和操作

// ignore_for_file: unused_import, unused_local_variable, unnecessary_import, use_build_context_synchronously, await_only_futures

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/ssh_model.dart';
import 'ssh_session_controller.dart';

/// SSH控制器
class SSHController extends ChangeNotifier {
  /// 当前会话模型
  SSHSessionModel? _currentSession;
  
  /// 连接状态监听器
  final _connectionStateController = StreamController<SSHConnectionState>.broadcast();
  
  /// 命令输出监听器
  final _commandOutputController = StreamController<String>.broadcast();
  
  /// 是否已销毁
  bool _isDisposed = false;
  
  /// 是否正在处理通知
  bool _isNotifying = false;
  
  /// 最后一次通知时间
  DateTime _lastNotifyTime = DateTime.now();
  
  /// 安全地通知监听器
  void _safeNotifyListeners() {
    // 避免重入和频繁通知
    if (_isDisposed || _isNotifying) return;
    
    // 节流控制，避免短时间内多次通知
    final now = DateTime.now();
    if (now.difference(_lastNotifyTime).inMilliseconds < 100) {
      // 如果距离上次通知时间小于100毫秒，使用Future.delayed延迟执行
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isDisposed) _safeNotifyListeners();
      });
      return;
    }
    
    try {
      _isNotifying = true;
      _lastNotifyTime = now;
      
      // 使用Future.microtask确保在下一帧开始前通知，避免在帧渲染中触发更新
      Future.microtask(() {
        try {
          if (!_isDisposed) {
            notifyListeners();
          }
        } catch (e) {
          debugPrint('SSHController通知监听器执行时出错: $e');
        } finally {
          _isNotifying = false;
        }
      });
    } catch (e) {
      _isNotifying = false;
      debugPrint('SSHController安排通知监听器时出错: $e');
    }
  }
  
  /// 安全地向流发送数据
  void _safeAddToStream<T>(StreamController<T> controller, T data) {
    if (_isDisposed) return;
    
    // 使用Future.microtask确保在当前帧完成后执行流操作
    Future.microtask(() {
      try {
        // 再次检查是否已销毁及流是否关闭
        if (_isDisposed || controller.isClosed) return;
        
        controller.add(data);
      } catch (e) {
        debugPrint('向流发送数据时出错: $e');
      }
    });
  }
  
  /// 获取当前会话
  SSHSessionModel? get currentSession => _currentSession;
  
  /// 获取连接状态流
  Stream<SSHConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// 获取命令输出流
  Stream<String> get commandOutputStream => _commandOutputController.stream;
  
  /// 获取当前连接状态
  bool get isConnected => !_isDisposed && (_currentSession?.isConnected ?? false);
  
  /// 连接到SSH服务器
  Future<bool> connect({
    required String host,
    required String username,
    required String password,
    int port = 22,
    int timeout = 10,
    BuildContext? context,
  }) async {
    if (_isDisposed) return false;
    
    // 先处理可能存在的旧连接，避免资源泄漏
    await disconnect(silent: true);
    
    try {
      // 创建连接配置
      final config = SSHConnectionConfig(
        host: host,
        port: port,
        username: username,
        password: password,
        timeout: timeout,
      );
      
      // 创建会话模型
      final sessionId = const Uuid().v4();
      _currentSession = SSHSessionModel(
        id: sessionId,
        config: config,
        connectionState: SSHConnectionState.connecting,
      );
      
      // 更新连接状态
      _safeAddToStream(_connectionStateController, SSHConnectionState.connecting);
      _safeNotifyListeners();
      
      // 创建SSH客户端
      final socket = await SSHSocket.connect(
        host, 
        port, 
        timeout: Duration(seconds: timeout)
      );
      
      if (_isDisposed) {
        socket.close();
        return false;
      }
      
      // 创建SSH连接
      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      if (_isDisposed) {
        client.close();
        return false;
      }
      
      // 更新会话状态
      if (_currentSession != null) {
        _currentSession!.client = client;
        _currentSession!.connectionState = SSHConnectionState.connected;
        _safeAddToStream(_connectionStateController, SSHConnectionState.connected);
        _safeNotifyListeners();
        
        // 记录连接历史
        if (context != null && context.mounted) {
          try {
            final sessionController = Provider.of<SSHSessionController>(
              context, 
              listen: false
            );
            
            sessionController.recordConnection(
              host: host,
              port: port,
              username: username,
              password: password,
            );
          } catch (e) {
            debugPrint('记录SSH连接历史失败: $e');
          }
        }
        
        return true;
      } else {
        client.close();
        return false;
      }
    } catch (e) {
      if (_currentSession != null) {
        _currentSession!.connectionState = SSHConnectionState.failed;
      }
      _safeAddToStream(_connectionStateController, SSHConnectionState.failed);
      debugPrint('SSH连接失败: $e');
      _safeNotifyListeners();
      return false;
    }
  }
  
  /// 执行SSH命令并获取结果
  Future<SSHCommandResult> executeCommand(String command) async {
    if (_isDisposed || !isConnected || _currentSession?.client == null) {
      return SSHCommandResult(
        exitCode: -1,
        output: '',
        error: 'SSH控制器已销毁或未连接',
      );
    }
    
    try {
      // 执行命令
      final process = await _currentSession!.client!.execute(command);
      
      if (_isDisposed) {
        process.close();
        return SSHCommandResult(
          exitCode: -1,
          output: '',
          error: 'SSH控制器已销毁',
        );
      }
      
      // 命令输出
      final stdoutBytes = await process.stdout.toList();
      final stderrBytes = await process.stderr.toList();
      
      if (_isDisposed) {
        return SSHCommandResult(
          exitCode: -1,
          output: '',
          error: 'SSH控制器已销毁',
        );
      }
      
      final flattenStdout = stdoutBytes.expand((e) => e).toList();
      final flattenStderr = stderrBytes.expand((e) => e).toList();
      
      final stdout = utf8.decode(flattenStdout, allowMalformed: true);
      final stderr = utf8.decode(flattenStderr, allowMalformed: true);
      
      // 等待命令完成
      final exitCode = await process.exitCode;
      
      if (_isDisposed) {
        return SSHCommandResult(
          exitCode: -1,
          output: '',
          error: 'SSH控制器已销毁',
        );
      }
      
      // 输出到命令流
      _safeAddToStream(_commandOutputController, stdout);
      
      // 添加到会话历史
      if (_currentSession != null) {
        _currentSession!.addOutput('$command\n$stdout');
        _safeNotifyListeners();
      }
      
      return SSHCommandResult(
        exitCode: exitCode ?? -1,
        output: stdout,
        error: stderr,
      );
    } catch (e) {
      final errorMsg = '执行命令出错: $e';
      _safeAddToStream(_commandOutputController, errorMsg);
      
      // 添加到会话历史
      if (_currentSession != null && !_isDisposed) {
        _currentSession!.addOutput('$command\n$errorMsg');
        _safeNotifyListeners();
      }
      
      return SSHCommandResult(
        exitCode: -1,
        output: '',
        error: e.toString(),
      );
    }
  }
  
  /// 创建一个交互式Shell会话
  Future<SSHSession?> startShell() async {
    if (!isConnected || _currentSession?.client == null) {
      throw SSHException('未连接到SSH服务器');
    }
    
    try {
      // 创建带有伪终端的Shell会话
      final session = await _currentSession!.client!.shell();
      
      // 更新会话信息
      _currentSession!.session = session;
      _safeNotifyListeners();
      
      return session;
    } catch (e) {
      debugPrint('启动Shell失败: $e');
      return null;
    }
  }
  
  /// 断开SSH连接
  Future<void> disconnect({bool silent = false}) async {
    if (_currentSession != null && !_isDisposed) {
      try {
        // 更新连接状态
        _currentSession!.connectionState = SSHConnectionState.disconnected;
        if (!silent) {
          _safeAddToStream(_connectionStateController, SSHConnectionState.disconnected);
        }
        
        // 关闭SSH客户端
        if (_currentSession!.client != null) {
          _currentSession!.client!.close();
          _currentSession!.client = null;
        }
        
        // 清除会话
        _currentSession!.session = null;
        
        // 通知监听器
        _safeNotifyListeners();
        
        if (!silent) {
          debugPrint('SSH连接已断开');
        }
      } catch (e) {
        debugPrint('断开SSH连接时出错: $e');
      }
    }
  }
  
  /// 清除会话历史
  void clearSessionHistory() {
    if (_isDisposed) return;
    
    if (_currentSession != null) {
      _currentSession!.clearOutputHistory();
      _safeNotifyListeners();
    }
  }
  
  /// 向SSH客户端发送Shell命令数据
  void sendToShellClient(String data) {
    if (_isDisposed) return;
    
    try {
      // 检查会话是否有效并且活跃
      if (_currentSession == null || !_currentSession!.hasActiveSession) {
        debugPrint('无法发送数据：无活动会话');
        return;
      }
      
      // 尝试向会话发送数据
      _currentSession!.session!.stdin.add(utf8.encode(data));
      
      // 记录活动时间
      _currentSession!.lastActivityAt = DateTime.now();
      
      // 使用延迟通知避免频繁更新
      Future.microtask(() {
        if (!_isDisposed) {
          _safeNotifyListeners();
        }
      });
    } catch (e) {
      debugPrint('发送数据到Shell出错: $e');
    }
  }
  
  /// 获取SFTP客户端
  Future<SftpClient?> getSFTPClient() async {
    if (_isDisposed) {
      debugPrint('SSH控制器已销毁，无法获取SFTP客户端');
      return null;
    }
    
    try {
      // 检查SSH客户端是否有效
      if (_currentSession == null || _currentSession!.client == null) {
        debugPrint('SSH客户端未初始化，无法获取SFTP客户端');
        return null;
      }

      // 等待认证完成 - 这是关键步骤
      // dartssh2文档中提到需要等待authenticated完成后才能使用SFTP
      try {
        debugPrint('等待SSH认证完成...');
        // 设置超时，避免无限等待
        await _currentSession!.client!.authenticated.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('SSH认证等待超时');
            return;
          }
        );
        debugPrint('SSH认证已完成，可以继续获取SFTP客户端');
      } catch (e) {
        debugPrint('等待SSH认证时出错: $e');
        // 继续尝试，可能已经认证成功
      }
      
      // 获取SFTP子系统
      final sftp = await _currentSession!.client!.sftp();
      debugPrint('SFTP子系统获取成功');
      return sftp;
    } catch (e) {
      debugPrint('获取SFTP客户端出错: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    // 标记为已销毁
    _isDisposed = true;
    
    // 断开连接
    try {
      if (_currentSession?.client != null) {
        _currentSession!.client!.close();
        _currentSession!.client = null;
        _currentSession!.session = null;
      }
    } catch (e) {
      debugPrint('断开SSH连接时出错: $e');
    }
    
    // 关闭流控制器
    try {
      if (!_connectionStateController.isClosed) _connectionStateController.close();
      if (!_commandOutputController.isClosed) _commandOutputController.close();
    } catch (e) {
      debugPrint('关闭SSH控制器流时出错: $e');
    }
    
    // 释放资源
    _currentSession = null;
    
    super.dispose();
  }
} 