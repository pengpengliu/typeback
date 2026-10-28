# Typeback

Typeback 是一个原生 macOS 菜单栏工具：全局键盘闲置指定秒数后，自动把当前输入源切换回用户选择的输入源，默认是 ABC。

## 本地开发

运行测试：

```bash
swift test
```

运行开发版：

```bash
swift run Typeback
```

开发版会调用 `NSApp.setActivationPolicy(.accessory)` 隐藏 Dock 图标。首次使用全局键盘监听前，需要在系统设置中授予 Accessibility 权限。

## 权限

Typeback 通过全局 `keyDown` 事件判断键盘闲置状态，因此需要 Accessibility 权限。

授权路径：

```text
System Settings -> Privacy & Security -> Accessibility
```

如果未授权，应用会继续常驻，但不会启动全局键盘监听。

## 打包

生成本地 `.app`：

```bash
scripts/build-app.sh
```

输出路径：

```text
dist/Typeback.app
```

构建 Intel + Apple Silicon 通用版本：

```bash
ARCHS="arm64 x86_64" scripts/build-app.sh
```

### GitHub Actions

`.github/workflows/build.yml` 会在推送到 `main` 和提交 PR 时运行测试、构建通用 `.app`，并把 `Typeback.zip` 作为 workflow artifact 上传。

推送 `v*` 标签时会额外用标签号设置版本，并创建 GitHub Release：

```bash
git tag v0.1.0
git push origin v0.1.0
```

第一版只覆盖本地开发构建和标准 Xcode 签名流程，不包含 Developer ID 分发。

## 手动验证清单

- 启动 `dist/Typeback.app` 后，菜单栏出现 Typeback 图标。
- Dock 不显示 Typeback 图标。
- 未授予 Accessibility 权限时，菜单和设置窗口显示权限缺失。
- 授权后点击“重新检查”，监听无需重启即可生效。
- 切换到非 ABC 输入源，停止键盘输入 10 秒后自动切回 ABC。
- 修改闲置秒数后，新的计时立即生效。
- 修改目标输入源后，下一次 idle reset 使用新目标。
- 关闭“启用自动切换”后，不再监听和切换输入源。
- 开机自动启动开关能同步系统登录项状态。

## 当前限制

- 不支持按应用设置不同输入法规则。
- 鼠标、触控板、滚动和窗口焦点变化不会重置 idle timer。
- 第一版只做本地 `.app` 打包和 ad-hoc 签名；正式分发仍需要 Developer ID 签名、公证和发布流程。
