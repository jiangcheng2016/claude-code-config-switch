# Claude配置切换工具 - 用户使用手册

> **这是一个为所有用户设计的手册，无论您是否有技术背景，都可以轻松上手使用**

## 📋 目录

1. [什么是Claude配置切换工具](#什么是claude配置切换工具)
2. [为什么需要这个工具](#为什么需要这个工具)
3. [安装指南](#安装指南)
4. [快速开始](#快速开始)
5. [详细功能说明](#详细功能说明)
6. [常见使用场景](#常见使用场景)
7. [故障排除](#故障排除)
8. [常见问题](#常见问题)

---

## 什么是Claude配置切换工具

### 简单理解
想象您有多张银行卡，每次购物时需要选择使用哪张卡。Claude配置切换工具就是帮您管理多个Claude AI服务"账户"的工具，让您可以轻松地在不同服务之间切换。

### 具体作用
- **管理多个Claude API配置**：存储不同服务商的API地址和密钥
- **一键切换服务**：快速在不同Claude服务之间切换
- **自动应用配置**：切换后立即生效，无需手动操作
- **安全存储**：安全地保存您的API密钥信息

---

## 为什么需要这个工具

### 解决的问题

1. **手动编辑配置麻烦**
   - 之前：需要手动编辑系统配置文件
   - 现在：一条命令即可切换

2. **多个服务管理困难**
   - 之前：容易忘记不同服务的配置信息
   - 现在：所有配置统一管理，随时切换

3. **配置错误风险**
   - 之前：手动修改容易出错
   - 现在：工具自动处理，减少错误

4. **团队协作不便**
   - 之前：配置难以分享
   - 现在：支持配置导入导出

### 使用场景举例

**场景1：个人用户**
- 您有一个付费的Claude服务和一个免费的备用服务
- 需要根据使用情况在两者之间切换

**场景2：开发者**
- 测试环境使用测试API
- 生产环境使用正式API
- 需要频繁切换进行开发调试

**场景3：团队使用**
- 不同团队成员使用不同的API配额
- 需要分享和管理多个配置

---

## 安装指南

### 系统要求
- **操作系统**：macOS 或 Linux
- **必需软件**：Python 3（系统通常已安装）
- **权限要求**：能够修改用户配置文件

### 安装步骤

#### 步骤1：下载工具
```bash
# 进入工具目录
cd /Users/你的用户名/Documents/Work/AI\ Web/AI-Tools/config_switch
```

#### 步骤2：运行安装程序
```bash
# 运行安装脚本
./install.sh
```

#### 步骤3：选择集成模式
安装程序会询问您选择集成模式：

```
Choose integration method:
1. Function mode (recommended) - Add shell function to ~/.zshrc
2. Alias mode - Add alias to ~/.zshrc  
3. Manual mode - No automatic integration

Choose [1-3]: 1
```

**推荐选择1**（Function mode），这是最方便的方式。

#### 步骤4：重新加载配置
```bash
# 重新加载shell配置
source ~/.zshrc

# 或者重新打开终端窗口
```

#### 步骤5：验证安装
```bash
# 测试命令是否可用
cswitch help
```

如果显示帮助信息，说明安装成功！

---

## 快速开始

### 第一次使用

安装完成后，工具会自动识别您现有的Claude配置并创建初始设置。

#### 查看当前配置
```bash
cswitch status
```

您会看到类似这样的输出：
```
📍 Current Configuration: ZhiPu AI Service (zhuipu)
ℹ️  Base URL: https://open.bigmodel.cn/api/anthropic
ℹ️  Token: f32e56d1***2e (masked)
```

#### 查看所有可用配置
```bash
cswitch list
```

输出示例：
```
⚙️  Available configurations:

1. 🟡 AnyRouter Proxy Service (anyrouter) - https://anyrouter.top
2. 🟢 ZhiPu AI Service (zhuipu) - https://open.bigmodel.cn/api/anthropic

📍 Current: ZhiPu AI Service (zhuipu)
```

### 基本操作

#### 1. 快速切换配置
```bash
# 切换到anyrouter服务
cswitch anyrouter

# 切换到zhuipu服务  
cswitch zhuipu
```

切换成功后会显示：
```
✅ Switched to: AnyRouter Proxy Service (anyrouter)
```

#### 2. 交互式选择
如果您不记得配置名称，可以使用交互模式：

```bash
# 不带参数运行
cswitch
```

会显示菜单让您选择：
```
✅ Claude Configuration Switcher

Available configurations:
1. 🟡 AnyRouter Proxy Service (anyrouter) - https://anyrouter.top
2. 🟢 ZhiPu AI Service (zhuipu) - https://open.bigmodel.cn/api/anthropic

Current: ZhiPu AI Service (zhuipu)

Choose [1-2] or [q]uit: 1
```

输入数字1，按回车即可切换。

---

## 详细功能说明

### 配置管理

#### 添加新配置
当您获得新的Claude API服务时，可以添加到工具中：

```bash
# 基本格式
cswitch add <别名> <API地址> <API密钥> [描述]

# 实际例子
cswitch add official "https://api.anthropic.com" "sk-ant-xxxxx" "Claude官方API"
```

**参数说明**：
- `别名`：您为这个配置起的简短名称（如：official, backup等）
- `API地址`：服务提供商给您的API地址
- `API密钥`：您的API密钥（通常以sk-开头）
- `描述`：可选，对这个配置的说明

#### 删除配置
```bash
# 删除不需要的配置
cswitch remove backup
```

系统会要求确认：
```
Are you sure you want to remove 'backup' configuration? [y/N]: y
```

#### 交互式添加
如果您不确定命令格式，可以使用交互式添加：

```bash
cswitch add
```

系统会逐步询问您输入信息：
```
Enter alias name: myapi
Enter base URL: https://my-api.com
Enter auth token: sk-xxxxx
Enter description (optional): My Custom API
✅ Configuration 'myapi' added successfully
```

### 状态查看

#### 查看当前状态
```bash
cswitch status
```

#### 查看所有配置
```bash
cswitch list
```

#### 查看帮助
```bash
cswitch help
```

### 高级功能

#### 配置导入导出
**导出配置**（用于备份或分享）：
```bash
cswitch export ~/my-configs.json
```

**导入配置**（从备份或他人分享的文件）：
```bash
cswitch import ~/shared-configs.json
```

#### 查看操作历史
```bash
cswitch history
```

#### 切换到上一个配置
```bash
cswitch last
```

---

## 常见使用场景

### 场景1：日常使用切换

**需求**：您有两个Claude服务，平时使用付费服务，当配额不足时切换到备用服务。

**操作流程**：
```bash
# 早上开始工作，查看当前配置
cswitch status

# 使用过程中，如果需要切换到备用服务
cswitch backup

# 工作结束，切换回主要服务
cswitch main
```

### 场景2：开发测试环境

**需求**：开发时使用测试API，发布时使用生产API。

**操作流程**：
```bash
# 开发阶段
cswitch test

# 测试完成，准备发布
cswitch prod

# 发布验证完成，回到开发
cswitch test
```

### 场景3：团队配置管理

**需求**：团队leader配置好所有API，分享给团队成员。

**Leader操作**：
```bash
# 添加各种配置
cswitch add team-dev "https://dev-api.com" "dev-token" "团队开发环境"
cswitch add team-prod "https://prod-api.com" "prod-token" "团队生产环境"

# 导出配置文件
cswitch export team-configs.json

# 分享 team-configs.json 给团队成员
```

**团队成员操作**：
```bash
# 导入leader分享的配置
cswitch import team-configs.json

# 查看可用配置
cswitch list

# 使用团队配置
cswitch team-dev
```

### 场景4：紧急切换

**需求**：主要服务突然不可用，需要快速切换到备用服务。

**操作流程**：
```bash
# 快速切换到备用服务
cswitch backup

# 验证切换成功
cswitch status

# 等主要服务恢复后切换回来
cswitch main
```

---

## 故障排除

### 安装问题

#### 问题1：提示"command not found"
**原因**：安装未完成或PATH配置问题

**解决方法**：
```bash
# 重新运行安装脚本
./install.sh

# 重新加载shell配置
source ~/.zshrc

# 或重启终端
```

#### 问题2：权限不足
**原因**：没有写入系统目录的权限

**解决方法**：
安装脚本会自动使用sudo获取权限，按提示输入密码即可。

#### 问题3：Python相关错误
**原因**：系统Python版本过低或未安装

**解决方法**：
```bash
# 检查Python版本
python3 --version

# 如果没有Python3，请安装（macOS用户）
brew install python3
```

### 使用问题

#### 问题1：切换后配置未生效
**原因**：可能是函数模式未正确配置

**解决方法**：
```bash
# 检查shell配置
grep "cswitch" ~/.zshrc

# 如果没有找到，重新安装
./install.sh
```

#### 问题2：配置丢失
**原因**：配置文件可能被误删

**解决方法**：
```bash
# 查看备份文件
ls ~/.claude-configs/backup/

# 恢复备份（选择最新的备份文件）
cp ~/.claude-configs/backup/2024-01-15.json ~/.claude-configs/config.json
```

#### 问题3：API密钥错误
**原因**：输入的API密钥格式不正确

**解决方法**：
```bash
# 重新添加正确的配置
cswitch add correct-name "正确的URL" "正确的密钥" "新配置"

# 删除错误的配置
cswitch remove wrong-name
```

### 配置问题

#### 问题1：无法创建配置文件
**原因**：目录权限问题

**解决方法**：
```bash
# 检查配置目录权限
ls -la ~/.claude-configs/

# 修复权限
chmod 700 ~/.claude-configs/
chmod 600 ~/.claude-configs/config.json
```

#### 问题2：JSON格式错误
**原因**：配置文件被手动修改后格式错误

**解决方法**：
```bash
# 恢复备份
cp ~/.claude-configs/backup/original-zshrc ~/.zshrc

# 重新初始化
cswitch init
```

---

## 常见问题

### Q1：这个工具安全吗？
**A：** 是的，非常安全。
- 所有配置文件都存储在您的个人目录中
- 文件权限设置为仅您可读写
- 不会向外发送任何数据
- 支持备份和恢复功能

### Q2：会影响我现有的配置吗？
**A：** 不会破坏您的配置。
- 安装前会自动备份您的原始配置文件
- 只修改Claude相关的环境变量
- 可以随时恢复到安装前的状态

### Q3：可以在多台电脑上使用吗？
**A：** 可以，通过导入导出功能。
```bash
# 在电脑A上导出
cswitch export ~/my-configs.json

# 传输文件到电脑B，然后导入
cswitch import ~/my-configs.json
```

### Q4：忘记了配置别名怎么办？
**A：** 使用列表命令查看。
```bash
# 查看所有配置
cswitch list

# 或使用交互模式
cswitch
```

### Q5：如何完全卸载这个工具？
**A：** 使用卸载脚本。
```bash
./install.sh uninstall
```
卸载程序会询问是否删除配置文件和shell集成。

### Q6：可以备份我的配置吗？
**A：** 可以，而且会自动备份。
- 每次修改配置都会自动创建备份
- 手动备份：`cswitch export backup.json`
- 备份文件位置：`~/.claude-configs/backup/`

### Q7：切换速度快吗？
**A：** 非常快，通常在0.1秒内完成。
- 切换后立即在当前终端生效
- 新开终端也会自动使用新配置

### Q8：支持Windows吗？
**A：** 目前只支持macOS和Linux。
Windows用户可以使用WSL（Windows Subsystem for Linux）。

### Q9：可以自定义配置文件位置吗？
**A：** 配置文件位置是固定的（`~/.claude-configs/`），这是为了保证一致性和安全性。

### Q10：如何获得技术支持？
**A：** 
- 查看项目目录中的设计文档
- 检查 `docs/` 目录中的技术文档
- 查看 `cursor_prompt.md` 了解工具设计初衷

---

## 总结

Claude配置切换工具让您可以：

✅ **轻松管理**多个Claude API配置  
✅ **快速切换**不同服务，一条命令搞定  
✅ **安全存储**您的API密钥信息  
✅ **自动生效**无需手动重启或重新加载  
✅ **团队协作**支持配置分享和导入导出  
✅ **故障恢复**完善的备份和恢复机制  

无论您是技术新手还是经验丰富的开发者，这个工具都能让您的Claude使用体验更加便捷和高效。

如果您在使用过程中遇到任何问题，请参考本手册的故障排除部分，或查看项目中的其他技术文档。
