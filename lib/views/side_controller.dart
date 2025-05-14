import 'package:flutter/material.dart';

/// 侧边栏控制器
/// 管理侧边栏的状态和业务逻辑
class SideController extends ChangeNotifier {
  // 当前选中的页面ID
  String _activePageId = 'home';
  
  // 是否展开侧边栏
  bool _isExpanded = true;
  
  /// 获取当前活动的页面ID
  String get activePageId => _activePageId;
  
  /// 获取侧边栏是否展开
  bool get isExpanded => _isExpanded;
  
  /// 设置活动页面ID
  void setActivePage(String pageId) {
    if (_activePageId != pageId) {
      _activePageId = pageId;
      notifyListeners();
    }
  }
  
  /// 切换侧边栏展开状态
  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }
  
  /// 展开侧边栏
  void expand() {
    if (!_isExpanded) {
      _isExpanded = true;
      notifyListeners();
    }
  }
  
  /// 收起侧边栏
  void collapse() {
    if (_isExpanded) {
      _isExpanded = false;
      notifyListeners();
    }
  }
  
  /// 根据路由名称设置活动页面ID
  void setActivePageByRoute(String route) {
    String pageId;
    
    switch (route) {
      case '/':
        pageId = 'home';
        break;
      case '/get_data':
        pageId = 'get_data';
        break;
      case '/modify_date':
        pageId = 'modify_date';
        break;
      case '/modify_home':
        pageId = 'modify_home';
        break;
      case '/modify_login':
        pageId = 'modify_login';
        break;
      case '/modify_register':
        pageId = 'modify_register';
        break;
      case '/modify_function':
        pageId = 'modify_function';
        break;
      case '/modify_pid':
        pageId = 'modify_pid';
        break;
      case '/modify_aim':
        pageId = 'modify_aim';
        break;
      case '/modify_fire':
        pageId = 'modify_fire';
        break;
      case '/modify_fov':
        pageId = 'modify_fov';
        break;
      case '/aim':
        pageId = 'aim';
        break;
      case '/data':
        pageId = 'data';
        break;
      case '/fov':
        pageId = 'fov';
        break;
      case '/function':
        pageId = 'function';
        break;
      case '/header':
        pageId = 'header';
        break;
      case '/pid':
        pageId = 'pid';
        break;
      case '/button_test':
        pageId = 'button';
        break;
      case '/message_test':
        pageId = 'message';
        break;
      case '/card_select_test':
        pageId = 'card_select';
        break;
      default:
        pageId = 'home';
    }
    
    setActivePage(pageId);
  }

  // 根据路由获取页面ID
  String getPageIdFromRoute(String route) {
    String pageId = 'home'; // 默认页面ID
    
    switch (route) {
      case '/':
        pageId = 'home';
        break;
      case '/data':
        pageId = 'modify_date';
        break;
      case '/side':
        pageId = 'side';
        break;
      case '/login':
        pageId = 'login';
        break;
      case '/register':
        pageId = 'register';
        break;
      case '/button_test':
        pageId = 'button_test';
        break;
      case '/message_test':
        pageId = 'message';
        break;
      case '/card_select_test':
        pageId = 'card_select';
        break;
      case '/log':
        pageId = 'log';
        break;
      default:
        pageId = 'home';
    }
    
    return pageId;
  }
}
