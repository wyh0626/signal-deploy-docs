# 补丁说明

English: [./en/patches.md](./en/patches.md)

这个仓库的核心原则之一是：尽量保留上游行为，补丁只解决“本地 dev 无法启动或无法联通”的问题。

## 为什么要有补丁

即使基础设施都能本地替代，仍然有两类问题很难只靠配置解决：

- 上游默认假设存在某些线上凭证或可信运行环境
- 桌面端开发依赖的原生模块，在本地开发机上经常编不过或缺失

所以这里的补丁目标不是“改造 Signal”，而是：

- 给本地环境补一个明确的、最小的入口
- 让功能缺失时优雅降级，而不是整个进程直接崩掉

## 当前补丁清单

### `patches/Signal-Server/0001-local-dev-registration-and-noop-pubsub.patch`

改动目的：

- 新增 `registrationService.type=local`
  允许 `signal-server` 用本地明文 gRPC 连接 `registration-service`，不依赖线上 identity token。
- 新增 `pubSubPublisher.type=noop`
  让依赖 Google Pub/Sub publisher 的模块在本地可以 no-op 跑起来。

影响范围：

- 只影响本地开发配置分支
- 不改变默认生产配置类型

### `patches/Signal-Desktop/0001-local-dev-desktop-fallbacks.patch`

改动目的：

- `fs-xattr` 缺失时，不让 preload 整体失败
- `@indutny/mac-screen-share` 缺失时，给出 fallback 而不是直接崩
- 新增 `scripts/start-local-dev.sh`
  通过 `NODE_CONFIG` 注入本地 `signal-server` 地址、证书和 captcha

影响范围：

- 主要影响本地 Electron 开发体验
- 屏幕共享相关能力不是这个仓库的验证重点

## 维护原则

- 能靠配置解决，就不要打补丁
- 能做成新增类型或 no-op 工厂，就不要改默认逻辑
- 每个补丁都应该能用一句话解释“为什么非它不可”
- 上游一旦提供正式配置入口，优先删补丁而不是继续累积

## 如何更新补丁

1. 在 `upstream/` 里的对应仓库修改本地代码
2. 确认改动确实是最小集合
3. 重新导出 patch 到 `patches/`
4. 跑 `./scripts/bootstrap-upstream.sh`
5. 跑 `./scripts/apply-local-patches.sh`
6. 跑 `./scripts/dev-up.sh --smoke-test`
7. 如果改到了桌面端，再跑 `./scripts/desktop-up.sh`

## 什么时候应该删补丁

- 上游已经提供正式配置入口
- 本地场景已经不再需要这个行为
- 补丁只是绕过旧问题，但新版本已经自然修复
