// ignore_for_file: use_super_parameters, library_private_types_in_public_api, unused_import

import 'package:flutter/material.dart';
import '../controllers/fov_controller.dart';
import '../models/game_model.dart';
import '../models/auth_model.dart';
import 'package:provider/provider.dart';
import 'package:getwidget/getwidget.dart';
import '../component/message_component.dart';

/// FOV设置屏幕 - 负责FOV参数调整的UI
class FovScreen extends StatefulWidget {
  const FovScreen({super.key});

  @override
  State<FovScreen> createState() => _FovScreenState();
}

class _FovScreenState extends State<FovScreen> {
  // 添加文本控制器
  final TextEditingController _fovInputController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // 延迟执行确保在构建完成后
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 刷新数据
      _refreshFovSettings();
    });
  }
  
  // 刷新FOV设置数据
  void _refreshFovSettings() {
    final gameModel = Provider.of<GameModel>(context, listen: false);
    final fovController = Provider.of<FovController>(context, listen: false);
    
    // 如果游戏名称与控制器中的不一致，强制触发控制器同步
    if (gameModel.currentGame != fovController.gameName) {
      fovController.handleGameChanged(gameModel.currentGame);
    } else {
      fovController.refreshFovConfig();
    }
    
    // 显示刷新提示
    MessageComponent.showIconToast(
      context: context,
      message: '正在刷新视野设置...',
      type: MessageType.info,
      duration: const Duration(seconds: 1),
    );
  }
  
  @override
  void dispose() {
    _fovInputController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // 使用Consumer同时监听GameModel变化和FovController变化
    return Consumer2<GameModel, FovController>(
      builder: (context, gameModel, fovController, child) {
        return Scaffold(
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部标题栏和按钮
                _buildHeader(gameModel, fovController, context),
                
                const SizedBox(height: 16),
                
                // 页面内容描述
                const GFCard(
                  color: Colors.white,
                  content: Text(
                    '视野范围和切换时间调整，修改FOV参数以获得最佳游戏体验。',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 滚动内容区域
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildAllFovSliders(context, fovController),
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
  Widget _buildHeader(GameModel gameModel, FovController controller, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 页面标题
        Text(
          '视野设置 - ${gameModel.currentGame}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // 按钮组
        Row(
          children: [
            // 刷新按钮
            GFIconButton(
              onPressed: _refreshFovSettings,
              icon: const Icon(Icons.refresh, color: Colors.white),
              color: GFColors.INFO,
              size: GFSize.SMALL,
              shape: GFIconButtonShape.circle,
              tooltip: '刷新FOV设置',
            ),
            
            const SizedBox(width: 12),
            
            // 保存按钮
            GFButton(
              onPressed: () => controller.saveFovConfig(context),
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

  /// 构建所有FOV相关的滑块
  Widget _buildAllFovSliders(BuildContext context, FovController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOV值
            const Text('FOV值', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('调整游戏中相机的视野范围，较大的值可以看到更多区域。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            
            // 使用文本标签显示FOV值
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Text(
                    '${controller.fov.toStringAsFixed(2)}°',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'FOV时间: ${controller.fovTime}ms',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // 自定义FOV值输入框
            const SizedBox(height: 10),
            const Text('自定义FOV值', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fovInputController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '输入FOV值',
                      suffixText: '°',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(_fovInputController.text);
                    if (value != null) {
                      controller.fov = value;
                      controller.handleParameterChanged('fov', value, context);
                      _fovInputController.clear();
                    } else {
                      MessageComponent.showIconToast(
                        context: context,
                        message: '请输入有效的数值',
                        type: MessageType.error,
                      );
                    }
                  },
                  child: const Text('应用'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // FOV时间滑块
            const Text('FOV时间', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('调整视野变化的过渡时间，以毫秒为单位。较低的值切换更快，较高的值过渡更平滑。', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 0.0,
                    max: 1000.0,
                    divisions: 1000,
                    value: controller.fovTime.toDouble(),
                    onChanged: (value) {
                      // 实时更新控制器中的值
                      controller.fovTime = value.toInt();
                    },
                    onChangeEnd: (value) {
                      // 滑块结束时触发保存
                      controller.handleParameterChanged('fovTime', value, context);
                    },
                  ),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: Text(
                    '${controller.fovTime}ms',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 添加开始测量按钮
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始测量'),
                onPressed: () {
                  // 添加确认对话框
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('确认开始FOV测量'),
                        content: const Text(
                          '测量过程中游戏画面会有明显变化，请确保您已做好准备。\n\n'
                          '点击"确认开始"继续测量操作。'
                        ),
                        actions: [
                          TextButton(
                            child: const Text('取消'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('确认开始'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              controller.startFovMeasurement(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
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
        ),
      ),
    );
  }
} 