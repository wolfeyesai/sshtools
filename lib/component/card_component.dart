// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// 基础空卡片组件
class BaseCard extends StatelessWidget {
  /// 卡片标题
  final String title;
  
  /// 卡片子内容
  final Widget? child;
  
  /// 卡片边距
  final EdgeInsetsGeometry? margin;
  
  /// 卡片内边距
  final EdgeInsetsGeometry? padding;
  
  /// 卡片背景色252+
  /// 63.
  final Color? backgroundColor;
  
  /// 卡片阴影高度
  final double elevation;

  /// 构造函数
  const BaseCard({
    Key? key,
    required this.title,
    this.child,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.elevation = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GFCard(
      margin: margin ?? const EdgeInsets.all(12.0),
      padding: padding ?? const EdgeInsets.all(12.0),
      title: GFListTile(
        title: GFTypography(
          text: title,
          type: GFTypographyType.typo4,
          showDivider: false,
        ),
      ),
      content: child,
      color: backgroundColor,
      elevation: elevation,
    );
  }
}

/// 具有两个按钮和下拉菜单的卡片组件
class ButtonDropdownCard extends StatefulWidget {
  /// 卡片标题
  final String title;
  
  /// 第一个按钮文本
  final String firstButtonText;
  
  /// 第二个按钮文本
  final String secondButtonText;
  
  /// 第一个按钮点击回调
  final VoidCallback? onFirstButtonPressed;
  
  /// 第二个按钮点击回调
  final VoidCallback? onSecondButtonPressed;
  
  /// 下拉菜单选项
  final List<String> dropdownItems;
  
  /// 下拉菜单初始选中值
  final String? initialDropdownValue;
  
  /// 下拉菜单值变化回调
  final Function(String?)? onDropdownChanged;
  
  /// 卡片边距
  final EdgeInsetsGeometry? margin;
  
  /// 卡片内边距
  final EdgeInsetsGeometry? padding;
  
  /// 卡片背景色
  final Color? backgroundColor;
  
  /// 卡片阴影高度
  final double elevation;

  /// 构造函数
  const ButtonDropdownCard({
    Key? key,
    required this.title,
    required this.firstButtonText,
    required this.secondButtonText,
    this.onFirstButtonPressed,
    this.onSecondButtonPressed,
    required this.dropdownItems,
    this.initialDropdownValue,
    this.onDropdownChanged,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.elevation = 2.0,
  }) : super(key: key);

  @override
  State<ButtonDropdownCard> createState() => _ButtonDropdownCardState();
}

class _ButtonDropdownCardState extends State<ButtonDropdownCard> {
  late String? dropdownValue;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.initialDropdownValue ?? 
                   (widget.dropdownItems.isNotEmpty ? widget.dropdownItems.first : null);
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: widget.title,
      margin: widget.margin,
      padding: widget.padding,
      backgroundColor: widget.backgroundColor,
      elevation: widget.elevation,
      child: GFCard(
        boxFit: BoxFit.cover,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(8.0),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 下拉菜单
            GFDropdown<String>(
              value: dropdownValue,
              isExpanded: true,
              items: widget.dropdownItems.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: GFTypography(
                    text: value,
                    type: GFTypographyType.typo5,
                    showDivider: false,
                  ),
                );
              }).toList(),
              hint: const GFTypography(
                text: '请选择一个选项',
                type: GFTypographyType.typo5,
                showDivider: false,
              ),
              onChanged: (value) {
                setState(() {
                  dropdownValue = value;
                });
                if (widget.onDropdownChanged != null) {
                  widget.onDropdownChanged!(value);
                }
              },
              icon: const Icon(Icons.arrow_drop_down),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              borderRadius: BorderRadius.circular(5),
              border: const BorderSide(color: Colors.grey, width: 1),
            ),
            
            const SizedBox(height: 16),
            
            // 按钮区域
            GFButtonBar(
              alignment: WrapAlignment.end,
              children: <Widget>[
                GFButton(
                  onPressed: widget.onFirstButtonPressed,
                  text: widget.firstButtonText,
                  shape: GFButtonShape.pills,
                ),
                const SizedBox(width: 8),
                GFButton(
                  onPressed: widget.onSecondButtonPressed,
                  text: widget.secondButtonText,
                  color: GFColors.SECONDARY,
                  shape: GFButtonShape.pills,
                ),
              ],
            ),
          ],
        ),
        buttonBar: const GFButtonBar(
          children: <Widget>[
            // 留空，使用自定义按钮区域
          ],
        ),
      ),
    );
  }
}

