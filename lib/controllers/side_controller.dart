// ignore_for_file: unnecessary_this

import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/sidebar_model.dart'; // 导入侧边栏模型
import '../models/auth_model.dart'; // 导入认证模型
import '../models/game_model.dart'; // 导入游戏模型 
import '../utils/logger.dart'; // 导入日志工具
import '../services/server_service.dart'; // 导入服务器服务
import '../component/message_component.dart'; // 导入消息组件

/// 侧边栏控制器
/// 负责管理侧边栏状态和页面切换
class SideController extends ChangeNotifier {
  // 当前活动页面
  String _activePage = 'home';
  
  // 侧边栏是否展开
  bool _isExpanded = true;
  
  // 侧边栏宽度
  double _sidebarWidth = 250;
  
  // 控制器是否已被销毁
  bool _isDisposed = false;
  
  // 服务和模型引用
  final ServerService _serverService;
  final SidebarModel _sidebarModel;
  final AuthModel _authModel;
  final GameModel _gameModel;
  
  // 日志工具
  final log = Logger();
  
  // 日志标签
  final String _logTag = 'SideController';
  
  // 所有页面ID列表
  final List<String> _allPageIds = [
    'home',
    'function',
    'pid',
    'fov',
    'aim',
    'fire',
    'data_collection'
  ];
  
  // Getters
  String get activePage => _activePage;
  bool get isExpanded => _isExpanded;
  double get sidebarWidth => _isExpanded ? _sidebarWidth : 60;
  List<String> get allPageIds => _allPageIds;
  
  /// 构造函数
  SideController({
    required ServerService serverService,
    required SidebarModel sidebarModel,
    required AuthModel authModel,
    required GameModel gameModel,
  }) : _serverService = serverService,
       _sidebarModel = sidebarModel,
       _authModel = authModel,
       _gameModel = gameModel {
    
    log.i(_logTag, '创建新的SideController实例 [${identityHashCode(this)}]');
    
    // 初始化状态
    _activePage = _sidebarModel.activeItemId;
    _isExpanded = _sidebarModel.expanded;
    _sidebarWidth = _sidebarModel.expandedWidth;
  }
  
  /// 设置当前激活页面
  void setActivePage(String page, BuildContext? context) {
    if (_activePage != page) {
      log.i(_logTag, '切换页面: 从 $_activePage 切换到 $page');
      
      // 立即更新UI状态
      _activePage = page;
      
      // 更新SidebarModel中的活动菜单项
      _sidebarModel.setActiveItem(page);
      
      // 立即通知UI更新
      notifyListeners();
      
      // 请求页面数据
      requestPageData(page, context);
    }
  }
  
  /// 请求页面数据 - 根据点击的菜单项ID请求对应页面的数据
  void requestPageData(String pageId, BuildContext? context) {
    log.i(_logTag, '请求页面数据: $pageId');
    
    if (!_serverService.isConnected) {
      log.w(_logTag, 'WebSocket未连接，无法请求数据');
      if (context != null) {
        MessageComponent.showIconToast(
          context: context,
          message: '服务器未连接，无法加载数据',
          type: MessageType.warning,
        );
      }
      return;
    }
    
    // 获取当前用户和游戏信息
    final username = _authModel.username;
    final gameName = _gameModel.currentGame;
    final cardKey = _gameModel.cardKey;
    
    // 更新时间戳
    final now = DateTime.now().toIso8601String();
    
    // 创建通用请求模板
    final Map<String, dynamic> baseRequest = {
      'content': {
        'username': username,
        'gameName': gameName,
        'cardKey': cardKey,
        'updatedAt': now,
      }
    };
    
    // 根据页面ID创建对应请求
    String action;
    switch (pageId) {
      case 'home':
        action = 'home_read';
        break;
      case 'function':
        action = 'function_read';
        break;
      case 'pid':
        action = 'pid_read';
        break;
      case 'fov':
        action = 'fov_read';
        break;
      case 'aim':
        action = 'aim_read';
        break;
      case 'fire':
        action = 'fire_read';
        break;
      case 'data_collection':
        action = 'data_collection_read';
        break;
      default:
        log.w(_logTag, '未知页面ID: $pageId，无法发送配置请求');
        return;
    }
    
    // 创建完整请求
    final request = {
      'action': action,
      ...baseRequest
    };
    
    // 发送请求
    _sendWebSocketRequest(request);
    
    log.i(_logTag, '已请求页面数据: $action', {
      'username': username,
      'gameName': gameName,
      'pageId': pageId
    });
    
    // 显示加载提示
    if (context != null) {
      MessageComponent.showIconToast(
        context: context,
        message: '正在加载${_getPageName(pageId)}数据...',
        type: MessageType.info,
        duration: const Duration(seconds: 1),
      );
    }
  }
  
