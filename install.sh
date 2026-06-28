#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="solana-launch-readiness"
INSTALL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${INSTALL_DIR}"
cp -r "${SCRIPT_DIR}/skill/." "${INSTALL_DIR}/"

echo "✓ solana-launch-readiness skill installed to ${INSTALL_DIR}"
