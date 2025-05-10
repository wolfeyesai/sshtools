// ignore_for_file: unused_import, avoid_print, duplicate_ignore, unnecessary_nullable_for_final_variable_declarations, unused_local_variable

import 'package:flutter/material.dart';
import 'dart:convert'; // 用于JSON编码
import 'dart:async'; // 添加dart:async引用
import '../component/dropdown_component.dart';
import '../utils/logger.dart'; // 导入日志工具
import '../services/server_service.dart'; // 导入服务器服务
import '../models/auth_model.dart'; // 导入认证模型
import '../models/game_model.dart'; // 导入游戏模型
import '../models/ui_config_model.dart'; // 导入UI配置模型
import '../models/game_icon_paths.dart'; // 导入游戏图标路径
import '../models/login_model.dart'; // 导入登录模型
import 'side_controller.dart'; // 导入侧边栏控制器
import 'package:provider/provider.dart'; // 导入Provider

/// 头部控制器 - 负责处理头部页面的业务逻辑
class HeaderController extends ChangeNotifier {
  /// 当前选中的游戏标签
  late GameLabelItem _selectedGame;
  
  /// 获取当前选中的游戏标签
  GameLabelItem get selectedGame => _selectedGame;
  
  /// 服务器服务
  final ServerService _serverService;
  
  /// 认证模型
  final AuthModel _authModel;
  
  /// 游戏模型
  final GameModel _gameModel;
  
  /// 登录模型
  final LoginModel _loginModel;
  
  /// 日志工具
  final log = Logger();
  
  /// 日志标签
  final String _logTag = 'HeaderController';
  
  /// 当前正在进行的刷新任务，用于在必要时取消
  SideController? _currentRefreshController;
  
  /// 用于取消延迟任务的计时器
  Timer? _disposeTimer;
  
  /// 构造函数
  HeaderController({
    required ServerService serverService,
    required AuthModel authModel,
    required GameModel gameModel,
    required LoginModel loginModel,
  }) : _serverService = serverService,
       _authModel = authModel,
       _gameModel = gameModel,
       _loginModel = loginModel {
    // 初始化选中的游戏标签
    _initFromGameModel();
  }
  
  /// 从游戏模型初始化数据
  void _initFromGameModel() {
    // 从游戏模型获取当前游戏
    final currentGameName = _gameModel.currentGame;
    
    // 获取所有游戏标签
    final allGames = getAllGameLabels();
    
    // 尝试匹配游戏名称
    bool foundMatch = false;
    for (final game in allGames) {
      if (game.id.toLowerCase() == currentGameName.toLowerCase() || 
          game.label.toLowerCase() == currentGameName.toLowerCase()) {
        _selectedGame = game;
        foundMatch = true;
        log.i(_logTag, '从游戏模型匹配到游戏', {
          'id': game.id, 
          'label': game.label
        });
        break;
      }
    }
    
    // 如果没有找到匹配的游戏，使用默认游戏
    if (!foundMatch) {
      _selectedGame = getDefaultGameLabel();
      log.i(_logTag, '未找到匹配游戏，使用默认游戏', {
        'id': _selectedGame.id, 
        'label': _selectedGame.label
      });
      
      // 更新游戏模型
      _gameModel.updateCurrentGame(_selectedGame.id);
    }
  }
  
  /// 处理游戏选择
  void handleGameSelected(String? gameId) {
    if (gameId != null && gameId != _selectedGame.id) {
      // 更新选中的游戏
      final allGames = getAllGameLabels();
      final newSelectedGame = allGames.firstWhere(
        (game) => game.id == gameId,
        orElse: () => _selectedGame,
      );
      
      _selectedGame = newSelectedGame;
      
      // 获取当前登录的用户名
      final String username = _authModel.username;
      
      // 更新游戏模型
      _gameModel.updateCurrentGame(_selectedGame.id);
      
      // 发送WebSocket消息通知后端
      _notifyServerGameChanged();
      
      // 通知监听器
      notifyListeners();
      
      log.i(_logTag, '游戏已选中并更新到游戏模型', {
        'gameId': _selectedGame.id,
        'username': username
      });
      
      // 刷新所有功能模块数据
      _refreshGameModules();
      
      // 刷新侧边栏数据
      _refreshSidebar();
    }
  }
  
