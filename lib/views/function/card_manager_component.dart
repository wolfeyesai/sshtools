// ignore_for_file: library_private_types_in_public_api, use_super_parameters, deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../../models/function_model.dart'; // 导入FunctionModel
import '../../component/dropdown_component.dart'; // 导入下拉组件

/// 卡片数据模型
class CardData {
  String presetName;  // 配置名称作为唯一标识
  String hotkey;      // 触发热键
  String aiMode;      // AI模式
  String lockPosition; // 锁定位置
  bool isSelected;
  bool triggerSwitch;  // 自动扳机
  bool enabled;        // 启用状态

  CardData({
    required this.presetName,
    required this.hotkey,
    required this.aiMode,
    required this.lockPosition,
    this.isSelected = false,
    this.triggerSwitch = false,
    this.enabled = true,
  });
  
  /// 将卡片数据转换为Map
  Map<String, dynamic> toJson() {
    return {
      'presetName': presetName,
      'hotkey': hotkey,
      'aiMode': aiMode,
      'lockPosition': lockPosition,
      'isSelected': isSelected,
      'triggerSwitch': triggerSwitch,
      'enabled': enabled,
    };
  }
  
  /// 从配置项创建卡片数据
  factory CardData.fromConfig(Map<String, dynamic> config, FunctionModel functionModel) {
    return CardData(
      presetName: config['presetName'] ?? '新配置',
      hotkey: config['hotkey'] ?? functionModel.hotkeys[0],
      aiMode: config['aiMode'] ?? functionModel.aiModes[0],
      lockPosition: config['lockPosition'] ?? functionModel.lockPositions[0],
      triggerSwitch: config['triggerSwitch'] ?? false,
      enabled: config['enabled'] ?? true,
    );
  }
  
  /// 转换为配置模型格式
  Map<String, dynamic> toConfigFormat() {
    return {
      'presetName': presetName,
      'aiMode': aiMode,
      'lockPosition': lockPosition,
      'hotkey': hotkey,
      'triggerSwitch': triggerSwitch,
      'enabled': enabled,
    };
  }
}

/// 添加卡片回调
typedef OnCardAdded = Function(CardData card);

/// 更新卡片回调
typedef OnCardUpdated = Function(CardData card);

/// 下拉菜单变更回调
typedef OnCardPropertyChanged = Function(CardData card, String property, String newValue);

/// 布尔属性变更回调
typedef OnCardBoolPropertyChanged = Function(CardData card, String property, bool newValue);

/// 获取所有卡片信息回调
typedef OnGetAllCardsInfo = Function(List<CardData> cards);

/// 卡片管理组件
class CardManagerComponent extends StatefulWidget {
  /// 卡片列表
  final List<CardData> cards;
  
  /// 应用栏标题
  final String appBarTitle;
  
  /// 添加卡片回调
  final OnCardAdded? onCardAdded;
  
  /// 更新卡片回调
  final OnCardUpdated? onCardUpdated;
  
  /// 卡片属性变更回调（用于下拉菜单变更）
  final OnCardPropertyChanged? onCardPropertyChanged;
  
  /// 卡片布尔属性变更回调（如开关状态）
  final OnCardBoolPropertyChanged? onCardBoolPropertyChanged;
  
  /// 获取所有卡片信息回调
  final OnGetAllCardsInfo? onGetAllCardsInfo;
  
  /// 是否外部处理下拉菜单变更事件
  final bool externalPropertyHandling;
  
  /// 是否启用滚动
  final bool enableScroll;
  
  /// 是否隐藏应用栏
  final bool hideAppBar;

  const CardManagerComponent({
    Key? key,
    required this.cards,
    this.appBarTitle = '卡片管理',
    this.onCardAdded,
    this.onCardUpdated,
    this.onCardPropertyChanged,
    this.onCardBoolPropertyChanged,
    this.onGetAllCardsInfo,
    this.externalPropertyHandling = false,
    this.enableScroll = true,
    this.hideAppBar = false,
  }) : super(key: key);

  @override
  _CardManagerComponentState createState() => _CardManagerComponentState();
}

class _CardManagerComponentState extends State<CardManagerComponent> {
  // 检测是否为移动设备
  bool get _isMobileDevice {
    final size = MediaQuery.of(context).size;
    return size.width < 600; // 一般将600px作为移动设备的宽度阈值
  }
  
