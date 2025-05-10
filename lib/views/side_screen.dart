// ignore_for_file: use_super_parameters, library_private_types_in_public_api, unnecessary_brace_in_string_interps, deprecated_member_use, unused_import, unused_local_variable

import 'package:flutter/material.dart';
import '../component/message_component.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../models/sidebar_model.dart'; // 导入侧边栏模型
import '../controllers/side_controller.dart'; // 添加控制器导入
import 'dart:math' as math;

/// 侧边栏组件
class SidebarScreen extends StatefulWidget {
  /// 选中的菜单ID
  final String selectedMenuId;
  
  /// 菜单选择回调
  final Function(String) onMenuSelected;
  
  /// 刷新回调
  final VoidCallback onRefresh;
  
  /// 版本信息
  final String version;
  
  /// 是否默认收起
  final bool initialCollapsed;
  
  /// 构造函数
  const SidebarScreen({
    Key? key,
    required this.selectedMenuId,
    required this.onMenuSelected,
    required this.onRefresh,
    required this.version,
    this.initialCollapsed = false,
  }) : super(key: key);
  
  @override
  _SidebarScreenState createState() => _SidebarScreenState();
}

/// 侧边栏状态
class _SidebarScreenState extends State<SidebarScreen> {
  // 是否展开侧边栏
  late bool _isExpanded;
  
  @override
  void initState() {
    super.initState();
    // 初始化侧边栏状态
    _isExpanded = !widget.initialCollapsed;
    
    // 同步状态到SidebarModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sidebarModel = Provider.of<SidebarModel>(context, listen: false);
      if (sidebarModel.expanded != _isExpanded) {
        sidebarModel.setExpandedState(_isExpanded);
      }
    });
  }
  
  // 切换侧边栏展开状态
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    // 更新SidebarModel中的展开状态
    Provider.of<SidebarModel>(context, listen: false).setExpandedState(_isExpanded);
  }
  
  // 处理菜单项点击
  void _handleMenuItemClick(Map<String, dynamic> item) {
    // 获取菜单ID
    final String menuId = item['id'] as String;
    
    // 更新侧边栏模型中的活动项
    Provider.of<SidebarModel>(context, listen: false).setActiveItem(menuId);
    
    // 调用外部回调
    widget.onMenuSelected(menuId);
    
    // 通知侧边栏控制器切换页面并加载数据
    final sideController = Provider.of<SideController>(context, listen: false);
    sideController.setActivePage(menuId, context);
    
    // 导航到对应路由
    final String route = item['route'] as String;
    
    // 使用microtask确保在当前事件循环完成后再导航
    Future.microtask(() {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // 使用Consumer获取SidebarModel，避免整个Widget重建
    return Consumer<SidebarModel>(
      builder: (context, sidebarModel, _) {
        // 获取屏幕宽度
        final screenWidth = MediaQuery.of(context).size.width;
        
        // 检查是否需要自动折叠侧边栏
        if (sidebarModel.sidebarConfig['autoCollapse']['enabled'] &&
            screenWidth < sidebarModel.sidebarConfig['autoCollapse']['screenWidth'] &&
            _isExpanded) {
          // 使用addPostFrameCallback避免在build过程中setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isExpanded = false;
              });
              sidebarModel.setExpandedState(false);
            }
          });
        }
        
        // 从配置获取侧边栏参数
        final bgColor = sidebarModel.sidebarConfig['colors']['background'];
        final activeColor = sidebarModel.sidebarConfig['colors']['active'];
        final inactiveColor = sidebarModel.sidebarConfig['colors']['inactive'];
        final hoverColor = sidebarModel.sidebarConfig['colors']['hover'];
        
        // 设置当前宽度
        final double expandedWidth = sidebarModel.sidebarConfig['width']['expanded'];
        final double collapsedWidth = sidebarModel.sidebarConfig['width']['collapsed'];
        final double currentWidth = _isExpanded ? 
            math.max(expandedWidth, 48.0) : math.max(collapsedWidth, 48.0);
        
        // 获取菜单项列表
        final menuItems = sidebarModel.menuItemsAsMap;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: currentWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 侧边栏菜单内容
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final isSelected = item['id'] == widget.selectedMenuId;
                    
                    return _buildMenuItem(item, isSelected, activeColor, inactiveColor, hoverColor);
                  },
                ),
              ),
              
              // 刷新按钮
              _buildRefreshButton(activeColor, inactiveColor),
              
              // 版本信息
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'v${widget.version}',
                    style: TextStyle(fontSize: 12, color: inactiveColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // 底部 - 折叠按钮
              const Divider(height: 1),
              Center(
                child: IconButton(
                  onPressed: _toggleExpanded,
                  icon: Icon(
                    _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: inactiveColor,
                  ),
                  tooltip: _isExpanded ? '收起菜单' : '展开菜单',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 构建刷新按钮
  Widget _buildRefreshButton(Color activeColor, Color inactiveColor) {
    if (_isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GFButton(
          onPressed: () {
            // 获取侧边栏控制器并刷新所有页面数据
            final sideController = Provider.of<SideController>(context, listen: false);
            sideController.refreshData(context);
            
            // 调用外部刷新回调
            widget.onRefresh();
          },
          text: '刷新数据',
          icon: const Icon(Icons.refresh, color: Colors.white),
          fullWidthButton: true,
          color: activeColor,
          size: GFSize.SMALL,
          borderShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Center(
          child: IconButton(
            onPressed: () {
              // 获取侧边栏控制器并刷新所有页面数据
              final sideController = Provider.of<SideController>(context, listen: false);
              sideController.refreshData(context);
              
              // 调用外部刷新回调
              widget.onRefresh();
            },
            icon: Icon(
              Icons.refresh,
              color: inactiveColor,
              size: 22,
            ),
            tooltip: '刷新数据',
            padding: EdgeInsets.zero,
          ),
        ),
      );
    }
  }
  
  // 创建菜单项
  Widget _buildMenuItem(Map<String, dynamic> item, bool isSelected, Color activeColor, Color inactiveColor, Color hoverColor) {
    // 在收起状态下，只显示图标
    if (!_isExpanded) {
      return InkWell(
        onTap: () => _handleMenuItemClick(item),
        child: Container(
          decoration: isSelected ? BoxDecoration(
            border: Border(
              left: BorderSide(
                color: activeColor,
                width: 4.0,
              ),
            ),
            color: hoverColor,
          ) : null,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Icon(
              item['icon'],
              color: isSelected ? activeColor : inactiveColor,
              size: isSelected ? 26 : 22,
            ),
          ),
        ),
      );
    }
    
    // 展开状态，显示完整菜单项
    return InkWell(
      onTap: () => _handleMenuItemClick(item),
      child: Container(
        decoration: isSelected ? BoxDecoration(
          border: Border(
            left: BorderSide(
              color: activeColor,
              width: 4.0,
            ),
          ),
          color: hoverColor,
        ) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              item['icon'],
              color: isSelected ? activeColor : inactiveColor,
              size: isSelected ? 24 : 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['title'],
                style: TextStyle(
                  fontSize: isSelected ? 16 : 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