  /// 刷新所有游戏相关的功能模块数据
  void _refreshGameModules() {
    try {
      log.i(_logTag, '开始刷新游戏相关功能模块数据');
      
      // 发送FOV数据刷新请求
      final fovRequest = {
        'action': 'fov_read',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      // 发送PID数据刷新请求
      final pidRequest = {
        'action': 'pid_read',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      // 发送瞄准数据刷新请求
      final aimRequest = {
        'action': 'aim_read',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      // 发送开火数据刷新请求
      final fireRequest = {
        'action': 'fire_read',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      // 发送数据采集刷新请求
      final dataCollectionRequest = {
        'action': 'data_collection_read',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'cardKey': _gameModel.cardKey,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      // 发送所有请求
      if (_serverService.isConnected) {
        // 按顺序发送，避免服务器负载过大
        _serverService.sendMessage(jsonEncode(fovRequest));
        log.i(_logTag, '已发送FOV数据刷新请求');
        
        Future.delayed(const Duration(milliseconds: 50), () {
          _serverService.sendMessage(jsonEncode(pidRequest));
          log.i(_logTag, '已发送PID数据刷新请求');
        });
        
        Future.delayed(const Duration(milliseconds: 100), () {
          _serverService.sendMessage(jsonEncode(aimRequest));
          log.i(_logTag, '已发送瞄准数据刷新请求');
        });
        
        Future.delayed(const Duration(milliseconds: 150), () {
          _serverService.sendMessage(jsonEncode(fireRequest));
          log.i(_logTag, '已发送开火数据刷新请求');
        });
        
        Future.delayed(const Duration(milliseconds: 200), () {
          _serverService.sendMessage(jsonEncode(dataCollectionRequest));
          log.i(_logTag, '已发送数据采集刷新请求');
        });
      } else {
        log.w(_logTag, 'WebSocket未连接，无法发送功能模块刷新请求');
      }
    } catch (e) {
      log.e(_logTag, '刷新游戏功能模块数据失败', e.toString());
    }
  }
  
  /// 刷新侧边栏数据
  void _refreshSidebar() {
    // 立即取消之前可能正在进行的任务
    _cancelCurrentRefreshTask();
    
    // 使用延迟执行，确保UI已更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _disposeTimer?.cancel();
        _disposeTimer = null;
        
        // 获取当前用户和游戏信息
        final username = _authModel.username;
        final gameName = _gameModel.currentGame;
        
        // 创建刷新请求
        final refreshRequest = {
          'action': 'sidebar_refresh',
          'content': {
            'username': username,
            'gameName': gameName,
            'updatedAt': DateTime.now().toIso8601String(),
          }
        };
        
        // 通过WebSocket发送请求
        if (_serverService.isConnected) {
          final jsonData = jsonEncode(refreshRequest);
          _serverService.sendMessage(jsonData);
          
          log.i(_logTag, '已发送侧边栏刷新请求', {
            'gameName': gameName, 
            'username': username
          });
        } else {
          log.w(_logTag, 'WebSocket未连接，无法发送侧边栏刷新请求');
        }
      } catch (e) {
        log.e(_logTag, '刷新侧边栏数据失败', e.toString());
      }
    });
  }
  
  /// 取消当前正在进行的刷新任务
  void _cancelCurrentRefreshTask() {
    _disposeTimer?.cancel();
    _disposeTimer = null;
    
    if (_currentRefreshController != null) {
      log.i(_logTag, '清理临时SideController');
      _currentRefreshController!.dispose();
      _currentRefreshController = null;
    }
  }
  
  @override
  void dispose() {
    // 取消所有正在进行的任务
    _cancelCurrentRefreshTask();
    log.i(_logTag, 'HeaderController资源已释放');
    super.dispose();
  }
  
  /// 通知服务器游戏选择已更改
  void _notifyServerGameChanged() {
    if (!_serverService.isConnected) {
      log.w(_logTag, '无法发送游戏更改消息，服务器未连接');
      return;
    }
    
    try {
      // 构建请求数据
      Map<String, dynamic> requestData = {
        'action': 'home_modify',
        'content': {
          'username': _authModel.username,
          'gameName': _gameModel.currentGame,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
      
      // 转换为JSON字符串
      String jsonMessage = jsonEncode(requestData);
      
      // 发送WebSocket消息
      _serverService.sendMessage(jsonMessage);
      
      log.i(_logTag, '已发送游戏更改消息', {
        'gameName': _gameModel.currentGame,
        'username': _authModel.username,
      });
    } catch (e) {
      log.e(_logTag, '发送游戏更改消息失败', e.toString());
    }
  }
  
  /// 处理退出登录
  void handleLogout(BuildContext context) {
    // 记录当前用户名，便于调试
    final String currentUsername = _authModel.username;
    final bool rememberPwd = _authModel.rememberPassword;
    log.i(_logTag, '用户退出登录前信息', {
      'username': currentUsername,
      'rememberPassword': rememberPwd
    });
    
    // 使用已注入的_authModel而不是通过Provider再次获取
    _authModel.logout();
    
    log.i(_logTag, '用户已退出登录，保留的用户名: ${_authModel.username}');
    
    // 导航到登录页面
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
  
  /// 处理刷新系统
  void handleRefreshSystem() {
    log.i(_logTag, '系统刷新开始');
    
    // 尝试连接或重新连接WebSocket
    _reconnectWebSocket();
    
    // 如果已连接，发送系统刷新请求
    if (_serverService.isConnected) {
      try {
        // 构建系统刷新请求
        Map<String, dynamic> refreshRequest = {
          'action': 'system_refresh',
          'content': {
            'username': _authModel.username,
            'gameName': _gameModel.currentGame,
            'refreshTime': DateTime.now().toIso8601String(),
          }
        };
        
        // 转换为JSON字符串
        String refreshJson = jsonEncode(refreshRequest);
        
        // 发送WebSocket消息
        _serverService.sendMessage(refreshJson);
        
        log.i(_logTag, '系统刷新请求已发送');
        
        // 同时发送状态栏查询请求，确保状态栏立即更新
        _serverService.sendMessage({
          'action': 'status_bar_query',
          'token': _serverService.token,
        });
        
        log.i(_logTag, '状态栏查询请求已发送');
        
        // 发送简化的心跳请求
        _serverService.sendMessage({
          'action': 'heartbeat',
          'content': {
            'clientStatus': 'active',
            'updatedAt': DateTime.now().toIso8601String(),
          }
        });
        log.i(_logTag, '心跳请求已发送');
        
        // 刷新所有功能模块数据
        _refreshGameModules();
      } catch (e) {
        log.e(_logTag, '发送系统刷新请求失败', e.toString());
      }
    } else {
      log.w(_logTag, '无法发送系统刷新请求，WebSocket未连接，正在尝试连接');
    }
    
    // 重新获取游戏标签
    _initFromGameModel();
    
    // 通知监听者
    notifyListeners();
  }
  
  /// 尝试连接或重新连接WebSocket
  void _reconnectWebSocket() {
    // 判断是否已连接
    if (_serverService.isConnected) {
      log.i(_logTag, 'WebSocket已连接，将重新连接');
      // 先断开连接
      _serverService.disconnect();
    }
    
    // 先尝试从ServerService获取连接信息
    String serverAddress = _serverService.serverAddress;
    String serverPort = _serverService.serverPort;
    String token = _serverService.token;
    
    // 如果ServerService中没有连接信息，则从LoginModel获取
    if (serverAddress.isEmpty || serverPort.isEmpty) {
      log.i(_logTag, 'ServerService中无连接信息，尝试从LoginModel获取');
      
      // 获取AuthModel中的登录信息（用户名和令牌）
      final String username = _authModel.username;
      token = _authModel.token;
      
      // 从LoginModel获取连接信息
      serverAddress = _loginModel.serverAddress;
      serverPort = _loginModel.serverPort;
      
      // 如果token为空，则尝试从LoginModel获取
      if (token.isEmpty) {
        token = _loginModel.token;
      }
      
      log.i(_logTag, '从LoginModel获取到连接信息', {
        'address': serverAddress,
        'port': serverPort,
        'hasToken': token.isNotEmpty,
      });
      
      // 注意：ServerService没有这些设置器，需要通过重新连接来更新连接信息
      // 只记录信息，连接时会使用这些值
      log.i(_logTag, '获取到连接信息，将在重连时使用', {
        'address': serverAddress,
        'port': serverPort,
        'hasToken': token.isNotEmpty,
      });
    }
    
    // 如果有连接信息，则尝试连接
    if (serverAddress.isNotEmpty && serverPort.isNotEmpty) {
      log.i(_logTag, '尝试连接WebSocket服务器', {
        'address': serverAddress,
        'port': serverPort,
        'hasToken': token.isNotEmpty,
      });
      
      // 异步连接，避免阻塞UI
      Future.microtask(() async {
        try {
          final success = await _serverService.connect(
            serverAddress: serverAddress,
            serverPort: serverPort,
            token: token,
          );
          
          if (success) {
            log.i(_logTag, 'WebSocket连接成功');
            
            // 连接成功后，更新LoginModel中的连接信息（确保同步）
            _loginModel.updateServerAddress(serverAddress);
            _loginModel.updateServerPort(serverPort);
            if (token.isNotEmpty) {
              _loginModel.updateToken(token);
            }
            
            // 立即发送状态栏查询请求
            _serverService.sendMessage({
              'action': 'status_bar_query',
              'token': token,
            });
            
            // 发送简化的心跳请求
            _serverService.sendMessage({
              'action': 'heartbeat',
              'content': {
                'clientStatus': 'active',
                'updatedAt': DateTime.now().toIso8601String(),
              }
            });
            log.i(_logTag, '心跳请求已发送');
            
            // 通知监听者
            notifyListeners();
          } else {
            log.e(_logTag, 'WebSocket连接失败');
          }
        } catch (e) {
          log.e(_logTag, 'WebSocket连接异常', e.toString());
        }
      });
    } else {
      log.w(_logTag, '无法连接WebSocket，缺少连接信息', {
        'address': serverAddress,
        'port': serverPort,
        'hasToken': token.isNotEmpty,
      });
    }
  }
  
  /// 从路径中提取游戏ID和显示名称
  (String id, String displayName) extractInfoFromPath(String path) {
    // 路径示例: assets/GameImgIco/apex.png
    final filename = path.split('/').last;
    final id = filename.split('.').first;
    // 直接使用文件名作为显示名称
    return (id, id);
  }
  
  /// 获取全部游戏标签项列表
  List<GameLabelItem> getAllGameLabels() {
    // 手动列出所有的图标路径
    final List<String> iconPaths = [
      GameIconPaths.apex,
      GameIconPaths.cf,
      GameIconPaths.cfhd,
      GameIconPaths.csgo2,
      GameIconPaths.defaultIcon,
      GameIconPaths.pubg,
      GameIconPaths.sjz,
      GameIconPaths.ssjj2,
      GameIconPaths.wwqy,
    ];
    
    // 将图标路径转换为GameLabelItem对象
    return iconPaths.map((iconPath) {
      final (id, displayName) = extractInfoFromPath(iconPath);
      // 对于defaultIcon特殊处理
      final String finalId = (iconPath == GameIconPaths.defaultIcon) ? 'default' : id;
      
      return GameLabelItem(
        id: finalId,
        label: displayName,
        iconPath: iconPath,
      );
    }).toList();
  }
  
  /// 将GameLabelItem转换为IconDropdownItem
  List<IconDropdownItem> convertToIconDropdownItems(List<GameLabelItem> games) {
    return games.map((game) => IconDropdownItem(
      value: game.id,
      text: game.label,
      image: Image.asset(
        game.iconPath,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      ),
    )).toList();
  }
}

/// 游戏标签项
class GameLabelItem {
  /// 游戏ID
  final String id;
  /// 显示名称
  final String label;
  /// 图标路径
  final String iconPath;

  /// 构造函数
  GameLabelItem({
    required this.id,
    required this.label,
    required this.iconPath,
  });
}

/// 获取默认游戏标签
GameLabelItem getDefaultGameLabel() {
  // 默认使用csgo2
  const String defaultGameName = 'csgo2';
  
  // 获取对应图标路径
  String iconPath = GameIconPaths.csgo2;
  
  return GameLabelItem(
    id: defaultGameName,
    label: defaultGameName,
    iconPath: iconPath,
  );
} 