/// 包含开关按钮的卡片组件
class SwitchButtonCard extends StatefulWidget {
  /// 卡片标题
  final String title;
  
  /// 开关选项列表，每项包含标题和初始状态
  final List<Map<String, dynamic>> switchItems;
  
  /// 确认按钮文本
  final String confirmButtonText;
  
  /// 确认按钮点击回调
  final VoidCallback? onConfirmPressed;
  
  /// 开关状态变化回调，参数为开关的索引和新状态
  final Function(int, bool)? onSwitchChanged;
  
  /// 卡片边距
  final EdgeInsetsGeometry? margin;
  
  /// 卡片内边距
  final EdgeInsetsGeometry? padding;
  
  /// 卡片背景色
  final Color? backgroundColor;
  
  /// 卡片阴影高度
  final double elevation;

  /// 构造函数
  const SwitchButtonCard({
    Key? key,
    required this.title,
    required this.switchItems,
    this.confirmButtonText = '确认',
    this.onConfirmPressed,
    this.onSwitchChanged,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.elevation = 2.0,
  }) : super(key: key);

  @override
  State<SwitchButtonCard> createState() => _SwitchButtonCardState();
}

class _SwitchButtonCardState extends State<SwitchButtonCard> {
  /// 存储所有开关的当前状态
  late List<bool> _switchValues;

  @override
  void initState() {
    super.initState();
    // 初始化开关状态
    _switchValues = widget.switchItems
        .map<bool>((item) => item['value'] as bool? ?? false)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: widget.title,
      margin: widget.margin,
      padding: widget.padding,
      backgroundColor: widget.backgroundColor,
      elevation: widget.elevation,
      child: GFCard(
        boxFit: BoxFit.cover,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(8.0),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 开关列表
            ...List.generate(
              widget.switchItems.length,
              (index) => _buildSwitchItem(index),
            ),
            
            const SizedBox(height: 16),
            
            // 确认按钮
            GFButtonBar(
              alignment: WrapAlignment.end,
              children: <Widget>[
                GFButton(
                  onPressed: widget.onConfirmPressed,
                  text: widget.confirmButtonText,
                  color: GFColors.PRIMARY,
                  shape: GFButtonShape.pills,
                ),
              ],
            ),
          ],
        ),
        buttonBar: const GFButtonBar(
          children: <Widget>[
            // 留空，使用自定义按钮区域
          ],
        ),
      ),
    );
  }

  /// 构建单个开关项
  Widget _buildSwitchItem(int index) {
    final item = widget.switchItems[index];
    final title = item['title'] as String? ?? '选项 ${index + 1}';
    final subtitle = item['subtitle'] as String?;
    final icon = item['icon'] as IconData?;
    
    return GFListTile(
      margin: const EdgeInsets.only(bottom: 4.0),
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      avatar: icon != null 
        ? GFIconButton(
            icon: Icon(icon, color: Theme.of(context).primaryColor),
            type: GFButtonType.transparent,
            onPressed: () {}, // 空函数，仅用于显示图标
          )
        : null,
      title: GFTypography(
        text: title,
        type: GFTypographyType.typo5,
        showDivider: false,
      ),
      subTitle: subtitle != null 
        ? GFTypography(
            text: subtitle,
            type: GFTypographyType.typo6,
            showDivider: false,
          ) 
        : null,
      icon: GFToggle(
        value: _switchValues[index],
        type: GFToggleType.ios,
        onChanged: (value) {
          setState(() {
            _switchValues[index] = value ?? false;
          });
          if (widget.onSwitchChanged != null) {
            widget.onSwitchChanged!(index, value ?? false);
          }
        },
        enabledTrackColor: GFColors.SUCCESS,
      ),
    );
  }
}

/// 创建一个简单的自定义内容卡片
class CustomContentCard extends StatelessWidget {
  /// 卡片标题
  final String title;
  
  /// 自定义内容
  final Widget content;
  
  /// 卡片边距
  final EdgeInsetsGeometry? margin;
  
