// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps

import 'dart:convert';
import 'package:flutter/material.dart';
import '../views/function/card_manager_component.dart';
import '../utils/logger.dart';
import '../models/function_model.dart';
import '../services/server_service.dart';
import '../models/game_model.dart';
import '../models/auth_model.dart';
import '../component/message_component.dart';

/// 事件处理器接口，用于定义卡片管理相关的事件处理方法
abstract class CardEventHandler {
  void onCardPropertyChanged(CardData card, String property, String newValue);
  void onCardBoolPropertyChanged(CardData card, String property, bool newValue);
  void onCardAdded(String presetName);
  void onGetAllCardsInfo();
  void onCardUpdated(CardData card);
}

/// 数据管理类，负责卡片数据的增删改查
class CardDataManager {
  // 卡片列表
  final List<CardData> cards = [];
  
  // 用于通知UI更新的回调
  final Function(VoidCallback) updateState;
  
  // FunctionModel
  final FunctionModel functionModel;
  
  CardDataManager({required this.updateState, required this.functionModel});
  
  /// 从模型数据初始化默认卡片
  void initDefaultCards() {
    cards.clear();
    final configList = functionModel.configs;
    
    for (final config in configList) {
      final card = CardData(
        presetName: config['presetName'] as String,
        hotkey: config['hotkey'] as String,
        aiMode: config['aiMode'] as String,
        lockPosition: config['lockPosition'] as String,
        triggerSwitch: config['triggerSwitch'] as bool,
        enabled: config['enabled'] as bool,
      );
      
      cards.add(card);
    }
  }
  
  /// 添加新卡片
  CardData addCard(String presetName) {
    final newCard = CardData(
      presetName: presetName,
      hotkey: functionModel.hotkeys.isNotEmpty ? functionModel.hotkeys[0] : '',
      aiMode: functionModel.aiModes.isNotEmpty ? functionModel.aiModes[0] : '',
      lockPosition: functionModel.lockPositions.isNotEmpty ? functionModel.lockPositions[0] : '',
      triggerSwitch: false,
      enabled: true,
    );
    
    updateState(() {
      cards.add(newCard);
      functionModel.addConfig(
        presetName: presetName,
        hotkey: newCard.hotkey,
        aiMode: newCard.aiMode,
        lockPosition: newCard.lockPosition,
        triggerSwitch: newCard.triggerSwitch,
        enabled: newCard.enabled,
      );
    });
    
    return newCard;
  }
  
  /// 更新卡片属性
  void updateCardProperty(CardData card, String property, String newValue) {
    updateState(() {
      switch (property) {
        case 'presetName':
          card.presetName = newValue;
          break;
        case 'hotkey':
          card.hotkey = newValue;
          break;
        case 'aiMode':
          card.aiMode = newValue;
          break;
        case 'lockPosition':
          card.lockPosition = newValue;
          break;
        default:
          return;
      }

      functionModel.updateConfig(card.presetName, property, newValue);
    });
  }
  
  /// 更新卡片布尔属性
  void updateCardBoolProperty(CardData card, String property, bool newValue) {
    updateState(() {
      switch (property) {
        case 'enabled':
          card.enabled = newValue;
          break;
        case 'triggerSwitch':
          card.triggerSwitch = newValue;
          break;
        default:
          return;
      }

      functionModel.updateConfig(card.presetName, property, newValue);
    });
  }
  
  /// 获取所有卡片信息并转换为JSON
  String getAllCardsInfo() => functionModel.toJson();
}

/// 事件处理器实现，处理卡片相关的所有事件
class CardEventHandlerImpl implements CardEventHandler {
  final CardDataManager dataManager;
  final FunctionModel functionModel;
  final ServerService? serverService;
  final GameModel? gameModel;
  final AuthModel? authModel;
  
  final log = Logger();
  final String _logTag = 'CardEvent';
  
  CardEventHandlerImpl({
    required this.dataManager, 
    required this.functionModel,
    this.serverService,
    this.gameModel,
    this.authModel,
  });
  
  @override
  void onCardPropertyChanged(CardData card, String property, String newValue) {
    dataManager.updateCardProperty(card, property, newValue);
    log.i(_logTag, '卡片属性已更新: ${card.presetName} - $property = $newValue');
  }
  
  @override
  void onCardBoolPropertyChanged(CardData card, String property, bool newValue) {
    dataManager.updateCardBoolProperty(card, property, newValue);
    log.i(_logTag, '卡片布尔属性已更新: ${card.presetName} - $property = $newValue');
  }
  
