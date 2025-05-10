// lib/services/ssh_service.dart

// ignore_for_file: unused_import, avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/device_model.dart';
import '../models/terminal_model.dart';
import '../models/settings_model.dart';
import '../utils/logger.dart';
import '../utils/ssh_client.dart'; // 确保导入 SshClient
// import 'package:ssh2/ssh2.dart'; // 根据 ssh_client.dart 的实现决定是否需要此导入

/// SSH 服务 - 处理 SSH 连接、命令执行等
class SshService with ChangeNotifier {
  final SettingsModel settingsModel;
  final Map<String, Process?> _activeProcesses = {};
  final StreamController<SshConnectionEvent> _connectionEventController = 
      StreamController<SshConnectionEvent>.broadcast();

  SshService({required this.settingsModel});

  Stream<SshConnectionEvent> get connectionEvents => 
      _connectionEventController.stream;

  // 当前连接状态
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // 终端输出流
  final ValueNotifier<String> _terminalOutput = ValueNotifier<String>('');
  ValueNotifier<String> get terminalOutput => _terminalOutput;

  // 连接到设备
  Future<bool> connectToDevice(SshDevice device) async {
    try {
      // 使用SSH命令进行连接测试
      final result = await Process.run('ssh', [
        '-p', device.port.toString(),
        '-o', 'ConnectTimeout=10',
        '-o', 'StrictHostKeyChecking=no',
        '${device.username}@${device.host}',
        'echo "Connection successful"'
      ]);

      if (result.exitCode == 0) {
        _connectionEventController.add(
          SshConnectionEvent(
            deviceId: device.id, 
            type: SshConnectionEventType.connected
          )
        );
        return true;
      } else {
        _connectionEventController.add(
          SshConnectionEvent(
            deviceId: device.id, 
            type: SshConnectionEventType.connectionFailed,
            error: result.stderr.toString()
          )
        );
        return false;
      }
    } catch (e) {
      _connectionEventController.add(
        SshConnectionEvent(
          deviceId: device.id, 
          type: SshConnectionEventType.connectionFailed,
          error: e.toString()
        )
      );
      return false;
    }
  }

  // 执行命令
  Future<String?> executeCommand(String deviceId, SshDevice device, String command) async {
    try {
      final result = await Process.run('ssh', [
        '-p', device.port.toString(),
        '-o', 'StrictHostKeyChecking=no',
        '${device.username}@${device.host}',
        command
      ]);

      if (result.exitCode == 0) {
        return result.stdout.toString();
      } else {
        _connectionEventController.add(
          SshConnectionEvent(
            deviceId: deviceId, 
            type: SshConnectionEventType.commandFailed,
            error: result.stderr.toString()
          )
        );
        return null;
      }
    } catch (e) {
      _connectionEventController.add(
        SshConnectionEvent(
          deviceId: deviceId, 
          type: SshConnectionEventType.commandFailed,
          error: e.toString()
        )
      );
      return null;
    }
  }

  // 断开连接
  Future<void> disconnectDevice(String deviceId) async {
    final process = _activeProcesses[deviceId];
    if (process == null) return;

    try {
      process.stdin.writeln('exit');
      await process.exitCode;
      _activeProcesses.remove(deviceId);
      
      _connectionEventController.add(
        SshConnectionEvent(
          deviceId: deviceId, 
          type: SshConnectionEventType.disconnected
        )
      );
      log.i('SshService', 'SSH连接已断开');
    } catch (e) {
      _connectionEventController.add(
        SshConnectionEvent(
          deviceId: deviceId, 
          type: SshConnectionEventType.disconnectionFailed,
          error: e.toString()
        )
      );
    }
  }
  
  // 清空终端输出
  void clearTerminalOutput() {
    _terminalOutput.value = '';
    notifyListeners();
  }

  // 打开交互式终端会话
  Future<bool> startInteractiveSession(String deviceId, SshDevice device) async {
    try {
      final process = await Process.start('ssh', [
        '-p', device.port.toString(),
        '-o', 'StrictHostKeyChecking=no',
        '${device.username}@${device.host}'
      ]);

      _activeProcesses[deviceId] = process;

      process.stdout.listen((data) {
        // 处理终端输出
      }, onDone: () {
        _connectionEventController.add(
          SshConnectionEvent(
            deviceId: deviceId, 
            type: SshConnectionEventType.disconnected
          )
        );
      });

      process.stderr.listen((data) {
        _connectionEventController.add(
          SshConnectionEvent(
            deviceId: deviceId, 
            type: SshConnectionEventType.shellFailed,
            error: String.fromCharCodes(data)
          )
        );
      });

      _connectionEventController.add(
        SshConnectionEvent(
          deviceId: deviceId, 
          type: SshConnectionEventType.shellStarted
        )
      );

      return true;
    } catch (e) {
      _connectionEventController.add(
        SshConnectionEvent(
          deviceId: deviceId, 
          type: SshConnectionEventType.shellFailed,
          error: e.toString()
        )
      );
      return false;
    }
  }

  // 发送命令到交互式终端
  Future<void> sendToShell(String deviceId, String command) async {
    final process = _activeProcesses[deviceId];
    if (process == null) return;

    try {
      process.stdin.writeln(command);
    } catch (e) {
      _connectionEventController.add(
        SshConnectionEvent(
          deviceId: deviceId, 
          type: SshConnectionEventType.shellCommandFailed,
          error: e.toString()
        )
      );
    }
  }

  // 关闭所有活动连接
  Future<void> disconnectAll() async {
    for (var deviceId in _activeProcesses.keys) {
      await disconnectDevice(deviceId);
    }
  }

  @override
  void dispose() {
    // 在 dispose 时确保断开连接
    disconnectAll();
    _terminalOutput.dispose();
    _connectionEventController.close();
    super.dispose();
  }
}

// SSH会话类
class SSHSession {
  final SshClient client;

  SSHSession(this.client);
}

// SSH连接事件枚举
enum SshConnectionEventType {
  connected,
  connectionFailed,
  disconnected,
  disconnectionFailed,
  commandFailed,
  shellStarted,
  shellFailed,
  shellCommandFailed
}

// SSH连接事件类
class SshConnectionEvent {
  final String deviceId;
  final SshConnectionEventType type;
  final String? error;

  SshConnectionEvent({
    required this.deviceId,
    required this.type,
    this.error,
  });
} 