  /// 卡片内边距
  final EdgeInsetsGeometry? padding;
  
  /// 卡片背景色
  final Color? backgroundColor;
  
  /// 卡片阴影高度
  final double elevation;

  /// 构造函数
  const CustomContentCard({
    Key? key,
    required this.title,
    required this.content,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.elevation = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: title,
      margin: margin,
      padding: padding,
      backgroundColor: backgroundColor,
      elevation: elevation,
      child: GFCard(
        boxFit: BoxFit.cover,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(8.0),
        content: content,
        buttonBar: const GFButtonBar(
          children: <Widget>[
            // 留空，内容中可自定义按钮
          ],
        ),
      ),
    );
  }
}

/*
使用说明：

1. 基础空卡片使用示例：
   ```dart
   BaseCard(
     title: '空卡片标题',
     child: Text('可以放任何Widget作为子内容'),
   )
   ```

2. 带按钮和下拉菜单的卡片使用示例：
   ```dart
   ButtonDropdownCard(
     title: '选择配置',
     dropdownItems: ['选项1', '选项2', '选项3'],
     initialDropdownValue: '选项1',
     onDropdownChanged: (value) {
       print('选择了: $value');
     },
     firstButtonText: '确定',
     secondButtonText: '取消',
     onFirstButtonPressed: () {
       // 处理确定按钮点击事件
     },
     onSecondButtonPressed: () {
       // 处理取消按钮点击事件
     },
   )
   ```

3. 自定义内容卡片使用示例：
   ```dart
   CustomContentCard(
     title: '自定义卡片',
     content: Column(
       children: [
         TextFormField(
           decoration: InputDecoration(labelText: '输入文本'),
         ),
         SizedBox(height: 10),
         GFButton(
           onPressed: () {},
           text: '提交',
           fullWidthButton: true,
         ),
       ],
     ),
   )
   ```

4. 带开关按钮的卡片使用示例：
   ```dart
   SwitchButtonCard(
     title: '功能开关设置',
     switchItems: [
       {'title': '开启通知', 'subtitle': '接收重要消息提醒', 'icon': Icons.notifications, 'value': true},
       {'title': '夜间模式', 'subtitle': '自动调整屏幕亮度', 'icon': Icons.nightlight_round, 'value': false},
       {'title': '自动同步', 'icon': Icons.sync, 'value': true},
     ],
     onSwitchChanged: (index, value) {
       print('第 $index 个开关切换为: $value');
     },
     onConfirmPressed: () {
       // 处理确认按钮点击事件
     },
   )
   ```

参数说明：
- BaseCard参数：
  - title: 卡片标题（必填）
  - child: 卡片内容Widget（可选）
  - margin: 卡片外边距（可选，默认12.0）
  - padding: 卡片内边距（可选，默认12.0）
  - backgroundColor: 卡片背景色（可选）
  - elevation: 卡片阴影高度（可选，默认2.0）

- ButtonDropdownCard参数：
  - title: 卡片标题（必填）
  - dropdownItems: 下拉菜单选项列表（必填）
  - initialDropdownValue: 下拉菜单初始值（可选）
  - onDropdownChanged: 下拉菜单值变化回调（可选）
  - firstButtonText: 第一个按钮文本（必填）
  - secondButtonText: 第二个按钮文本（必填）
  - onFirstButtonPressed: 第一个按钮点击回调（可选）
  - onSecondButtonPressed: 第二个按钮点击回调（可选）
  - margin, padding, backgroundColor, elevation: 同BaseCard

- CustomContentCard参数：
  - title: 卡片标题（必填）
  - content: 自定义内容Widget（必填）
  - margin, padding, backgroundColor, elevation: 同BaseCard

- SwitchButtonCard参数：
  - title: 卡片标题（必填）
  - switchItems: 开关选项列表（必填），每个选项是一个Map，包含：
    - title: 选项标题（必填）
    - subtitle: 选项副标题（可选）
    - icon: 选项前图标（可选）
    - value: 开关初始状态（可选，默认false）
  - confirmButtonText: 确认按钮文本（可选，默认"确认"）
  - onConfirmPressed: 确认按钮点击回调（可选）
  - onSwitchChanged: 开关状态变化回调（可选），参数为开关索引和新状态
  - margin, padding, backgroundColor, elevation: 同BaseCard
*/
