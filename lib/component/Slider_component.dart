// ignore_for_file: deprecated_member_use, use_super_parameters, unused_import, file_names, dead_code, sized_box_for_whitespace, unnecessary_import, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'package:getwidget/getwidget.dart';
import 'dart:async';

/// 计算10的幂
/// 用于精确计算滑块步进值
int pow10(int exponent) {
  int result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

/// 基于指定小数位数创建精确的步进值
/// 例如：小数位为2时，步进值为0.01
/// 这对于PID控制参数的精细调整非常重要
double createStepValue(int decimalPlaces) {
  final factor = pow10(decimalPlaces);
  return 1.0 / factor;
}

/// 自定义滑块设置类，处理滑块的各种属性和精确值计算
/// 专为PID控制器参数调整设计，确保参数调整的精确性和一致性
class SliderSetting {
  /// 滑块标签 - 显示参数名称（如移动速度、跟踪速度等）
  final String label;
  
  /// 当前值 - 参数的当前设置值
  final double value;
  
  /// 最小值 - 参数允许的最小值
  final double min;
  
  /// 最大值 - 参数允许的最大值
  final double max;
  
  /// 滑块步进值 - 控制滑块调整的精度
  /// 对于PID参数，通常需要较高精度（如0.001-0.01）
  final double stepValue;
  
  /// 按钮步进值，更精细的步长控制
  /// 允许通过按钮进行比滑块更精确的微调
  final double buttonStepValue;
  
  /// 总步数 - 滑块从最小值到最大值的总步数
  /// 影响滑块的精度和平滑度
  final int totalSteps;
  
  /// 值更改回调 - 当值变化时实时更新PID控制器参数
  final ValueChanged<double> onChanged;
  
  /// 值更改结束回调 - 当用户完成调整后保存参数
  final ValueChanged<double>? onChangeEnd;
  
  /// 显示的小数位数 - 控制显示和计算的精度
  /// PID控制参数通常需要2-3位小数精度
  final int decimalPlaces;
  
  /// 单位后缀 - 如帧、系数等
  final String? suffix;
  
  /// 构造函数
  const SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.stepValue,
    this.buttonStepValue = 0.0, // 默认和stepValue相同
    required this.totalSteps,
    required this.onChanged,
    this.onChangeEnd,
    required this.decimalPlaces,
    this.suffix,
  });
  
  /// 获取当前值的格式化文本
  /// 用于在UI中显示精确的参数值
  String get formattedValue => formatValue(value);
  
  /// 获取指定值的格式化文本
  /// 确保显示的值精确到指定小数位
  String formatValue(double val) {
    String text = val.toStringAsFixed(decimalPlaces);
    if (suffix != null && suffix!.isNotEmpty) {
      text += ' $suffix';
    }
    return text;
  }
  
  /// 基于步数计算精确值
  /// 将滑块位置（步数）转换为实际的PID参数值
  /// 确保转换过程中不会因浮点精度问题而失真
  double valueFromStep(int step) {
    // 确保步数在有效范围内
    final validStep = math.min(math.max(0, step), totalSteps);
    
    // 使用精确的因子方法计算值
    final range = max - min;
    final exactValue = min + (validStep / totalSteps) * range;
    
    // 格式化确保符合精度要求
    return double.parse(exactValue.toStringAsFixed(decimalPlaces));
  }

  /// 基于给定值获取最接近的步数
  /// 将实际PID参数值转换回滑块位置（步数）
  int stepFromValue(double value) {
    // 处理边界情况
    if (value <= min) return 0;
    if (value >= max) return totalSteps;
    
    // 计算当前值占总范围的比例
    final range = max - min;
    final proportion = (value - min) / range;
    
    // 将比例转换为步数
    final step = (proportion * totalSteps).round();
    
    // 确保步数在有效范围内
    return math.min(math.max(0, step), totalSteps);
  }
  
  /// 增加值一个步进（按钮使用）
  /// 用于微调PID参数，每次精确增加一个步进值
  double increaseValue(double currentValue) {
    // 使用按钮步进值，如果未指定则使用普通步进值
    final realStepValue = buttonStepValue > 0 ? buttonStepValue : stepValue;
    
    // 精确的增量计算，避免浮点数精度问题
    final newValue = (currentValue * 1000 + realStepValue * 1000) / 1000;
    
    // 确保不超出最大值，同时保持精度
    return math.min(double.parse(newValue.toStringAsFixed(decimalPlaces)), max);
  }
  
  /// 减少值一个步进（按钮使用）
  /// 用于微调PID参数，每次精确减少一个步进值
  double decreaseValue(double currentValue) {
    // 使用按钮步进值，如果未指定则使用普通步进值
    final realStepValue = buttonStepValue > 0 ? buttonStepValue : stepValue;
    
    // 精确的减量计算，避免浮点数精度问题
    final newValue = (currentValue * 1000 - realStepValue * 1000) / 1000;
    
    // 确保不低于最小值，同时保持精度
    return math.max(double.parse(newValue.toStringAsFixed(decimalPlaces)), min);
  }
}

