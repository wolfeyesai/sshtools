// ignore_for_file: library_private_types_in_public_api, unused_import, unreachable_switch_default, use_super_parameters

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// 资源状态项模型
class ResourceStatusItem {
  /// 服务ID
  final String id;
  
  /// 服务名称
  final String name;
  
  /// 服务状态
  final ResourceStatus status;
  
  /// 状态描述
  final String description;
  
  /// 服务图标
  final IconData? icon;

  /// 构造函数
  ResourceStatusItem({
    required this.id,
    required this.name,
    required this.status,
    this.description = '',
    this.icon,
  });
}

/// 资源状态枚举
enum ResourceStatus {
  /// 正常
  normal,
  
  /// 警告
  warning,
  
  /// 错误
  error,
  
  /// 关闭
  offline,
  
  /// 加载中
  loading,
}

/// 资源标签组件
class ResourceLabelComponent extends StatefulWidget {
  /// 标签文本
  final String label;
  
  /// 标签图标
  final IconData? icon;
  
  /// 是否显示状态指示点
  final bool showStatusIndicator;
  
  /// 当前总体状态
  final ResourceStatus overallStatus;
  
  /// 资源状态项列表
  final List<ResourceStatusItem> statusItems;
  
  /// 点击标签回调
  final Function()? onTap;
  
  /// 自定义弹出内容构建器
  final Widget Function(BuildContext, List<ResourceStatusItem>)? popupBuilder;
  
  /// 弹出位置
  final PopupPosition popupPosition;
  
  /// 标签背景颜色
  final Color? backgroundColor;
  
  /// 标签文本颜色
  final Color? textColor;
  
  /// 标签圆角
  final double borderRadius;
  
  /// 标签内边距
  final EdgeInsetsGeometry padding;

  /// 构造函数
  const ResourceLabelComponent({
    Key? key,
    required this.label,
    this.icon,
    this.showStatusIndicator = true,
    this.overallStatus = ResourceStatus.normal,
    this.statusItems = const [],
    this.onTap,
    this.popupBuilder,
    this.popupPosition = PopupPosition.bottom,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  }) : super(key: key);

  @override
  _ResourceLabelComponentState createState() => _ResourceLabelComponentState();
}

/// 资源标签组件状态
class _ResourceLabelComponentState extends State<ResourceLabelComponent> {
  /// 获取状态对应的颜色
  Color getStatusColor(ResourceStatus status) {
    switch (status) {
      case ResourceStatus.normal:
        return Colors.green;
      case ResourceStatus.warning:
        return Colors.orange;
      case ResourceStatus.error:
        return Colors.red;
      case ResourceStatus.offline:
        return Colors.grey;
      case ResourceStatus.loading:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 此处为组件UI构建，具体实现将由使用者定制
    return Container();
  }
}

/// 弹出位置枚举
enum PopupPosition {
  /// 顶部
  top,
  
  /// 底部
  bottom,
  
  /// 左侧
  left,
  
  /// 右侧
  right,
}

/// 资源状态弹出面板
class ResourceStatusPopup extends StatelessWidget {
  /// 状态项列表
  final List<ResourceStatusItem> statusItems;
  
  /// 标题
  final String? title;
  
  /// 自定义项构建器
  final Widget Function(BuildContext, ResourceStatusItem)? itemBuilder;
  
  /// 面板宽度
  final double? width;
  
  /// 面板高度
  final double? height;
  
  /// 面板背景色
  final Color? backgroundColor;
  
  /// 面板圆角
  final double borderRadius;
  
  /// 构造函数
  const ResourceStatusPopup({
    Key? key,
    required this.statusItems,
    this.title,
    this.itemBuilder,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 此处为弹出面板UI构建，具体实现将由使用者定制
    return Container();
  }
}

/// 资源标签组显示模式
enum ResourceLabelDisplayMode {
  /// 行显示
  row,
  
  /// 网格显示
  grid,
  
  /// 堆叠显示
  stack,
}

/// 资源标签组
class ResourceLabelGroup extends StatelessWidget {
  /// 标签项列表
  final List<ResourceLabelComponent> labels;
  
  /// 显示模式
  final ResourceLabelDisplayMode displayMode;
  
  /// 间距
  final double spacing;
  
  /// 行间距（网格模式）
  final double runSpacing;
  
  /// 网格列数（网格模式）
  final int gridColumns;
  
