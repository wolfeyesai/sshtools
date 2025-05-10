// ignore_for_file: unused_import, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import '../component/card_select_component.dart';
import '../models/game_icon_paths.dart';
import '../utils/logger.dart';
import 'header_controller.dart';
import 'dart:convert';
import '../services/server_service.dart';
import '../models/auth_model.dart';
import '../models/game_model.dart';
import '../component/message_component.dart';

/// 首页控制器 - 负责处理首页配置的业务逻辑
/// 
/// 使用Provider模式管理状态，包括游戏选择和卡密管理
/// 与HeaderController进行双向同步
class HomeController extends ChangeNotifier {
  /// 选中的游戏
  CardItem? _selectedGame;
  
  /// 卡密输入控制器
  final TextEditingController cardKeyController = TextEditingController();
  
  /// 页头控制器，用于同步游戏选择
  HeaderController? _headerController;
  
  /// 依赖的服务和模型
  final ServerService _serverService;
  final AuthModel _authModel;
  final GameModel _gameModel;
  
  /// 控制器是否已被销毁
  bool _isDisposed = false;
  
  /// 获取当前选中的游戏
  CardItem? get selectedGame => _selectedGame;
  
  /// 日志
  final String _logTag = 'HomeController';
  final log = Logger();
  
  /// 构造函数 - 注入所需的服务和模型
  HomeController({
    required ServerService serverService,
    required AuthModel authModel,
    required GameModel gameModel,
  }) : _serverService = serverService,
       _authModel = authModel,
       _gameModel = gameModel {
    _initFromGameModel();
    cardKeyController.text = _gameModel.cardKey;
    _serverService.addMessageListener(_handleServerMessage);
    log.i(_logTag, '初始化HomeController');
  }
  
  /// 设置页头控制器引用 - 实现双向同步
  void setHeaderController(HeaderController controller) {
    _headerController = controller;
    _headerController!.addListener(_syncFromHeader);
    _syncFromHeader();
  }
  
  /// 从页头控制器同步游戏选择
  void _syncFromHeader() {
    if (_headerController == null) return;
    
    final headerGameId = _headerController!.selectedGame.id;
    final gameList = getGameCards();
    
    // 查找匹配的游戏
    for (final game in gameList) {
      if (game.id.toLowerCase() == headerGameId.toLowerCase()) {
        if (_selectedGame == null || _selectedGame!.id != game.id) {
          _selectedGame = game;
          log.i(_logTag, '从头部控制器同步游戏选择', { 'gameId': game.id });
          notifyListeners();
        }
        break;
      }
    }
  }
  
  /// 从游戏模型初始化数据
  void _initFromGameModel() {
    final currentGameName = _gameModel.currentGame;
    final gameList = getGameCards();
    
    // 获取文件名格式（不包含路径和扩展名）
    String getFileNameFormat(String name) {
      if (!name.contains('/') && !name.contains('.')) {
        return name.toLowerCase();
      }
      final fileName = name.split('/').last;
      return fileName.split('.').first.toLowerCase();
    }
    
    final gameNameFileFormat = getFileNameFormat(currentGameName);
    
    // 查找匹配的游戏
    for (final game in gameList) {
      if (game.id.toLowerCase() == gameNameFileFormat || 
          game.title.toLowerCase() == gameNameFileFormat) {
        _selectedGame = game;
        log.i(_logTag, '匹配到游戏', {'id': game.id, 'title': game.title});
        return;
      }
    }
    
    // 如果没有找到匹配，使用第一个游戏
    if (gameList.isNotEmpty) {
      _selectedGame = gameList.first;
      _gameModel.updateCurrentGame(_selectedGame!.id);
      log.w(_logTag, '未找到匹配游戏，使用首个游戏', {'id': _selectedGame!.id});
    }
  }
  
  /// 选择游戏 - 由UI调用
  void selectGame(CardItem game) {
    if (_selectedGame?.id == game.id) return;
    
    _selectedGame = game;
    _gameModel.updateCurrentGame(game.id);
    
    // 同步到页头控制器
    if (_headerController != null) {
      _headerController!.handleGameSelected(game.id);
    } else {
      _notifyServerModelChanged('游戏');
    }
    
    log.i(_logTag, '游戏选择已更新', {'gameId': game.id, 'username': _authModel.username});
    notifyListeners();
  }
  
