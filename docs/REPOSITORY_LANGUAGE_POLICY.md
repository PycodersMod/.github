# PycodersMod 仓库语言规范

## 默认语言

PycodersMod 的 first-party 自然语言默认使用简体中文。适用范围包括 README、文档、贡献/安全说明、仓库简介、架构说明、代码注释、JavaDoc/KDoc、PowerShell 帮助、配置注释、测试注释、TODO/FIXME 中的自然语言、工作流名称与步骤说明、CLI 帮助、面向人的错误和日志、issue/PR 模板说明，以及新提交标题和正文。

## 技术标识保持原样

函数、类、变量、API、schema/JSON 字段、枚举值、错误代码、CLI 参数、Loader、Minecraft、Forge、Fabric、NeoForge、Quilt、LiteLoader、Gradle、Java、PowerShell、GitHub、CurseForge、Modrinth、SHA-256、Pester 和固定状态码等技术标识不翻译。机器协议要求的固定文本同样保持原样。

## 明确例外

- CurseForge `introduction.md`：先写完整英文介绍，再写完整中文翻译；两种语言语义对应，不得交替段落，也不得描述尚未实现的功能。
- 已存在的版本 changelog/release notes：先写完整英文内容，再写完整中文翻译；没有既有日志时不伪造历史记录。
- LICENSE、第三方 NOTICE、vendored 第三方源码、固定上游 fixture、自动生成的上游文件、上游 metadata 与固定协议原文不得为满足中文要求而改写。
- 代码和数据中的技术 identifier 不属于自然语言规范。

## README 与发布页面区分

Mod README 是仓库维护与导航说明，默认中文。发布用的 CurseForge introduction 按双语例外处理。技术资源、游戏翻译文件和第三方格式不得因本规范而破坏其协议要求。

## 提交与隐私

新 commit 标题和正文使用中文；不得为了语言规范改写历史 commit。所有公开文件仍须遵守公开卫生和隐私规范，禁止加入本机绝对路径、私人邮箱、凭据、本机代理或未经允许的个人信息。
