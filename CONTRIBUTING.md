# 为 PycodersMod 贡献

感谢你帮助改进 PycodersMod 项目。

## 开发流程

1. 对较大改动或新增兼容目标，先提交 issue 讨论。
2. Fork 仓库并创建聚焦当前工作内容的分支。
3. 改动限制在单个仓库内，并遵循该仓库的构建和测试说明。
4. 向 `main` 提交 Pull Request，说明对用户可见的影响，并附上相关构建或测试结果。
5. 根据评审意见修改，等待仓库代码所有者批准后合并。

默认分支 `main` 受仓库规则保护。issue、提交、Pull Request 和构建产物不得包含本机绝对路径、私人账号信息、凭据、本机代理设置或未经脱敏的本机日志。

所有 first-party 自然语言默认使用中文。详见[仓库语言规范](docs/REPOSITORY_LANGUAGE_POLICY.md)。

## Mod 仓库目录

Mod 工程位于 `<loader>/<Minecraft版本>/` 下，例如 `forge/1.20.1/` 或 `fabric/1.21.6/`。`README.md`、`LICENSE`、`CODEOWNERS` 和 `.gitignore` 等共享元数据留在仓库根目录。详细要求见 [Mod 仓库目录规范](docs/MOD_REPOSITORY_LAYOUT.md)。
