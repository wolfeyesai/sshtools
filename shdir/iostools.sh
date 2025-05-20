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

# 等待动画
show_spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# 主菜单
show_main_menu() {
  clear
  print_message $BLUE "===== iOS 开发环境配置工具 ====="
  echo ""
  echo "1. 安装/升级 Ruby 到最新版本 (系统级配置)"
  echo "2. 安装 CocoaPods (系统级配置)"
  echo "3. 重建 iOS 目录"
  echo "4. 运行 pod install"
  echo "5. 构建并运行 iOS 应用 (模拟器)"
  echo "6. 检查环境状态"
  echo "7. 重启电脑 (应用所有系统配置)"
  echo "8. 退出"
  echo ""
  read -p "请选择一个选项 [1-8]: " choice
  
  case $choice in
    1) install_ruby ;;
    2) install_cocoapods ;;
    3) rebuild_ios_directory ;;
    4) run_pod_install ;;
    5) run_ios_app ;;
    6) check_environment ;;
    7) restart_computer ;;
    8) exit 0 ;;
    *) 
      print_message $RED "无效的选择!"
      sleep 1
      show_main_menu
      ;;
  esac
}

# 安装/升级 Ruby
install_ruby() {
  clear
  print_message $BLUE "===== 安装/升级 Ruby ====="
  echo ""
  
  # 检查是否安装了 Homebrew
  if ! command_exists brew; then
    print_message $RED "Homebrew 未安装。请先安装 Homebrew。"
    echo "您可以运行以下命令安装 Homebrew:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  print_message $GREEN "正在更新 Homebrew..."
  brew update &
  show_spinner $!
  
  # 卸载 Ruby (如果已安装)
  if brew list ruby &>/dev/null; then
    print_message $YELLOW "检测到已安装的 Ruby，正在卸载..."
    brew uninstall --force ruby &
    show_spinner $!
  fi
  
  # 安装 Ruby
  print_message $GREEN "正在安装最新版本的 Ruby..."
  brew install ruby &
  show_spinner $!
  
  # 配置环境变量
  print_message $GREEN "配置环境变量..."
  
  # 获取Ruby安装路径
  ruby_install_path=$(brew --prefix ruby)
  ruby_bin_path="${ruby_install_path}/bin"
  
  # 创建 Ruby 和 Gems 的系统级配置
  print_message $GREEN "创建系统级配置文件..."
  
  sudo_prompt="请输入管理员密码以设置系统级配置（这将确保在所有会话中生效）:"
  
  # 创建系统范围的配置文件
  cat > /tmp/ruby_paths.sh << EOF
# Ruby 环境变量设置
export PATH="${ruby_bin_path}:\$PATH"
ruby_version=\$(${ruby_bin_path}/ruby -e 'puts RUBY_VERSION.match(/\d+\.\d+/)[0]')
export GEM_HOME="${ruby_install_path}/lib/ruby/gems/\${ruby_version}.0"
export GEM_PATH="\$GEM_HOME"
export PATH="\$GEM_HOME/bin:\$PATH"
EOF
  
  print_message $YELLOW "$sudo_prompt"
  sudo mkdir -p /etc/profile.d
  sudo cp /tmp/ruby_paths.sh /etc/profile.d/
  sudo chmod 644 /etc/profile.d/ruby_paths.sh
  
  # 同时创建用户级别配置
  # 备份并清理 .zshrc 中的旧 Ruby 配置
  if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d%H%M%S)
    grep -v "ruby_setup.sh\|Ruby 环境变量\|GEM_HOME\|GEM_PATH\|ruby/bin" ~/.zshrc > ~/.zshrc.tmp
    mv ~/.zshrc.tmp ~/.zshrc
  fi
  
  # 添加到用户配置
  cat >> ~/.zshrc << EOF

# Ruby 环境变量设置（由 iOS 工具脚本设置）
if [ -f /etc/profile.d/ruby_paths.sh ]; then
  source /etc/profile.d/ruby_paths.sh
