# 版本与分支策略

## 目标

让部署文档仓库和 Signal 上游版本建立明确映射，避免“文档是一版、脚本是一版、真正能跑的是另一版”。

## 约定

- `main`
  持续维护主分支，可以包含尚未完全验证的新版本准备工作。
- `signal-server/<tag>`
  已验证分支，直接对应某个 `Signal-Server` tag。

示例：

- `signal-server/v20260324.1.0`

## 版本清单

每个已验证分支都应包含：

- `versions/current.env`
  当前分支的默认上游版本。
- `versions/<signal-server-tag>.env`
  与分支名一致的快照文件。

## 更新流程

1. 从 `main` 或上一条已验证分支切新分支，例如 `signal-server/v20260401.1.0`
2. 更新 `versions/current.env`
3. 同步新增 `versions/v20260401.1.0.env`
4. 运行：
   - `./scripts/bootstrap-upstream.sh`
   - `./scripts/dev-up.sh`
   - `./scripts/desktop-up.sh`（如果要验证桌面端）
5. 根据上游改动调整：
   - `patches/Signal-Server/*`
   - `patches/Signal-Desktop/*`
   - `deploy/config/signal-server.yml.tmpl`
   - 文档中的兼容性说明
6. 验证通过后，把该分支作为该版本的发布分支推送到 GitHub

## 为什么以 `Signal-Server` 为主版本

这套部署的核心是服务端环境是否能跑通，所以分支主锚点放在 `Signal-Server` 最合理。`registration-service` 和 `Signal-Desktop` 则作为同一分支里的配套钉住版本。

## 建议在 PR 中检查的内容

- `Signal-Server` 是否仍能完成启动
- `registration-service` 是否仍能完成本地验证码验证
- `dynamic-config` 和 `asn` 初始化对象是否仍可被消费
- `Signal-Desktop` 是否还能走 standalone
- 本地补丁是否仍然最小且明确
