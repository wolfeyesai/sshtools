// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

/// 可选择的卡片项数据模型
class CardItem {
  final String id;       // 卡片唯一标识
  final String title;    // 卡片标题
  final IconData? icon;   // 可选的卡片图标
  final String? imagePath; // 可选的图片路径
  final Color? color;    // 可选的卡片颜色

  CardItem({
    required this.id,
    required this.title,
    this.icon,
    this.imagePath,
    this.color,
  });
}

/// 网格卡片选择组件
/// 
/// 一个通过网格展示多个卡片并允许用户选择的组件
/// 可自适应不同屏幕尺寸，每个卡片显示图片/图标和名称
/// 卡片尺寸限制在120x120到180x180之间
class CardSelectComponent extends StatefulWidget {
  /// 要展示的卡片列表
  final List<CardItem> cardItems;
  
  /// 当选择卡片变化时的回调
  final Function(CardItem) onCardSelected;
  
  /// 可选的初始选中的卡片ID
  final String? initialSelectedId;
  
  /// 网格的列数，默认为根据屏幕宽度自动计算
  final int? crossAxisCount;
  
  /// 网格项之间的水平间距
  final double crossAxisSpacing;
  
  /// 网格项之间的垂直间距
  final double mainAxisSpacing;
  
  /// 是否允许卡片自动缩放，默认为true
  final bool allowAutoScale;

  const CardSelectComponent({
    Key? key,
    required this.cardItems,
    required this.onCardSelected,
    this.initialSelectedId,
    this.crossAxisCount,
    this.crossAxisSpacing = 10.0,
    this.mainAxisSpacing = 10.0,
    this.allowAutoScale = true,
  }) : super(key: key);

  @override
  State<CardSelectComponent> createState() => _CardSelectComponentState();
}

class _CardSelectComponentState extends State<CardSelectComponent> {
  String? _selectedCardId;
  
  @override
  void initState() {
    super.initState();
    _selectedCardId = widget.initialSelectedId;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用宽度自动计算列数，如果没有指定
        final double maxWidth = constraints.maxWidth;
        final int columns = widget.crossAxisCount ?? _calculateColumns(maxWidth);
        
        // 计算卡片尺寸，保持在最小120x120和最大180x180之间
        double cardWidth = _calculateCardWidth(maxWidth, columns);
        
        return Wrap(
          spacing: widget.crossAxisSpacing,
          runSpacing: widget.mainAxisSpacing,
          alignment: WrapAlignment.start,
          children: widget.cardItems.map((cardItem) {
            final bool isSelected = cardItem.id == _selectedCardId;
            return SizedBox(
              width: cardWidth,
              height: cardWidth,
              child: _buildSelectableCard(cardItem, isSelected),
            );
          }).toList(),
        );
      }
    );
  }
  
  /// 根据可用宽度计算合适的列数
  int _calculateColumns(double availableWidth) {
    if (availableWidth < 300) {
      return 1; // 手机小屏幕
    } else if (availableWidth < 600) {
      return 2; // 手机大屏幕或小平板
    } else if (availableWidth < 900) {
      return 3; // 平板
    } else if (availableWidth < 1200) {
      return 4; // 桌面或大平板
    } else {
      return 5; // 超大屏幕
    }
  }
  
  /// 计算卡片宽度，保持在最小120和最大180之间
  double _calculateCardWidth(double availableWidth, int columns) {
    // 考虑间距计算实际可用宽度
    double totalSpacing = widget.crossAxisSpacing * (columns - 1);
    double availableCardWidth = (availableWidth - totalSpacing) / columns;
    
    // 限制在120到180之间
    if (!widget.allowAutoScale) {
      return 150.0; // 固定尺寸
    } else if (availableCardWidth < 120) {
      return 120.0;
    } else if (availableCardWidth > 180) {
      return 180.0;
    } else {
      return availableCardWidth;
    }
  }
  
  /// 构建一个可选择的卡片
  Widget _buildSelectableCard(CardItem cardItem, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardId = cardItem.id;
        });
        widget.onCardSelected(cardItem);
      },
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: cardItem.color ?? Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图片或图标
            Expanded(
              flex: 3,
              child: Center(
                child: _buildCardMedia(cardItem),
              ),
            ),
            // 卡片名称
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  cardItem.title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建卡片媒体内容（图片或图标）
  Widget _buildCardMedia(CardItem cardItem) {
    if (cardItem.imagePath != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          cardItem.imagePath!,
          fit: BoxFit.contain,
        ),
      );
    } else if (cardItem.icon != null) {
      return Icon(
        cardItem.icon,
        size: 40,
        color: Theme.of(context).colorScheme.secondary,
      );
    } else {
      return const SizedBox(); // 如果既没有图片也没有图标，则返回一个空的SizedBox
    }
  }
} 