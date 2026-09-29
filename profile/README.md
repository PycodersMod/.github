# PycodersMod

PycodersMod 是一组由 Pycoder 自主研发的 Minecraft Java Edition Mod 项目，涵盖独立模组、跨 Mod 联动、功能扩展、开发框架与相关开发工具。

项目以长期维护、实际游玩需求、兼容性探索和 Mod 开发实践为导向，并持续覆盖不同 Minecraft 版本以及 Forge、NeoForge、Fabric 等 Mod Loader。

当前 10 个 Mod 仓库中，4 个已公开源码、6 个仍为 Private。MinecraftModTestLauncher 暂为 Private，待历史隐私缓存清除后再公开。各仓库可见性以 GitHub 当前状态为准。

## 装饰

### Facade
面向建筑场景的可配置装饰立面方块。

- Minecraft：1.20.1
- Loader：Forge
- 状态：Alpha；仓库可见性：Public
- Repository：[PycodersMod/Facade](https://github.com/PycodersMod/Facade)

## 冒险

### Poetry Cloud Planets
为 Minecraft 世界加入诗意主题的特殊星球与维度内容。

- Minecraft：1.20.1
- Loader：Forge
- 状态：Alpha；仓库可见性：Private（源码暂未公开）
- Repository：[PycodersMod/PoetryCloudPlanets](https://github.com/PycodersMod/PoetryCloudPlanets)（Private）

## 实用

### SharecodeChest
提供可记录和分享战利品领取信息的特殊容器。

- Minecraft：1.20.1
- Loader：Forge
- 状态：开发中；仓库可见性：Public
- Repository：[PycodersMod/SharecodeChest](https://github.com/PycodersMod/SharecodeChest)

### JournalMod
在游戏内以书籍界面记录和阅读日志内容。

- Minecraft：1.20.1
- Loader：Forge
- 状态：Alpha；仓库可见性：Private（源码暂未公开）
- Repository：[PycodersMod/JournalMod](https://github.com/PycodersMod/JournalMod)（Private）

## 辅助

### Tetra Holographic Blueprint
为 Tetra 工作台规划材料与蓝图装配流程。

- Minecraft：1.20.1
- Loader：Forge
- 状态：Alpha；仓库可见性：Private（源码暂未公开）
- Repository：[PycodersMod/TetraHolographicBlueprint](https://github.com/PycodersMod/TetraHolographicBlueprint)（Private）

### CarpetPlayerAddition
扩展 Carpet 假人 /player 命令的物品栏操作能力。

- Minecraft：1.21.6
- Loader：Fabric
- 状态：开发中；仓库可见性：Public
- Repository：[PycodersMod/CarpetPlayerAddition](https://github.com/PycodersMod/CarpetPlayerAddition)

## 魔改

### Create Probability Tuning
为 Create 加工配方调校概率输出行为。

- Minecraft：1.21.1
- Loader：NeoForge
- 状态：活跃开发；仓库可见性：Private（源码暂未公开）
- Repository：[PycodersMod/CreateProbabilityTuning](https://github.com/PycodersMod/CreateProbabilityTuning)（Private）

### TaCZ in Tetra
连接 TaCZ 枪械与 Tetra 模块系统，提供可配置的组合与兼容内容。

- Minecraft：1.20.1
- Loader：Forge
- 状态：Alpha；仓库可见性：Private（源码暂未公开）
- Repository：[PycodersMod/TaCZinTetra](https://github.com/PycodersMod/TaCZinTetra)（Private）

## LIB

### CustomShapezAPI
为 Shapez 相关内容提供 Minecraft Forge API 扩展；当前仍处于功能骨架阶段。

- Minecraft：1.20.1
- Loader：Forge
- 状态：骨架阶段；仓库可见性：Private（源码暂未公开）
- Repository：[PycodersMod/CustomShapezAPI](https://github.com/PycodersMod/CustomShapezAPI)（Private）

### CustomTamingFramework
为自定义生物驯服行为提供可复用的框架能力。

- Minecraft：1.20.1
- Loader：Forge
- 状态：Alpha；仓库可见性：Public
- Repository：[PycodersMod/CustomTamingFramework](https://github.com/PycodersMod/CustomTamingFramework)

## 开发工具

### MinecraftModTestLauncher
面向 Windows 10/11 的 Minecraft Java Edition Mod 开发环境启动器，支持 Forge、NeoForge、Fabric 项目检测，Java/Gradle 环境解析、构建、隔离 Session、多玩家客户端编排、Integrated LAN 与 Dedicated 模式。

- 仓库可见性：Private（历史隐私修复验证中）；Windows CI 与 Pester 测试通过
- GitHub：[PycodersMod/MinecraftModTestLauncher](https://github.com/PycodersMod/MinecraftModTestLauncher)
