import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ssh_saved_session_model.dart';
import '../models/ip_model.dart';
import '../utils/logger.dart';

/// SSH会话控制器
class SSHSessionController extends ChangeNotifier {
  /// 存储键名
  static const String _storageKey = 'ssh_saved_sessions';
  
  /// 会话列表
  List<SSHSavedSessionModel> _sessions = [];
  
  /// 是否正在执行操作
  bool _isBusy = false;
  
  /// 最后一次保存时间
  DateTime? _lastSaveTime;
  
  /// 获取会话列表
  List<SSHSavedSessionModel> get sessions => List.unmodifiable(_sessions);
  
  /// 获取收藏会话
  List<SSHSavedSessionModel> get favoriteSessions => 
      List.unmodifiable(_sessions.where((session) => session.isFavorite).toList());
  
  /// 获取最后保存时间
  DateTime? get lastSaveTime => _lastSaveTime;
  
  /// 获取会话数量
  int get sessionCount => _sessions.length;
  
  /// 初始化控制器
  Future<void> init() async {
    if (_isBusy) {
      log.w('SSHSessionController', 'init(): 控制器正忙，跳过初始化');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHSessionController', 'init(): 开始初始化会话控制器');
      debugPrint('SSHSessionController.init(): 开始初始化，设置_isBusy=true');
      await _loadSessionsInternal();
      log.i('SSHSessionController', 'init(): 会话控制器初始化完成，加载了 ${_sessions.length} 个会话');
    } catch (e) {
      log.e('SSHSessionController', '初始化SSH会话控制器出错', e);
      debugPrint('SSHSessionController.init(): 初始化出错: $e');
      _sessions = [];
    } finally {
      _isBusy = false;
      debugPrint('SSHSessionController.init(): 初始化完成，设置_isBusy=false');
    }
  }
  
