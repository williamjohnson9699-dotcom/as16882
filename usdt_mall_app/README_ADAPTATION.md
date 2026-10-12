---

# Flutter 项目环境适配说明 (2026-03-02)

针对 `usdt_mall_app` 项目在不同 Flutter/Dart 版本下的兼容性问题，本文档记录了最终验证成功的开发环境配置方案，以避免后续开发中重复触发 SDK 版本冲突及插件编译错误。

## 1. 核心环境要求

经过多次版本测试，本项目最稳定的运行环境配置如下：

| 组件 | 版本 | 说明 |
| --- | --- | --- |
| **Flutter SDK** | **3.24.5** | 避开了 3.41+ 版本的插件弃用问题，同时高于 3.22.0 |
| **Dart SDK** | **3.5.4** | 严格匹配 `pubspec.yaml` 中的 `^3.5.4` 约束 |
| **渠道** | **stable** | 确保生产环境插件的稳定性 |

---

## 2. 环境修复与适配步骤

若重新部署环境，请按以下顺序执行操作：

### 第一步：SDK 版本对齐 (推荐使用 Scoop)

由于项目强依赖 Dart 3.5.4，必须安装对应的 Flutter 3.24.5：

```powershell
# 1. 切换/安装指定版本
scoop install flutter@3.24.5
scoop reset flutter

# 2. 验证版本 (必须确保 Dart 为 3.5.4)
flutter --version

```

### 第二步：依赖清理与重构

由于切换过 SDK 版本，必须清理旧的生成文件和锁文件：

```powershell
# 进入项目根目录
flutter clean
Remove-Item pubspec.lock -ErrorAction SilentlyContinue

# 重新获取依赖
flutter pub get

```

### 第三步：关键代码修复 (已知不兼容项)

由于 `animated_emoji` 插件在 Dart 3.5+ 环境下对部分枚举值的定义发生了变动，需要手动修复聊天页面的报错：

* **文件位置**: `lib/features/chat/screens/chat_page.dart`
* **修复动作**: 将 `AnimatedEmojis.dizzy` 替换为 `AnimatedEmojis.smile`（或其他有效表情）。
* **快捷命令**:
```powershell
(Get-Content lib/features/chat/screens/chat_page.dart) -replace 'AnimatedEmojis.dizzy', 'AnimatedEmojis.smile' | Set-Content lib/features/chat/screens/chat_page.dart

```



---

## 3. 常见坑点排查 (Troubleshooting)

### Q1: `version solving failed` (requires SDK version ^3.5.4)

* **原因**: 当前 Flutter 携带的 Dart 版本低于 3.5.4（如 Flutter 3.24.0 仅带 Dart 3.5.0）。
* **解决**: 必须升级 Flutter 到 **3.24.5**。

### Q2: `unknown SDK ">=3.5.3 <4.0.0"` 或格式错误

* **原因**: 手动修改 `pubspec.yaml` 时编码格式被 PowerShell 改变（变为 UTF-16），或 `environment` 缩进错误。
* **解决**: 确保 `pubspec.yaml` 为 **UTF-8 (无 BOM)** 编码，且格式严格如下：
```yaml
environment:
  sdk: ^3.5.4

```



### Q3: 运行报错 `Member not found: 'dizzy'`

* **原因**: `animated_emoji` 库更新后删除了 `dizzy` 属性。
* **解决**: 执行上述“第三步”中的代码替换命令。

---

## 4. 运行命令

建议优先在安卓模拟器或真机运行：

```powershell
flutter run

```

---
