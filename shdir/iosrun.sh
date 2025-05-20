#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 打印带颜色的消息
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# 检查命令是否存在
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 加载 Ruby 环境配置（如果存在）
if [ -f ~/ruby_setup.sh ]; then
  source ~/ruby_setup.sh
fi

# 清屏并显示标题
clear
print_message $BLUE "===== iOS 应用运行工具 ====="
echo ""

# 检查环境
print_message $GREEN "检查环境..."

# 检查 Flutter
if ! command_exists flutter; then
  print_message $RED "错误: Flutter 未安装或不在 PATH 中。"
  exit 1
fi

# 检查 iOS 目录
if [ ! -d "ios" ]; then
  print_message $RED "错误: 未找到 iOS 目录。"
  print_message $YELLOW "是否要创建 iOS 目录? (y/n)"
  read -p "> " create_ios
  if [[ "$create_ios" == "y" ]]; then
    print_message $GREEN "创建 iOS 目录..."
    flutter create --platforms=ios .
  else
    print_message $RED "取消操作。"
    exit 1
  fi
fi

# 检查 CocoaPods 是否已安装
if ! command_exists pod; then
  print_message $YELLOW "警告: CocoaPods 未安装或不在 PATH 中。"
  print_message $YELLOW "您可能需要运行 'gem install cocoapods' 或更新 PATH。"
  print_message $YELLOW "是否继续？(y/n)"
  read -p "> " continue_without_pods
  if [[ "$continue_without_pods" != "y" ]]; then
    print_message $RED "取消操作。"
    exit 1
  fi
fi

# 检查 Pod 安装
if [ ! -d "ios/Pods" ]; then
  print_message $YELLOW "警告: 未找到 Pods 目录。是否运行 pod install? (y/n)"
  read -p "> " run_pod_install
  if [[ "$run_pod_install" == "y" ]]; then
    print_message $GREEN "运行 pod install..."
    (cd ios && pod install)
    if [ $? -ne 0 ]; then
      print_message $RED "pod install 失败。"
      print_message $YELLOW "是否继续? (y/n)"
      read -p "> " continue_after_error
      if [[ "$continue_after_error" != "y" ]]; then
        print_message $RED "取消操作。"
        exit 1
      fi
    fi
  fi
fi

# 获取可用的 iOS 模拟器
print_message $GREEN "获取可用的 iOS 模拟器..."
simulators=$(flutter devices | grep -i iphone)
has_real_device=$(flutter devices | grep -i "iphone" | grep -i "mobile" | grep -v "simulator")

# 显示可用设备
echo ""
print_message $GREEN "可用的 iOS 设备:"

if [ -n "$simulators" ] || [ -n "$has_real_device" ]; then
  flutter devices | grep -i "iphone\|ios"
  echo ""
  
  # 选择设备类型
  print_message $GREEN "选择设备类型:"
  echo "1. 使用特定的 iPhone 模拟器"
  echo "2. 使用真实 iOS 设备 (如已连接)"
  echo "3. 自动选择任何可用的 iOS 设备"
  echo "4. 启动模拟器并使用它"
  echo "5. 退出"
  
  read -p "请选择 [1-5]: " device_choice
  
  case $device_choice in
    1)
      # 让用户选择特定模拟器
      echo ""
      print_message $GREEN "选择特定模拟器:"
      simulators_list=$(flutter devices | grep -i "iphone" | grep -i "simulator")
      echo "$simulators_list" | cat -n
      echo ""
      read -p "请输入序号: " simulator_number
      simulator_id=$(echo "$simulators_list" | sed -n "${simulator_number}p" | awk '{print $2}')
      
      if [ -n "$simulator_id" ]; then
        print_message $GREEN "使用模拟器: $simulator_id"
        flutter run -d "$simulator_id"
      else
        print_message $RED "无效的选择。"
        exit 1
      fi
      ;;
    2)
      if [ -n "$has_real_device" ]; then
        device_id=$(echo "$has_real_device" | awk '{print $2}' | head -1)
        print_message $GREEN "使用真实设备: $device_id"
        flutter run -d "$device_id"
      else
        print_message $RED "未找到已连接的 iOS 设备。"
        exit 1
      fi
      ;;
    3)
      print_message $GREEN "自动选择 iOS 设备..."
      flutter run -d "ios"
      ;;
    4)
      print_message $GREEN "启动 iOS 模拟器..."
      open -a Simulator
      
      print_message $YELLOW "等待模拟器启动..."
      sleep 5
      
      print_message $GREEN "在模拟器上运行应用..."
      flutter run -d "iPhone"
      ;;
    5)
      print_message $YELLOW "退出。"
      exit 0
      ;;
    *)
      print_message $RED "无效的选择。"
      exit 1
      ;;
  esac
else
  print_message $RED "未找到 iOS 设备或模拟器。"
  print_message $YELLOW "是否要启动一个 iOS 模拟器? (y/n)"
  read -p "> " start_simulator
  
  if [[ "$start_simulator" == "y" ]]; then
    print_message $GREEN "启动 iOS 模拟器..."
    open -a Simulator
    print_message $YELLOW "等待模拟器启动..."
    sleep 5
    
    print_message $GREEN "在模拟器上运行应用..."
    flutter run -d "iPhone"
  else
    print_message $RED "退出。"
    exit 1
  fi
fi
