// ignore_for_file: library_private_types_in_public_api, use_super_parameters

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// 卡片数据模型
class CardData {
  String id;
  String title;
  String keyboardSetting;
  String pidMode;
  String errorPosition;
  IconData icon;
  bool isSelected;

  CardData({
    required this.id,
    required this.title,
    required this.keyboardSetting,
    required this.pidMode,
    required this.errorPosition,
    required this.icon,
    this.isSelected = false,
  });
  
  /// 将卡片数据转换为Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'keyboardSetting': keyboardSetting,
      'pidMode': pidMode,
      'errorPosition': errorPosition,
      'isSelected': isSelected,
    };
  }
}

/// 添加卡片回调
typedef OnCardAdded = Function(CardData card);

/// 删除卡片回调
typedef OnCardRemoved = Function(String cardId);

/// 更新卡片回调
typedef OnCardUpdated = Function(CardData card);

/// 下拉菜单变更回调
typedef OnCardPropertyChanged = Function(CardData card, String property, String newValue);

/// 添加新卡片请求回调
typedef OnAddCardRequest = Function();

/// 删除选中卡片请求回调
typedef OnDeleteSelectedRequest = Function(List<CardData> selectedCards);

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
  
  /// 删除卡片回调
  final OnCardRemoved? onCardRemoved;
  
  /// 更新卡片回调
  final OnCardUpdated? onCardUpdated;
  
  /// 卡片属性变更回调（用于下拉菜单变更）
  final OnCardPropertyChanged? onCardPropertyChanged;
  
  /// 添加新卡片请求回调
  final OnAddCardRequest? onAddCardRequest;
  
  /// 删除选中卡片请求回调
  final OnDeleteSelectedRequest? onDeleteSelectedRequest;
  
  /// 获取所有卡片信息回调
  final OnGetAllCardsInfo? onGetAllCardsInfo;
  
  /// 是否外部处理下拉菜单变更事件
  final bool externalPropertyHandling;

  const CardManagerComponent({
    Key? key,
    required this.cards,
    this.appBarTitle = '卡片管理',
    this.onCardAdded,
    this.onCardRemoved,
    this.onCardUpdated,
    this.onCardPropertyChanged,
    this.onAddCardRequest,
    this.onDeleteSelectedRequest,
    this.onGetAllCardsInfo,
    this.externalPropertyHandling = false,
  }) : super(key: key);

  @override
  _CardManagerComponentState createState() => _CardManagerComponentState();
}

class _CardManagerComponentState extends State<CardManagerComponent> {
  // 是否处于多选模式
  bool _isMultiSelectMode = false;
  
  // 获取选中的卡片数量
  int get _selectedCount => widget.cards.where((card) => card.isSelected).length;

  // 获取选中的卡片列表
  List<CardData> get _selectedCards => widget.cards.where((card) => card.isSelected).toList();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部应用栏
        _buildAppBar(),
        
