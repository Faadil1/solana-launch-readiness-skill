#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $1"
  exit 1
}

pass() {
  echo "PASS: $1"
}

# 1. Required files
for f in \
  README.md LICENSE CLAUDE.md install.sh install-custom.sh \
  skill/SKILL.md skill/security.md skill/testing.md skill/rpc.md skill/docs.md skill/demo.md skill/remediation.md \
  commands/launch-check.md commands/fix-blockers.md \
  rules/no-shared-rpc.md \
  examples/launch-check-cases.md tests/manual-harness.md
do
  test -f "$f" || fail "missing $f"
done
pass "required files exist"

# 2. 19 criteria IDs in core files
for id in A1 A2 A3 A4 A5 B1 B2 B3 B4 C1 C2 C3 C4 D1 D2 D3 E1 E2 E3
do
  grep -q "$id" skill/SKILL.md || fail "$id missing from skill/SKILL.md"
  grep -q "$id" skill/remediation.md || fail "$id missing from skill/remediation.md"
done
pass "all 19 criteria present in SKILL.md and remediation.md"

# 3. Domain module coverage
for id in A1 A2 A3 A4 A5; do grep -q "$id" skill/security.md || fail "$id missing from security.md"; done
for id in B1 B2 B3 B4; do grep -q "$id" skill/testing.md || fail "$id missing from testing.md"; done
for id in C1 C2 C3 C4; do grep -q "$id" skill/rpc.md || fail "$id missing from rpc.md"; done
for id in D1 D2 D3; do grep -q "$id" skill/docs.md || fail "$id missing from docs.md"; done
for id in E1 E2 E3; do grep -q "$id" skill/demo.md || fail "$id missing from demo.md"; done
pass "domain modules cover expected IDs"

# 4. Verdict language
grep -q "NOT_LAUNCH_READY" skill/SKILL.md || fail "NOT_LAUNCH_READY missing"
grep -q "LAUNCH_READY_WITH_RISKS" skill/SKILL.md || fail "LAUNCH_READY_WITH_RISKS missing"
grep -q "LAUNCH_READY" skill/SKILL.md || fail "LAUNCH_READY missing"
grep -q "19 Criteria" skill/SKILL.md || fail "19 Criteria heading missing"
! grep -R --exclude-dir=.git --exclude=cloud-sanity.sh "18 Criteria\|18-criteria" . >/dev/null || fail "stale 18 criteria reference found"
pass "verdict language and 19 criteria count valid"

# 5. Commands
grep -q "STEP 0" commands/launch-check.md || fail "STEP 0 missing from launch-check"
grep -q "remediation.md" commands/launch-check.md || fail "remediation.md missing from launch-check"
grep -q "/launch-check" commands/fix-blockers.md || fail "/launch-check missing from fix-blockers"
grep -q "remediation.md" commands/fix-blockers.md || fail "remediation.md missing from fix-blockers"
pass "commands reference expected flow"

# 6. Rule triggers
grep -q "api.mainnet-beta.solana.com" rules/no-shared-rpc.md || fail "public RPC trigger missing"
grep -q "clusterApiUrl" rules/no-shared-rpc.md || fail "clusterApiUrl trigger missing"
grep -q "C1" rules/no-shared-rpc.md || fail "C1 missing from no-shared-rpc"
grep -q "/launch-check" rules/no-shared-rpc.md || fail "/launch-check missing from no-shared-rpc"
pass "no-shared-rpc rule triggers valid"

# 7. README proof
grep -q "doesn't help you ship faster" README.md || fail "README positioning line missing"
grep -q "/launch-check" README.md || fail "README missing /launch-check"
grep -q "/fix-blockers" README.md || fail "README missing /fix-blockers"
grep -q "api.mainnet-beta.solana.com" README.md || fail "README missing rule example"
grep -q "Faadil1" README.md || fail "README install URL does not include Faadil1"
pass "README proof sections valid"

# 8. Example cases
grep -q "MAINNET_WITH_FUNDS" examples/launch-check-cases.md || fail "Case 1 context missing"
grep -q "NOT_LAUNCH_READY" examples/launch-check-cases.md || fail "Case 1 verdict missing"
grep -q "LAUNCH_READY_WITH_RISKS" examples/launch-check-cases.md || fail "Case 2 verdict missing"
grep -q "DEMO_HACKATHON" examples/launch-check-cases.md || fail "Case 3 context missing"
pass "example cases present"

# 9. Installer executable
test -x install.sh || fail "install.sh not executable"
test -x install-custom.sh || fail "install-custom.sh not executable"
pass "installers executable"

# 10. Forbidden phrases
for phrase in \
  "comprehensive checklist" \
  "best practices" \
  "ensure your project is secure" \
  "helps you launch with confidence" \
  "AI-powered analysis" \
  "improve security" \
  "review your code" \
  "production-ready RPC"
do
  ! grep -R -i --exclude-dir=.git --exclude=cloud-sanity.sh "$phrase" . >/dev/null || fail "forbidden phrase found: $phrase"
done
pass "forbidden phrase scan clean"

echo
echo "ALL CLOUD SANITY CHECKS PASSED"
