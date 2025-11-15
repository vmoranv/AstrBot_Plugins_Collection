#!/usr/bin/env bash
set -e

echo "=== GitHub权限诊断脚本 ==="
echo "仓库: ${GITHUB_REPOSITORY}"
echo "PAT_TOKEN存在: ${PAT_TOKEN:+yes}"

# 1. 测试PAT_TOKEN的基本权限
echo "1. 测试PAT_TOKEN基本权限..."
response=$(curl -s -H "Authorization: token ${PAT_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/user")

if echo "$response" | jq -e '.login' > /dev/null 2>&1; then
  user=$(echo "$response" | jq -r '.login')
  echo "✅ PAT_TOKEN认证成功，用户: $user"
else
  echo "❌ PAT_TOKEN认证失败"
  echo "$response"
  exit 1
fi

# 2. 检查仓库权限
echo "2. 检查仓库权限..."
repo_response=$(curl -s -H "Authorization: token ${PAT_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}")

if echo "$repo_response" | jq -e '.full_name' > /dev/null 2>&1; then
  repo_name=$(echo "$repo_response" | jq -r '.full_name')
  repo_permissions=$(echo "$repo_response" | jq -r '.permissions')
  echo "✅ 仓库访问成功: $repo_name"
  echo "权限: $repo_permissions"
  
  # 检查是否有推送权限
  can_push=$(echo "$repo_response" | jq -r '.permissions.push // false')
  if [ "$can_push" = "true" ]; then
    echo "✅ 具有推送权限"
  else
    echo "❌ 没有推送权限"
  fi
else
  echo "❌ 无法访问仓库"
  echo "$repo_response"
fi

# 3. 检查分支保护规则
echo "3. 检查main分支保护规则..."
branch_response=$(curl -s -H "Authorization: token ${PAT_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/branches/main")

if echo "$branch_response" | jq -e '.protected' > /dev/null 2>&1; then
  is_protected=$(echo "$branch_response" | jq -r '.protected')
  if [ "$is_protected" = "true" ]; then
    echo "⚠️ main分支受保护"
    echo "保护规则: $(echo "$branch_response" | jq -r '.protection')"
  else
    echo "✅ main分支未受保护"
  fi
else
  echo "❌ 无法获取分支信息"
fi

# 4. 测试Git推送权限
echo "4. 测试Git推送权限..."
git ls-remote origin HEAD > /dev/null 2>&1 && echo "✅ Git读取权限正常" || echo "❌ Git读取权限失败"

echo "=== 诊断完成 ==="