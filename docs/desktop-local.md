# Signal-Desktop 本地调试

## 两种使用方式

### 1. Standalone Device

这是最快的本地验证路径。

- 不需要 Android 主设备
- 直接让 Desktop 连到本地 `signal-server`
- 可以验证注册、配置加载、WebSocket、基础接口联通性

启动方式：

```bash
./scripts/dev-up.sh
./scripts/desktop-up.sh
```

进入桌面端后，在二维码页选择：

- `File -> Set Up as Standalone Device`

本地规则：

- captcha：`noop.noop.registration.localtest`
- 验证码：手机号后 6 位

### 2. Link Device

这是“扫二维码绑定主设备”的链路。

前提：

- 主设备也必须接到这套本地环境
- 最适合的是本地改过服务地址的 Android 版

注意：

- 官方商店里安装的 Signal Android / iOS 默认连的是官方环境
- 它们不能直接扫这套本地 Desktop

## 这个仓库对 Desktop 做了什么

- 给 `Signal-Desktop` 打最小补丁
- 增加 `scripts/start-local-dev.sh`
- 启动时把以下配置注入 `NODE_CONFIG`
  - `serverUrl`
  - `storageUrl`
  - `directoryUrl`
  - `cdn`
  - `challengeUrl`
  - `registrationChallengeUrl`
  - `certificateAuthority`
  - `serverPublicParams`
  - `hardcodedCaptchaForLocalTestingOnly`

## macOS 上的兼容性说明

本项目对两个容易卡住的原生模块做了降级处理：

- `fs-xattr`
  编不过时不再阻塞 preload 整体启动。
- `@indutny/mac-screen-share`
  缺失时退回 Electron 的桌面捕获路径。

这意味着：

- 注册和基础聊天调试不受影响
- 屏幕共享相关功能不保证可用
