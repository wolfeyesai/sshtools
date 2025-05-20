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

# 获取macos目录的实际路径（当前、上一级或指定绝对路径）
get_macos_dir() {
  local current_dir=$(pwd)
  if [ -d "$current_dir/macos" ]; then
    echo "$current_dir/macos"
  elif [ -d "$(dirname "$current_dir")/macos" ]; then
    echo "$(dirname "$current_dir")/macos"
  elif [ -d "/Users/yibao/sshtools/macos" ]; then
    echo "/Users/yibao/sshtools/macos"
  else
    echo ""
  fi
}

# 主菜单
show_main_menu() {
  clear
  print_message $BLUE "===== macOS 开发环境配置工具 ====="
  echo ""
  echo "1. 安装/升级 Ruby 到最新版本 (系统级配置)"
  echo "2. 安装 CocoaPods (系统级配置)"
  echo "3. 重建 macOS 目录"
  echo "4. 运行 flutter pub get"
  echo "5. 构建并运行 macOS 应用"
  echo "6. 检查环境状态"
  echo "7. 重启电脑 (应用所有系统配置)"
  echo "8. 构建发布版应用"
  echo "9. 打包应用为ZIP文件"
  echo "10. 退出"
  echo ""
  read -p "请选择一个选项 [1-10]: " choice
  
  case $choice in
    1) install_ruby ;;
    2) install_cocoapods ;;
    3) rebuild_macos_directory ;;
    4) run_flutter_pub_get ;;
    5) run_macos_app ;;
    6) check_environment ;;
    7) restart_computer ;;
    8) build_release_app ;;
    9) package_app ;;
    10) exit 0 ;;
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
  
  ruby_install_path=$(brew --prefix ruby)
  ruby_bin_path="${ruby_install_path}/bin"
  
  print_message $GREEN "创建系统级配置文件..."
  sudo_prompt="请输入管理员密码以设置系统级配置（这将确保在所有会话中生效）:"
  
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
  
  # 用户级别配置
  if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d%H%M%S)
    grep -v "ruby_setup.sh\|Ruby 环境变量\|GEM_HOME\|GEM_PATH\|ruby/bin" ~/.zshrc > ~/.zshrc.tmp
    mv ~/.zshrc.tmp ~/.zshrc
  fi
  cat >> ~/.zshrc << EOF

# Ruby 环境变量设置（由 macOS 工具脚本设置）
if [ -f /etc/profile.d/ruby_paths.sh ]; then
  source /etc/profile.d/ruby_paths.sh
fi
EOF
  source /tmp/ruby_paths.sh
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
  if ! command_exists ruby; then
    print_message $RED "未找到 Ruby。请先运行选项 1 安装 Ruby。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
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
  ruby_prefix=$(brew --prefix ruby)
  ruby_minor_version=$(ruby -e 'puts RUBY_VERSION.match(/\d+\.\d+/)[0]')
  gem_dir="${ruby_prefix}/lib/ruby/gems/${ruby_minor_version}.0"
  gem_bin_dir="${gem_dir}/bin"
  print_message $GREEN "设置 Gem 目录权限..."
  mkdir -p "$gem_bin_dir"
  sudo_prompt="请输入管理员密码以设置 Gem 目录权限:"
  print_message $YELLOW "$sudo_prompt"
  sudo chown -R $(whoami) "$gem_dir"
  print_message $GREEN "安装 CocoaPods..."
  GEM_HOME="$gem_dir" GEM_PATH="$gem_dir" PATH="$gem_bin_dir:$PATH" gem install cocoapods
  print_message $GREEN "创建 CocoaPods 软链接..."
  print_message $YELLOW "$sudo_prompt"
  sudo ln -sf "$gem_bin_dir/pod" /usr/local/bin/pod
  if [ -f "$gem_bin_dir/pod" ]; then
    pod_version=$("$gem_bin_dir/pod" --version 2>/dev/null || echo "未知版本")
    print_message $GREEN "CocoaPods 安装成功!"
    echo "CocoaPods 版本: $pod_version"
    echo "CocoaPods 路径: $gem_bin_dir/pod"
    echo "全局软链接: /usr/local/bin/pod"
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

