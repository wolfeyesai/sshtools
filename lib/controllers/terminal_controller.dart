// ignore_for_file: unused_import, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 导入模型和服务
import '../models/terminal_model.dart';
import '../services/ssh_service.dart'; // 导入 SSHService
// import '../services/server_service.dart'; // 移除旧的 ServerService 导入
import '../utils/logger.dart';

// TerminalController
class TerminalController extends ChangeNotifier {
  final TerminalModel _terminalModel;
  final SshService _sshService; // SSH Service 引用

  TerminalController(this._terminalModel, this._sshService); // 添加 SshService 参数

  // 发送命令到当前会话
  void sendCommand(String command) {
    if (_terminalModel.currentSession == null) {
      // 如果没有当前会话，创建一个新会话（这里使用临时ID）
      final session = _terminalModel.createSession('temp');
      // 添加命令到输出
      _terminalModel.addOutputToCurrentSession('> $command');
      
      // TODO: 通过SSH服务发送命令
      // 模拟命令响应
      Future.delayed(Duration(milliseconds: 300), () {
        _terminalModel.addOutputToCurrentSession('Command executed: $command');
      });
    } else {
      // 添加命令到输出
      _terminalModel.addOutputToCurrentSession('> $command');
      
      // TODO: 通过SSH服务发送命令
      // 模拟命令响应
      Future.delayed(Duration(milliseconds: 300), () {
        _terminalModel.addOutputToCurrentSession('Command executed: $command');
      });
    }
    log.i('TerminalController', '发送命令: $command');
  }
  
  // 连接到设备
  Future<bool> connectToDevice(String deviceId) async {
    // 创建新会话
    final session = _terminalModel.createSession(deviceId);
    
    // 添加连接信息到输出
    _terminalModel.addOutputToCurrentSession('Connecting to device...');
    
    // TODO: 使用SSH服务建立连接
    // 模拟连接过程
    await Future.delayed(Duration(seconds: 1));
    _terminalModel.updateSessionConnectionStatus(session.id, true);
    _terminalModel.addOutputToCurrentSession('Connected successfully.');
    
    return true;
  }
  
  // 断开连接
  void disconnect() {
    if (_terminalModel.currentSession != null) {
      final sessionId = _terminalModel.currentSession!.id;
      
      // TODO: 使用SSH服务断开连接
      
      _terminalModel.updateSessionConnectionStatus(sessionId, false);
      _terminalModel.addOutputToCurrentSession('Disconnected from server.');
    }
  }
  
  // 清空当前会话输出
  void clearOutput() {
    _terminalModel.clearCurrentSessionOutput();
  }
} 