  /// 向服务器发送模型变更通知
  void _notifyServerModelChanged(String changeType) {
    if (!_serverService.isConnected) {
      log.w(_logTag, '无法发送${changeType}更改消息，服务器未连接');
      return;
    }
    
    try {
      final requestData = {
        'action': 'home_modify',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      _serverService.sendMessage(jsonEncode(requestData));
      log.i(_logTag, '已发送${changeType}更改消息');
    } catch (e) {
      log.e(_logTag, '发送${changeType}更改消息失败', e.toString());
    }
  }
  
  /// 处理卡密输入变化 - 由UI调用
  void onCardKeyChanged(String value) {
    _gameModel.updateCardKey(value);
    _notifyServerModelChanged('卡密');
  }
  
  /// 获取所有游戏卡片 - 由UI调用
  List<CardItem> getGameCards() {
    // 从路径中提取文件名作为标题
    String extractTitleFromPath(String path) {
      final fileName = path.split('/').last;
      return fileName.split('.').first;
    }
    
    // 游戏图片路径集合
    final List<String> imagePaths = [
      GameIconPaths.apex,
      GameIconPaths.cf,
      GameIconPaths.cfhd,
      GameIconPaths.csgo2,
      GameIconPaths.pubg,
      GameIconPaths.sjz,
      GameIconPaths.ssjj2,
      GameIconPaths.wwqy,
    ];
    
    // 创建卡片列表
    return imagePaths.map((path) {
      final fileName = extractTitleFromPath(path);
      return CardItem(
        id: fileName,
        title: fileName,
        imagePath: path,
        color: Colors.white,
      );
    }).toList();
  }
  
  /// 获取初始选中的游戏ID - 由UI调用
  String? getInitialSelectedId() => _selectedGame?.id;
  
  /// 刷新首页配置 - 由UI调用
  void refreshHomeConfig() {
    if (!_serverService.isConnected) {
      log.w(_logTag, '无法刷新首页配置，服务器未连接');
      return;
    }
    
    try {
      final requestData = {
        'action': 'home_read',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      _serverService.sendMessage(jsonEncode(requestData));
      log.i(_logTag, '已请求首页配置');
    } catch (e) {
      log.e(_logTag, '请求首页配置失败', e.toString());
    }
  }
  
  /// 保存首页配置 - 由UI调用
  void saveHomeConfig(BuildContext context) {
    if (!_serverService.isConnected) {
      log.w(_logTag, '无法保存首页配置，服务器未连接');
      return;
    }
    
    try {
      final requestData = {
        'action': 'home_modify',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      _serverService.sendMessage(jsonEncode(requestData));
      log.i(_logTag, '已保存首页配置');
      
      // 显示保存成功消息
      MessageComponent.showIconToast(
        context: context,
        message: '首页配置已保存',
        type: MessageType.success,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      log.e(_logTag, '保存首页配置失败', e.toString());
      
      // 显示保存失败消息
      MessageComponent.showIconToast(
        context: context,
        message: '保存失败: ${e.toString()}',
        type: MessageType.error,
        duration: const Duration(seconds: 2),
      );
    }
  }
  
  /// 处理服务器消息
  void _handleServerMessage(dynamic message) {
    if (_isDisposed) return;
    
    try {
      final responseData = jsonDecode(message.toString());
      
      // 处理首页配置读取响应
      if (responseData['action'] == 'home_read') {
        log.i(_logTag, '收到首页配置响应');
        
        if (responseData['status'] != 'ok') return;
        
        final data = responseData['data'];
        if (data == null) return;
        
        // 更新卡密
        final cardKey = data['cardKey'];
        if (cardKey != null && cardKey.toString().isNotEmpty) {
          cardKeyController.text = cardKey.toString();
          _gameModel.updateCardKey(cardKey.toString());
        }
        
        // 更新游戏
        final gameName = data['gameName'];
        if (gameName != null && gameName.toString().isNotEmpty) {
          _gameModel.updateCurrentGame(gameName.toString());
          
          // 查找并设置对应的游戏卡片
          for (final game in getGameCards()) {
            if (game.id.toLowerCase() == gameName.toString().toLowerCase()) {
              _selectedGame = game;
              break;
            }
          }
          
          notifyListeners();
        }
      }
      // 处理首页配置修改响应
      else if (responseData['action'] == 'home_modify_response') {
        log.i(_logTag, '收到保存配置响应');
        
        if (responseData['status'] != 'ok') {
          log.w(_logTag, '保存配置响应状态异常', {'status': responseData['status']});
          return;
        }
        
        final data = responseData['data'];
        if (data == null) return;
        
        log.i(_logTag, '成功保存配置', {'username': data['username'], 'gameName': data['gameName']});
      }
    } catch (e) {
      log.e(_logTag, '处理服务器消息失败', e.toString());
    }
  }
  
  /// 销毁资源
  @override
  void dispose() {
    _isDisposed = true;
    
    // 保存最终状态
    if (_selectedGame != null) {
      _gameModel.updateCurrentGame(_selectedGame!.id);
    }
    _gameModel.updateCardKey(cardKeyController.text);
    
    // 清理资源
    _serverService.removeMessageListener(_handleServerMessage);
    if (_headerController != null) {
      _headerController!.removeListener(_syncFromHeader);
    }
    
    cardKeyController.dispose();
    super.dispose();
  }
} 