  /// 获取页面名称
  String _getPageName(String pageId) {
    switch (pageId) {
      case 'home': return '首页';
      case 'function': return '功能设置';
      case 'pid': return 'PID设置';
      case 'fov': return '视野设置';
      case 'aim': return '瞄准设置';
      case 'fire': return '射击设置';
      case 'data_collection': return '数据收集';
      default: return '页面';
    }
  }
  
  /// 发送WebSocket请求
  void _sendWebSocketRequest(Map<String, dynamic> request) {
    // 检查控制器是否已被销毁
    if (_isDisposed) {
      log.w(_logTag, '控制器已销毁，忽略WebSocket请求');
      return;
    }
    
    if (_serverService.isConnected) {
      try {
        // 转换为JSON字符串
        String jsonMessage = jsonEncode(request);
        
        // 发送消息
        _serverService.sendMessage(jsonMessage);
        
        log.i(_logTag, '已发送WebSocket请求: ${request['action']}');
      } catch (e) {
        log.e(_logTag, '发送WebSocket请求失败', e.toString());
      }
    } else {
      log.w(_logTag, 'WebSocket未连接，无法发送请求');
    }
  }
  
  /// 发送心跳请求
  void _sendHeartbeatRequest() {
    if (!_serverService.isConnected) {
      log.w(_logTag, 'WebSocket未连接，无法发送心跳请求');
      return;
    }
    
    // 获取当前用户和游戏信息
    final username = _authModel.username;
    final gameName = _gameModel.currentGame;
    final cardKey = _gameModel.cardKey;
    
    // 更新时间戳
    final now = DateTime.now().toIso8601String();
    
    // 创建心跳请求
    final heartbeatRequest = {
      'action': 'heartbeat',
      'content': {
        'username': username,
        'gameName': gameName,
        'cardKey': cardKey,
        'updatedAt': now,
        'clientStatus': 'active',
      }
    };
    
    // 发送心跳请求
    _sendWebSocketRequest(heartbeatRequest);
    
    log.i(_logTag, '已发送心跳请求');
  }
  
  /// 切换侧边栏展开状态
  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    
    // 更新SidebarModel中的展开状态
    _sidebarModel.setExpandedState(_isExpanded);
    
    notifyListeners();
  }
  
  /// 检查页面是否为活动页面
  bool isPageActive(String page) {
    return _activePage == page;
  }
  
  /// 刷新数据，发送所有页面的请求
  void refreshData(BuildContext? context) {
    log.i(_logTag, '刷新所有页面数据');
    
    if (!_serverService.isConnected) {
      log.w(_logTag, 'WebSocket未连接，无法刷新数据');
      if (context != null) {
        MessageComponent.showIconToast(
          context: context,
          message: '服务器未连接，无法刷新数据',
          type: MessageType.warning,
        );
        return;
      }
    }
    
    // 显示刷新提示
    if (context != null) {
      MessageComponent.showIconToast(
        context: context,
        message: '正在刷新所有页面数据...',
        type: MessageType.info,
        duration: const Duration(seconds: 2),
      );
    }
    
    // 基础信息
    final username = _authModel.username;
    final gameName = _gameModel.currentGame;
    final cardKey = _gameModel.cardKey;
    final now = DateTime.now().toIso8601String();
    
    // 1. 首先发送心跳请求
    _sendHeartbeatRequest();
    
    // 2. 尝试发送刷新所有页面的请求
    final refreshAllRequest = {
      'action': 'refresh_all_pages',
      'content': {
        'username': username,
        'gameName': gameName,
        'cardKey': cardKey,
        'updatedAt': now,
      }
    };
    
    // 发送统一刷新请求
    _sendWebSocketRequest(refreshAllRequest);
    
    // 3. 为所有页面单独发送请求作为备份机制
    for (String pageId in _allPageIds) {
      // 使用Future.delayed为每个请求添加小延迟，避免请求过于集中
      Future.delayed(Duration(milliseconds: 100 * _allPageIds.indexOf(pageId)), () {
        requestPageData(pageId, null); // 不为每个页面单独显示提示
      });
    }
    
    // 通知监听者数据已刷新
    notifyListeners();
  }
  
  @override
  void dispose() {
    _isDisposed = true; // 设置销毁标记
    
    log.i(_logTag, '释放SideController资源 [${identityHashCode(this)}]');
    super.dispose();
  }
} 