# Remediation Guide

## Purpose

This module converts unresolved BLOCKER and HIGH findings into exact, user-run commands or concrete code/config actions. It does not execute fixes, send transactions, modify wallet authorities, or deploy anything itself — every action below is something the user runs. Load this module only after a verdict has named unresolved findings in `SKILL.md`.

## Remediation Priority

Fix BLOCKERs first, then HIGH, in the order they appear in the verdict's prioritized fix list. MEDIUM findings are included only where needed to explain a HIGH/BLOCKER fix's context. LOW findings are omitted unless the user asks for them directly.

---

## Signature Remediation Example

```
Context detected: MAINNET_WITH_FUNDS

NOT_LAUNCH_READY

BLOCKER A1 — Upgrade authority is a hot wallet.
  Fix: solana program set-upgrade-authority <PROGRAM_ID> <SQUADS_MULTISIG_ADDRESS>

BLOCKER C1 — Production RPC is api.mainnet-beta.solana.com.
  Fix: set RPC_URL to a dedicated Helius/Triton endpoint before launch.
```

This is the standard output shape: verdict first, named BLOCKERs second, exact fix third. No setup narration precedes it.

---

## A1 — Upgrade Authority Is a Hot Wallet

**Trigger:** `solana program show <PROGRAM_ID>` returns a single-keypair address as Authority, with no multisig or hardware-wallet confirmation, on MAINNET_WITH_FUNDS (BLOCKER) or any other context (HIGH).

**Why it matters:** Whoever holds that one keypair can push an arbitrary program upgrade at any time, including one that drains user funds. There is no second check.

**Fix:**
```
solana program set-upgrade-authority <PROGRAM_ID> --new-upgrade-authority <SQUADS_MULTISIG_ADDRESS>
```
If the program is feature-complete and no further upgrades are intended:
```
solana program set-upgrade-authority <PROGRAM_ID> --final
```

**Verify:**
```
solana program show <PROGRAM_ID>
```
Authority field should now show the multisig address or `none`.

**What not to do:** Do not run this command on the user's behalf. Do not accept a hot wallet as a temporary fix on MAINNET_WITH_FUNDS — this is a BLOCKER with no acceptable interim state. Choosing the multisig signer set requires human approval — do not select signers for the user.

---

## A2 — Build Not Verifiable

**Trigger:** No record on otter.so/verify.ellipsis.fi, and `anchor verify` has not been run, on MAINNET_NO_FUNDS or MAINNET_WITH_FUNDS (HIGH).

**Why it matters:** Without a verifiable build, no one can confirm the deployed bytecode matches the published source — a silent mismatch is undetectable.

**Fix:**
```
anchor build --verifiable
anchor verify -p <PROGRAM_NAME> <PROGRAM_ID>
```

**Verify:** `anchor verify` exits successfully, or the program ID appears on otter.so/verify.ellipsis.fi.

**What not to do:** Do not claim verification succeeded without the command's actual output confirming it.

---

## A3 — IDL or Interface Evidence Missing

**Trigger:** Anchor program with `anchor idl fetch <PROGRAM_ID>` returning empty (HIGH on MAINNET_NO_FUNDS/WITH_FUNDS). Non-Anchor program with no published client SDK docs or interface spec.

**Why it matters:** Without a published interface, integrators and reviewers cannot confirm how to call the program correctly, increasing the chance of malformed transactions or copy-pasted incorrect integrations.

**Fix (Anchor):**
```
anchor idl init -f target/idl/<program_name>.json <PROGRAM_ID>
```
**Fix (non-Anchor):** Document every instruction's accounts and byte layout in README or a docs page — this is a documentation action, not a command; requires the project owner to write it.

**Verify:**
```
anchor idl fetch <PROGRAM_ID>
```
Should return a non-empty IDL.

**What not to do:** Do not require an on-chain IDL from a non-Anchor program — confirm the equivalent docs exist instead.

---

## A4 — Vulnerabilities Present or `cargo audit` Not Run

**Trigger:** `cargo audit` reports critical/high advisories, or has never been run, on MAINNET_WITH_FUNDS (BLOCKER) or other contexts (MEDIUM/HIGH).

**Why it matters:** Known-vulnerable dependencies are a documented, exploitable attack surface — this is the lowest-effort check with the highest avoidable risk if skipped.