# 重建 macOS 目录
rebuild_macos_directory() {
  clear
  print_message $BLUE "===== 重建 macOS 目录 ====="
  echo ""
  current_dir=$(pwd)
  project_root=$current_dir
  if [[ "$current_dir" == */shdir ]]; then
    project_root="$(dirname "$current_dir")"
  elif [[ "$current_dir" == */macos ]]; then
    project_root="$(dirname "$current_dir")"
  fi
  print_message $GREEN "项目根目录: $project_root"
  print_message $YELLOW "警告: 此操作将删除并重新创建 macOS 目录 ($project_root/macos)。"
  read -p "是否继续? (y/n): " confirm
  if [[ "$confirm" != "y" ]]; then
    print_message $RED "操作已取消。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  if ! command_exists flutter; then
    print_message $RED "未找到 Flutter 命令。请确保已安装 Flutter 并添加到 PATH。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  cd "$project_root"
  print_message $GREEN "正在删除 macOS 目录..."
  if [ -d "macos" ]; then
    rm -rf macos
    print_message $GREEN "已删除: $project_root/macos"
  else
    print_message $YELLOW "提示: 未找到 macOS 目录，将创建新目录。"
  fi
  print_message $GREEN "正在重新创建 macOS 平台..."
  flutter create --platforms=macos . &
  show_spinner $!
  if [ -d "macos" ]; then
    print_message $GREEN "macOS 目录已成功重建: $project_root/macos"
    print_message $YELLOW "您现在可以运行选项 4 来执行 flutter pub get。"
  else
    print_message $RED "重建 macOS 目录失败。请检查 Flutter 安装。"
  fi
  cd "$current_dir"
  echo ""
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 运行 flutter pub get
run_flutter_pub_get() {
  clear
  print_message $BLUE "===== 运行 flutter pub get ====="
  echo ""
  current_dir=$(pwd)
  project_root=$current_dir
  if [[ "$current_dir" == */shdir ]]; then
    project_root="$(dirname "$current_dir")"
  elif [[ "$current_dir" == */macos ]]; then
    project_root="$(dirname "$current_dir")"
  fi
  macos_dir=$(get_macos_dir)
  print_message $GREEN "项目根目录: $project_root"
  if [ -z "$macos_dir" ]; then
    print_message $RED "未找到 macOS 目录。请先运行选项 3 重建 macOS 目录。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  if ! command_exists flutter; then
    print_message $RED "未找到 Flutter 命令。请确保已安装 Flutter 并添加到 PATH。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  print_message $GREEN "正在运行 flutter pub get..."
  (cd "$project_root" && flutter pub get) &
  show_spinner $!
  if [ $? -eq 0 ]; then
    print_message $GREEN "flutter pub get 完成。"
  else
    print_message $RED "flutter pub get 过程中出现错误。"
  fi
  echo ""
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 构建并运行 macOS 应用
run_macos_app() {
  clear
  print_message $BLUE "===== 构建并运行 macOS 应用 ====="
  echo ""
  macos_dir=$(get_macos_dir)
  if [ -z "$macos_dir" ]; then
    print_message $RED "未找到 macOS 目录。请先运行选项 3 重建 macOS 目录。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  if ! command_exists flutter; then
    print_message $RED "未找到 Flutter 命令。请确保已安装 Flutter 并添加到 PATH。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  print_message $GREEN "正在构建并运行 macOS 应用..."
  (cd "$(dirname "$macos_dir")" && flutter run -d macos)
  echo ""
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 检查环境状态
check_environment() {
  clear
  print_message $BLUE "===== 环境状态检查 ====="
  echo ""
  echo "Ruby 状态:"
  if command_exists ruby; then
    ruby_version=$(ruby -v)
    ruby_path=$(which ruby)
    print_message $GREEN "✓ Ruby 已安装"
    echo "  版本: $ruby_version"
    echo "  路径: $ruby_path"
    if [[ $ruby_path == */usr/local/* || $ruby_path == */opt/homebrew/* ]]; then
      print_message $GREEN "  ✓ 使用的是 Homebrew 安装的 Ruby"
    else
      print_message $YELLOW "  ⚠ 使用的不是 Homebrew 安装的 Ruby"
    fi
  else
    print_message $RED "✗ Ruby 未安装或不在 PATH 中"
  fi
  echo ""
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
  echo "Flutter 状态:"
  if command_exists flutter; then
    flutter_version=$(flutter --version | head -n 1)
    flutter_path=$(which flutter)
    print_message $GREEN "✓ Flutter 已安装"
    echo "  版本: $flutter_version"
    echo "  路径: $flutter_path"
    flutter_macos_support=$(flutter doctor | grep -i macos)
    if [[ $flutter_macos_support == *"[✓]"* ]]; then
      print_message $GREEN "  ✓ Flutter macOS 支持已配置"
    else
      print_message $YELLOW "  ⚠ Flutter macOS 支持可能未正确配置"
    fi
  else
    print_message $RED "✗ Flutter 未安装或不在 PATH 中"
  fi
  echo ""
  echo "项目 macOS 目录状态:"
  macos_dir=$(get_macos_dir)
  if [ -n "$macos_dir" ]; then
    print_message $GREEN "✓ macOS 目录存在: $macos_dir"
    if [ -f "$macos_dir/Runner.xcworkspace" ]; then
      print_message $GREEN "  ✓ Runner.xcworkspace 存在"
    else
      print_message $YELLOW "  ⚠ Runner.xcworkspace 不存在，可能需要重新创建 macOS 目录"
    fi
  else
    print_message $RED "✗ macOS 目录不存在"
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

# 构建发布版应用
build_release_app() {
  clear
  print_message $BLUE "===== 构建发布版 macOS 应用 ====="
  echo ""
  
  if ! command_exists flutter; then
    print_message $RED "未找到 Flutter 命令。请确保已安装 Flutter 并添加到 PATH。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  current_dir=$(pwd)
  project_root=$current_dir
  if [[ "$current_dir" == */shdir ]]; then
    project_root="$(dirname "$current_dir")"
  elif [[ "$current_dir" == */macos ]]; then
    project_root="$(dirname "$current_dir")"
  fi
  
  # 设置macOS最低部署版本
  macos_dir=$(get_macos_dir)
  if [ -n "$macos_dir" ]; then
    set_macos_minimum_version "$macos_dir"
  fi
  
  print_message $GREEN "正在构建发布版 macOS 应用..."
  cd "$project_root"
  flutter build macos --release &
  show_spinner $!
  
  if [ $? -eq 0 ]; then
    app_path="$project_root/build/macos/Build/Products/Release/sshtools.app"
    if [ -d "$app_path" ]; then
      app_size=$(du -sh "$app_path" | awk '{print $1}')
      print_message $GREEN "✓ 发布版构建成功: $app_path ($app_size)"
    else
      print_message $GREEN "✓ 发布版构建成功，但找不到预期的.app文件"
    fi
  else
    print_message $RED "构建过程中出现错误。"
  fi
  
  # 返回到原始目录
  cd "$current_dir"
  
  echo ""
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 打包应用为ZIP文件
package_app() {
  clear
  print_message $BLUE "===== 打包 macOS 应用 ====="
  echo ""
  
  current_dir=$(pwd)
  project_root=$current_dir
  if [[ "$current_dir" == */shdir ]]; then
    project_root="$(dirname "$current_dir")"
  elif [[ "$current_dir" == */macos ]]; then
    project_root="$(dirname "$current_dir")"
  fi
  
  app_path="$project_root/build/macos/Build/Products/Release/sshtools.app"
  if [ ! -d "$app_path" ]; then
    print_message $RED "找不到构建好的应用。请先运行选项 8 构建发布版应用。"
    read -p "按回车键返回主菜单..."
    show_main_menu
    return
  fi
  
  # 创建桌面上的目标目录
  user_desktop="$HOME/Desktop"
  target_dir="$user_desktop/SSHTools_macOS"
  mkdir -p "$target_dir"
  
  print_message $GREEN "正在将应用复制到 $target_dir..."
  cp -R "$app_path" "$target_dir/"
  
  # 创建简单的使用说明
  readme_file="$target_dir/使用说明.txt"
  cat > "$readme_file" << EOF
SSH工具 - macOS版

使用方法:
1. 首次运行时，右键点击应用选择"打开"
2. 在出现的警告对话框中选择"打开"
3. 如果应用仍无法打开，请到"系统设置 > 隐私与安全性"中允许应用运行

注意:
- 此应用未经签名，macOS可能会显示安全警告
- 这是正常的，您可以安全使用此应用

EOF
  
  # 创建ZIP文件
  cd "$target_dir/.."
  zip_name="SSHTools_macOS.zip"
  print_message $GREEN "正在创建ZIP包: $user_desktop/$zip_name..."
  zip -r "$zip_name" "SSHTools_macOS" &
  show_spinner $!
  
  if [ -f "$zip_name" ]; then
    zip_size=$(du -sh "$zip_name" | awk '{print $1}')
    print_message $GREEN "✓ 打包成功: $user_desktop/$zip_name ($zip_size)"
  else
    print_message $RED "ZIP包创建失败。"
  fi
  
  # 返回到原始目录
  cd "$current_dir"
  
  echo ""
  print_message $GREEN "提示: 您可以将 $user_desktop/$zip_name 分享给其他用户"
  print_message $YELLOW "注意: 由于应用未签名，用户首次运行时需要通过系统安全设置授权"
  echo ""
  read -p "按回车键返回主菜单..."
  show_main_menu
}

# 启动脚本
clear
print_message $GREEN "欢迎使用 macOS 开发环境配置工具"
echo ""
show_main_menu
