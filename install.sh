#!/usr/bin/env bash

set -euo pipefail

SKILL_NAME="chinese-literature-review-writing"
REPOSITORY="tanqi87/chinese-literature-review-writing-skill"
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
DESTINATION_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
TEMP_DOWNLOAD_DIR=""
STAGING_DIR=""

show_help() {
  printf '%s\n' \
    "安装中文论文综述写作 Skill" \
    "" \
    "用法：" \
    "  bash install.sh" \
    "  bash install.sh --dest /指定的/skills/目录" \
    "" \
    "说明：" \
    "  默认安装到 ~/.codex/skills/" \
    "  如果已经存在同名 Skill，安装程序会停止，不会覆盖原文件。"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "错误：--dest 后需要提供目录。"
        exit 2
      fi
      DESTINATION_ROOT="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "错误：不支持的参数：$1"
      show_help
      exit 2
      ;;
  esac
done

DESTINATION_DIR="$DESTINATION_ROOT/$SKILL_NAME"

cleanup() {
  if [[ -n "$STAGING_DIR" && -d "$STAGING_DIR" ]]; then
    rm -rf "$STAGING_DIR"
  fi
  if [[ -n "$TEMP_DOWNLOAD_DIR" && -d "$TEMP_DOWNLOAD_DIR" ]]; then
    rm -rf "$TEMP_DOWNLOAD_DIR"
  fi
}
trap cleanup EXIT

if [[ -e "$DESTINATION_DIR" ]]; then
  echo "已检测到同名 Skill：$DESTINATION_DIR"
  echo "为避免覆盖你的文件，本次没有执行安装。"
  exit 0
fi

SOURCE_DIR=""

if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  SOURCE_DIR="$SCRIPT_DIR/$SKILL_NAME"
fi

if [[ -z "$SOURCE_DIR" || ! -f "$SOURCE_DIR/SKILL.md" ]]; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "错误：未找到 curl，无法下载安装包。"
    exit 1
  fi

  TEMP_DOWNLOAD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/literature-review-skill.XXXXXX")"
  ARCHIVE_PATH="$TEMP_DOWNLOAD_DIR/repository.zip"
  EXTRACT_PATH="$TEMP_DOWNLOAD_DIR/extracted"
  mkdir -p "$EXTRACT_PATH"

  echo "正在从 GitHub 下载 Skill…"
  curl -fsSL "https://github.com/$REPOSITORY/archive/refs/heads/main.zip" -o "$ARCHIVE_PATH"

  if command -v ditto >/dev/null 2>&1; then
    ditto -x -k "$ARCHIVE_PATH" "$EXTRACT_PATH"
  elif command -v unzip >/dev/null 2>&1; then
    unzip -q "$ARCHIVE_PATH" -d "$EXTRACT_PATH"
  else
    echo "错误：未找到 ditto 或 unzip，无法解压安装包。"
    exit 1
  fi

  SOURCE_DIR="$EXTRACT_PATH/chinese-literature-review-writing-skill-main/$SKILL_NAME"
fi

REQUIRED_FILES=(
  "SKILL.md"
  "agents/openai.yaml"
  "references/retrieval-rules.md"
  "references/writing-rules.md"
)

for REQUIRED_FILE in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$SOURCE_DIR/$REQUIRED_FILE" ]]; then
    echo "错误：安装包中缺少 $SKILL_NAME/$REQUIRED_FILE。"
    exit 1
  fi
done

mkdir -p "$DESTINATION_ROOT"
STAGING_DIR="$(mktemp -d "$DESTINATION_ROOT/.${SKILL_NAME}.install.XXXXXX")"
cp -R "$SOURCE_DIR"/. "$STAGING_DIR"/

for REQUIRED_FILE in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$STAGING_DIR/$REQUIRED_FILE" ]]; then
    echo "错误：复制后的 Skill 文件不完整，缺少 $REQUIRED_FILE。"
    exit 1
  fi
done

mv "$STAGING_DIR" "$DESTINATION_DIR"
STAGING_DIR=""

echo
echo "安装完成：$DESTINATION_DIR"
echo "请重新打开 Codex 或开始一个新对话，然后使用："
echo "  \$chinese-literature-review-writing"
