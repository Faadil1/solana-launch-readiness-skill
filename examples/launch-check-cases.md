# /launch-check — Expected Cases

Three reference cases for verifying `/launch-check` behavior. Each case states the launch context, the evidence setup that should be assumed or simulated, and the verdict and findings that output is expected to match.

These are proof references for manual verification — not a fake Solana project. No actual program, repo, or deployment is created; the evidence below is described to Claude Code as the state of a hypothetical project when running `/launch-check`.

---

## Case 1 — MAINNET_WITH_FUNDS → NOT_LAUNCH_READY

**Context:** `MAINNET_WITH_FUNDS`

**Evidence setup:**
- Upgrade authority is a single-keypair hot wallet (no Squads multisig, not revoked).
- RPC configuration contains `api.mainnet-beta.solana.com`.

**Expected findings:** `BLOCKER A1`, `BLOCKER C1`

**Expected output excerpt:**
```
NOT_LAUNCH_READY

BLOCKER A1 — Upgrade authority is a hot wallet.
  Fix: solana program set-upgrade-authority <PROGRAM_ID> <SQUADS_MULTISIG_ADDRESS>

BLOCKER C1 — Production RPC is api.mainnet-beta.solana.com.
  Fix: set RPC_URL to a dedicated Helius/Triton endpoint before launch.
```

**Pass condition:** Verdict is exactly `NOT_LAUNCH_READY`. Both A1 and C1 appear under BLOCKERs, each with an exact fix command — not a general recommendation.

---

## Case 2 — DEVNET → LAUNCH_READY_WITH_RISKS

**Context:** `DEVNET`

**Evidence setup:**
- Core instruction tests are missing for some instructions (not full B1 coverage).
- No recent Surfpool or devnet integration run is evidenced within the last 48 hours (B3 unresolved).
- No active BLOCKER-severity criteria are unresolved at this context.

**Expected findings:** `HIGH B1`, `HIGH B3`

**Expected output excerpt:**
```
LAUNCH_READY_WITH_RISKS

HIGH B1 — Core instruction tests missing for [N] instructions.
  Fix: add LiteSVM or cargo test coverage for the untested instructions.

HIGH B3 — No integration test run found within the last 48 hours.
  Fix: run the integration suite against devnet or Surfpool and retain the dated log.
```

**Pass condition:** Verdict is exactly `LAUNCH_READY_WITH_RISKS`. Both B1 and B3 appear under HIGH Risks. No BLOCKER section is populated.

---

## Case 3 — DEMO_HACKATHON → LAUNCH_READY

**Context:** `DEMO_HACKATHON`

**Evidence setup:**
- Demo link is reachable (no localhost-only access path).
- `README.md` and `LICENSE` are both present.
- Project makes no real-funds or mainnet-deployment claim.
- No unresolved BLOCKER, HIGH, or three-or-more MEDIUM findings exist for the modules loaded under this context.

**Expected findings:** None

**Expected output excerpt:**
```
LAUNCH_READY

No BLOCKERs. No unresolved HIGH risks.
```

**Pass condition:** Verdict is exactly `LAUNCH_READY`. BLOCKERs and HIGH Risks sections are empty (`None`), consistent with `skill/SKILL.md`'s required output format for a clean result.
