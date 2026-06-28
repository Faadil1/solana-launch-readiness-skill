# Solana Launch Readiness Skill

Default assumption: NOT_LAUNCH_READY until evidence proves otherwise. This skill does not advise — it gates.

STEP 0 — classify launch context first. Severity for every criterion below depends on this classification; do not skip it.

Output one verdict: LAUNCH_READY, LAUNCH_READY_WITH_RISKS, or NOT_LAUNCH_READY. Never soften a BLOCKER into a suggestion.

## Purpose

This is a launch verdict engine, not a checklist. It turns Solana-specific launch evidence — program authority, RPC configuration, test coverage, documentation state, demo readiness — into a single context-aware verdict. A checklist asks the founder to self-grade. This skill gates: it assumes the project is not ready until each criterion is evidenced, and it never lets a BLOCKER pass as a recommendation.

## When to Use

- The user asks whether a Solana project is ready to demo, submit, deploy, or launch.
- The user wants Claude Code to assess a repo before calling the work done.
- The user has a Solana program, dApp, or hackathon/bounty submission and needs hard blockers surfaced before going further.

## When NOT to Use

- The user wants help writing Solana code from scratch. (Use Solana dev/build skills instead.)
- The user wants a deep code audit or formal third-party security audit. (This skill checks audit *status*, not code correctness.)
- The user wants autonomous wallet or deployment changes made on their behalf. (This skill never executes — see Safety Boundaries.)

---

## STEP 0 — Classify Launch Context

Every criterion's severity depends on this classification. Ask or infer from project files before applying anything below.

| Context | Definition |
|---|---|
| `DEMO_HACKATHON` | Building to show judges or demo to an audience. No real user funds at risk. |
| `DEVNET` | Live on devnet only. Real infrastructure, no real funds. |
| `MAINNET_NO_FUNDS` | Deployed on mainnet but the program does not custody or transfer user funds (read-only oracle, registry, non-financial dApp). |
| `MAINNET_WITH_FUNDS` | Deployed on mainnet and moves, holds, or controls real user funds or tokens. |

If context is ambiguous, ask exactly one clarifying question before proceeding. Do not guess on this step — every downstream severity depends on it. Record the selected context; all evidence below is read relative to it.

---

## STEP 1 — Classify Project Type and Route Progressively

Load only the modules required for the detected project type. Do not load a module that has no applicable criteria for this project.

| Project type | Load |
|---|---|
| On-chain program | `security.md` + `testing.md` |
| Frontend-only dApp | `rpc.md` + `demo.md` |
| Documentation / submission review | `docs.md` + `demo.md` |
| Full-stack Solana project | All domain modules |
| Unresolved BLOCKER or HIGH found | `remediation.md` |

---

## Severity Table — 19 Criteria, Context-Aware

Columns: `DEMO/HK` = DEMO_HACKATHON · `DEVNET` · `NO_FUNDS` = MAINNET_NO_FUNDS · `WITH_FUNDS` = MAINNET_WITH_FUNDS

### Domain A — Program Security & Authority (`security.md`)

| ID | Criterion | DEMO/HK | DEVNET | NO_FUNDS | WITH_FUNDS |
|---|---|---|---|---|---|
| A1 | Upgrade authority is not a hot wallet (Squads multisig, hardware wallet, or revoked) | HIGH | HIGH | HIGH | **BLOCKER** |
| A2 | Program build is verifiable (anchor build --verifiable, OtterSec, or Ellipsis verified) | LOW | MEDIUM | HIGH | HIGH |
| A3 | IDL published on-chain (Anchor only) — non-Anchor: equivalent client SDK docs or interface spec present | LOW | MEDIUM | HIGH | HIGH |
| A4 | No known critical/high vulnerabilities — at minimum `cargo audit` clean | MEDIUM | HIGH | HIGH | **BLOCKER** |
| A5 | External security review completed (Trail of Bits, OtterSec, Halborn, Neodyme, or Superteam Bug Bash) | LOW | LOW | MEDIUM | HIGH |

### Domain B — Testing Evidence (`testing.md`)

| ID | Criterion | DEMO/HK | DEVNET | NO_FUNDS | WITH_FUNDS |
|---|---|---|---|---|---|
| B1 | LiteSVM unit tests present covering core instructions — not happy-path only | MEDIUM | HIGH | HIGH | HIGH |
| B2 | Error paths tested — every `error_code` variant has a rejection test | LOW | MEDIUM | MEDIUM | HIGH |
| B3 | Surfpool or devnet integration test executed without failures in last 48h | LOW | HIGH | HIGH | HIGH |
| B4 | No `#[cfg(test)]`-only keypairs in production code paths | MEDIUM | HIGH | HIGH | **BLOCKER** |

