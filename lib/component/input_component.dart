// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

/// 简单输入组件
class InputComponent {
  /// 创建单个输入框
  static Widget createInput({
    required String label,
    required String hint,
    IconData? icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    bool passwordVisible = false,
    Function(bool)? onTogglePasswordVisibility,
  }) {
    // 如果没有提供控制器，则创建一个新的
    final inputController = controller ?? TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签显示
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        // 输入框
        TextFormField(
          controller: inputController,
          obscureText: isPassword && !passwordVisible,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon) : null,
            suffixIcon: isPassword 
                ? IconButton(
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      if (onTogglePasswordVisibility != null) {
                        onTogglePasswordVisibility(!passwordVisible);
                      }
                    },
                  ) 
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入$label';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 创建多个垂直排列的输入框
  static Widget createMultiInputs({
    required List<Map<String, dynamic>> inputs,
    List<TextEditingController>? controllers,
    double spacing = 16.0,
    List<bool>? passwordVisibleList,
    Function(int, bool)? onTogglePasswordVisibility,
  }) {
    // 如果没有提供控制器，则创建新的控制器列表
    final inputControllers = controllers ?? 
        List.generate(inputs.length, (index) => TextEditingController());
    
    // 如果没有提供密码可见性列表，则创建新的列表
    final passwordVisibles = passwordVisibleList ?? 
        List.generate(inputs.length, (index) => false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(inputs.length * 2 - 1, (index) {
        // 如果是偶数索引，返回输入框
        if (index % 2 == 0) {
          int inputIndex = index ~/ 2;
          Map<String, dynamic> input = inputs[inputIndex];
          
          // 确保控制器列表长度足够
          TextEditingController controller = 
              inputIndex < inputControllers.length 
                  ? inputControllers[inputIndex] 
                  : TextEditingController();
          
          // 获取字段属性
          String label = input['label'] ?? '输入';
          String hint = input['hint'] ?? '请输入';
          IconData? icon = input['icon'];
          bool isPassword = input['isPassword'] ?? false;
          TextInputType keyboardType = input['keyboardType'] ?? TextInputType.text;
          ValueChanged<String>? onChanged = input['onChanged'];
          
          // 处理密码可见性
          bool passwordVisible = false;
          if (isPassword && inputIndex < passwordVisibles.length) {
            passwordVisible = passwordVisibles[inputIndex];
          }
          
          return createInput(
            label: label,
            hint: hint,
            icon: icon,
            isPassword: isPassword,
            keyboardType: keyboardType,
            controller: controller,
            onChanged: onChanged,
            passwordVisible: passwordVisible,
            onTogglePasswordVisibility: isPassword 
                ? (visible) {
                    if (onTogglePasswordVisibility != null) {
                      onTogglePasswordVisibility(inputIndex, visible);
                    }
                  } 
                : null,
          );
        } else {
          // 如果是奇数索引，返回间距
          return SizedBox(height: spacing);
        }
      }),
    );
  }

  /// 创建简单的输入表单
  static Widget createInputForm({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> inputs,
    required VoidCallback onSubmit,
    String submitButtonText = '提交',
    Widget? additionalWidget,
    double width = 420.0,
  }) {
    // 为每个输入创建控制器
    final List<TextEditingController> controllers = 
        List.generate(inputs.length, (index) => TextEditingController());
    
    // 为每个密码输入创建可见性状态
    final List<bool> passwordVisibleList = 
        List.generate(inputs.length, (index) => false);
    
    // 创建GlobalKey用于表单验证
    final formKey = GlobalKey<FormState>();
    
    return StatefulBuilder(
      builder: (context, setState) {
        return GFCard(
          boxFit: BoxFit.cover,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Container(
            width: width,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 标题
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 输入框组
                  createMultiInputs(
                    inputs: inputs,
                    controllers: controllers,
                    spacing: 24.0,
                    passwordVisibleList: passwordVisibleList,
                    onTogglePasswordVisibility: (index, visible) {
                      setState(() {
                        passwordVisibleList[index] = visible;
                      });
                    },
                  ),
                  
                  // 附加组件
                  if (additionalWidget != null) ...[
                    const SizedBox(height: 12),
                    additionalWidget,
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // 提交按钮
                  GFButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        onSubmit();
                      }
                    },
                    text: submitButtonText,
                    fullWidthButton: true,
                    size: GFSize.LARGE,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

/// 使用示例
/// 
/// 1. 创建单个输入框
/// ```dart
/// InputComponent.createInput(
///   label: '用户名',
///   hint: '请输入用户名',
///   icon: Icons.person,
/// )
/// ```
/// 
/// 2. 创建多个输入框
/// ```dart
/// InputComponent.createMultiInputs(
///   inputs: [
///     {
///       'label': '用户名',
///       'hint': '请输入用户名',
///       'icon': Icons.person,
///     },
///     {
///       'label': '密码',
///       'hint': '请输入密码',
///       'icon': Icons.lock,
///       'isPassword': true,
///     },
///   ],
/// )
/// ```
/// 
/// 3. 创建完整表单（最简单的方式）
/// ```dart
/// InputComponent.createInputForm(
///   context: context,
///   title: '用户登录',
///   inputs: [
///     {
///       'label': '用户名',
///       'hint': '请输入用户名',
///       'icon': Icons.person,
///     },
///     {
///       'label': '密码',
///       'hint': '请输入密码',
///       'icon': Icons.lock,
///       'isPassword': true,
///     },
///   ],
///   onSubmit: () {
///     print('表单提交');
///     // 获取输入值: controllers[0].text, controllers[1].text
///   },
///   submitButtonText: '登录',
/// )
/// ``` 