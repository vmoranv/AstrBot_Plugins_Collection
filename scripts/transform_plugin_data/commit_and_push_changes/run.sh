#!/usr/bin/env bash
set -e

echo "=== 开始推送脚本 ==="
echo "仓库: ${GITHUB_REPOSITORY}"
echo "PAT_TOKEN存在: ${PAT_TOKEN:+yes}"

# 验证认证状态
echo "验证Git认证状态..."
if git ls-remote origin HEAD > /dev/null 2>&1; then
  echo "✅ Git认证成功"
else
  echo "❌ Git认证失败，检查PAT_TOKEN权限"
  exit 1
fi

# 添加和提交文件
git add plugin_cache_original.json

# 获取统计信息用于提交信息（与转换输出对齐：扁平对象）
total_plugins=$(jq 'keys | length' plugin_cache_original.json 2>/dev/null || echo "0")
success_repos=$(jq '[.[] | select(.status == "success")] | length' repo_info.json 2>/dev/null || echo "0")

commit_message="🔄 Update plugin cache: $total_plugins plugins, $success_repos fresh updates - $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

git commit -m "$commit_message"

# 推送更改 - 使用最简单直接的方法
echo "推送更改到远程仓库..."

# 设置远程URL使用PAT_TOKEN
git remote set-url origin https://${PAT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git

# 尝试推送
echo "执行推送命令..."
git push origin HEAD:main

echo "✅ 推送成功完成"