        // 主体内容
        Expanded(
          child: widget.cards.isEmpty 
              ? _buildEmptyView()
              : _buildCardList(),
        ),
      ],
    );
  }

  /// 构建应用栏
  Widget _buildAppBar() {
    return AppBar(
      title: Text(_isMultiSelectMode 
          ? '已选择 $_selectedCount 项' 
          : widget.appBarTitle),
      centerTitle: true,
      leading: _isMultiSelectMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = false;
                  // 取消所有选择
                  for (var card in widget.cards) {
                    card.isSelected = false;
                  }
                });
              },
            )
          : null,
      actions: [
        // 添加新卡片按钮
        if (!_isMultiSelectMode) ...[
          // 获取卡片信息按钮
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '获取卡片信息',
            onPressed: () {
              if (widget.onGetAllCardsInfo != null) {
                widget.onGetAllCardsInfo!(widget.cards);
              }
            },
          ),
          
          // 添加新卡片按钮
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加新卡片',
            onPressed: () {
              // 触发添加卡片请求
              if (widget.onAddCardRequest != null) {
                widget.onAddCardRequest!();
              }
            },
          ),
        ],
        
        // 多选模式切换按钮或删除按钮
        if (_isMultiSelectMode)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _selectedCount > 0 ? () {
              // 触发删除选中卡片请求
              if (widget.onDeleteSelectedRequest != null) {
                widget.onDeleteSelectedRequest!(_selectedCards);
              }
              
              // 退出多选模式
              setState(() {
                _isMultiSelectMode = false;
              });
            } : null,
          )
        else
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: '多选模式',
            onPressed: () {
              setState(() {
                _isMultiSelectMode = true;
              });
            },
          ),
      ],
    );
  }

  /// 构建卡片列表
  Widget _buildCardList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.start,
            children: widget.cards.map((card) {
              return SizedBox(
                width: cardWidth,
                child: _buildCardItem(card),
              );
            }).toList(),
          );
        }
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
    // 在多选模式下使用GestureDetector处理点击，否则使用Dismissible实现滑动删除
    return _isMultiSelectMode
        ? GestureDetector(
            onTap: () {
              setState(() {
                card.isSelected = !card.isSelected;
              });
            },
            child: _buildCard(card),
          )
        : Dismissible(
            key: Key(card.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '删除',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              // 显示确认对话框
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除卡片"${card.title}"吗？'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              // 通知父组件卡片已删除
              if (widget.onCardRemoved != null) {
                widget.onCardRemoved!(card.id);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除 ${card.title}')),
              );
            },
            child: _buildCard(card),
          );
  }

  /// 构建卡片主体内容
  Widget _buildCard(CardData card) {
    return Card(
      elevation: card.isSelected ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: card.isSelected ? Colors.blue : Colors.transparent,
          width: card.isSelected ? 2 : 0,
        ),
      ),
      margin: const EdgeInsets.all(0),
      color: card.isSelected ? Colors.blue.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和图标行
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(
                    card.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isMultiSelectMode)
                  GFCheckbox(
                    size: GFSize.SMALL,
                    type: GFCheckboxType.circle,
                    activeIcon: const Icon(
                      Icons.check,
                      size: 15,
                      color: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        card.isSelected = value;
                      });
                    },
                    value: card.isSelected,
                    inactiveIcon: null,
                  ),
              ],
            ),
            
            const Divider(height: 24),
            
            // 配置项下拉菜单
            _buildDropdownRow('按键设置:', card.keyboardSetting, 
              ['左键', '右键', '中键', '方向键'], 
              (newValue) {
                if (widget.externalPropertyHandling && widget.onCardPropertyChanged != null) {
                  // 由父组件处理属性变更
                  widget.onCardPropertyChanged!(card, 'keyboardSetting', newValue!);
                } else {
                  // 在组件内部处理属性变更
                  setState(() => card.keyboardSetting = newValue!);
                  if (widget.onCardUpdated != null) {
                    widget.onCardUpdated!(card);
                  }
                }
              }),
            
            const SizedBox(height: 8),
            
            _buildDropdownRow('PID模式:', card.pidMode, 
              ['PID模式', '手动模式', '自动模式', '混合模式'], 
              (newValue) {
                if (widget.externalPropertyHandling && widget.onCardPropertyChanged != null) {
                  // 由父组件处理属性变更
                  widget.onCardPropertyChanged!(card, 'pidMode', newValue!);
                } else {
                  // 在组件内部处理属性变更
                  setState(() => card.pidMode = newValue!);
                  if (widget.onCardUpdated != null) {
                    widget.onCardUpdated!(card);
                  }
                }
              }),
            
            const SizedBox(height: 8),
            
            _buildDropdownRow('错误部位:', card.errorPosition, 
              ['头部', '颈部', '肩部', '手臂', '躯干', '腿部'], 
              (newValue) {
                if (widget.externalPropertyHandling && widget.onCardPropertyChanged != null) {
                  // 由父组件处理属性变更
                  widget.onCardPropertyChanged!(card, 'errorPosition', newValue!);
                } else {
                  // 在组件内部处理属性变更
                  setState(() => card.errorPosition = newValue!);
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

  /// 构建带标签的下拉行
  Widget _buildDropdownRow(String label, String value, List<String> items, Function(String?) onChanged) {
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
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
            '点击下方按钮添加新卡片',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          GFButton(
            onPressed: () {
              // 触发添加卡片请求
              if (widget.onAddCardRequest != null) {
                widget.onAddCardRequest!();
              }
            },
            text: '添加新卡片',
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            color: GFColors.PRIMARY,
          ),
        ],
      ),
    );
  }
}