  /// 内部方法：从存储加载会话，不受_isBusy标志影响
  Future<bool> _loadSessionsInternal() async {
    try {
      log.i('SSHSessionController', '_loadSessionsInternal(): 开始从持久化存储加载会话数据');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      log.d('SSHSessionController', '_loadSessionsInternal(): 从SharedPreferences读取的数据', jsonString);
      debugPrint('SSHSessionController._loadSessionsInternal(): 从存储读取的原始数据长度: ${jsonString?.length ?? 0}');
      
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          debugPrint('SSHSessionController._loadSessionsInternal(): 解析后的JSON列表长度: ${jsonList.length}');
          
          _sessions = jsonList
              .map((json) => SSHSavedSessionModel.fromJson(json))
              .toList();
          
          // 按最后连接时间排序，最近的在前面
          _sessions.sort((a, b) => b.lastConnectedAt.compareTo(a.lastConnectedAt));
          
          log.i('SSHSessionController', '_loadSessionsInternal(): 成功加载 ${_sessions.length} 个会话');
          for (var session in _sessions) {
            log.d('SSHSessionController', '已加载会话', '${session.name} (${session.host}:${session.port})');
            debugPrint('SSHSessionController._loadSessionsInternal(): 加载会话: ${session.name} (${session.host}:${session.port})');
          }
          
          notifyListeners();
          return true;
        } catch (e) {
          log.e('SSHSessionController', '解析SSH会话JSON出错', e);
          debugPrint('SSHSessionController._loadSessionsInternal(): 解析SSH会话JSON出错: $e');
          _sessions = [];
          return false;
        }
      } else {
        log.w('SSHSessionController', '_loadSessionsInternal(): 未找到会话数据或数据为空');
        debugPrint('SSHSessionController._loadSessionsInternal(): 未找到会话数据或数据为空');
        _sessions = [];
        return false;
      }
    } catch (e) {
      log.e('SSHSessionController', '加载SSH会话出错', e);
      debugPrint('SSHSessionController._loadSessionsInternal(): 加载SSH会话出错: $e');
      _sessions = [];
      return false;
    }
  }
  
  /// 内部方法：保存会话到存储，不受_isBusy标志影响
  Future<bool> _saveSessionsInternal() async {
    try {
      if (_sessions.isEmpty) {
        log.i('SSHSessionController', '_saveSessionsInternal(): 会话列表为空，跳过保存');
        debugPrint('SSHSessionController._saveSessionsInternal(): 会话列表为空，跳过保存');
        return false;
      }
      
      log.i('SSHSessionController', '_saveSessionsInternal(): 开始保存 ${_sessions.length} 个会话到持久化存储');
      debugPrint('SSHSessionController._saveSessionsInternal(): 开始保存 ${_sessions.length} 个会话到持久化存储');
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _sessions.map((session) => session.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      debugPrint('SSHSessionController._saveSessionsInternal(): 要保存的JSON数据长度: ${jsonString.length}');
      log.d('SSHSessionController', '_saveSessionsInternal(): 要保存的JSON数据', jsonString);
      
      final result = await prefs.setString(_storageKey, jsonString);
      if (result) {
        _lastSaveTime = DateTime.now();
        log.i('SSHSessionController', '_saveSessionsInternal(): 会话数据保存成功');
        debugPrint('SSHSessionController._saveSessionsInternal(): 会话数据保存成功，时间: $_lastSaveTime');
        
        // 验证保存结果
        final savedData = prefs.getString(_storageKey);
        if (savedData != null && savedData.isNotEmpty) {
          debugPrint('SSHSessionController._saveSessionsInternal(): 验证保存结果成功，数据长度: ${savedData.length}');
          return true;
        } else {
          debugPrint('SSHSessionController._saveSessionsInternal(): 警告：验证保存结果失败，无法读取保存的数据');
          return false;
        }
      } else {
        log.e('SSHSessionController', '_saveSessionsInternal(): 会话数据保存失败');
        debugPrint('SSHSessionController._saveSessionsInternal(): 会话数据保存失败');
        return false;
      }
    } catch (e) {
      log.e('SSHSessionController', '保存SSH会话出错', e);
      debugPrint('SSHSessionController._saveSessionsInternal(): 保存SSH会话出错: $e');
      return false;
    }
  }
  
  /// 从存储加载会话
  Future<void> loadSessions() async {
    if (_isBusy) {
      log.w('SSHSessionController', 'loadSessions(): 控制器正忙，跳过加载');
      debugPrint('SSHSessionController.loadSessions(): 控制器正忙，使用内部方法尝试加载');
      await _loadSessionsInternal();
      return;
    }
    _isBusy = true;
    
    try {
      await _loadSessionsInternal();
    } finally {
      _isBusy = false;
    }
  }
  
  /// 保存会话到存储
  Future<void> saveSessions() async {
    if (_isBusy) {
      log.w('SSHSessionController', 'saveSessions(): 控制器正忙，跳过保存');
      debugPrint('SSHSessionController.saveSessions(): 控制器正忙，使用内部方法尝试保存');
      await _saveSessionsInternal();
      return;
    }
    _isBusy = true;
    
    try {
      await _saveSessionsInternal();
    } finally {
      _isBusy = false;
    }
  }
  
  /// 添加会话
  Future<void> addSession(SSHSavedSessionModel session) async {
    if (_isBusy) {
      log.w('SSHSessionController', 'addSession(): 控制器正忙，跳过添加会话');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHSessionController', 'addSession(): 添加会话 ${session.name} (${session.host}:${session.port})');
      
      // 避免重复的会话连接信息
      final existingIndex = _sessions.indexWhere(
        (s) => s.host == session.host && 
              s.port == session.port && 
              s.username == session.username
      );
      
      if (existingIndex >= 0) {
        // 更新现有会话的最后连接时间
        log.i('SSHSessionController', 'addSession(): 会话已存在，更新最后连接时间');
        _sessions[existingIndex].lastConnectedAt = DateTime.now();
      } else {
        // 添加新会话
        log.i('SSHSessionController', 'addSession(): 添加新会话');
        _sessions.add(session);
      }
      
      // 排序
      _sessions.sort((a, b) => b.lastConnectedAt.compareTo(a.lastConnectedAt));
      
      await saveSessions();
      notifyListeners();
    } catch (e) {
      log.e('SSHSessionController', '添加会话出错', e);
    } finally {
      _isBusy = false;
    }
  }
  
  /// 更新会话
  Future<void> updateSession(SSHSavedSessionModel session) async {
    if (_isBusy) {
      log.w('SSHSessionController', 'updateSession(): 控制器正忙，跳过更新会话');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHSessionController', 'updateSession(): 更新会话 ${session.name} (${session.host}:${session.port})');
      
      final index = _sessions.indexWhere((s) => s.id == session.id);
      
      if (index >= 0) {
        _sessions[index] = session;
        await saveSessions();
        notifyListeners();
        log.i('SSHSessionController', 'updateSession(): 会话更新成功');
      } else {
        log.w('SSHSessionController', 'updateSession(): 未找到指定ID的会话', session.id);
      }
    } catch (e) {
      log.e('SSHSessionController', '更新会话出错', e);
    } finally {
      _isBusy = false;
    }
  }
  
  /// 删除会话
  Future<void> deleteSession(String id) async {
    if (_isBusy) {
      log.w('SSHSessionController', 'deleteSession(): 控制器正忙，跳过删除会话');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHSessionController', 'deleteSession(): 删除会话ID', id);
      
      _sessions.removeWhere((session) => session.id == id);
      await saveSessions();
      notifyListeners();
      
      log.i('SSHSessionController', 'deleteSession(): 会话删除成功');
    } catch (e) {
      log.e('SSHSessionController', '删除会话出错', e);
    } finally {
      _isBusy = false;
    }
  }
  
  /// 切换收藏状态
  Future<void> toggleFavorite(String id) async {
    if (_isBusy) {
      log.w('SSHSessionController', 'toggleFavorite(): 控制器正忙，跳过切换收藏状态');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHSessionController', 'toggleFavorite(): 切换会话收藏状态，ID', id);
      
      final index = _sessions.indexWhere((session) => session.id == id);
      
      if (index >= 0) {
        _sessions[index].isFavorite = !_sessions[index].isFavorite;
        await saveSessions();
        notifyListeners();
        
        log.i('SSHSessionController', 'toggleFavorite(): 会话收藏状态已切换为', _sessions[index].isFavorite);
      } else {
        log.w('SSHSessionController', 'toggleFavorite(): 未找到指定ID的会话', id);
      }
    } catch (e) {
      log.e('SSHSessionController', '切换收藏状态出错', e);
    } finally {
      _isBusy = false;
    }
  }
  
  /// 记录连接
  Future<void> recordConnection({
    required String host,
    required int port,
    required String username,
    required String password,
    String? name,
  }) async {
    final sessionName = name ?? '$username@$host:$port';
    
    log.i('SSHSessionController', 'recordConnection(): 记录连接 $sessionName');
    
    // 检查是否已存在
    final existingIndex = _sessions.indexWhere(
      (s) => s.host == host && s.port == port && s.username == username
    );
    
    if (existingIndex >= 0) {
      // 更新现有会话
      log.i('SSHSessionController', 'recordConnection(): 更新现有会话');
      _sessions[existingIndex].lastConnectedAt = DateTime.now();
      if (name != null) {
        _sessions[existingIndex].name = name;
      }
    } else {
      // 添加新会话
      log.i('SSHSessionController', 'recordConnection(): 添加新会话');
      final newSession = SSHSavedSessionModel(
        name: sessionName,
        host: host,
        port: port,
        username: username,
        password: password,
      );
      _sessions.add(newSession);
    }
    
    // 排序并保存
    _sessions.sort((a, b) => b.lastConnectedAt.compareTo(a.lastConnectedAt));
    await saveSessions();
    notifyListeners();
  }
  
  /// 清空会话历史
  Future<void> clearHistory() async {
    if (_isBusy) {
      log.w('SSHSessionController', 'clearHistory(): 控制器正忙，跳过清空历史');
      return;
    }
    _isBusy = true;
    
    try {
      log.i('SSHSessionController', 'clearHistory(): 清空会话历史，保留收藏的会话');
      
      // 只保留收藏的会话
      _sessions = _sessions.where((s) => s.isFavorite).toList();
      await saveSessions();
      notifyListeners();
      
      log.i('SSHSessionController', 'clearHistory(): 会话历史已清空，剩余收藏会话数', _sessions.length);
    } catch (e) {
      log.e('SSHSessionController', '清空会话历史出错', e);
    } finally {
      _isBusy = false;
    }
  }
  
  /// 从设备创建会话
  SSHSavedSessionModel createSessionFromDevice({
    required IPDeviceModel device,
    required String username,
    required String password,
    required int port,
  }) {
    // 生成会话名称
    final sessionName = '${device.displayName} 会话';
    
    log.i('SSHSessionController', 'createSessionFromDevice(): 从设备创建会话 $sessionName');
    
    // 创建会话对象
    final session = SSHSavedSessionModel(
      name: sessionName,
      host: device.ipAddress,
      port: port,
      username: username,
      password: password,
    );
    
    return session;
  }
  
  /// 标记会话为已使用
  Future<void> markSessionAsUsed(String sessionId) async {
    try {
      log.i('SSHSessionController', 'markSessionAsUsed(): 标记会话为已使用，ID', sessionId);
      
      final session = getSessionById(sessionId);
      
      if (session != null) {
        session.lastConnectedAt = DateTime.now();
        await saveSessions();
        
        log.i('SSHSessionController', 'markSessionAsUsed(): 会话使用时间已更新');
      } else {
        log.w('SSHSessionController', 'markSessionAsUsed(): 未找到指定ID的会话', sessionId);
      }
    } catch (e) {
      log.e('SSHSessionController', '更新会话使用时间出错', e);
    }
  }
  
  /// 搜索会话
  List<SSHSavedSessionModel> searchSessions(String keyword) {
    if (keyword.isEmpty) {
      return _sessions;
    }
    
    keyword = keyword.toLowerCase();
    
    return _sessions.where((session) {
      return session.name.toLowerCase().contains(keyword) ||
          session.host.toLowerCase().contains(keyword) ||
          session.username.toLowerCase().contains(keyword);
    }).toList();
  }
  
  /// 按最近使用时间排序会话
  List<SSHSavedSessionModel> getRecentSessions({int limit = 5}) {
    final sessions = List<SSHSavedSessionModel>.from(_sessions);
    sessions.sort((a, b) => b.lastConnectedAt.compareTo(a.lastConnectedAt));
    
    if (sessions.length <= limit) {
      return sessions;
    }
    
    return sessions.sublist(0, limit);
  }
  
  /// 获取会话
  SSHSavedSessionModel? getSessionById(String sessionId) {
    try {
      return _sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      log.w('SSHSessionController', 'getSessionById(): 未找到指定ID的会话', sessionId);
      return null;
    }
  }
} 