/// 带有长按重复功能的自定义按钮
class _LongPressButton extends StatefulWidget {
  final IconData icon;
  final bool isPressed;
  final VoidCallback onPressed;
  final VoidCallback onOperationEnd;  // 添加操作结束回调

  const _LongPressButton({
    Key? key,
    required this.icon,
    required this.isPressed,
    required this.onPressed,
    required this.onOperationEnd,
  }) : super(key: key);

  @override
  State<_LongPressButton> createState() => _LongPressButtonState();
}

class _LongPressButtonState extends State<_LongPressButton> {
  Timer? _timer;
  int _accelerationCounter = 0;
  bool _isOperating = false;
  
  // 开始长按时的调用函数
  void _startRepeating() {
    // 先停止可能已经存在的计时器
    _stopRepeating();
    
    // 标记开始操作
    _isOperating = true;
    
    // 先立即执行一次
    widget.onPressed();
    
    // 设置一个初始延迟较短的计时器
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      widget.onPressed();
      _accelerationCounter++;
      
      // 随着长按持续，更快加速
      if (_accelerationCounter == 2) {
        _stopRepeating();
        _timer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
          widget.onPressed();
        });
      }
    });
  }
  
  // 停止长按重复调用
  void _stopRepeating() {
    _timer?.cancel();
    _timer = null;
    _accelerationCounter = 0;
  }
  
  // 结束操作，触发onOperationEnd回调
  void _finishOperation() {
    _stopRepeating();
    
    // 如果确实进行了操作，触发结束回调
    if (_isOperating) {
      widget.onOperationEnd();
    }
    
    _isOperating = false;
  }
  
  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {}, // 长按开始时什么都不做，由onLongPressStart处理
      onLongPressStart: (_) => _startRepeating(),
      onLongPressEnd: (_) => _finishOperation(),
      onLongPressCancel: () => _finishOperation(),
      onTap: () {
        // 单击也应该标记为操作
        _isOperating = true;
        widget.onPressed();
        _finishOperation();
      },
      child: GFIconButton(
        onPressed: widget.onPressed,
        icon: Icon(
          widget.icon,
          size: 18,
          color: Colors.white,
        ),
        type: GFButtonType.solid,
        shape: GFIconButtonShape.standard,
        size: GFSize.SMALL,
        color: widget.isPressed ? GFColors.PRIMARY.withOpacity(0.7) : GFColors.PRIMARY,
        boxShadow: BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ),
    );
  }
}

/// 构建加减按钮
/// 用于PID参数的精细调整，比滑块更精确
Widget _buildStepperButton({
  required IconData icon,
  required bool isPressed,
  required VoidCallback onPressed,
  required VoidCallback onOperationEnd,
}) {
  return _LongPressButton(
    icon: icon,
    isPressed: isPressed,
    onPressed: onPressed,
    onOperationEnd: onOperationEnd,
  );
}

