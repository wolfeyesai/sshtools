// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:getwidget/getwidget.dart';
import '../component/card_select_component.dart';
import '../component/input_component.dart';
import '../controllers/home_controller.dart';
import '../controllers/header_controller.dart';
import '../services/server_service.dart'; // 导入服务器服务
import '../models/auth_model.dart'; // 导入认证模型
import '../models/game_model.dart'; // 导入游戏模型
import '../component/message_component.dart'; // 导入消息组件

/// 首页配置页面
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final homeController = HomeController(
          serverService: Provider.of<ServerService>(context, listen: false),
          authModel: Provider.of<AuthModel>(context, listen: false),
          gameModel: Provider.of<GameModel>(context, listen: false),
        );
        // 设置HeaderController引用以实现双向同步
        homeController.setHeaderController(
          Provider.of<HeaderController>(context, listen: false)
        );
        return homeController;
      },
      child: const _HomeScreenView(),
    );
  }
}

/// 首页视图组件
class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();
  
  // 处理刷新配置
  void _handleRefreshConfig(BuildContext context) {
    final controller = Provider.of<HomeController>(context, listen: false);
    controller.refreshHomeConfig();
    
    MessageComponent.showIconToast(
      context: context,
      message: '正在刷新首页配置...',
      type: MessageType.info,
      duration: const Duration(seconds: 1),
    );
  }
  
  // 处理保存配置
  void _handleSaveConfig(BuildContext context) {
    final controller = Provider.of<HomeController>(context, listen: false);
    controller.saveHomeConfig(context);
  }

  @override
  Widget build(BuildContext context) {
    // 获取设备信息
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    
    // 获取控制器
    final homeController = Provider.of<HomeController>(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题栏和按钮
            _buildHeader(context, homeController),
            
            // 卡密输入框
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8.0 : 16.0, 
                vertical: 8.0
              ),
              child: InputComponent.createInput(
                label: '卡密',
                hint: '请输入您的卡密',
                icon: Icons.vpn_key,
                controller: homeController.cardKeyController,
                onChanged: homeController.onCardKeyChanged,
              ),
            ),
            
            // 游戏卡片选择区域
            Expanded(
              child: _buildCardSelectionArea(context, isSmallScreen, homeController),
            ),
          ],
        ),
      ),
      // 底部已选择游戏显示条
      bottomNavigationBar: _buildSelectedGameBar(context, isSmallScreen),
    );
  }
  
  /// 构建顶部标题和按钮
  Widget _buildHeader(BuildContext context, HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 页面标题
          const Text(
            '首页配置',
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
                onPressed: () => _handleSaveConfig(context),
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
  
  // 构建卡片选择区域
  Widget _buildCardSelectionArea(
    BuildContext context, 
    bool isSmallScreen, 
    HomeController homeController
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 计算列数
            final int columnsToUse = isSmallScreen 
              ? 2 // 手机屏幕2列
              : constraints.maxWidth < 900 
                ? 3 // 平板3列
                : 4; // 大屏4列
            
            return CardSelectComponent(
              cardItems: homeController.getGameCards(),
              onCardSelected: homeController.selectGame,
              initialSelectedId: homeController.getInitialSelectedId(),
              crossAxisCount: columnsToUse,
              allowAutoScale: true,
              crossAxisSpacing: isSmallScreen ? 2.0 : 4.0,
              mainAxisSpacing: isSmallScreen ? 2.0 : 4.0,
            );
          }
        ),
      ),
    );
  }
  
  // 构建已选择游戏显示条
  Widget _buildSelectedGameBar(BuildContext context, bool isSmallScreen) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final selectedGame = controller.selectedGame;
        if (selectedGame == null) return const SizedBox.shrink();
        
        return Container(
          color: Colors.blue.shade50,
          padding: EdgeInsets.symmetric(
            vertical: 12.0, 
            horizontal: isSmallScreen ? 16.0 : 24.0
          ),
          child: Row(
            children: [
              if (selectedGame.imagePath != null)
                Image.asset(
                  selectedGame.imagePath!,
                  width: 24,
                  height: 24,
                ),
              const SizedBox(width: 8),
              Text(
                '已选择: ${selectedGame.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 