// ignore_for_file: unnecessary_import, prefer_final_fields

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 侧边栏模型 - 管理侧边栏状态和菜单项
class SidebarModel extends ChangeNotifier {
  // 侧边栏状态
  bool _expanded = true;
  
  // 侧边栏尺寸
  double _expandedWidth = 160.0;
  double _collapsedWidth = 70.0;
  
  // 侧边栏颜色
  Color _backgroundColor = const Color.fromARGB(255, 247, 242, 242);
  Color _headerColor = Colors.blue.shade700;
  Color _activeColor = Colors.blue;
  Color _inactiveColor = const Color.fromARGB(255, 52, 100, 172);
  Color _hoverColor = const Color.fromARGB(255, 192, 187, 189);
  
  // 显示选项
  bool _showIcons = true;
  bool _showText = true;
  
  // 自动收起选项
  bool _autoCollapseEnabled = true;
  double _autoCollapseThreshold = 600.0;
  
  // 菜单项
  final List<SidebarMenuItem> _menuItems = [
    SidebarMenuItem(
      id: 'home',
      title: '首页配置',
      icon: Icons.home,
      route: '/home',
    ),
    SidebarMenuItem(
      id: 'function',
      title: '功能设置',
      icon: Icons.settings,
      route: '/function',
    ),
    SidebarMenuItem(
      id: 'pid',
      title: 'PID设置',
      icon: Icons.tune,
      route: '/pid',
    ),
    SidebarMenuItem(
      id: 'fov',
      title: '视野设置',
      icon: Icons.visibility,
      route: '/fov',
    ),
    SidebarMenuItem(
      id: 'aim',
      title: '瞄准设置',
      icon: Icons.adjust,
      route: '/aim',
    ),
    SidebarMenuItem(
      id: 'fire',
      title: '射击设置',
      icon: Icons.fireplace,
      route: '/fire',
    ),
    SidebarMenuItem(
      id: 'data_collection',
      title: '数据收集',
      icon: Icons.data_array,
      route: '/data_collection',
    ),
  ];
  
  // 当前选中菜单项ID
  String _activeItemId = 'home';
  
  // 侧边栏配置
  Map<String, dynamic> _sidebarConfig = {
    'colors': {
      'background': const Color.fromARGB(255, 247, 242, 242),
      'header': Colors.blue.shade700,
      'active': Colors.blue,
      'inactive': const Color.fromARGB(255, 52, 100, 172),
      'hover': const Color.fromARGB(255, 192, 187, 189),
    },
    'width': {
      'expanded': 200.0,
      'collapsed': 60.0,
    },
    'autoCollapse': {
      'enabled': true,
      'screenWidth': 600.0,
    },
  };
  
  // Getters
  bool get expanded => _expanded;
  double get expandedWidth => _expandedWidth;
  double get collapsedWidth => _collapsedWidth;
  Color get backgroundColor => _backgroundColor;
  Color get headerColor => _headerColor;
  Color get activeColor => _activeColor;
  Color get inactiveColor => _inactiveColor;
  Color get hoverColor => _hoverColor;
  bool get showIcons => _showIcons;
  bool get showText => _showText;
  bool get autoCollapseEnabled => _autoCollapseEnabled;
  double get autoCollapseThreshold => _autoCollapseThreshold;
  List<SidebarMenuItem> get menuItems => _menuItems;
  String get activeItemId => _activeItemId;
  Map<String, dynamic> get sidebarConfig => _sidebarConfig;
  
  // 当前侧边栏宽度
  double get currentWidth => _expanded ? _expandedWidth : _collapsedWidth;
  
  // 获取菜单项列表，转换为原来的格式以保持兼容性
  List<Map<String, dynamic>> get menuItemsAsMap {
    return _menuItems.map((item) => {
      'id': item.id,
      'title': item.title,
      'icon': item.icon,
      'route': item.route,
    }).toList();
  }
  
  // 初始化 - 从持久化存储加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _expanded = prefs.getBool('sidebar_expanded') ?? true;
    _expandedWidth = prefs.getDouble('sidebar_expandedWidth') ?? 160.0;
    _collapsedWidth = prefs.getDouble('sidebar_collapsedWidth') ?? 70.0;
    
    _showIcons = prefs.getBool('sidebar_showIcons') ?? true;
    _showText = prefs.getBool('sidebar_showText') ?? true;
    
    _autoCollapseEnabled = prefs.getBool('sidebar_autoCollapseEnabled') ?? true;
    _autoCollapseThreshold = prefs.getDouble('sidebar_autoCollapseThreshold') ?? 600.0;
    
    _activeItemId = prefs.getString('sidebar_activeItemId') ?? 'home';
    
