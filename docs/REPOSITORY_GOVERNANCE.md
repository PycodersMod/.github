# PycodersMod 仓库治理规范

本规范适用于 PycodersMod 组织维护的仓库。

## 所有权与评审

- `main` 是默认集成分支。
- 贡献者的改动通过 Pull Request 提交。
- Pull Request 至少需要一项批准和代码所有者评审；新提交后旧批准作废。
- `@ZYQ-2020` 是代码所有者，也是 Collaboration Gate 中唯一配置的绕过账号。
- 独立的 History Safety 规则禁止强制推送和删除默认分支，且没有绕过账号。
- 本规范不添加组织级或管理员级的广泛绕过权限。

## 本地开发与发布

新提交使用仓库本地 Git 身份：账号 `ZYQ-2020` 和 GitHub 提供的 noreply 邮箱。项目工作不得修改全局 Git 身份。提交信息和发布日志不得包含本机绝对路径、私人信息、私人邮箱、主机名或本机代理设置。

## 应用和审计规则

使用 `scripts/Apply-PycodersModGovernance.ps1 -Repo <仓库名>` 将规则应用到一个仓库，使用 `-All` 应用到组织仓库清单，或使用 `-Audit` 检查仓库规则和 `main` 上生效的规则。脚本要求 GitHub CLI 登录账号为 `ZYQ-2020`，实时查询账号数字 ID，并使用 repository-level ruleset API；不要求组织级 ruleset 管理权限。

## 新仓库引导顺序

每个新仓库均按以下顺序完成引导：

1. 在 PycodersMod 组织中创建仓库。
2. 将默认分支初始化为 `main`。
3. 设置仓库本地 Git 身份为 `ZYQ-2020` 及其 GitHub noreply 邮箱，不修改全局 Git 身份。
4. 在仓库根目录添加归属 `@ZYQ-2020` 的 `CODEOWNERS`。
5. 若为 Mod 仓库，将每个可构建工程放在 `<loader>/<兼容线>/` 下，共享元数据留在根目录；单版本目标使用精确 Minecraft 版本目录，详见 `MOD_REPOSITORY_LAYOUT.md`。
6. 发布前运行公开卫生扫描并解决所有发现。
7. 将初始内容推送到 `main`。
8. 使用 `scripts/Apply-PycodersModGovernance.ps1 -Repo <仓库名>` 应用仓库治理规则。
9. 使用 `scripts/Apply-PycodersModGovernance.ps1 -Audit` 审计 ruleset 和 `main` 生效规则。
10. 只有审计通过后，才将仓库标记为可正常开发。

每个新仓库都必须加入脚本的显式仓库清单，并在根目录添加 `CODEOWNERS`。修改治理脚本时先以 `.github` canary 验证，再应用到其它仓库。

## 临时克隆与稀疏检出

Mod 仓库可只检出单个工程目录：

```powershell
git clone --filter=blob:none --sparse https://github.com/PycodersMod/SharecodeChest.git <TEMP_DIR>/sharecodechest-sparse
git -C <TEMP_DIR>/sharecodechest-sparse sparse-checkout set forge/1.20.1
```

所选 Loader/版本目录可独立出现在工作树中。只有确认没有进程使用临时克隆，且其中不再存有唯一证据后，才可将其删除。