  @override
  void onCardAdded(String presetName) {
    dataManager.addCard(presetName);
    log.i(_logTag, '已添加新卡片: $presetName');
  }
  
  @override
  void onGetAllCardsInfo() {
    log.i(_logTag, '准备发送功能配置');
    _sendFunctionConfigToServer();
  }
  
  /// 向后端发送功能设置配置信息
  void _sendFunctionConfigToServer() {
    if (serverService == null || !serverService!.isConnected) {
      log.e(_logTag, '无法发送配置到服务器：WebSocket未连接');
      return;
    }
    
    if (gameModel == null || authModel == null) {
      log.e(_logTag, '无法发送配置到服务器：模型未初始化');
      return;
    }
    
    try {
      final String gameName = gameModel!.currentGame;
      final String cardKey = gameModel!.cardKey;
      final String username = authModel!.username;
      
      final payload = {
        'action': 'function_modify',
        'content': {
          'username': username,
          'gameName': gameName,
          'cardKey': cardKey,
          'configs': functionModel.configs,
          'createdAt': functionModel.createdAt,
          'updatedAt': functionModel.updatedAt
        }
      };
      
      serverService!.sendMessage(jsonEncode(payload));
      log.i(_logTag, '已发送功能配置到服务器：$gameName');
    } catch (e) {
      log.e(_logTag, '发送配置到服务器时出错：$e');
    }
  }
  
  @override
  void onCardUpdated(CardData card) {
    log.i(_logTag, '卡片已更新: ${card.presetName}');
  }
}

/// 功能控制器 - 负责连接UI和数据模型
class FunctionController extends ChangeNotifier {
  late CardDataManager _dataManager;
  late CardEventHandler _eventHandler;
  final FunctionModel _functionModel;
  final ServerService? _serverService;
  final GameModel? _gameModel;
  final AuthModel? _authModel;
  
  final log = Logger();
  bool _isDisposed = false;
  final String _logTag = 'FunctionController';
  
  List<CardData> get cards => _dataManager.cards;
  
  // 防抖动控制
  DateTime _lastRequestTime = DateTime.now().subtract(const Duration(minutes: 1));
  String _lastRequestedGame = '';
  
  // 请求状态
  bool _isRequesting = false;
  
  FunctionController({
    required FunctionModel functionModel,
    ServerService? serverService,
    GameModel? gameModel,
    AuthModel? authModel,
  }) : _functionModel = functionModel,
       _serverService = serverService,
       _gameModel = gameModel,
       _authModel = authModel {
    _initController();
  }
  
  /// 初始化控制器
  void _initController() {
    _dataManager = CardDataManager(
      updateState: (callback) {
        callback();
        notifyListeners();
      },
      functionModel: _functionModel,
    );
    
    _eventHandler = CardEventHandlerImpl(
      dataManager: _dataManager,
      functionModel: _functionModel,
      serverService: _serverService,
      gameModel: _gameModel,
      authModel: _authModel,
    );
    
    if (_serverService != null) {
      _serverService.addMessageListener(_handleServerMessage);
    }
    
    if (_gameModel != null) {
      _gameModel.addListener(_handleGameModelChanged);
    }
    
    _dataManager.initDefaultCards();
  }
  
  /// 处理服务器消息
  void _handleServerMessage(dynamic message) {
    if (_isDisposed) return;
    
    try {
      final Map<String, dynamic> responseData = jsonDecode(message.toString());
      final String action = responseData['action'] ?? '';
      
      // 处理读取功能配置响应
      if (action == 'function_read_response') {
        _handleFunctionReadResponse(responseData);
        _isRequesting = false;
        return;
      }
      
      // 处理修改功能配置响应
      if (action == 'function_modify_response') {
        _handleFunctionModifyResponse(responseData);
        return;
      }
    } catch (e) {
      log.e(_logTag, '处理服务器消息失败: $e');
      _isRequesting = false;
    }
  }
  
  /// 处理功能配置读取响应
  void _handleFunctionReadResponse(Map<String, dynamic> response) {
    try {
      final status = response['status'];
      if (status == 'success' || status == 'ok') {
        final data = response['data'];
        if (data != null && data['configs'] != null) {
          final configs = data['configs'] as List<dynamic>;
          _updateFunctionConfigs(configs);
          notifyListeners();
        }
      } else {
        log.w(_logTag, '功能配置读取失败: ${response['message'] ?? '未知错误'}');
      }
    } catch (e) {
      log.e(_logTag, '处理功能配置读取响应失败: $e');
    }
  }
  
