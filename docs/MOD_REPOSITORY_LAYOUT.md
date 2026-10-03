# Mod 仓库目录规范

每个 Mod 仓库的共享元数据保留在根目录；每个可构建项目放在 `<loader>/<Minecraft版本或兼容线>/`。

```text
README.md
LICENSE
CODEOWNERS
forge/1.20.1/
fabric/1.21.6/
neoforge/1.21.1/
```

Loader 目录使用小写规范名称。README 的“支持目标”HTML 表格是**当前仓库内的目录导航**，不是官网导航：Loader 链接使用 `<loader>/`，Minecraft 链接使用 `<loader>/<兼容线>/`。例如：

```html
<a href="forge/">Forge</a>
<a href="forge/1.20.1/">1.20.1</a>
```

以下链接不得放在“支持目标”表格中：

```html
<a href="https://files.minecraftforge.net/">Forge</a>
<a href="https://minecraft.net/">1.20.1</a>
```

Loader 固定顺序为 Fabric、Forge、NeoForge、Quilt、LiteLoader、Legacy Fabric、Ornithe Loader、Rift、ModLoader、ModLoaderMP、JarMod、Other，不按字母顺序排列。Minecraft 兼容线按 Mojang 正式版本 `releaseTime` 从新到旧排序，不能按版本字符串排序；范围以其中最新的正式版本决定排序位置。同一 Loader 有多个兼容线时，Loader 单元格只显示一次，并以 `rowspan` 覆盖对应版本行。Loader 链接文本使用 Loader 的规范名称，版本链接文本和目标目录名称一致（显示范围可用 en dash，目录范围用连字符）。

目标分类按实际运行时判断：选用 Fabric Loader 的 Ploceus、Ornithe 生态项目列为 Fabric；仅当 Ornithe Loader 本身是运行时时才标作 Ornithe Loader。

每次修改 Mod README 后，在本机完整仓库工作区运行：

```powershell
& .github/scripts/Test-ModReadmeTargets.ps1 -WorkspaceRoot <WORKSPACE_ROOT>
```

也可用 `-RepositoryRoot <REPOSITORY_ROOT>` 单独检查一个 Mod。审计器检查表格标题和结构、Loader/Minecraft href 的相对路径语义、目标目录存在性、Loader 顺序、同 Loader 版本发布日期顺序、表格外链和未解析模板表达式；任何问题都会以非零状态结束。外部 Loader 官网可放在独立的“上游项目”或“相关链接”章节，不得占用目录导航表格。

新增目标时不要移动仓库根元数据。除非文件确实由多个目标共享且有说明，否则 `.gitignore`、构建文件、Wrapper、资源和 source set 均保留在目标目录。运行时依赖路径应使用 workspace runtime root 或从祖先目录发现，不得假定相对构建文件的固定层级。

该目录结构支持只检出一个目标目录，例如：`git sparse-checkout set forge/1.20.1`。
