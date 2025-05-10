// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import '../component/Slider_component.dart';
import '../controllers/aim_controller.dart';

/// 瞄准设置页面
class AimScreen extends StatelessWidget {
  const AimScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 使用Consumer<AimController>替代Provider.of获取AimController
    return Consumer<AimController>(
      builder: (context, controller, child) {
        return Scaffold(
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部标题栏和按钮
                _buildHeader(controller, context),
                
                const SizedBox(height: 16),
                
                // 页面内容描述
                const GFCard(
                  color: Colors.white,
                  content: Text(
                    '瞄准参数设置，调整游戏射击时的自动瞄准区域和范围。不同的参数会影响瞄准的精准度和效果。',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 瞄准参数调整区域
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildAllAimSliders(controller, context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建顶部标题和按钮
  Widget _buildHeader(AimController controller, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 页面标题
        const Text(
          '瞄准设置',
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
              onPressed: () => controller.requestAimParams(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              color: GFColors.INFO,
              size: GFSize.SMALL,
              shape: GFIconButtonShape.circle,
              tooltip: '刷新参数',
            ),
            
            const SizedBox(width: 12),
            
            // 保存按钮
            GFButton(
              onPressed: () => controller.saveAimConfig(context),
              text: '保存',
              icon: const Icon(Icons.save, color: Colors.white),
              color: GFColors.PRIMARY,
              size: GFSize.MEDIUM,
              shape: GFButtonShape.standard,
            ),
          ],
        ),
      ],
    );
  }

  /// 创建所有瞄准参数的滑块组
  Widget _buildAllAimSliders(AimController controller, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 基于屏幕宽度确定布局方式
        bool isWideScreen = constraints.maxWidth > 768;
        
        // 瞄准范围参数组
        Widget aimRangeCard = buildMultiSliderCard(
          title: '瞄准范围参数',
          labels: ['瞄准范围', '跟踪范围'],
          values: [
            controller.aimRange, 
            controller.trackRange,
          ],
          onChangedCallbacks: [
            (value) => controller.aimRange = value,
            (value) => controller.trackRange = value,
          ],
          onChangeEndCallbacks: [
            (_) => controller.handleParameterChanged('aimRange', controller.aimRange, context),
            (_) => controller.handleParameterChanged('trackRange', controller.trackRange, context),
          ],
          mins: [0.0, 0.001],
          maxs: [416.0, 15.0],
          decimalPlaces: 1,
        );
        
        // 身体部位高度参数组
        Widget bodyHeightCard = buildMultiSliderCard(
          title: '身体部位高度',
          labels: ['头部高度', '颈部高度', '胸部高度'],
          values: [
            controller.headHeight, 
            controller.neckHeight, 
            controller.chestHeight,
          ],
          onChangedCallbacks: [
            (value) => controller.headHeight = value,
            (value) => controller.neckHeight = value,
            (value) => controller.chestHeight = value,
          ],
          onChangeEndCallbacks: [
            (_) => controller.handleParameterChanged('headHeight', controller.headHeight, context),
            (_) => controller.handleParameterChanged('neckHeight', controller.neckHeight, context),
            (_) => controller.handleParameterChanged('chestHeight', controller.chestHeight, context),
          ],
          mins: [0.0, 0.0, 0.0],
          maxs: [200.0, 200.0, 200.0],
          decimalPlaces: 2,
        );
        
        // 头部范围参数组
        Widget headRangeCard = buildMultiSliderCard(
          title: '头部范围',
          labels: ['头部X范围', '头部Y范围'],
          values: [
            controller.headRangeX, 
            controller.headRangeY,
          ],
          onChangedCallbacks: [
            (value) => controller.headRangeX = value,
            (value) => controller.headRangeY = value,
          ],
          onChangeEndCallbacks: [
            (_) => controller.handleParameterChanged('headRangeX', controller.headRangeX, context),
            (_) => controller.handleParameterChanged('headRangeY', controller.headRangeY, context),
          ],
          mins: [0.00, 0.00],
          maxs: [300.0, 300.0],
          decimalPlaces: 3,
        );
        
        // 颈部和胸部范围参数组
        Widget neckChestRangeCard = buildMultiSliderCard(
          title: '颈部和胸部范围',
          labels: [
            '颈部X范围', '颈部Y范围',
            '胸部X范围', '胸部Y范围'
          ],
          values: [
            controller.neckRangeX, 
            controller.neckRangeY,
            controller.chestRangeX, 
            controller.chestRangeY
          ],
          onChangedCallbacks: [
            (value) => controller.neckRangeX = value,
            (value) => controller.neckRangeY = value,
            (value) => controller.chestRangeX = value,
            (value) => controller.chestRangeY = value,
          ],
          onChangeEndCallbacks: [
            (_) => controller.handleParameterChanged('neckRangeX', controller.neckRangeX, context),
            (_) => controller.handleParameterChanged('neckRangeY', controller.neckRangeY, context),
            (_) => controller.handleParameterChanged('chestRangeX', controller.chestRangeX, context),
            (_) => controller.handleParameterChanged('chestRangeY', controller.chestRangeY, context),
          ],
          mins: [0.0, 0.0, 0.0, 0.0],
          maxs: [5.0, 5.0, 5.0, 5.0],
          decimalPlaces: 2,
        );
        
        // 根据屏幕宽度选择布局方式
        return Column(
          children: [
            // 第一行卡片
            isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: aimRangeCard),
                      const SizedBox(width: 16),
                      Expanded(child: bodyHeightCard),
                    ],
                  )
                : Column(
                    children: [
                      aimRangeCard,
                      const SizedBox(height: 16),
                      bodyHeightCard,
                    ],
                  ),
            
            const SizedBox(height: 16),
            
            // 第二行卡片
            isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: headRangeCard),
                      const SizedBox(width: 16),
                      Expanded(child: neckChestRangeCard),
                    ],
                  )
                : Column(
                    children: [
                      headRangeCard,
                      const SizedBox(height: 16),
                      neckChestRangeCard,
                    ],
                  ),
            
            const SizedBox(height: 20),
            
            // 重置按钮
            Center(
              child: GFButton(
                onPressed: () => controller.resetToDefaults(context),
                text: '恢复默认值',
                icon: const Icon(Icons.restore, color: Colors.white),
                color: GFColors.SECONDARY,
                size: GFSize.MEDIUM,
                shape: GFButtonShape.standard,
              ),
            ),
          ],
        );
      },
    );
  }
} 