  @override
  Widget build(BuildContext context) {
    // 在移动设备上自动启用滚动
    final bool shouldEnableScroll = widget.enableScroll || _isMobileDevice;
    
    return Column(
      children: [
        // 顶部应用栏 - 仅在不隐藏时显示
        if (!widget.hideAppBar) _buildAppBar(),
        
        // 主体内容
        Expanded(
          child: widget.cards.isEmpty 
              ? _buildEmptyView()
              : shouldEnableScroll
                  ? _buildScrollableCardList()  // 可滚动版本
                  : _buildCardList(),  // 原有版本
        ),
      ],
    );
  }

  /// 构建应用栏
  Widget _buildAppBar() {
    return AppBar(
      title: Text(widget.appBarTitle),
      centerTitle: true,
      elevation: 2.0, // 添加一些阴影效果
      toolbarHeight: _isMobileDevice ? 56.0 : 64.0, // 在移动设备上使用更紧凑的高度
      actions: [
        // 保存配置按钮
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: '保存配置',
          onPressed: () {
            if (widget.onGetAllCardsInfo != null) {
              widget.onGetAllCardsInfo!(widget.cards);
            }
          },
        ),
      ],
    );
  }

  /// 构建可滚动的卡片列表（适用于移动端）
  Widget _buildScrollableCardList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      // 使用更适合移动设备的滚动物理效果
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final int columns = _calculateColumns(maxWidth);
            final double cardWidth = _calculateCardWidth(maxWidth, columns);
            final double spacing = 12.0;
            
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              alignment: WrapAlignment.start,
              children: widget.cards.map((card) {
                return SizedBox(
                  width: cardWidth,
                  // 添加触摸反馈效果
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.blue.withOpacity(0.1),
                      highlightColor: Colors.blue.withOpacity(0.05),
                      onTap: () {
                        // 触摸卡片时可以触发选中状态或其他交互
                        // 这里可以添加交互逻辑
                      },
                      child: _buildCardItem(card),
                    ),
                  ),
                );
              }).toList(),
            );
          }
        ),
        // 添加底部填充，确保最后一个卡片可以完全滚动显示
        const SizedBox(height: 80),
      ],
    );
  }

  /// 构建卡片列表
  Widget _buildCardList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 空状态显示
            if (widget.cards.isEmpty) {
              return _buildEmptyView();
            }
            
            // 计算网格列数和卡片宽度
            final double maxWidth = constraints.maxWidth;
            final int columns = _calculateColumns(maxWidth);
            final double cardWidth = _calculateCardWidth(maxWidth, columns);
            final double spacing = 12.0;
            
            return Column(
              children: [
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  alignment: WrapAlignment.start,
                  children: widget.cards.map((card) {
                    return SizedBox(
                      width: cardWidth,
                      // 添加触摸反馈效果，与可滚动版本保持一致
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.blue.withOpacity(0.1),
                          highlightColor: Colors.blue.withOpacity(0.05),
                          onTap: () {
                            // 触摸卡片时可以触发选中状态或其他交互
                          },
                          child: _buildCardItem(card),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // 底部填充
                const SizedBox(height: 80),
              ],
            );
          }
        ),
      ),
    );
  }
  
  /// 根据可用宽度计算合适的列数
  int _calculateColumns(double availableWidth) {
    if (availableWidth < 450) {
      return 1; // 手机或窄屏幕
    } else if (availableWidth < 800) {
      return 2; // 平板或中等屏幕
    } else if (availableWidth < 1200) {
      return 3; // 桌面或宽屏
    } else {
      return 4; // 超宽屏幕
    }
  }
  
  /// 计算卡片宽度
  double _calculateCardWidth(double availableWidth, int columns) {
    // 考虑间距计算实际可用宽度
    double totalSpacing = 12.0 * (columns - 1);
    return (availableWidth - totalSpacing) / columns;
  }

  /// 构建单个卡片项
  Widget _buildCardItem(CardData card) {
    return _buildCard(card);
  }

  /// 构建卡片主体内容
  Widget _buildCard(CardData card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(0),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Text(
              card.presetName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            
            const Divider(height: 24),
            
            // 启用状态开关
            _buildSwitchRow('启用状态:', card.enabled, 
              (newValue) {
                if (widget.externalPropertyHandling && widget.onCardBoolPropertyChanged != null) {
                  // 由父组件处理属性变更
                  widget.onCardBoolPropertyChanged!(card, 'enabled', newValue);
                } else {
                  // 在组件内部处理属性变更
                  setState(() => card.enabled = newValue);
                  if (widget.onCardUpdated != null) {
                    widget.onCardUpdated!(card);
                  }
                }
              }),
            
            const SizedBox(height: 8),
            
            // 自动扳机开关
            _buildSwitchRow('自动扳机:', card.triggerSwitch, 
              (newValue) {
                if (widget.externalPropertyHandling && widget.onCardBoolPropertyChanged != null) {
                  // 由父组件处理属性变更
                  widget.onCardBoolPropertyChanged!(card, 'triggerSwitch', newValue);
                } else {
                  // 在组件内部处理属性变更
                  setState(() => card.triggerSwitch = newValue);
                  if (widget.onCardUpdated != null) {
                    widget.onCardUpdated!(card);
                  }
                }
              }),
            
            const SizedBox(height: 8),
            
            // 热键设置下拉菜单 - 使用封装的IconDropdown组件
            _buildIconDropdownRow(
              '触发热键:', 
              card.hotkey, 
              Provider.of<FunctionModel>(context, listen: false).hotkeys,
              Icons.keyboard,
              (newValue) {
                if (widget.externalPropertyHandling && widget.onCardPropertyChanged != null) {
                  // 由父组件处理属性变更
                  widget.onCardPropertyChanged!(card, 'hotkey', newValue!);
                } else {
                  // 在组件内部处理属性变更
                  setState(() => card.hotkey = newValue!);
                  if (widget.onCardUpdated != null) {
                    widget.onCardUpdated!(card);
                  }
                }
              }),
            
            const SizedBox(height: 8),
            
            // AI模式下拉菜单 - 使用封装的IconDropdown组件
            _buildIconDropdownRow(
              'AI模式:', 
              card.aiMode, 
              Provider.of<FunctionModel>(context, listen: false).aiModes, 
              Icons.smart_toy,
              (newValue) {
                if (widget.externalPropertyHandling && widget.onCardPropertyChanged != null) {
                  // 由父组件处理属性变更
                  widget.onCardPropertyChanged!(card, 'aiMode', newValue!);
                } else {
                  // 在组件内部处理属性变更
                  setState(() => card.aiMode = newValue!);
                  if (widget.onCardUpdated != null) {
                    widget.onCardUpdated!(card);
                  }
                }
              }),
            
            const SizedBox(height: 8),
            
            // 锁定位置下拉菜单 - 使用封装的IconDropdown组件
            _buildIconDropdownRow(
              '锁定位置:', 
              card.lockPosition, 
              Provider.of<FunctionModel>(context, listen: false).lockPositions, 
              Icons.gps_fixed,
              (newValue) {
                if (widget.externalPropertyHandling && widget.onCardPropertyChanged != null) {
                  // 由父组件处理属性变更
                  widget.onCardPropertyChanged!(card, 'lockPosition', newValue!);
                } else {
                  // 在组件内部处理属性变更
                  setState(() => card.lockPosition = newValue!);
                  if (widget.onCardUpdated != null) {
                    widget.onCardUpdated!(card);
                  }
                }
              }),
          ],
        ),
      ),
    );
  }

  /// 构建带标签的IconDropdown下拉行
  Widget _buildIconDropdownRow(String label, String value, List<String> items, IconData itemIcon, Function(String?) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: IconDropdown(
            value: value,
            items: items.map((item) => IconDropdownItem(
              value: item,
              text: item,
              icon: itemIcon,
            )).toList(),
            onChanged: onChanged,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(4),
            border: const BorderSide(color: Colors.grey),
            dropdownButtonColor: Colors.white,
            textStyle: const TextStyle(fontSize: 14),
            iconSize: 18,
          ),
        ),
      ],
    );
  }

  /// 构建带开关的行
  Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(
                value ? '已启用' : '已禁用',
                style: TextStyle(
                  color: value ? Colors.green : Colors.grey,
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 50,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: value ? Colors.green : Colors.grey.shade300,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => onChanged(!value),
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            spreadRadius: 0.5,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  /// 构建空视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.dashboard_customize,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无卡片',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请等待系统加载预设配置',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