  /// 构造函数
  const ResourceLabelGroup({
    Key? key,
    required this.labels,
    this.displayMode = ResourceLabelDisplayMode.row,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.gridColumns = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 此处为标签组UI构建，具体实现将由使用者定制
    return Container();
  }
}

// -----------------------------------------------------------------------------
// 使用示例
// -----------------------------------------------------------------------------
/*
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:your_app/component/resource_label_component.dart';

class ResourceServiceDemo extends StatefulWidget {
  const ResourceServiceDemo({Key? key}) : super(key: key);

  @override
  _ResourceServiceDemoState createState() => _ResourceServiceDemoState();
}

class _ResourceServiceDemoState extends State<ResourceServiceDemo> {
  // 1. 创建资源状态项列表
  final List<ResourceStatusItem> _networkServices = [
    ResourceStatusItem(
      id: 'server1',
      name: 'Web服务器',
      status: ResourceStatus.normal,
      description: '服务器运行正常，负载 24%',
      icon: Icons.web,
    ),
    ResourceStatusItem(
      id: 'server2',
      name: '数据库服务器',
      status: ResourceStatus.warning,
      description: '数据库连接池接近上限，负载 78%',
      icon: Icons.storage,
    ),
    ResourceStatusItem(
      id: 'server3',
      name: '缓存服务器',
      status: ResourceStatus.error,
      description: '缓存服务不可访问',
      icon: Icons.memory,
    ),
  ];

  final List<ResourceStatusItem> _localServices = [
    ResourceStatusItem(
      id: 'disk',
      name: '磁盘状态',
      status: ResourceStatus.normal,
      description: '剩余空间 120GB',
      icon: Icons.disc_full,
    ),
    ResourceStatusItem(
      id: 'memory',
      name: '内存使用',
      status: ResourceStatus.normal,
      description: '使用率 45%',
      icon: Icons.memory,
    ),
  ];

  // 2. 创建资源标签组件和处理点击事件的方法
  void _showNetworkServiceStatus(BuildContext context) {
    // 创建底部弹出面板
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GFCard(
          boxFit: BoxFit.cover,
          title: GFListTile(
            title: Text('网络服务状态'),
            icon: Icon(Icons.info_outline),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _networkServices.map((service) {
              return ListTile(
                leading: Icon(
                  service.icon ?? Icons.circle,
                  color: _getStatusColor(service.status),
                ),
                title: Text(service.name),
                subtitle: Text(service.description),
                trailing: GFBadge(
                  color: _getStatusColor(service.status),
                  shape: GFBadgeShape.pills,
                  child: Text(_getStatusText(service.status)),
                ),
              );
            }).toList(),
          ),
          buttonBar: GFButtonBar(
            children: <Widget>[
              GFButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                text: '关闭',
                type: GFButtonType.outline,
              ),
              GFButton(
                onPressed: () {
                  // 触发刷新状态的逻辑
                  _refreshNetworkServices();
                  Navigator.pop(context);
                },
                text: '刷新',
                color: GFColors.PRIMARY,
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 辅助方法：获取状态对应的颜色
  Color _getStatusColor(ResourceStatus status) {
    switch (status) {
      case ResourceStatus.normal:
        return GFColors.SUCCESS;
      case ResourceStatus.warning:
        return GFColors.WARNING;
      case ResourceStatus.error:
        return GFColors.DANGER;
      case ResourceStatus.offline:
        return GFColors.DARK;
      case ResourceStatus.loading:
        return GFColors.INFO;
      default:
        return GFColors.LIGHT;
    }
  }
  
  // 辅助方法：获取状态对应的文本
  String _getStatusText(ResourceStatus status) {
    switch (status) {
      case ResourceStatus.normal:
        return '正常';
      case ResourceStatus.warning:
        return '警告';
      case ResourceStatus.error:
        return '错误';
      case ResourceStatus.offline:
        return '离线';
      case ResourceStatus.loading:
        return '加载中';
      default:
        return '未知';
    }
  }
  
  // 3. 刷新服务状态的模拟方法
  void _refreshNetworkServices() {
    // 在实际应用中，这里可能会调用API或WebSocket来获取最新状态
    setState(() {
      // 模拟状态变化
      _networkServices[1].status = ResourceStatus.normal;
      _networkServices[2].status = ResourceStatus.warning;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 4. 使用ResourceLabelComponent和ResourceLabelGroup
    // 确定网络服务的整体状态
    ResourceStatus networkOverallStatus = ResourceStatus.normal;
    
    // 如果有任何一个服务处于错误状态，整体状态为错误
    if (_networkServices.any((service) => service.status == ResourceStatus.error)) {
      networkOverallStatus = ResourceStatus.error;
    } 
    // 否则，如果有任何一个服务处于警告状态，整体状态为警告
    else if (_networkServices.any((service) => service.status == ResourceStatus.warning)) {
      networkOverallStatus = ResourceStatus.warning;
    }
    
    // 创建网络服务标签
    final networkLabel = ResourceLabelComponent(
      label: '网络服务',
      icon: Icons.cloud,
      overallStatus: networkOverallStatus,
      statusItems: _networkServices,
      onTap: () => _showNetworkServiceStatus(context),
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      borderRadius: 20.0,
      showStatusIndicator: true,
    );
    
    // 创建本地服务标签
    final localLabel = ResourceLabelComponent(
      label: '本地服务',
      icon: Icons.computer,
      overallStatus: ResourceStatus.normal,
      statusItems: _localServices,
      onTap: () {
        // 这里可以实现类似的弹出面板逻辑
      },
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      borderRadius: 20.0,
      showStatusIndicator: true,
    );
    
    // 使用标签组组合多个标签
    return Scaffold(
      appBar: AppBar(
        title: Text('资源状态服务示例'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 使用ResourceLabelGroup显示资源标签
            ResourceLabelGroup(
              labels: [networkLabel, localLabel],
              displayMode: ResourceLabelDisplayMode.row,
              spacing: 16.0,
            ),
            
            SizedBox(height: 32),
            
            // 手动刷新按钮
            GFButton(
              onPressed: _refreshNetworkServices,
              text: '刷新服务状态',
              shape: GFButtonShape.pills,
              size: GFSize.LARGE,
              color: GFColors.PRIMARY,
              icon: Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. 自定义弹出内容构建器示例
Widget customPopupBuilder(BuildContext context, List<ResourceStatusItem> items) {
  return GFCard(
    boxFit: BoxFit.cover,
    title: GFListTile(
      title: Text('自定义状态面板'),
    ),
    content: Container(
      height: 200,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final item = items[index];
          return GFListTile(
            avatar: GFAvatar(
              backgroundColor: _getStatusColor(item.status),
              child: Icon(item.icon ?? Icons.info, color: Colors.white),
            ),
            title: Text(item.name),
            subTitle: Text(item.description),
          );
        },
      ),
    ),
  );
}
*/ 