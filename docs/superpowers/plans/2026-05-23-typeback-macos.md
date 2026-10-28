# Typeback macOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个原生 macOS 菜单栏工具，在全局键盘闲置指定秒数后自动切换到用户选择的输入源，默认切换到 ABC。

**Architecture:** 使用 Swift Package 管理源码，拆分为 `TypebackCore` library target 和 `Typeback` executable target。Core 负责偏好设置、输入源、权限、登录项和 idle 监听；App target 负责 SwiftUI 设置窗口、AppKit 菜单栏和生命周期组装。

**Tech Stack:** Swift 5.9 package manifest、SwiftUI、AppKit、Carbon Text Input Source Services、ApplicationServices Accessibility、ServiceManagement、XCTest。

---

## 文件结构

- `Package.swift`：SwiftPM 包定义，包含 `TypebackCore`、`Typeback`、`TypebackCoreTests`。
- `Sources/TypebackCore/PreferencesStore.swift`：偏好设置模型、默认值、`UserDefaults` 持久化和 idle 秒数 clamp。
- `Sources/TypebackCore/InputSource.swift`：输入源展示模型。
- `Sources/TypebackCore/InputSourceManager.swift`：输入源协议和基于 TIS API 的系统实现。
- `Sources/TypebackCore/KeyboardIdleMonitor.swift`：全局/本地键盘事件监听和 idle timer。
- `Sources/TypebackCore/PermissionManager.swift`：Accessibility 权限检测和系统设置跳转。
- `Sources/TypebackCore/LaunchAtLoginManager.swift`：基于 `SMAppService.mainApp` 的开机启动封装。
- `Sources/Typeback/AppController.swift`：应用服务编排、设置变更、权限刷新、idle reset 动作。
- `Sources/Typeback/AppDelegate.swift`：macOS 生命周期入口，隐藏 Dock 图标，启动服务。
- `Sources/Typeback/StatusBarController.swift`：菜单栏图标、菜单项和菜单动作。
- `Sources/Typeback/SettingsWindowController.swift`：AppKit window 包装 SwiftUI 设置页。
- `Sources/Typeback/SettingsView.swift`：设置 UI。
- `Sources/Typeback/TypebackApp.swift`：SwiftUI `@main` 入口。
- `Resources/Info.plist`：打包 `.app` 时使用，包含 `LSUIElement`。
- `scripts/build-app.sh`：构建 release binary 并生成 `dist/Typeback.app`。
- `Tests/TypebackCoreTests/PreferencesStoreTests.swift`：偏好设置默认值、clamp、持久化测试。
- `README.md`：本地构建、运行、权限和打包说明。

## Task 1: SwiftPM 项目骨架

**Files:**
- Create: `Package.swift`
- Create: `.gitignore`
- Create: `README.md`

- [ ] 创建 SwiftPM package manifest，声明 macOS 13.0、`TypebackCore` library、`Typeback` executable 和 `TypebackCoreTests`。
- [ ] 添加 `.gitignore`，忽略 `.build/`、`dist/`、Xcode 用户状态和 macOS 元数据。
- [ ] 添加 README，记录 `swift test`、`swift run Typeback`、`scripts/build-app.sh` 的用途。
- [ ] 运行 `swift package describe`，预期能正确解析 package。

## Task 2: 偏好设置核心与测试

**Files:**
- Create: `Sources/TypebackCore/PreferencesStore.swift`
- Create: `Tests/TypebackCoreTests/PreferencesStoreTests.swift`

- [ ] 先写测试：默认值为 enabled true、idle 10 秒、target ABC、launchAtLogin false。
- [ ] 先写测试：idle 秒数小于 1 时 clamp 到 1，大于 3600 时 clamp 到 3600。
- [ ] 先写测试：写入后用同一个 `UserDefaults` suite 重新创建 store 可以读回持久化值。
- [ ] 实现 `PreferencesStore` 和 `TypebackPreferences`。
- [ ] 运行 `swift test`，预期全部通过。

## Task 3: 输入源、权限、登录项和 idle 监听

**Files:**
- Create: `Sources/TypebackCore/InputSource.swift`
- Create: `Sources/TypebackCore/InputSourceManager.swift`
- Create: `Sources/TypebackCore/PermissionManager.swift`
- Create: `Sources/TypebackCore/LaunchAtLoginManager.swift`
- Create: `Sources/TypebackCore/KeyboardIdleMonitor.swift`

- [ ] 实现 `InputSource` 模型，包含 `id` 和 `localizedName`。
- [ ] 实现 `InputSourceManaging` 协议与 `SystemInputSourceManager`，封装 TIS 枚举、当前输入源读取和按 ID 切换。
- [ ] 实现 `PermissionManaging` 协议与 `AccessibilityPermissionManager`，支持权限检测和打开系统 Accessibility 设置页。
- [ ] 实现 `LaunchAtLoginManaging` 协议与 `SystemLaunchAtLoginManager`，支持读取和设置 `SMAppService.mainApp` 状态。
- [ ] 实现 `KeyboardIdleMonitor`，监听 global/local `keyDown`，按配置 idle 秒数触发 `onIdle`。
- [ ] 运行 `swift test`，预期 core 可编译且测试通过。

## Task 4: App 编排、菜单栏和设置窗口

**Files:**
- Create: `Sources/Typeback/AppController.swift`
- Create: `Sources/Typeback/AppDelegate.swift`
- Create: `Sources/Typeback/StatusBarController.swift`
- Create: `Sources/Typeback/SettingsWindowController.swift`
- Create: `Sources/Typeback/SettingsView.swift`
- Create: `Sources/Typeback/TypebackApp.swift`

- [ ] 实现 `AppController`，负责读取系统状态、响应设置变更、启动/停止 monitor、idle 后切换输入源。
- [ ] 实现 `StatusBarController`，提供启用开关、reset 目标、idle 秒数、权限状态、设置和退出菜单。
- [ ] 实现 `SettingsWindowController`，用 `NSHostingView` 承载 SwiftUI 设置页。
- [ ] 实现 `SettingsView`，提供启用、闲置秒数、输入源选择、开机启动、权限状态和打开系统设置按钮。
- [ ] 实现 `AppDelegate` 和 `TypebackApp`，隐藏 Dock 图标并启动 controller/status bar。
- [ ] 运行 `swift build`，预期 app target 编译通过。

## Task 5: App bundle 打包

**Files:**
- Create: `Resources/Info.plist`
- Create: `scripts/build-app.sh`

- [ ] 添加 `Info.plist`，包含 bundle ID、executable、macOS 13.0 最低版本和 `LSUIElement=true`。
- [ ] 添加 `scripts/build-app.sh`，构建 release binary 并生成 `dist/Typeback.app`。
- [ ] 运行 `scripts/build-app.sh`，预期生成 `dist/Typeback.app`。

## Task 6: 验证与收尾

**Files:**
- Modify: `README.md`

- [ ] 运行 `swift test`。
- [ ] 运行 `swift build`。
- [ ] 运行 `scripts/build-app.sh`。
- [ ] 如 SwiftPM package 支持，运行 `xcodebuild -scheme Typeback -destination 'platform=macOS' build`。
- [ ] 更新 README 中的限制和手动验证步骤。
- [ ] 检查当前目录是否为 Git 仓库；如果不是，跳过 commit，并在最终说明中明确。
