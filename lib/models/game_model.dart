// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 游戏模型 - 管理游戏相关数据
class GameModel extends ChangeNotifier {
  // 游戏列表
  final List<String> _gameList = [
    'apex',
    'cf',
    'cfhd',
    'csgo2',
    'sj2',
    'ssjj2',
    'wwqy'
  ];
  
  // 当前选中的游戏
  String _currentGame = 'csgo2';
  
  // 卡密信息
  String _cardKey = '';
  
  // 游戏切换监听器
  final List<Function(String)> _gameChangeListeners = [];
  
  // 添加上次游戏切换时间记录
  DateTime _lastGameChangeTime = DateTime.now().subtract(const Duration(minutes: 1));
  
  // Getters
  List<String> get gameList => _gameList;
  String get currentGame => _currentGame;
  String get cardKey => _cardKey;
  
  // 添加游戏切换监听器
  void addGameChangeListener(Function(String) listener) {
    if (!_gameChangeListeners.contains(listener)) {
      _gameChangeListeners.add(listener);
    }
  }
  
  // 移除游戏切换监听器
  void removeGameChangeListener(Function(String) listener) {
    _gameChangeListeners.remove(listener);
  }
  
  // 触发游戏变更事件
  void _notifyGameChanged(String newGame) {
    for (final listener in _gameChangeListeners) {
      try {
        listener(newGame);
      } catch (e) {
        print('游戏变更监听器错误: $e');
      }
    }
  }
  
  // 图标路径获取
  String getGameIconPath(String gameName) {
    final gameIcons = {
      'apex': 'assets/GameImgIco/apex.png',
      'cf': 'assets/GameImgIco/cf.png',
      'cfhd': 'assets/GameImgIco/cfhd.jpg',
      'csgo2': 'assets/GameImgIco/csgo2.png',
      'sj2': 'assets/GameImgIco/sjz.png',
      'ssjj2': 'assets/GameImgIco/ssjj2.png',
      'wwqy': 'assets/GameImgIco/wwqy.png',
    };
    
    return gameIcons[gameName] ?? 'assets/GameImgIco/default.png';
  }
  
  // 初始化 - 从持久化存储加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 添加新游戏到列表
    final savedGameList = prefs.getStringList('gameList');
    if (savedGameList != null && savedGameList.isNotEmpty) {
      _gameList.clear();
      _gameList.addAll(savedGameList);
    }
    
    // 保存旧值以检测变化
    final oldGame = _currentGame;
    
    _currentGame = prefs.getString('currentGame') ?? 'csgo2';
    _cardKey = prefs.getString('cardKey') ?? '';
    
    // 检测游戏是否变更
    if (oldGame != _currentGame) {
      _notifyGameChanged(_currentGame);
    }
    
    notifyListeners();
  }
  
  // 更新当前游戏
  Future<void> updateCurrentGame(String gameName) async {
    // 检查游戏是否存在于列表中，且与当前游戏不同
    if (_gameList.contains(gameName) && _currentGame != gameName) {
      // 防抖动：检查距离上次切换时间是否足够
      final now = DateTime.now();
      if (now.difference(_lastGameChangeTime).inMilliseconds < 500) {
        print('忽略过快的游戏切换请求，上次切换时间: ${_lastGameChangeTime.toIso8601String()}');
        return;
      }
      
      // 更新上次切换时间
      _lastGameChangeTime = now;
      
      // 保存旧值以用于输出日志
      final oldGame = _currentGame;
      
      _currentGame = gameName;
      await _saveSettings();
      
      // 触发游戏变更事件
      _notifyGameChanged(gameName);
      
      notifyListeners();
      
      print('游戏已切换: $oldGame -> $gameName');
    }
  }
  
  // 更新卡密
  Future<void> updateCardKey(String cardKey) async {
    _cardKey = cardKey;
    await _saveSettings();
    notifyListeners();
  }
  
  // 添加游戏
  Future<void> addGame(String gameName) async {
    if (!_gameList.contains(gameName)) {
      _gameList.add(gameName);
      await _saveSettings();
      notifyListeners();
    }
  }
  
  // 移除游戏
  Future<void> removeGame(String gameName) async {
    if (_gameList.contains(gameName)) {
      _gameList.remove(gameName);
      
      // 如果移除的是当前游戏，则切换到默认游戏
      if (_currentGame == gameName && _gameList.isNotEmpty) {
        final newGame = _gameList.first;
        _currentGame = newGame;
        
        // 触发游戏变更事件
        _notifyGameChanged(newGame);
      }
      
      await _saveSettings();
      notifyListeners();
    }
  }
  
  // 保存设置到持久化存储
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setStringList('gameList', _gameList);
    await prefs.setString('currentGame', _currentGame);
    await prefs.setString('cardKey', _cardKey);
  }
} 