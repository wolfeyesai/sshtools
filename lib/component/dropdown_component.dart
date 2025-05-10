// ignore_for_file: use_super_parameters, avoid_unnecessary_containers, prefer_if_null_operators, unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class IconDropdownItem {
  final String value;
  final String text;
  final IconData? icon;
  final Widget? image;

  IconDropdownItem({
    required this.value,
    required this.text,
    this.icon,
    this.image,
  }) : assert(icon != null || image != null, '必须提供icon或image中的一个');
}

class IconDropdown extends StatelessWidget {
  final String? value;
  final List<IconDropdownItem> items;
  final Function(String?) onChanged;
  final IconData? dropdownIcon;
  final Widget? dropdownImage;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final BorderSide border;
  final Color? dropdownButtonColor;
  final TextStyle? textStyle;
  final double iconSize;
  final bool showTextOnSmallScreens;
  final double smallScreenWidth;

  const IconDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.dropdownIcon,
    this.dropdownImage,
    this.height = 50,
    this.width,
    this.margin,
    this.padding = const EdgeInsets.all(15),
    this.borderRadius,
    this.border = const BorderSide(color: Colors.black12, width: 1),
    this.dropdownButtonColor,
    this.textStyle,
    this.iconSize = 24,
    this.showTextOnSmallScreens = true,
    this.smallScreenWidth = 600,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 检测是否为小屏幕
    final isSmallScreen = MediaQuery.of(context).size.width < smallScreenWidth;
    
