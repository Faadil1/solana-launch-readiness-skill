#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="solana-launch-readiness"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Install to (1) personal ~/.claude/skills/ or (2) project ./.claude/skills/? [1/2]"
read -r choice

case "${choice}" in
  2)
    INSTALL_DIR="./.claude/skills/${SKILL_NAME}"
    ;;
  *)
    INSTALL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
    ;;
esac

mkdir -p "${INSTALL_DIR}"
cp -r "${SCRIPT_DIR}/skill/." "${INSTALL_DIR}/"

echo "✓ solana-launch-readiness skill installed to ${INSTALL_DIR}"