**Fix:**
```
cargo audit
```
Upgrade every crate with a flagged advisory, then re-run until clean.

**Verify:** `cargo audit` exits with no critical/high advisories.

**What not to do:** Do not treat a clean `cargo audit` as proof the program logic itself is vulnerability-free — it only covers known dependency CVEs. This BLOCKER cannot be waived by stated intent to fix later; it must show clean.

---

## A5 — External Security Review Missing

**Trigger:** No published audit report or named reviewing entity found, on MAINNET_WITH_FUNDS (HIGH).

**Why it matters:** Self-review and AI-assisted review both miss classes of bugs that an independent specialist reviewer is trained to catch.

**Fix:** Requires human approval — engaging an auditor (Trail of Bits, OtterSec, Halborn, Neodyme) or submitting to a Superteam Bug Bash is a scoping and budget decision the project owner must make; this skill cannot select or engage a reviewer on the user's behalf.

**Verify:** A published report exists and is linked from the README.

**What not to do:** Do not state or imply a review has occurred without a named reviewer and report.

---

## B1 — Core Instruction Tests Missing

**Trigger:** Test suite has zero or partial coverage of defined instructions, confirmed via `anchor test` / `cargo test` and review of which instructions are actually invoked.

**Why it matters:** An untested instruction is the most likely place for an unhandled edge case to reach production unnoticed.

**Fix:** Write a test for each untested instruction using LiteSVM (preferred) or direct `cargo test` invocation, covering at least one non-trivial input per instruction, then run:
```
anchor test
cargo test
```

**Verify:** Re-run the grep used in `testing.md` (`grep -R "LiteSVM\|litesvm" tests/ programs/`) and confirm every instruction now has a matching test call.

**What not to do:** Do not report coverage as complete based on a passing suite alone — confirm which instructions are actually exercised.

---

## B2 — Error Path Tests Missing

**Trigger:** One or more `#[error_code]` variants have no test that deliberately triggers and asserts on them.

**Why it matters:** Untested error paths can fail silently or behave unexpectedly under the exact conditions they exist to guard against.

**Fix:** Add a test per missing error variant that triggers the specific failing condition and asserts on that exact error code, not a generic failure.

**Verify:**
```
grep -R "assert_err\|AnchorError\|error_code" tests/ programs/
```
Confirm count of tested variants matches count of defined variants.

**What not to do:** Do not count a happy-path test that "would fail if something broke" as error-path coverage.

---

## B3 — Recent Live Integration Evidence Missing

**Trigger:** No CI log, Surfpool transcript, or dated devnet run within the last 48 hours.

**Why it matters:** Unit tests do not catch network-layer or runtime failures that only appear when a transaction actually travels through a live cluster.

**Fix:** Run the project's integration test suite against devnet or Surfpool now, and retain the log/output with a timestamp.

**Verify:** Log or CI run shows a timestamp within 48 hours of the launch-readiness check, with a successful outcome.

**What not to do:** Do not accept a stale or undated prior run as current evidence.

---

## B4 — Test-Only Keypairs in Production Code Paths

**Trigger:** `Keypair::new()` or `read_keypair_file()` found outside a `#[cfg(test)]` guard or `tests/` directory, in a file reachable by the production build, on MAINNET_WITH_FUNDS (BLOCKER).

**Why it matters:** A test keypair reachable in production is a predictable, often hardcoded, signing key — an attacker who finds it gains unintended signing capability.

**Fix:** Move the flagged keypair generation behind `#[cfg(test)]` or into `tests/`, excluded from the production build.

**Verify:**
```
grep -R "#\[cfg(test)\].*Keypair\|Keypair::new\|read_keypair_file" programs/ src/ app/
```
Re-run and confirm zero matches outside test-scoped files.

**What not to do:** Do not accept "we'll fix it before mainnet" as resolution — this BLOCKER requires the grep to show zero matches before the verdict changes.

---

## C1 — Shared Public RPC in Production

**Trigger:** `api.mainnet-beta.solana.com` or `clusterApiUrl('mainnet-beta')` found in a production code path, on MAINNET_WITH_FUNDS (BLOCKER).

**Why it matters:** The shared public endpoint rate-limits unpredictably under load — a funded production app can fail silently for users at the worst possible moment.