fi
EOF
  
  # 立即应用配置
  source /tmp/ruby_paths.sh
  
  # 验证安装
  ruby_version=$(ruby -v)
  ruby_path=$(which ruby)
  
  echo ""
  print_message $GREEN "Ruby 安装完成!"
  echo "Ruby 版本: $ruby_version"
  echo "Ruby 路径: $ruby_path"
  echo ""
  print_message $YELLOW "重要: 系统级配置已设置，重启电脑后将对所有终端窗口永久生效。"
  print_message $YELLOW "当前会话中的配置已应用，可以继续安装 CocoaPods。"
  echo ""
  
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 安装 CocoaPods
install_cocoapods() {
  clear
  print_message $BLUE "===== 安装 CocoaPods ====="
  echo ""
  
  # 检查 Ruby 环境
  if ! command_exists ruby; then
    print_message $RED "未找到 Ruby。请先运行选项 1 安装 Ruby。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  # 检查 Ruby 版本
  ruby_version=$(ruby -v)
  if [[ ! $ruby_version =~ [3-9]\.[0-9]+\.[0-9]+ ]]; then
    print_message $RED "检测到 Ruby 版本过低: $ruby_version"
    print_message $RED "CocoaPods 需要 Ruby 3.0.0 或更高版本。请先更新 Ruby。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  print_message $GREEN "检测到 Ruby 版本: $ruby_version"
  print_message $GREEN "正在安装 CocoaPods..."
  
  # 确保 gem 目录存在并具有适当的权限
  ruby_prefix=$(brew --prefix ruby)
  ruby_minor_version=$(ruby -e 'puts RUBY_VERSION.match(/\d+\.\d+/)[0]')
  gem_dir="${ruby_prefix}/lib/ruby/gems/${ruby_minor_version}.0"
  gem_bin_dir="${gem_dir}/bin"
  
  # 设置权限
  print_message $GREEN "设置 Gem 目录权限..."
  mkdir -p "$gem_bin_dir"
  sudo_prompt="请输入管理员密码以设置 Gem 目录权限:"
  print_message $YELLOW "$sudo_prompt"
  sudo chown -R $(whoami) "$gem_dir"
  
  # 安装 CocoaPods (使用全路径)
  print_message $GREEN "安装 CocoaPods..."
  GEM_HOME="$gem_dir" GEM_PATH="$gem_dir" PATH="$gem_bin_dir:$PATH" gem install cocoapods
  
  # 创建 CocoaPods 软链接到全局可访问目录
  print_message $GREEN "创建 CocoaPods 软链接..."
  print_message $YELLOW "$sudo_prompt"
  sudo ln -sf "$gem_bin_dir/pod" /usr/local/bin/pod
  
  # 验证安装
  if [ -f "$gem_bin_dir/pod" ]; then
    pod_version=$("$gem_bin_dir/pod" --version 2>/dev/null || echo "未知版本")
    print_message $GREEN "CocoaPods 安装成功!"
    echo "CocoaPods 版本: $pod_version"
    echo "CocoaPods 路径: $gem_bin_dir/pod"
    echo "全局软链接: /usr/local/bin/pod"
    
    # 确保在重启后也能使用
    print_message $GREEN "确保 CocoaPods 在重启后也能使用..."
    cat > /tmp/cocoapods_paths.sh << EOF
# CocoaPods 路径设置
if [ -d "$gem_bin_dir" ]; then
  export PATH="$gem_bin_dir:\$PATH"
fi
EOF

    print_message $YELLOW "$sudo_prompt"
    sudo cp /tmp/cocoapods_paths.sh /etc/profile.d/
    sudo chmod 644 /etc/profile.d/cocoapods_paths.sh
    
    print_message $GREEN "系统级配置已设置，重启电脑后将对所有终端窗口永久生效。"
  else
    print_message $RED "CocoaPods 安装似乎失败。请检查错误信息。"
  fi
  
  echo ""
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 重建 iOS 目录
rebuild_ios_directory() {
  clear
  print_message $BLUE "===== 重建 iOS 目录 ====="
  echo ""
  
  # 获取当前目录
  current_dir=$(pwd)
  
  # 确定项目根目录
  project_root=$current_dir
  if [[ "$current_dir" == */shdir ]]; then
    # 如果在shdir中，返回上一级
    project_root="$(dirname "$current_dir")"
  elif [[ "$current_dir" == */ios ]]; then
    # 如果在ios中，返回上一级
    project_root="$(dirname "$current_dir")"
  fi
  
  print_message $GREEN "项目根目录: $project_root"
  
  # 确认操作
  print_message $YELLOW "警告: 此操作将删除并重新创建 iOS 目录 ($project_root/ios)。"
  read -p "是否继续? (y/n): " confirm
  if [[ "$confirm" != "y" ]]; then
    print_message $RED "操作已取消。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  # 检查 Flutter
  if ! command_exists flutter; then
    print_message $RED "未找到 Flutter 命令。请确保已安装 Flutter 并添加到 PATH。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  # 进入项目根目录
  cd "$project_root"
  
  # 删除 iOS 目录
  print_message $GREEN "正在删除 iOS 目录..."
  if [ -d "ios" ]; then
    rm -rf ios
    print_message $GREEN "已删除: $project_root/ios"
  else
    print_message $YELLOW "提示: 未找到 iOS 目录，将创建新目录。"
  fi
  
  # 重新创建 iOS 平台
  print_message $GREEN "正在重新创建 iOS 平台..."
  flutter create --platforms=ios . &
  show_spinner $!
  
  if [ -d "ios" ]; then
    print_message $GREEN "iOS 目录已成功重建: $project_root/ios"
    
    # 提示运行 pod install
    print_message $YELLOW "您现在可以运行选项 4 来执行 pod install。"
  else
    print_message $RED "重建 iOS 目录失败。请检查 Flutter 安装。"
  fi
  
  # 返回到原始目录
  cd "$current_dir"
  
  echo ""
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 运行 pod install
run_pod_install() {
  clear
  print_message $BLUE "===== 运行 pod install ====="
  echo ""
  
  # 获取当前目录
  current_dir=$(pwd)
  
  # 确定项目根目录
  project_root=$current_dir
  if [[ "$current_dir" == */shdir ]]; then
    # 如果在shdir中，返回上一级
    project_root="$(dirname "$current_dir")"
  elif [[ "$current_dir" == */ios ]]; then
    # 如果在ios中，返回上一级
    project_root="$(dirname "$current_dir")"
  fi
  
  print_message $GREEN "项目根目录: $project_root"
  
  # 检查 iOS 目录是否存在
  if [ ! -d "$project_root/ios" ]; then
    print_message $RED "未找到 iOS 目录。请先运行选项 3 重建 iOS 目录。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  # 检查 CocoaPods
  if ! command_exists pod; then
    print_message $RED "未找到 CocoaPods 命令。请先运行选项 2 安装 CocoaPods。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  # 运行 pod install
  print_message $GREEN "正在 iOS 目录中运行 pod install..."
  (cd "$project_root/ios" && pod install) &
  show_spinner $!
  
  # 检查结果
  if [ $? -eq 0 ]; then
    print_message $GREEN "pod install 完成。"
    if [ -f "$project_root/ios/Podfile.lock" ]; then
      print_message $GREEN "成功创建 Podfile.lock。"
    fi
  else
    print_message $RED "pod install 过程中出现错误。"
  fi
  
  echo ""
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 构建并运行 iOS 应用
run_ios_app() {
  clear
  print_message $BLUE "===== 构建并运行 iOS 应用 ====="
  echo ""
  
  # 获取当前目录
  current_dir=$(pwd)
  
  # 确定项目根目录
  project_root=$current_dir
  if [[ "$current_dir" == */shdir ]]; then
    # 如果在shdir中，返回上一级
    project_root="$(dirname "$current_dir")"
  elif [[ "$current_dir" == */ios ]]; then
    # 如果在ios中，返回上一级
    project_root="$(dirname "$current_dir")"
  fi
  
  print_message $GREEN "项目根目录: $project_root"
  
  # 检查 iOS 目录和 Pods
  if [ ! -d "$project_root/ios" ]; then
    print_message $RED "未找到 iOS 目录。请先运行选项 3 重建 iOS 目录。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  if [ ! -d "$project_root/ios/Pods" ]; then
    print_message $YELLOW "未找到 Pods 目录。您可能需要先运行选项 4 (pod install)。"
    read -p "是否继续? (y/n): " continue_without_pods
    if [[ "$continue_without_pods" != "y" ]]; then
      show_main_menu
      return
    fi
  fi
  
  # 获取可用的 iOS 设备
  print_message $GREEN "正在获取可用的 iOS 设备..."
  all_devices=$(flutter devices)
  simulators=$(echo "$all_devices" | grep -i "iphone" | grep -i "simulator")
  real_devices=$(echo "$all_devices" | grep -i "iphone\|ios" | grep -v "simulator")
  
  # 检查是否有可用设备
  if [ -z "$simulators" ] && [ -z "$real_devices" ]; then
    print_message $RED "未找到任何 iOS 设备或模拟器。"
    print_message $YELLOW "您可以通过运行 'open -a Simulator' 启动模拟器，或连接真机设备。"
    read -p "是否尝试启动模拟器? (y/n): " start_simulator
    if [[ "$start_simulator" == "y" ]]; then
      print_message $GREEN "正在启动模拟器..."
      open -a Simulator
      print_message $YELLOW "请等待模拟器完全启动，然后重新尝试此选项。"
    fi
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  # 显示设备选择菜单
  clear
  print_message $BLUE "===== iOS 设备选择 ====="
  echo ""
  
  # 显示所有设备
  print_message $GREEN "检测到以下 iOS 设备:"
  echo "$all_devices" | grep -i "iphone\|ios"
  echo ""
  
  # 设备选择菜单
  echo "请选择要使用的设备类型:"
  echo "1. 使用真实设备 (如可用)"
  echo "2. 使用模拟器 (如可用)"
  echo "3. 返回主菜单"
  echo ""
  read -p "请选择 [1-3]: " device_choice
  
  device_id=""
  
  case $device_choice in
    1)
      if [ -z "$real_devices" ]; then
        print_message $RED "未检测到任何真实 iOS 设备。请确保设备已连接并被信任。"
        read -p "按回车键返回主菜单..."
        show_main_menu
        return
      fi
      
      # 如果有多个真实设备，让用户选择
      device_count=$(echo "$real_devices" | wc -l)
      if [ "$device_count" -gt 1 ]; then
        echo ""
        print_message $GREEN "检测到多个真实设备，请选择:"
        echo "$real_devices" | cat -n
        read -p "请输入设备编号: " device_num
        selected_device=$(echo "$real_devices" | sed -n "${device_num}p")
      else
        selected_device="$real_devices"
      fi
      
      # 正确提取设备ID (第三列)
      device_id=$(echo "$selected_device" | awk -F' • ' '{print $2}')
      ;;
    2)
      if [ -z "$simulators" ]; then
        print_message $YELLOW "未检测到模拟器。是否启动模拟器? (y/n)"
        read -p "> " start_sim
        if [[ "$start_sim" == "y" ]]; then
          print_message $GREEN "启动模拟器..."
          open -a Simulator
          print_message $YELLOW "请等待模拟器启动，然后重新运行此选项。"
          read -p "按回车键返回主菜单..."
          show_main_menu
          return
        else
          read -p "按回车键返回主菜单..."
          show_main_menu
          return
        fi
      fi
      
      # 如果有多个模拟器，让用户选择
      simulator_count=$(echo "$simulators" | wc -l)
      if [ "$simulator_count" -gt 1 ]; then
        echo ""
        print_message $GREEN "检测到多个模拟器，请选择:"
        echo "$simulators" | cat -n
        read -p "请输入模拟器编号: " sim_num
        selected_simulator=$(echo "$simulators" | sed -n "${sim_num}p")
      else
        selected_simulator="$simulators"
      fi
      
      # 正确提取设备ID (第三列)
      device_id=$(echo "$selected_simulator" | awk -F' • ' '{print $2}')
      ;;
    3)
      show_main_menu
      return
      ;;
    *)
      print_message $RED "无效的选择!"
      read -p "按回车键返回主菜单..."
      show_main_menu
      return
      ;;
  esac
  
  if [ -z "$device_id" ]; then
    print_message $RED "未能获取有效的设备 ID。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  # 运行应用
  print_message $GREEN "正在设备 $device_id 上启动应用..."
  cd "$project_root"
  flutter run -d "$device_id"
  
  # 返回到原始目录
  cd "$current_dir"
  
  # Flutter run 是交互式的，所以我们不使用 spinner
  
  echo ""
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 检查环境状态
check_environment() {
  clear
  print_message $BLUE "===== 环境状态检查 ====="
  echo ""
  
  # 检查 Ruby
  echo "Ruby 状态:"
  if command_exists ruby; then
    ruby_version=$(ruby -v)
    ruby_path=$(which ruby)
    print_message $GREEN "✓ Ruby 已安装"
    echo "  版本: $ruby_version"
    echo "  路径: $ruby_path"
    
    # 检查是否是 Homebrew 的 Ruby
    if [[ $ruby_path == *"/usr/local/"* || $ruby_path == *"/opt/homebrew/"* ]]; then
      print_message $GREEN "  ✓ 使用的是 Homebrew 安装的 Ruby"
    else
      print_message $YELLOW "  ⚠ 使用的不是 Homebrew 安装的 Ruby"
    fi
  else
    print_message $RED "✗ Ruby 未安装或不在 PATH 中"
  fi
  echo ""
  
  # 检查 CocoaPods
  echo "CocoaPods 状态:"
  if command_exists pod; then
    pod_version=$(pod --version)
    pod_path=$(which pod)
    print_message $GREEN "✓ CocoaPods 已安装"
    echo "  版本: $pod_version"
    echo "  路径: $pod_path"
  else
    print_message $RED "✗ CocoaPods 未安装或不在 PATH 中"
  fi
  echo ""
  
  # 检查 Flutter
  echo "Flutter 状态:"
  if command_exists flutter; then
    flutter_version=$(flutter --version | head -n 1)
    flutter_path=$(which flutter)
    print_message $GREEN "✓ Flutter 已安装"
    echo "  版本: $flutter_version"
    echo "  路径: $flutter_path"
    
    # 检查 iOS 支持
    flutter_ios_support=$(flutter doctor | grep -i ios)
    if [[ $flutter_ios_support == *"[✓]"* ]]; then
      print_message $GREEN "  ✓ Flutter iOS 支持已配置"
    else
      print_message $YELLOW "  ⚠ Flutter iOS 支持可能未正确配置"
    fi
  else
    print_message $RED "✗ Flutter 未安装或不在 PATH 中"
  fi
  echo ""
  
  # 检查 iOS 目录
  echo "项目 iOS 目录状态:"
  if [ -d "ios" ]; then
    print_message $GREEN "✓ iOS 目录存在"
    
    if [ -f "ios/Podfile" ]; then
      print_message $GREEN "  ✓ Podfile 存在"
    else
      print_message $RED "  ✗ Podfile 不存在"
    fi
    
    if [ -d "ios/Pods" ]; then
      print_message $GREEN "  ✓ Pods 目录存在"
    else
      print_message $YELLOW "  ⚠ Pods 目录不存在，可能需要运行 pod install"
    fi
    
    if [ -f "ios/Podfile.lock" ]; then
      print_message $GREEN "  ✓ Podfile.lock 存在"
    else
      print_message $YELLOW "  ⚠ Podfile.lock 不存在，可能需要运行 pod install"
    fi
  else
    print_message $RED "✗ iOS 目录不存在"
  fi
  echo ""
  
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 重启电脑
restart_computer() {
  clear
  print_message $BLUE "===== 重启电脑 ====="
  echo ""
  print_message $YELLOW "警告: 此操作将重启您的电脑以应用所有系统级配置。"
  print_message $YELLOW "请确保保存所有工作。"
  echo ""
  read -p "是否继续重启电脑? (y/n): " confirm
  if [[ "$confirm" == "y" ]]; then
    print_message $GREEN "正在重启电脑..."
    sudo shutdown -r now
  else
    print_message $RED "重启操作已取消。"
    read -p "按回车键返回主菜单..."
    show_main_menu
  fi
}

# 启动脚本
clear
print_message $GREEN "欢迎使用 iOS 开发环境配置工具"
echo ""

# 创建iosrun.sh脚本
cat > iosrun.sh << 'EOF'
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
EOF

# 使iosrun.sh可执行
chmod +x iosrun.sh
print_message $GREEN "已创建 iosrun.sh 脚本用于直接运行 iOS 应用"
echo ""

show_main_menu
