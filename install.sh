#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="solana-launch-readiness"
INSTALL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
REPO_URL="https://github.com/Faadil1/solana-launch-readiness-skill.git"

TMP_DIR=""

cleanup() {
  if [ -n "${TMP_DIR}" ] && [ -d "${TMP_DIR}" ]; then
    rm -rf "${TMP_DIR}"
  fi
}
trap cleanup EXIT

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" 2>/dev/null && pwd || true)"

if [ -n "${SCRIPT_DIR}" ] && [ -d "${SCRIPT_DIR}/skill" ]; then
  SOURCE_DIR="${SCRIPT_DIR}"
else
  TMP_DIR="$(mktemp -d)"
  git clone --depth 1 "${REPO_URL}" "${TMP_DIR}/repo" >/dev/null
  SOURCE_DIR="${TMP_DIR}/repo"
fi

mkdir -p "${INSTALL_DIR}"

cp -R "${SOURCE_DIR}/skill/." "${INSTALL_DIR}/"

mkdir -p "${INSTALL_DIR}/commands"
cp -R "${SOURCE_DIR}/commands/." "${INSTALL_DIR}/commands/"

mkdir -p "${INSTALL_DIR}/rules"
cp -R "${SOURCE_DIR}/rules/." "${INSTALL_DIR}/rules/"

echo "Installed ${SKILL_NAME} to ${INSTALL_DIR}"
echo "Available commands: /launch-check, /fix-blockers"
