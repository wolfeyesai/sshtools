// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import '../controllers/fire_controller.dart';
import 'package:provider/provider.dart';

/// 射击设置屏幕
class FireScreen extends StatefulWidget {
  const FireScreen({super.key});

  @override
  State<FireScreen> createState() => _FireScreenState();
}

class _FireScreenState extends State<FireScreen> {
  @override
  Widget build(BuildContext context) {
    // 使用Consumer获取FireController并监听其变化
    return Consumer<FireController>(
      builder: (context, fireController, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('射击设置'),
            actions: [
              // 保存按钮
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => fireController.saveFireConfig(context),
                tooltip: '保存设置',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和说明
                const Text(
                  '射击参数设置',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '调整射击速度、延迟和控制参数，优化游戏中的射击表现。',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                
                // 射击参数卡片
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('基本射击参数', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        // 射击速度滑块
                        _buildParameterSlider(
                          label: '射击速度',
                          description: '控制射击的速度，越大射击越快。',
                          value: fireController.fireSpeed,
                          min: 0.01,
                          max: 1.0,
                          divisions: 99,
                          onChanged: (value) => fireController.fireSpeed = value,
                          onChangeEnd: (value) => fireController.handleParameterChanged('fireSpeed', value, context),
                          valueDisplay: fireController.fireSpeed.toStringAsFixed(2),
                        ),
                        
                        // 射击延迟滑块
                        _buildParameterSlider(
                          label: '射击延迟',
                          description: '控制射击间的延迟时间，越小射击越连贯。',
                          value: fireController.fireDelay.toDouble(),
                          min: 10.0,
                          max: 500.0,
                          divisions: 49,
                          onChanged: (value) => fireController.fireDelay = value.toInt(),
                          onChangeEnd: (value) => fireController.handleParameterChanged('fireDelay', value, context),
                          valueDisplay: '${fireController.fireDelay} ms',
                        ),
                        
                        // 后坐力控制滑块
                        _buildParameterSlider(
                          label: '后坐力控制',
                          description: '控制射击时后坐力的抑制程度，越大控制越强。',
                          value: fireController.recoilControl,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: (value) => fireController.recoilControl = value,
                          onChangeEnd: (value) => fireController.handleParameterChanged('recoilControl', value, context),
                          valueDisplay: fireController.recoilControl.toStringAsFixed(2),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 射击模式卡片
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('射击模式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        // 自动射击开关
                        SwitchListTile(
                          title: const Text('自动射击'),
                          subtitle: const Text('启用后，瞄准时自动开火'),
                          value: fireController.autoFire,
                          onChanged: (value) {
                            fireController.autoFire = value;
                            fireController.handleParameterChanged('autoFire', value, context);
                          },
                        ),
                        
                        // 连发数量滑块 (只在自动射击开启时可用)
                        if (fireController.autoFire)
                          _buildParameterSlider(
                            label: '连发数量',
                            description: '自动射击时的连发数量，0表示持续射击直到松开按键。',
                            value: fireController.burstCount.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            onChanged: (value) => fireController.burstCount = value.toInt(),
                            onChangeEnd: (value) => fireController.handleParameterChanged('burstCount', value, context),
                            valueDisplay: fireController.burstCount == 0 ? '持续' : '${fireController.burstCount}发',
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // 重置按钮
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('重置为默认值'),
                    onPressed: () => fireController.resetToDefaults(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  /// 构建单个参数的滑块控件
  Widget _buildParameterSlider({
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
    required String valueDisplay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            Expanded(
              child: Slider(
                min: min,
                max: max,
                divisions: divisions,
                value: value,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Text(
                valueDisplay,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
} 