    return Container(
      height: height,
      width: width ?? MediaQuery.of(context).size.width,
      margin: margin ?? const EdgeInsets.all(20),
      child: DropdownButtonHideUnderline(
        child: GFDropdown<String>(
          padding: padding,
          borderRadius: borderRadius ?? BorderRadius.circular(10),
          border: border,
          dropdownButtonColor: dropdownButtonColor ?? Colors.grey[300],
          value: value,
          onChanged: onChanged,
          icon: dropdownImage ?? (dropdownIcon != null ? Icon(dropdownIcon, size: iconSize) : null),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item.value,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 50,
                        maxWidth: 300,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLeadingWidget(item),
                          if (!isSmallScreen || showTextOnSmallScreens)
                            ...[
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  item.text,
                                  style: textStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
  
  Widget _buildLeadingWidget(IconDropdownItem item) {
    if (item.image != null) {
      return item.image!;
    } else if (item.icon != null) {
      return Icon(item.icon, size: iconSize);
    } else {
      return const SizedBox.shrink(); // 不应该发生，因为构造函数有断言
    }
  }
}

class IconMultiSelectDropdown extends StatelessWidget {
  final List<String> selectedValues;
  final List<IconDropdownItem> items;
  final Function(List<dynamic>) onSelect;
  final String dropdownTitleTileText;
  final Color? dropdownTitleTileColor;
  final EdgeInsets? dropdownTitleTileMargin;
  final EdgeInsets? dropdownTitleTilePadding;
  final BorderSide? dropdownUnderlineBorder;
  final Border? dropdownTitleTileBorder;
  final BorderRadius? dropdownTitleTileBorderRadius;
  final IconData? expandedIcon;
  final IconData? collapsedIcon;
  final Widget? expandedImage;
  final Widget? collapsedImage;
  final Widget? submitButton;
  final Widget? cancelButton;
  final TextStyle? dropdownTitleTileTextStyle;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final GFCheckboxType type;
  final Color activeBgColor;
  final Color activeBorderColor;
  final Color inactiveBorderColor;
  final double iconSize;

  const IconMultiSelectDropdown({
    Key? key,
    required this.selectedValues,
    required this.items,
    required this.onSelect,
    this.dropdownTitleTileText = '请选择',
    this.dropdownTitleTileColor,
    this.dropdownTitleTileMargin,
    this.dropdownTitleTilePadding,
    this.dropdownUnderlineBorder,
    this.dropdownTitleTileBorder,
    this.dropdownTitleTileBorderRadius,
    this.expandedIcon,
    this.collapsedIcon,
    this.expandedImage,
    this.collapsedImage,
    this.submitButton,
    this.cancelButton,
    this.dropdownTitleTileTextStyle,
    this.padding,
    this.margin,
    this.type = GFCheckboxType.basic,
    this.activeBgColor = const Color(0x8000FF00), // 半透明绿色
    this.activeBorderColor = Colors.green,
    this.inactiveBorderColor = Colors.grey,
    this.iconSize = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 将IconDropdownItem列表转换为GFMultiSelect需要的格式
    final List<dynamic> dropList = items
        .map((item) => {
              'value': item.value,
              'text': item.text,
              'icon': item.icon,
              'image': item.image,
            })
        .toList();

    // 注意：由于GFMultiSelect不直接支持自定义项构建器，
    // 我们需要在使用前准备好下拉项的显示方式
    final List<Widget> customItemList = dropList.map((item) {
      return ListTile(
        leading: _buildItemLeadingWidget(item),
        title: Text(item['text']),
        dense: true,
      );
    }).toList();

    return Container(
      child: GFMultiSelect(
        items: dropList,
        onSelect: onSelect,
        dropdownTitleTileText: dropdownTitleTileText,
        dropdownTitleTileColor: dropdownTitleTileColor ?? Colors.grey[200],
        dropdownTitleTileMargin: dropdownTitleTileMargin ??
            const EdgeInsets.only(top: 22, left: 18, right: 18, bottom: 5),
        dropdownTitleTilePadding:
            dropdownTitleTilePadding ?? const EdgeInsets.all(10),
        dropdownUnderlineBorder: dropdownUnderlineBorder ??
            const BorderSide(color: Colors.transparent, width: 2),
        dropdownTitleTileBorder: dropdownTitleTileBorder ??
            Border.all(color: Colors.grey[300]!, width: 1),
        dropdownTitleTileBorderRadius:
            dropdownTitleTileBorderRadius ?? BorderRadius.circular(5),
        expandedIcon: expandedImage != null 
            ? expandedImage! 
            : expandedIcon != null
                ? Icon(
                    expandedIcon,
                    color: Colors.black54,
                  )
                : const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
        collapsedIcon: collapsedImage != null
            ? collapsedImage!
            : collapsedIcon != null
                ? Icon(
                    collapsedIcon,
                    color: Colors.black54,
                  )
                : const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.black54,
                  ),
        submitButton: submitButton ?? const Text('确定'),
        cancelButton: cancelButton ?? const Text('取消'),
        dropdownTitleTileTextStyle: dropdownTitleTileTextStyle ??
            const TextStyle(fontSize: 14, color: Colors.black54),
        padding: padding ?? const EdgeInsets.all(6),
        margin: margin ?? const EdgeInsets.all(6),
        type: type,
        activeBgColor: activeBgColor,
        activeBorderColor: activeBorderColor,
        inactiveBorderColor: inactiveBorderColor,
      ),
    );
  }
  
  Widget _buildItemLeadingWidget(dynamic item) {
    if (item['image'] != null) {
      return item['image'];
    } else if (item['icon'] != null) {
      return Icon(item['icon'], size: iconSize);
    } else {
      return const SizedBox.shrink();
    }
  }
}

/* 使用示例:

// 单选下拉菜单示例
// -------------------------------------
// 1. 定义状态变量
String selectedValue = '选项1';

// 2. 创建下拉菜单 (使用图标)
IconDropdown(
  value: selectedValue,
  items: [
    IconDropdownItem(value: '选项1', text: '选项一', icon: Icons.home),
    IconDropdownItem(value: '选项2', text: '选项二', icon: Icons.settings),
    IconDropdownItem(value: '选项3', text: '选项三', icon: Icons.person),
  ],
  onChanged: (newValue) {
    setState(() {
      selectedValue = newValue!;
    });
  },
  dropdownIcon: Icons.arrow_drop_down,
  height: 50,
  width: 300,
  margin: EdgeInsets.all(10),
  padding: EdgeInsets.all(10),
  borderRadius: BorderRadius.circular(8),
  border: BorderSide(color: Colors.grey, width: 1),
  dropdownButtonColor: Colors.white,
  textStyle: TextStyle(fontSize: 16),
  iconSize: 20,
)

// 2. 创建下拉菜单 (使用图片)
IconDropdown(
  value: selectedValue,
  items: [
    IconDropdownItem(
      value: '选项1', 
      text: '选项一', 
      image: Image.asset('assets/images/home.png', width: 24, height: 24)
    ),
    IconDropdownItem(
      value: '选项2', 
      text: '选项二', 
      image: Image.network('https://example.com/icon.png', width: 24, height: 24)
    ),
    IconDropdownItem(
      value: '选项3', 
      text: '选项三', 
      image: CircleAvatar(
        backgroundImage: NetworkImage('https://example.com/avatar.jpg'),
        radius: 12,
      )
    ),
  ],
  onChanged: (newValue) {
    setState(() {
      selectedValue = newValue!;
    });
  },
  dropdownImage: Image.asset('assets/images/dropdown.png', width: 24, height: 24),
)

// 多选下拉菜单示例
// -------------------------------------
// 1. 定义状态变量
List<String> selectedValues = [];

// 2. 创建多选下拉菜单 (混合使用图标和图片)
IconMultiSelectDropdown(
  selectedValues: selectedValues,
  items: [
    IconDropdownItem(value: '选项1', text: '选项一', icon: Icons.home),
    IconDropdownItem(
      value: '选项2', 
      text: '选项二', 
      image: Image.asset('assets/images/settings.png', width: 24, height: 24)
    ),
    IconDropdownItem(value: '选项3', text: '选项三', icon: Icons.person),
  ],
  onSelect: (values) {
    setState(() {
      selectedValues = values.cast<String>();
    });
  },
  dropdownTitleTileText: '请选择选项',
  expandedIcon: Icons.keyboard_arrow_down,
  collapsedIcon: Icons.keyboard_arrow_up,
  // 也可以使用图片
  // expandedImage: Image.asset('assets/images/down.png', width: 24, height: 24),
  // collapsedImage: Image.asset('assets/images/up.png', width: 24, height: 24),
)

*/