/// 创建带加减按钮的滑块组件
/// 
/// 包含标签、加减按钮和滑块，集成了数值显示
/// 专为PID控制系统参数调整设计，确保高精度和易用性
Widget buildSliderWithButtons(SliderSetting setting) {
  return StatefulBuilder(
    builder: (context, setState) {
      // 初始化值和状态
      int currentStep = setting.stepFromValue(setting.value);
      double displayValue = setting.valueFromStep(currentStep);
      bool decreaseButtonPressed = false;
      bool increaseButtonPressed = false;
      
      // 防止并发更新的锁
      bool _isUpdating = false;
      
      // 减少值的安全函数（不触发保存）
      void safeDecreaseValue() {
        if (_isUpdating) return; // 如果正在更新，忽略此次调用
        _isUpdating = true;
        
        // 设置按钮视觉反馈
        setState(() => decreaseButtonPressed = true);
        
        // 计算新值，确保精度
        final newValue = setting.decreaseValue(displayValue);
        
        // 更新状态
        setState(() {
          currentStep = setting.stepFromValue(newValue);
          displayValue = newValue;
          decreaseButtonPressed = false;
        });
        
        // 只调用onChanged回调，更新控制器中的参数，但不触发保存
        setting.onChanged(newValue);
        
        // 解锁，允许下一次更新
        _isUpdating = false;
      }
      
      // 增加值的安全函数（不触发保存）
      void safeIncreaseValue() {
        if (_isUpdating) return; // 如果正在更新，忽略此次调用
        _isUpdating = true;
        
        // 设置按钮视觉反馈
        setState(() => increaseButtonPressed = true);
        
        // 计算新值，确保精度
        final newValue = setting.increaseValue(displayValue);
        
        // 更新状态
        setState(() {
          currentStep = setting.stepFromValue(newValue);
          displayValue = newValue;
          increaseButtonPressed = false;
        });
        
        // 只调用onChanged回调，更新控制器中的参数，但不触发保存
        setting.onChanged(newValue);
        
        // 解锁，允许下一次更新
        _isUpdating = false;
      }
      
      // 操作结束时触发保存
      void triggerSave() {
        if (setting.onChangeEnd != null) {
          setting.onChangeEnd!(displayValue);
        }
      }
      
      return GFCard(
        margin: const EdgeInsets.symmetric(vertical: 4.0), // 减小卡片外部垂直间距
        padding: const EdgeInsets.all(8.0), // 减小卡片内部填充
        boxFit: BoxFit.cover,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标签和加减按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 参数标签（如：移动速度、跟踪速度等）
                Expanded(
                  flex: 3,
                  child: GFTypography(
                    text: setting.label,
                    type: GFTypographyType.typo4,
                    showDivider: false,
                  ),
                ),
            
                // 加减按钮组 - 用于精细调整PID参数
                Row(
                  children: [
                    // 减按钮 - 精确减少一个步进值
                    _buildStepperButton(
                      icon: Icons.remove,
                      isPressed: decreaseButtonPressed,
                      onPressed: safeDecreaseValue,
                      onOperationEnd: triggerSave,
                    ),
                    
                    // 数值显示 - 展示当前参数的精确值
                    Container(
                      width: 70,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: GFColors.LIGHT),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        setting.formatValue(displayValue),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: GFColors.PRIMARY,
                        ),
                      ),
                    ),
                    
                    // 加按钮 - 精确增加一个步进值
                    _buildStepperButton(
                      icon: Icons.add,
                      isPressed: increaseButtonPressed,
                      onPressed: safeIncreaseValue,
                      onOperationEnd: triggerSave,
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8.0), // 减小标签与滑块之间的间距
            
            // 滑块部分 - 用于快速大范围调整参数
            Row(
              children: [
                // 最小值标签
                SizedBox(
                  width: 40,
                  child: GFTypography(
                    text: setting.min.toStringAsFixed(setting.decimalPlaces),
                    type: GFTypographyType.typo6,
                    showDivider: false,
                  ),
                ),
                
                // 滑块 - 主要调整控件
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4.0,
                        activeTrackColor: GFColors.PRIMARY,
                        inactiveTrackColor: GFColors.LIGHT,
                        thumbColor: GFColors.PRIMARY,
                        overlayColor: GFColors.PRIMARY.withOpacity(0.2),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
                        showValueIndicator: ShowValueIndicator.never,
                        trackShape: const RoundedRectSliderTrackShape(),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10.0,
                          pressedElevation: 4.0,
                        ),
                      ),
                      child: Slider(
                        value: currentStep.toDouble(),
                        min: 0,
                        max: setting.totalSteps.toDouble(),
                        divisions: setting.totalSteps,
                        mouseCursor: SystemMouseCursors.click,
                        onChanged: (sliderValue) {
                          // 如果正在更新，忽略此次拖动事件
                          if (_isUpdating) return;
                          _isUpdating = true;
                          
                          // 滑块值直接使用整数步数，避免浮点数精度问题
                          final step = sliderValue.round();
                          
                          // 从步数计算精确的对应值
                          final newValue = setting.valueFromStep(step);
                          
                          // 更新UI显示
                          setState(() {
                            currentStep = step;
                            displayValue = newValue;
                          });
                          
                          // 回调更新控制器中的参数 (只在拖动中，不触发保存)
                          setting.onChanged(newValue);
                          
                          // 设置一个短延迟以允许UI更新完成
                          Future.microtask(() {
                            _isUpdating = false;
                          });
                        },
                        onChangeEnd: (sliderValue) {
                          // 在滑块拖动结束时才触发保存
                          if (setting.onChangeEnd != null) {
                            final step = sliderValue.round();
                            final newValue = setting.valueFromStep(step);
                            setting.onChangeEnd!(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                
                // 最大值标签
                SizedBox(
                  width: 40,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GFTypography(
                      text: setting.max.toStringAsFixed(setting.decimalPlaces),
                      type: GFTypographyType.typo6,
                      showDivider: false,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// 创建参数滑块控件
/// 
/// 包含参数标签、加减按钮和滑块
/// 
/// 参数:
/// - [label] 参数标签
/// - [value] 当前值
/// - [min] 最小值
/// - [max] 最大值
/// - [onChanged] 值改变回调
/// - [onChangeEnd] 值改变结束回调
/// - [decimalPlaces] 小数位数
/// - [suffix] 单位后缀
Widget buildParameterSlider({
  required String label,
  required double value,
  required double min,
  required double max,
  required ValueChanged<double> onChanged,
  ValueChanged<double>? onChangeEnd,
  required int decimalPlaces,
  String? suffix,
}) {
  // 基于小数位数创建精确的步进值
  final stepValue = createStepValue(decimalPlaces);
  
  // 确保最小值和最大值符合精度要求
  final adjustedMin = double.parse(min.toStringAsFixed(decimalPlaces));
  final adjustedMax = double.parse(max.toStringAsFixed(decimalPlaces));
  
  // 计算总步数（精确计算，确保步数是整数）
  final factor = pow10(decimalPlaces);
  final totalSteps = ((adjustedMax - adjustedMin) * factor).round();
  
  // 处理初始值，确保符合精度要求
  final initialValue = math.min(
    math.max(
      double.parse(value.toStringAsFixed(decimalPlaces)),
      adjustedMin
    ),
    adjustedMax
  );
  
  // 创建滑块设置对象
  final setting = SliderSetting(
    label: label,
    value: initialValue,
    min: adjustedMin,
    max: adjustedMax,
    stepValue: stepValue,
    totalSteps: totalSteps,
    onChanged: onChanged,
    onChangeEnd: onChangeEnd,
    decimalPlaces: decimalPlaces,
    suffix: suffix,
  );
  
  // 构建带按钮的滑块
  return buildSliderWithButtons(setting);
}

// 为了保持API兼容性，buildSlider函数现在直接调用buildSliderWithButtons
Widget buildSlider(SliderSetting setting) {
  return buildSliderWithButtons(setting);
}

/// 批量创建多个参数滑块
/// 
/// 根据参数列表快速创建多个滑块控件
/// 
/// 参数:
/// - [labels] 参数标签列表
/// - [values] 当前值列表
/// - [onChangedCallbacks] 值变化回调函数列表
/// - [onChangeEndCallbacks] 值变化结束回调函数列表(可选)
/// - [mins] 最小值列表(默认都为0.0)
/// - [maxs] 最大值列表(默认都为10.0)
/// - [decimalPlaces] 小数位数(适用于所有滑块)
/// - [suffixes] 后缀列表(可选)
/// - [spacing] 滑块之间的间距
List<Widget> buildParameterSliders({
  required List<String> labels,
  required List<double> values,
  required List<ValueChanged<double>> onChangedCallbacks,
  List<ValueChanged<double>?>? onChangeEndCallbacks,
  List<double>? mins,
  List<double>? maxs,
  required int decimalPlaces,
  List<String?>? suffixes,
  double spacing = 4.0, // 减小默认间距
}) {
  // 验证参数长度一致
  assert(labels.length == values.length && labels.length == onChangedCallbacks.length, 
    '参数名称、值和回调函数数量必须一致');
  
  if (onChangeEndCallbacks != null) {
    assert(labels.length == onChangeEndCallbacks.length, '参数名称和结束回调函数数量必须一致');
  }
  
  if (mins != null) {
    assert(labels.length == mins.length, '参数名称和最小值数量必须一致');
  }
  
  if (maxs != null) {
    assert(labels.length == maxs.length, '参数名称和最大值数量必须一致');
  }
  
  if (suffixes != null) {
    assert(labels.length == suffixes.length, '参数名称和后缀数量必须一致');
  }
  
  // 创建参数滑块列表
  final List<Widget> sliders = [];
  
  for (int i = 0; i < labels.length; i++) {
    sliders.add(
      buildParameterSlider(
        label: labels[i],
        value: values[i],
        min: mins != null ? mins[i] : 0.0,
        max: maxs != null ? maxs[i] : 10.0,
        onChanged: onChangedCallbacks[i],
        onChangeEnd: onChangeEndCallbacks != null ? onChangeEndCallbacks[i] : null,
        decimalPlaces: decimalPlaces,
        suffix: suffixes != null ? suffixes[i] : null,
      )
    );
    
    // 如果不是最后一个，添加间距
    if (i < labels.length - 1) {
      sliders.add(SizedBox(height: spacing));
    }
  }
  
  return sliders;
}

/// 多滑块组合控件
/// 将多个PID相关参数滑块组合在一个包含标题的卡片中
/// 例如：将移动控制参数(移动速度、跟踪速度、抖动力度)组合在一起
Widget buildMultiSliderCard({
  required String title,
  required List<String> labels,
  required List<double> values,
  required List<ValueChanged<double>> onChangedCallbacks,
  List<ValueChanged<double>?>? onChangeEndCallbacks,
  List<double>? mins,
  List<double>? maxs,
  required int decimalPlaces,
  List<String?>? suffixes,
  Color? backgroundColor,
  double elevation = 2.0,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // 获取滑块列表
      final sliders = buildParameterSliders(
        labels: labels,
        values: values,
        onChangedCallbacks: onChangedCallbacks,
        onChangeEndCallbacks: onChangeEndCallbacks,
        mins: mins,
        maxs: maxs,
        decimalPlaces: decimalPlaces,
        suffixes: suffixes,
      );

      return GFCard(
        boxFit: BoxFit.cover,
        margin: const EdgeInsets.symmetric(vertical: 4.0), // 减小卡片外部垂直间距
        padding: const EdgeInsets.all(8.0), // 减小卡片内部填充
        title: GFListTile(
          padding: const EdgeInsets.all(8.0), // 减小标题内部填充
          margin: EdgeInsets.zero, // 移除标题外部间距
          title: GFTypography(
            text: title,
            type: GFTypographyType.typo4,
            showDivider: false,
          ),
        ),
        content: Wrap(
          spacing: 8.0, // 减小水平间距
          runSpacing: 4.0, // 减小垂直间距
          children: sliders.map((slider) {
            // 根据可用宽度决定每个滑块组件的宽度
            double itemWidth = constraints.maxWidth;
            
            // 如果屏幕足够宽，可以并排显示多个滑块
            if (constraints.maxWidth > 600) {
              // 两列布局
              itemWidth = (constraints.maxWidth / 2) - 8.0;
            }
            if (constraints.maxWidth > 900) {
              // 三列布局
              itemWidth = (constraints.maxWidth / 3) - 8.0;
            }
            
            return Container(
              width: itemWidth,
              child: slider,
            );
          }).toList(),
        ),
        color: backgroundColor,
        elevation: elevation,
      );
    }
  );
}

/// PID控制器参数说明：
/// 
/// 在瞄准辅助系统中，PID控制器负责根据目标位置和当前位置的差异计算所需的修正力度，
/// 实现平滑且精确的瞄准效果。
/// 
/// 主要参数包括：
/// 
/// 1. 移动速度(moveSpeed)：
///    - 控制瞄准目标时的移动速率
///    - 值越大，瞄准移动越快；值越小，移动越慢且平滑
///    - 主要影响PID中的比例项(P)的响应强度
///
/// 2. 跟踪速度(trackSpeed)：
///    - 控制瞄准后持续跟踪目标的速度
///    - 值越大，跟踪目标的反应速度越快；值越小，跟踪更平稳但反应较慢
///    - 主要影响PID中的微分项(D)的响应强度
///
/// 3. 抖动力度(shakeSpeed)：
///    - 控制瞄准时的微小随机抖动，使瞄准看起来更自然
///    - 值越大，抖动越明显；值越小，瞄准越稳定
///    - 主要是为了模拟真实人类瞄准的微小不稳定性
///
/// 4. 死区大小(deadZone)：
///    - 设定不触发瞄准辅助的中心区域范围
///    - 值越大，需要更大偏移才会触发辅助；值越小，辅助更敏感
///    - 用于防止在目标附近时出现过度修正
///
/// 5. 移动时间(moveTime)：
///    - 瞄准辅助的持续帧数，影响辅助的持续时间
///    - 值越大，辅助持续时间越长；值越小，辅助作用时间越短
///    - 控制PID控制器的连续作用时间
///
/// 6. 积分限制(integralLimit)：
///    - PID控制器中I项(积分项)的上限，影响瞄准的稳定性
///    - 值越大，瞄准修正力度越强但可能过冲；值越小，修正更平滑但反应较慢
///    - 用于限制积分项的累积效应，防止系统不稳定

/// 使用示例：
/// ```dart
/// // 移动速度滑块示例 - 控制瞄准时的移动速率
/// buildParameterSlider(
///   label: '移动速度',
///   value: controller.moveSpeed,
///   min: 0.0,
///   max: 10.0,
///   onChanged: (value) => controller.moveSpeed = value,
///   onChangeEnd: (value) => controller.markParameterChanged('移动速度'),
///   decimalPlaces: 3, // 精确到0.001
/// )
/// 
/// // 跟踪速度示例 - 控制瞄准后持续跟踪目标的速度
/// buildParameterSlider(
///   label: '跟踪速度',
///   value: controller.trackSpeed,
///   min: 0.0,
///   max: 20.0,
///   onChanged: (value) => controller.trackSpeed = value,
///   onChangeEnd: (value) => controller.markParameterChanged('跟踪速度'),
///   decimalPlaces: 3,
/// )
/// 
/// // 多参数组示例 - 移动控制参数组
/// buildMultiSliderCard(
///   title: '移动控制参数',
///   labels: ['移动速度', '跟踪速度', '抖动力度'],
///   values: [controller.moveSpeed, controller.trackSpeed, controller.shakeSpeed],
///   onChangedCallbacks: [
///     (value) => controller.moveSpeed = value,
///     (value) => controller.trackSpeed = value,
///     (value) => controller.shakeSpeed = value,
///   ],
///   onChangeEndCallbacks: [
///     (_) => controller.updatePidModel(),
///     (_) => controller.updatePidModel(),
///     (_) => controller.updatePidModel(),
///   ],
///   mins: [0.0, 0.0, 0.0],
///   maxs: [10.0, 20.0, 15.0],
///   decimalPlaces: 3,
/// )
/// ```