**Fix:** Replace the shared endpoint with a dedicated provider URL. Set `RPC_URL` (or `NEXT_PUBLIC_RPC_URL`, depending on the project's config convention) to a Helius, Triton, or QuickNode mainnet endpoint in `.env`/`.env.production`, then confirm the running app actually loads that value rather than a hardcoded fallback.

**Verify:**
```
grep -R "api.mainnet-beta.solana.com\|clusterApiUrl" .
```
Confirm zero matches in files that execute in production.

**What not to do:** Do not embed the dedicated provider's API key directly in public client-side code if the URL contains one — route it through a server-side proxy or environment variable instead.

---

## C2 — Missing Retry/Recovery Logic

**Trigger:** `TransactionExpiredBlockheightExceededError` or `SendTransactionError` is caught but only logged, with no retry or blockhash refresh.

**Why it matters:** Transient network conditions cause these errors routinely — without recovery, a normal hiccup becomes a failed user transaction with no automatic retry.

**Fix:** Add a retry wrapper around transaction submission that re-fetches a fresh blockhash and resubmits on these specific error types, rather than surfacing a bare failure.

**Verify:**
```
grep -R "TransactionExpiredBlockheightExceededError\|SendTransactionError\|retry" src/ app/ lib/
```
Confirm the matched code path includes an actual retry attempt, not just a log statement.

**What not to do:** Do not credit a dependency's built-in retry capability (e.g., an SDK's retry option) as resolved unless the project actually configures or invokes it.

---

## C3 — Missing Pre-Submission Simulation

**Trigger:** One or more state-changing transaction paths send without calling `simulateTransaction` first.

**Why it matters:** Simulating first surfaces a failure before it costs a transaction fee or has any on-chain side effect — skipping it means failures are discovered the expensive way.

**Fix:** Add a `simulateTransaction` call (or SDK-equivalent) before every `sendTransaction` call, and check the simulation result before proceeding.

**Verify:**
```
grep -R "simulateTransaction\|simulate" src/ app/ lib/
```
Confirm every state-changing send path has a matching simulation call upstream of it.

**What not to do:** Do not assume wallet-adapter behavior simulates automatically — most do not.

---

## C4 — Missing Spending Circuit Breaker or Hard Cap

**Trigger:** Program or client transfers SOL/tokens with no enforced maximum amount, on MAINNET_WITH_FUNDS (BLOCKER) — only applicable if the program actually moves funds.

**Why it matters:** An unbounded transfer path means a bug, misuse, or exploit can move an arbitrarily large amount in a single call.

**Fix:** Add an enforced maximum transfer amount inside the program instruction itself (not only the client UI), so the cap holds even if the program is called directly.

**Verify:**
```
grep -R "transfer\|sendAndConfirmTransaction\|createTransferInstruction\|token" src/ app/ programs/
```
Confirm the cap is enforced at the program/server layer, not just a frontend input `max` attribute.

**What not to do:** Do not apply this fix to a program confirmed read-only or non-financial — C4 is not applicable in that case.

---

## D1 — Wrong or Missing Network Program ID in Docs

**Trigger:** README claims mainnet deployment but the published program ID matches the devnet `declare_id!()` value, or no network is stated, on MAINNET_WITH_FUNDS (BLOCKER).

**Why it matters:** A user who copies the wrong program ID interacts with the wrong network entirely — at best a wasted transaction, at worst confusion that enables a scam impersonating the real deployment.

**Fix:** Update README to show the program ID confirmed via `solana program show <PROGRAM_ID>` against the correct cluster, clearly labeled by network. If both devnet and mainnet IDs are documented, separate them explicitly rather than listing one unlabeled.

**Verify:**
```
grep -R "program id\|programId\|declare_id!\|mainnet\|devnet" README.md docs/ programs/ app/ src/
```
Confirm the README's stated ID matches `declare_id!()` and the claimed network.

**What not to do:** Never invent or guess a program ID to fill this gap — confirm the real value from source or on-chain query, or ask the user directly.

---

## D2 — Missing User-Facing Error Mapping

**Trigger:** Client catches `AnchorError`/`ProgramError` but only logs it; the user sees a generic failure message regardless of which on-chain error fired.

