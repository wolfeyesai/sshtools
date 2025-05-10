// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import '../controllers/pid_controller.dart';
import 'package:provider/provider.dart';
import 'package:getwidget/getwidget.dart';
import '../component/Slider_component.dart';

/// 近端瞄准控制设置屏幕 - 负责近端瞄准辅助参数调整的UI
class PidScreen extends StatelessWidget {
  const PidScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 使用Consumer获取PidController并监听其变化
    return Consumer<PidController>(
      builder: (context, pidController, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12), // 减小整体内边距
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部标题栏和按钮
                _buildHeader(pidController, context),
                
                const SizedBox(height: 10), // 减小顶部与说明卡片的间距
                
                // 页面内容描述
                const GFCard(
                  margin: EdgeInsets.symmetric(vertical: 4.0), // 减小卡片外部垂直间距
                  padding: EdgeInsets.all(8.0), // 减小卡片内部填充
                  color: Colors.white,
                  content: Text(
                    '调整游戏中的瞄准辅助参数。不同的参数将影响瞄准时的灵敏度、稳定性和响应速度，找到最适合你的设置。',
                    style: TextStyle(fontSize: 14), // 减小字体大小
                  ),
                ),
                
                const SizedBox(height: 8), // 减小说明卡片与参数区域的间距
                
                // 近端瞄准参数调整区域
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildAllAimSliders(pidController, context),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  /// 构建顶部标题和按钮
  Widget _buildHeader(PidController controller, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 页面标题
        const Text(
          'PID设置',
          style: TextStyle(
            fontSize: 22, // 稍微减小字体大小
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // 按钮组
        Row(
          children: [
            // 刷新按钮
            GFIconButton(
              onPressed: () => controller.requestPidParams(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              color: GFColors.INFO,
              size: GFSize.SMALL,
              shape: GFIconButtonShape.circle,
              tooltip: '刷新参数',
            ),
            
            const SizedBox(width: 10), // 减小按钮间距
            
            // 保存按钮
            GFButton(
              onPressed: () => controller.savePidConfig(context),
              text: '保存',
              icon: const Icon(Icons.save, color: Colors.white),
              color: GFColors.PRIMARY,
              size: GFSize.SMALL, // 使用小一点的按钮
              shape: GFButtonShape.standard,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建所有近端瞄准相关的滑块
  Widget _buildAllAimSliders(PidController controller, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 基于屏幕宽度确定布局方式
        final bool isWideScreen = constraints.maxWidth > 768;
        
        // 定义参数组 - 移动控制
        final moveParams = _ParamGroup(
          title: '移动控制参数',
          labels: const ['近端移动速度', '近端跟踪速度', '近端抖动力度'],
          values: [
            controller.nearMoveFactor, 
            controller.nearStabilizer,
            controller.nearResponseRate,
          ],
          onChangedCallbacks: [
            (value) => controller.nearMoveFactor = value,
            (value) => controller.nearStabilizer = value,
            (value) => controller.nearResponseRate = value,
          ],
          onChangeEndCallbacks: [
            (_) => controller.handleParameterChanged('nearMoveFactor', controller.nearMoveFactor, context),
            (_) => controller.handleParameterChanged('nearStabilizer', controller.nearStabilizer, context),
            (_) => controller.handleParameterChanged('nearResponseRate', controller.nearResponseRate, context),
          ],
          mins: const [0.0, 0.0, 0.0],
          maxs: const [2.0, 5.0, 5.0],
        );
        
        // 定义参数组 - 精度控制
        final precisionParams = _ParamGroup(
          title: '精度控制参数',
          labels: const ['近端死区大小', '近端回弹速度', '近端积分限制', '远端系数'],
          values: [
            controller.nearAssistZone, 
            controller.nearResponseDelay,
            controller.nearMaxAdjustment,
            controller.farFactor,
          ],
          onChangedCallbacks: [
            (value) => controller.nearAssistZone = value,
            (value) => controller.nearResponseDelay = value,
            (value) => controller.nearMaxAdjustment = value,
            (value) => controller.farFactor = value,
          ],
          onChangeEndCallbacks: [
            (_) => controller.handleParameterChanged('nearAssistZone', controller.nearAssistZone, context),
            (_) => controller.handleParameterChanged('nearResponseDelay', controller.nearResponseDelay, context),
            (_) => controller.handleParameterChanged('nearMaxAdjustment', controller.nearMaxAdjustment, context),
            (_) => controller.handleParameterChanged('farFactor', controller.farFactor, context),
          ],
          mins: const [0.0, 0.0, 0.0, 0.0],
          maxs: const [10.0, 2.0, 200.0, 2.0],
          suffixes: const [null, null, null, null],
        );
        
        // 构建参数卡片
        final Widget moveControlCard = _buildParameterCard(context, moveParams);
        final Widget precisionControlCard = _buildParameterCard(context, precisionParams);
        
        // 根据屏幕宽度选择布局方式
        return Column(
          children: [
            // 卡片布局
            if (isWideScreen)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: moveControlCard),
                  const SizedBox(width: 8), // 减小卡片之间的横向间距
                  Expanded(child: precisionControlCard),
                ],
              )
            else
              Column(
                children: [
                  moveControlCard,
                  const SizedBox(height: 8), // 减小卡片之间的纵向间距
                  precisionControlCard,
                ],
              ),
            
            const SizedBox(height: 10), // 减小卡片与底部按钮的间距
            
            // 重置按钮
            Center(
              child: GFButton(
                onPressed: () => controller.resetToDefaults(context),
                text: '恢复默认值',
                icon: const Icon(Icons.restore, color: Colors.white),
                color: GFColors.SECONDARY,
                size: GFSize.SMALL, // 使用小一点的按钮
                shape: GFButtonShape.standard,
              ),
            ),
          ],
        );
      }
    );
  }
  
  /// 构建参数卡片 - 统一处理所有参数卡片的创建
  Widget _buildParameterCard(BuildContext context, _ParamGroup params) {
    return buildMultiSliderCard(
      title: params.title,
      labels: params.labels,
      values: params.values,
      onChangedCallbacks: params.onChangedCallbacks,
      onChangeEndCallbacks: params.onChangeEndCallbacks,
      mins: params.mins,
      maxs: params.maxs,
      decimalPlaces: 2,
      suffixes: params.suffixes,
    );
  }
}

/// 参数组数据类，用于组织参数渲染
class _ParamGroup {
  final String title;
  final List<String> labels;
  final List<double> values;
  final List<ValueChanged<double>> onChangedCallbacks;
  final List<ValueChanged<double>?> onChangeEndCallbacks;
  final List<double> mins;
  final List<double> maxs;
  final List<String?>? suffixes;
  
  const _ParamGroup({
    required this.title,
    required this.labels,
    required this.values,
    required this.onChangedCallbacks,
    required this.onChangeEndCallbacks,
    required this.mins,
    required this.maxs,
    this.suffixes,
  });
} 