    // 更新配置
    _sidebarConfig['width']['expanded'] = _expandedWidth;
    _sidebarConfig['width']['collapsed'] = _collapsedWidth;
    _sidebarConfig['autoCollapse']['enabled'] = _autoCollapseEnabled;
    _sidebarConfig['autoCollapse']['screenWidth'] = _autoCollapseThreshold;
    _sidebarConfig['colors']['background'] = _backgroundColor;
    _sidebarConfig['colors']['header'] = _headerColor;
    _sidebarConfig['colors']['active'] = _activeColor;
    _sidebarConfig['colors']['inactive'] = _inactiveColor;
    _sidebarConfig['colors']['hover'] = _hoverColor;
    
    notifyListeners();
  }
  
  /// 切换侧边栏展开状态
  void toggleExpanded() {
    setExpandedState(!_expanded);
  }
  
  /// 直接设置侧边栏展开状态
  void setExpandedState(bool expanded) {
    if (_expanded != expanded) {
      _expanded = expanded;
      _saveSettings();
      notifyListeners();
    }
  }
  
  // 设置活动菜单项
  void setActiveItem(String id) {
    if (_activeItemId != id) {
      // 先更新内存中的值
      _activeItemId = id;
      
      // 立即通知UI更新
      notifyListeners();
      
      // 异步保存设置，不阻塞UI
      Future.microtask(() async {
        await _saveSettings();
      });
    }
  }
  
  // 根据屏幕宽度自动调整侧边栏状态
  void adjustForScreenWidth(double screenWidth) {
    if (_autoCollapseEnabled && screenWidth < _autoCollapseThreshold) {
      setExpandedState(false);
    }
  }
  
  // 更新侧边栏配置
  void updateSidebarConfig({
    Color? backgroundColor,
    Color? headerColor,
    Color? activeColor,
    Color? inactiveColor,
    Color? hoverColor,
    double? expandedWidth,
    double? collapsedWidth,
    bool? autoCollapseEnabled,
    double? autoCollapseThreshold,
  }) {
    bool changed = false;
    
    if (backgroundColor != null && backgroundColor != _backgroundColor) {
      _backgroundColor = backgroundColor;
      _sidebarConfig['colors']['background'] = backgroundColor;
      changed = true;
    }
    
    if (headerColor != null && headerColor != _headerColor) {
      _headerColor = headerColor;
      _sidebarConfig['colors']['header'] = headerColor;
      changed = true;
    }
    
    if (activeColor != null && activeColor != _activeColor) {
      _activeColor = activeColor;
      _sidebarConfig['colors']['active'] = activeColor;
      changed = true;
    }
    
    if (inactiveColor != null && inactiveColor != _inactiveColor) {
      _inactiveColor = inactiveColor;
      _sidebarConfig['colors']['inactive'] = inactiveColor;
      changed = true;
    }
    
    if (hoverColor != null && hoverColor != _hoverColor) {
      _hoverColor = hoverColor;
      _sidebarConfig['colors']['hover'] = hoverColor;
      changed = true;
    }
    
    if (expandedWidth != null && expandedWidth != _expandedWidth) {
      _expandedWidth = expandedWidth;
      _sidebarConfig['width']['expanded'] = expandedWidth;
      changed = true;
    }
    
    if (collapsedWidth != null && collapsedWidth != _collapsedWidth) {
      _collapsedWidth = collapsedWidth;
      _sidebarConfig['width']['collapsed'] = collapsedWidth;
      changed = true;
    }
    
    if (autoCollapseEnabled != null && autoCollapseEnabled != _autoCollapseEnabled) {
      _autoCollapseEnabled = autoCollapseEnabled;
      _sidebarConfig['autoCollapse']['enabled'] = autoCollapseEnabled;
      changed = true;
    }
    
    if (autoCollapseThreshold != null && autoCollapseThreshold != _autoCollapseThreshold) {
      _autoCollapseThreshold = autoCollapseThreshold;
      _sidebarConfig['autoCollapse']['screenWidth'] = autoCollapseThreshold;
      changed = true;
    }
    
    if (changed) {
      _saveSettings();
      notifyListeners();
    }
  }
  
  // 保存设置到持久化存储
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('sidebar_expanded', _expanded);
    await prefs.setDouble('sidebar_expandedWidth', _expandedWidth);
    await prefs.setDouble('sidebar_collapsedWidth', _collapsedWidth);
    
    await prefs.setBool('sidebar_showIcons', _showIcons);
    await prefs.setBool('sidebar_showText', _showText);
    
    await prefs.setBool('sidebar_autoCollapseEnabled', _autoCollapseEnabled);
    await prefs.setDouble('sidebar_autoCollapseThreshold', _autoCollapseThreshold);
    
    await prefs.setString('sidebar_activeItemId', _activeItemId);
  }
  
  // 刷新数据
  void refreshData() {
    notifyListeners();
  }
}

/// 侧边栏菜单项
class SidebarMenuItem {
  final String id;
  final String title;
  final IconData icon;
  final String route;
  
  SidebarMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.route,
  });
} 