#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="solana-launch-readiness"
INSTALL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
REPO_URL="https://github.com/Faadil1/solana-launch-readiness-skill.git"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If running from a cloned repo, use local files.
if [ -d "${SCRIPT_DIR}/skill" ]; then
  SOURCE_DIR="${SCRIPT_DIR}"
else
  # If running via: bash <(curl -fsSL .../install.sh)
  # BASH_SOURCE points to /dev/fd, so clone a temporary copy.
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT
  git clone --depth 1 "${REPO_URL}" "${TMP_DIR}/repo" >/dev/null
  SOURCE_DIR="${TMP_DIR}/repo"
fi

mkdir -p "${INSTALL_DIR}"

cp -R "${SOURCE_DIR}/skill/." "${INSTALL_DIR}/"

if [ -d "${SOURCE_DIR}/commands" ]; then
  mkdir -p "${INSTALL_DIR}/commands"
  cp -R "${SOURCE_DIR}/commands/." "${INSTALL_DIR}/commands/"
fi

if [ -d "${SOURCE_DIR}/rules" ]; then
  mkdir -p "${INSTALL_DIR}/rules"
  cp -R "${SOURCE_DIR}/rules/." "${INSTALL_DIR}/rules/"
fi

echo "Installed ${SKILL_NAME} to ${INSTALL_DIR}"
echo "Available commands: /launch-check, /fix-blockers"
