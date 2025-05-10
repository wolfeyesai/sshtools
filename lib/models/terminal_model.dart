import 'package:flutter/material.dart';

// SSH终端会话模型
class TerminalSession {
  final String id;
  final String deviceId;
  final List<String> outputLines;
  final bool isConnected;

  TerminalSession({
    required this.id,
    required this.deviceId,
    this.outputLines = const [],
    this.isConnected = false,
  });

  TerminalSession copyWith({
    String? id,
    String? deviceId,
    List<String>? outputLines,
    bool? isConnected,
  }) {
    return TerminalSession(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      outputLines: outputLines ?? this.outputLines,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

// 终端模型管理
class TerminalModel extends ChangeNotifier {
  List<TerminalSession> _sessions = [];
  TerminalSession? _currentSession;

  List<TerminalSession> get sessions => _sessions;
  TerminalSession? get currentSession => _currentSession;

  // 创建新的终端会话
  TerminalSession createSession(String deviceId) {
    final newSession = TerminalSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: deviceId,
    );
    _sessions.add(newSession);
    _currentSession = newSession;
    notifyListeners();
    return newSession;
  }

  // 切换当前终端会话
  void switchSession(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    _currentSession = session;
    notifyListeners();
  }

  // 关闭终端会话
  void closeSession(String sessionId) {
    _sessions.removeWhere((session) => session.id == sessionId);
    if (_currentSession?.id == sessionId) {
      _currentSession = _sessions.isNotEmpty ? _sessions.last : null;
    }
    notifyListeners();
  }

  // 添加输出行到当前会话
  void addOutputToCurrentSession(String line) {
    if (_currentSession != null) {
      final updatedSession = _currentSession!.copyWith(
        outputLines: [..._currentSession!.outputLines, line],
      );
      final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
      _sessions[index] = updatedSession;
      _currentSession = updatedSession;
      notifyListeners();
    }
  }

  // 清空当前会话输出
  void clearCurrentSessionOutput() {
    if (_currentSession != null) {
      final updatedSession = _currentSession!.copyWith(outputLines: []);
      final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
      _sessions[index] = updatedSession;
      _currentSession = updatedSession;
      notifyListeners();
    }
  }

  // 更新会话连接状态
  void updateSessionConnectionStatus(String sessionId, bool isConnected) {
    final index = _sessions.indexWhere((session) => session.id == sessionId);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(isConnected: isConnected);
      if (_currentSession?.id == sessionId) {
        _currentSession = _sessions[index];
      }
      notifyListeners();
    }
  }
} 