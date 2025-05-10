// ignore_for_file: library_private_types_in_public_api, use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:getwidget/getwidget.dart';
import '../../controllers/function_controller.dart';
import 'card_manager_component.dart';
import '../../component/message_component.dart';

/// 功能设置页面 - 管理各种功能配置和预设
class FunctionScreen extends StatelessWidget {
  const FunctionScreen({Key? key}) : super(key: key);
  
  // 处理保存配置
  void _handleSaveConfig(BuildContext context, List<CardData> cards) {
    final controller = Provider.of<FunctionController>(context, listen: false);
    controller.saveAllCardsInfo(context);
  }
  
  // 处理刷新配置
  void _handleRefreshConfig(BuildContext context) {
    final controller = Provider.of<FunctionController>(context, listen: false);
    controller.refreshFunctionConfig();
    
    MessageComponent.showIconToast(
      context: context,
      message: '正在刷新功能配置...',
      type: MessageType.info,
      duration: const Duration(seconds: 1),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FunctionController>(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏和按钮
            _buildHeader(context, controller),
            
            // 卡片管理组件
            Expanded(
              child: CardManagerComponent(
                cards: controller.cards,
                appBarTitle: '功能设置',
                externalPropertyHandling: true,
                onCardPropertyChanged: controller.updateCardProperty,
                onCardBoolPropertyChanged: controller.updateCardBoolProperty,
                onGetAllCardsInfo: (cards) => _handleSaveConfig(context, cards),
                enableScroll: true,
                hideAppBar: true, // 隐藏组件内的AppBar
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建顶部标题和按钮
  Widget _buildHeader(BuildContext context, FunctionController controller) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 页面标题
          const Text(
            '功能设置',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // 按钮组
          Row(
            children: [
              // 刷新按钮
              GFIconButton(
                onPressed: () => _handleRefreshConfig(context),
                icon: const Icon(Icons.refresh, color: Colors.white),
                color: GFColors.INFO,
                size: GFSize.SMALL,
                shape: GFIconButtonShape.circle,
                tooltip: '刷新参数',
              ),
              
              const SizedBox(width: 12),
              
              // 保存按钮
              GFButton(
                onPressed: () => _handleSaveConfig(context, controller.cards),
                text: '保存',
                icon: const Icon(Icons.save, color: Colors.white),
                color: GFColors.PRIMARY,
                size: GFSize.MEDIUM,
                shape: GFButtonShape.standard,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
