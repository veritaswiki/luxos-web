# 贡献指南

感谢你考虑为 Luxos Web 项目做出贡献！

## 开发流程

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交你的更改 (`git commit -m '添加一些很棒的特性'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## Pull Request 指南

1. 更新 README.md，包含新功能的说明（如果适用）
2. 更新文档，说明任何更改
3. PR 应该指向 `main` 分支

## 开发设置

1. 克隆你 fork 的仓库
   ```bash
   git clone https://github.com/你的用户名/luxos-web.git
   cd luxos-web
   ```

2. 安装开发依赖
   ```bash
   # 确保已安装 Docker 和 Docker Compose
   docker-compose up -d
   ```

## 代码风格

- Shell 脚本遵循 [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- 使用 4 个空格进行缩进
- 每个文件末尾保留一个空行
- 删除尾随空格

## 提交消息指南

- 使用现在时态 ("Add feature" 而不是 "Added feature")
- 第一行是对更改的简短总结（50 个字符或更少）
- 如果需要，可以添加更详细的解释性文本
- 使用 markdown 格式

例如：
```
添加自动备份功能

- 实现每日自动备份
- 添加备份轮转
- 配置备份保留策略
```

## 报告 Bug

报告 bug 时，请包含：

- 你的操作系统版本
- Docker 和 Docker Compose 版本
- 问题的详细描述
- 重现步骤
- 预期行为
- 实际行为
- 相关日志输出

## 功能请求

- 使用 issue 模板
- 清楚地描述你想要的功能
- 解释为什么这个功能会对项目有用
- 提供可能的实现方案

## 行为准则

### 我们的承诺

为了营造开放和友好的环境，我们承诺：

- 使用友好和包容的语言
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情

### 不可接受的行为

不可接受的行为包括：

- 使用性化语言或图像
- 挑衅、侮辱或贬低性评论
- 公开或私下骚扰
- 未经明确许可发布他人信息
- 其他不道德或不专业的行为

## 许可

通过贡献你的代码，你同意你的贡献将在 MIT 许可下获得许可。 