**Why it matters:** A user who hits "insufficient balance" but sees "transaction failed" cannot self-correct — they retry the same failing action or abandon the flow.

**Fix:** Add a mapping from `error.errorCode.code` (or equivalent) to a specific user-facing message for each known error variant.

**Verify:**
```
grep -R "AnchorError\|errorCode\|error_code\|ProgramError\|catch" src/ app/ lib/
```
Confirm the catch block branches on the specific error code rather than only logging.

**What not to do:** Do not count a generic "transaction failed" toast as resolved — the specific error must reach the user in some readable form.

---

## D3 — Missing Security Disclosure Process

**Trigger:** No `SECURITY.md` and no README section with an actionable contact method, on MAINNET_WITH_FUNDS (HIGH).

**Why it matters:** Without a clear reporting path, a researcher who finds a vulnerability has no responsible-disclosure option and may default to public disclosure or do nothing.

**Fix:** Add a `SECURITY.md` (root or `.github/`) containing: a contact email or form, expected response time, and scope of what to report. A minimal version is sufficient — completeness matters more than length.

**Verify:**
```
ls SECURITY.md .github/SECURITY.md
grep -R "security@\|disclosure\|vulnerability\|bug bounty" README.md SECURITY.md .github/ docs/
```
Confirm a concrete contact method is present, not just a statement of intent.

**What not to do:** Do not count a general "Contact" section as resolved unless it specifically addresses security reporting.

---

## E1 — Localhost-Only Demo / No Reachable Demo

**Trigger:** README's only documented access path is local setup instructions (`npm run dev`), with no deployed URL.

**Why it matters:** A reviewer cannot evaluate a demo they cannot reach — this directly blocks the submission, independent of how good the underlying code is.

**Fix:** Deploy the frontend to a reachable host (Vercel, Netlify, Cloud Run, Render) and add that URL to the README, in addition to (not instead of) any local setup instructions.

**Verify:**
```
grep -R "localhost\|127.0.0.1" README.md docs/ app/ src/
```
Confirm a deployed URL is documented as the primary access path.

**What not to do:** Do not assume code completeness implies the demo is reachable — confirm an actual working URL exists.

---

## E2 — Overfunded Demo Wallet

**Trigger:** User states or implies the demo wallet holds significantly more than the demo's actual on-chain actions require, on MAINNET_WITH_FUNDS (BLOCKER).

**Why it matters:** A publicly demoed wallet address with excess real funds is an exploitable target for anyone watching the demo or reading the repo.

**Fix:** Move excess funds to a separate wallet not exposed in any public demo, repo, or video — requires human approval, since only the user can decide where remaining funds go and execute the transfer themselves.

**Verify:** User confirms the demo wallet now holds only the minimum needed for the demo's actual actions plus transaction fees.

**What not to do:** Never request the wallet's private key or seed phrase to check or move funds yourself. Never query the wallet balance autonomously — only act on balance information the user provides.

---

## E3 — Incomplete Submission Package

**Trigger:** One or more of README, LICENSE, demo link/video, or confirmed-public repo status is missing.

**Why it matters:** A missing core artifact (especially LICENSE or a working demo link) can disqualify a submission before a reviewer even evaluates the technical work.

**Fix:** Add whichever specific artifact is missing — create `README.md` or `LICENSE` if absent, add a demo link/video reference to the README, or confirm/change the repository's visibility to public.

**Verify:**
```
ls README.md LICENSE
git remote -v
git status --short
```
Confirm all four artifacts (README, LICENSE, demo reference, public visibility) are present, and that `git status --short` shows no uncommitted changes that would differ from what a reviewer checks out.

**What not to do:** Do not assume a `git remote -v` entry confirms public visibility — private repos have remotes too; confirm with the user directly.

---

## Safety Boundaries (Remediation)

- Never execute any command in this guide on the user's behalf — every fix above is presented for the user to run themselves.
- Never request a private key, seed phrase, or keypair file content, under any phrasing.
- Never instruct the user to paste a secret into chat.
- Authority changes, wallet fund movement, and deployment actions are described as exact user-run commands only — this module never performs them.
- Where a fix requires a judgment call this skill cannot make on the user's behalf (selecting multisig signers, engaging an external auditor, deciding where to move excess demo funds), it is explicitly labeled "requires human approval" above rather than silently assumed.