### Domain C — RPC & Runtime Reliability (`rpc.md`)

| ID | Criterion | DEMO/HK | DEVNET | NO_FUNDS | WITH_FUNDS |
|---|---|---|---|---|---|
| C1 | Dedicated RPC endpoint in use (Helius, Triton, QuickNode) — not `api.mainnet-beta.solana.com` | LOW | MEDIUM | HIGH | **BLOCKER** |
| C2 | Retry logic for `TransactionExpiredBlockheightExceededError` and `SendTransactionError` | LOW | MEDIUM | HIGH | HIGH |
| C3 | Transaction simulation called before submission on all state-changing operations | LOW | HIGH | HIGH | HIGH |
| C4 | Spending circuit breaker or hard cap implemented (applies only if program transfers SOL or tokens) | LOW | MEDIUM | MEDIUM | **BLOCKER** |

### Domain D — Documentation & Discoverability (`docs.md`)

| ID | Criterion | DEMO/HK | DEVNET | NO_FUNDS | WITH_FUNDS |
|---|---|---|---|---|---|
| D1 | README shows correct network program ID — no devnet placeholder in production docs | MEDIUM | LOW | HIGH | **BLOCKER** |
| D2 | Anchor error codes mapped to user-facing messages in client — errors not silently swallowed | LOW | MEDIUM | MEDIUM | HIGH |
| D3 | Security contact or disclosure process documented (SECURITY.md or README section) | LOW | LOW | MEDIUM | HIGH |

### Domain E — Demo & Submission Confidence (`demo.md`)

| ID | Criterion | DEMO/HK | DEVNET | NO_FUNDS | WITH_FUNDS |
|---|---|---|---|---|---|
| E1 | Live demo runs on target network without localhost dependencies | HIGH | HIGH | HIGH | HIGH |
| E2 | Demo wallet funded only to minimum needed — no excess funds in hot demo wallet | HIGH | MEDIUM | HIGH | **BLOCKER** |
| E3 | Submission package complete: README, demo link/video, repo public, LICENSE present | HIGH | HIGH | HIGH | HIGH |

**Conditional note:** C4 applies only when the program transfers or custodies SOL or tokens. If the program is read-only, C4 = LOW in every context.

---

## Verdict Logic

```
PRE-CONDITION: STEP 0 must be complete before any verdict is computed.

BLOCKER evaluation:
  A criterion is an active BLOCKER only when both are true:
    (1) its severity cell for the detected context = BLOCKER
    (2) it is unresolved (no evidence found)

NOT_LAUNCH_READY
  → One or more active BLOCKERs.
  Must name each BLOCKER by ID and title, explain why it disqualifies
  for this specific context, and provide the exact fix command or action.
  Never downgrade a BLOCKER to a suggestion.

LAUNCH_READY_WITH_RISKS
  → Zero active BLOCKERs
  → AND (one or more unresolved HIGH, OR three or more unresolved MEDIUM
    in the detected context column)
  Must list each unresolved HIGH with a recommended fix, and summarize
  MEDIUM count as advisory.

LAUNCH_READY
  → Zero active BLOCKERs
  → Zero unresolved HIGH
  → Fewer than three unresolved MEDIUM
  Any remaining MEDIUM is advisory only and does not change the verdict.

HARD RULE: Never output LAUNCH_READY while any context-mapped BLOCKER
is unresolved. This is enforced by the table above, not by judgment.
```

---

## Required Output Format

Every `/launch-check` run must return, in this order:

1. **Detected launch context** — the STEP 0 classification used
2. **Loaded modules** — which domain files were read for this run
3. **Evidence table** — criterion ID, status (resolved/unresolved), severity for this context
4. **Verdict** — exactly one of LAUNCH_READY / LAUNCH_READY_WITH_RISKS / NOT_LAUNCH_READY
5. **BLOCKERs** — named, with exact fix command (empty list if none)
6. **HIGH risks** — named, with recommended fix
7. **MEDIUM advisories** — summarized, does not change verdict
8. **Prioritized fixes** — ordered BLOCKER first, then HIGH, then MEDIUM
9. **Missing evidence** — criteria that could not be checked and why

## Token Discipline

- Load only the modules required by STEP 1 routing. Do not load a module with no applicable criteria for the detected project type.
- Do not repeat full module content in the output — reference the criterion ID and verdict-relevant detail only.
- Verdict comes first in the response. Evidence detail is concise and secondary.

## Safety Boundaries

- Never request private keys or seed phrases.
- Never send transactions on the user's behalf.
- Never modify wallet authorities or deployments directly.
- Always provide the exact command for the user to run manually — this skill diagnoses and prescribes, it does not execute.
