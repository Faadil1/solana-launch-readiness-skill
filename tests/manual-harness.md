# Manual Verification Harness

Manual steps to verify the skill installs correctly, the `no-shared-rpc` rule fires, and `/launch-check` / `/fix-blockers` behave as documented. No automated test framework — run these by hand and compare actual output to the pass criteria below.

---

## 1. Install Test

```bash
bash install.sh
test -f ~/.claude/skills/solana-launch-readiness/SKILL.md
```

**Pass:** `install.sh` exits without error and the second command exits `0` — `SKILL.md` exists at the install path. Re-running `bash install.sh` a second time should also exit cleanly (idempotent).

---

## 2. Custom Install Test

```bash
printf "1\n" | bash install-custom.sh
printf "2\n" | bash install-custom.sh
test -f ./.claude/skills/solana-launch-readiness/SKILL.md
```

**Pass:** Choice `1` installs to `~/.claude/skills/solana-launch-readiness/`. Choice `2` (run from a directory you intend as the project root) installs to `./.claude/skills/solana-launch-readiness/`, and the final `test` command confirms `SKILL.md` exists at that project-relative path.

---

## 3. Rule Test

```bash
mkdir -p /tmp/solana-launch-rule-test
echo 'RPC_URL=https://api.mainnet-beta.solana.com' > /tmp/solana-launch-rule-test/.env
```

Then, with Claude Code pointed at `/tmp/solana-launch-rule-test`, ask it to review or work with that project's RPC configuration.

**Expected warning content:**
- "Shared public Solana mainnet RPC detected"
- Reference to Criterion C1
- Statement that context severity is unknown until `/launch-check` classifies it

**Pass:** The warning fires before Claude continues with the requested task, and includes all three elements above — not a generic "RPC looks fine" or no response at all.

---

## 4. Command Behavior Tests

Using the three cases in `examples/launch-check-cases.md`:

1. For each case, describe the evidence setup to Claude Code (in this conversation or a fresh one) and run `/launch-check`.
2. Compare the actual verdict and named findings against that case's expected output excerpt.
3. For Case 1 (`NOT_LAUNCH_READY`), follow up with `/fix-blockers` and confirm the fixes returned match `skill/remediation.md`'s entries for A1 and C1 — not an invented fix.

---

## 5. Pass Criteria Summary

| # | Check | Pass condition |
|---|---|---|
| 1 | `install.sh` | Installs cleanly, idempotent on re-run |
| 2 | `install-custom.sh` | Both choice `1` and choice `2` install to the correct respective path |
| 3 | `no-shared-rpc` rule | Warning fires with all three required elements before Claude continues |
| 4 | Case 1 | `/launch-check` produces `NOT_LAUNCH_READY` with BLOCKER A1 and BLOCKER C1 |
| 5 | Case 2 | `/launch-check` produces `LAUNCH_READY_WITH_RISKS` with HIGH B1 and HIGH B3 |
| 6 | Case 3 | `/launch-check` produces `LAUNCH_READY` with no BLOCKERs or HIGH risks |
| 7 | `/fix-blockers` | For Case 1, returns fixes matching `skill/remediation.md` entries for A1 and C1, not invented ones |

All seven must pass before considering the skill verified end-to-end.
