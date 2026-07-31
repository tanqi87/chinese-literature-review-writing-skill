#!/bin/bash

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER="$SCRIPT_DIR/install.sh"

echo "中文论文综述写作 Skill 安装程序"
echo

if [[ -f "$INSTALLER" ]]; then
  /bin/bash "$INSTALLER" "$@"
else
  /usr/bin/curl -fsSL \
    "https://raw.githubusercontent.com/tanqi87/chinese-literature-review-writing-skill/main/install.sh" \
    | /bin/bash -s -- "$@"
fi

INSTALL_STATUS=$?

echo
if [[ $INSTALL_STATUS -eq 0 ]]; then
  echo "操作已完成。"
else
  echo "安装没有完成，请查看上方提示。"
fi

read -r -p "按回车键关闭窗口…"
exit "$INSTALL_STATUS"