  /// 处理功能配置修改响应
  void _handleFunctionModifyResponse(Map<String, dynamic> response) {
    try {
      final status = response['status'];
      if (status == 'success' || status == 'ok') {
        log.i(_logTag, '功能配置修改成功');
      } else {
        log.w(_logTag, '功能配置修改失败: ${response['message'] ?? '未知错误'}');
      }
    } catch (e) {
      log.e(_logTag, '处理功能配置修改响应失败: $e');
    }
  }
  
  /// 更新功能模型中的配置
  void _updateFunctionConfigs(List<dynamic> configs) {
    try {
      final updatedConfigs = configs
          .map((config) => Map<String, dynamic>.from(config as Map))
          .toList();
      
      _functionModel.setConfigs(updatedConfigs);
      _dataManager.initDefaultCards();
    } catch (e) {
      log.e(_logTag, '更新功能配置失败: $e');
    }
  }
  
  /// 添加新卡片
  void addCard(String presetName) {
    _eventHandler.onCardAdded(presetName);
    notifyListeners();
  }
  
  /// 更新卡片属性
  void updateCardProperty(CardData card, String property, String newValue) {
    _eventHandler.onCardPropertyChanged(card, property, newValue);
  }
  
  /// 更新卡片布尔属性
  void updateCardBoolProperty(CardData card, String property, bool newValue) {
    _eventHandler.onCardBoolPropertyChanged(card, property, newValue);
  }
  
  /// 获取所有卡片信息并发送到服务器
  String getAllCardsInfo() {
    _eventHandler.onGetAllCardsInfo();
    return _dataManager.getAllCardsInfo();
  }
  
  /// 获取所有卡片信息并发送到服务器，带消息提示
  Future<void> saveAllCardsInfo(BuildContext context) async {
    try {
      _eventHandler.onGetAllCardsInfo();
      
      MessageComponent.showIconToast(
        context: context,
        message: '功能配置已保存',
        type: MessageType.success,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      log.e(_logTag, '保存功能配置失败: $e');
      
      MessageComponent.showIconToast(
        context: context,
        message: '保存失败: $e',
        type: MessageType.error,
        duration: const Duration(seconds: 2),
      );
    }
  }
  
  /// 主动刷新功能配置
  void refreshFunctionConfig() {
    if (_isRequesting) {
      log.i(_logTag, '已有请求正在进行中，忽略此次刷新');
      return;
    }
    
    if (_serverService == null || !_serverService.isConnected || 
        _authModel == null || _gameModel == null) {
      log.w(_logTag, '无法刷新配置：服务未连接或模型未初始化');
      return;
    }
    
    _lastRequestTime = DateTime.now().subtract(const Duration(seconds: 5));
    _lastRequestedGame = '';
    _requestFunctionConfig();
  }
  
  /// 处理卡片更新
  void handleCardUpdated(CardData card) {
    _eventHandler.onCardUpdated(card);
    notifyListeners();
  }
  
  /// 处理游戏模型变更
  void _handleGameModelChanged() {
    if (_isDisposed || _gameModel == null) return;
    _requestFunctionConfig();
  }
  
  /// 请求最新的功能配置
  void _requestFunctionConfig() {
    if (_isRequesting) return;
    
    if (_serverService == null || !_serverService.isConnected || 
        _authModel == null || _gameModel == null) {
      return;
    }
    
    final now = DateTime.now();
    final currentGame = _gameModel.currentGame;
    
    // 防抖动控制
    if (_lastRequestedGame == currentGame && 
        now.difference(_lastRequestTime).inMilliseconds < 2000) {
      return;
    }
    
    _lastRequestTime = now;
    _lastRequestedGame = currentGame;
    _isRequesting = true;
    
    try {
      final request = {
        'action': 'function_read',
        'content': {
          'username': _authModel.username,
          'gameName': currentGame,
          'cardKey': _gameModel.cardKey,
          'updatedAt': now.toIso8601String(),
        }
      };
      
      _serverService.sendMessage(jsonEncode(request));
      log.i(_logTag, '已请求功能配置: $currentGame');
      
      // 设置超时处理
      Future.delayed(const Duration(seconds: 10), () {
        if (_isRequesting) {
          _isRequesting = false;
          log.w(_logTag, '功能配置请求超时');
        }
      });
    } catch (e) {
      _isRequesting = false;
      log.e(_logTag, '请求功能配置失败: $e');
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    
    if (_serverService != null) {
      _serverService.removeMessageListener(_handleServerMessage);
    }
    
    if (_gameModel != null) {
      _gameModel.removeListener(_handleGameModelChanged);
    }
    
    super.dispose();
  }
}
