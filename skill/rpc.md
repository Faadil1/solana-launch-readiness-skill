# RPC & Runtime Reliability — Domain C

## Purpose

This module evaluates whether the application has launch-relevant evidence for RPC endpoint configuration, transaction retry behavior, pre-submission simulation, and fund-movement safeguards. It does not benchmark RPC providers and does not execute or send any transaction. It checks whether runtime failure risks — the kind that cause silent fund loss or a broken demo mid-launch — are surfaced and addressed before launch, not after.

Severity for every criterion below is read from the launch context classified in `SKILL.md` STEP 0. Do not apply these severities without that classification.

---

## C1 — Dedicated RPC Endpoint in Use

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | MEDIUM | HIGH | **BLOCKER** |

**What to check:** Whether the application's production RPC configuration points to a dedicated provider (Helius, Triton, QuickNode) rather than the shared public endpoint.

**Commands:**
```
grep -R "api.mainnet-beta.solana.com\|clusterApiUrl" .
```
Also inspect `.env`, `.env.production`, `NEXT_PUBLIC_RPC_URL`, `RPC_URL`, and any config files (`config.ts`, `constants.ts`, deployment manifests) for the actual endpoint used at runtime — a `grep` hit on the literal string is a starting signal, not the full picture, since the URL may be injected via an environment variable whose value isn't checked into the repo.

**Evidence examples:**
- Resolved: the production RPC URL (confirmed in `.env`/config, or directly stated by the user) points to a named dedicated provider's endpoint.
- Unresolved: `grep` finds `api.mainnet-beta.solana.com` or `clusterApiUrl('mainnet-beta')` directly in a file that runs in production, or the RPC URL is an environment variable whose actual value the user has not disclosed.
- Missing: no RPC configuration found at all — ask the user where the app's RPC endpoint is set.

**How to classify:** A reference to `clusterApiUrl('devnet')` or `clusterApiUrl('testnet')` is not the same finding as `clusterApiUrl('mainnet-beta')` — only flag the mainnet shared-endpoint case under this criterion. If the URL is environment-variable-driven, ask what the variable resolves to in production rather than assuming it's safe or unsafe.

**What not to assume:** Do not assume an RPC URL is "probably fine" because the project demoed successfully once — shared public endpoints degrade under load and rate-limit unpredictably, which is exactly the failure mode this criterion exists to catch before it happens during a funded mainnet launch.

**Output wording:** "Production RPC endpoint: [confirmed dedicated provider: <name> / shared public endpoint (api.mainnet-beta.solana.com) detected / cannot determine — RPC URL is environment-variable-driven, value not disclosed]."

**Fix when unresolved, MAINNET_WITH_FUNDS:** Replace the shared endpoint with a dedicated provider URL (e.g., a Helius or Triton mainnet endpoint) in the relevant `.env`/config, and confirm the new value is what actually loads at runtime — not just what's written in a template file.

---

## C2 — Retry Logic for Transaction Expiry and Send Failures

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | MEDIUM | HIGH | HIGH |

**What to check:** Whether the client code handles `TransactionExpiredBlockheightExceededError` and `SendTransactionError` with a retry or recovery path, rather than letting the transaction fail silently or crash the calling code.

**Command:**
```
grep -R "TransactionExpiredBlockheightExceededError\|SendTransactionError\|retry" src/ app/ lib/
```

**Evidence examples:**
- Resolved: a `grep` match shows the error type being caught and handled with a retry, a re-fetched blockhash, or an explicit user-facing recovery message — not just logged and dropped.
- Unresolved: the error type appears only in a generic `catch (e) { console.error(e) }` block with no retry or recovery logic, or transaction-sending code has no error handling at all.
- Missing: no transaction-sending code found in the inspected paths, or the project does not submit transactions client-side (e.g., it's a read-only viewer).

**How to classify:** Catching the error and logging it is not equivalent to handling it. Resolved evidence requires an actual retry attempt, a blockhash refresh before resubmission, or a deliberate fallback — not just visibility into the failure.

**What not to assume:** Do not assume retry logic exists because the library used (e.g., `@solana/web3.js`, Helius SDK) has retry options available — check that the project actually configures or invokes them, rather than crediting the dependency's capability to the project.

**Output wording:** "Transaction retry handling: [confirmed — retry/recovery logic found for <error type> / errors caught but not retried / no transaction error handling found / not applicable — no client-side transaction submission]."

---

## C3 — Transaction Simulation Before Submission

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | HIGH | HIGH | HIGH |

**What to check:** Whether every state-changing transaction is simulated before being sent, so a failure surfaces before it costs a fee or has on-chain side effects.

**Command:**
```
grep -R "simulateTransaction\|simulate" src/ app/ lib/
```

**Evidence examples:**
- Resolved: every code path that builds and sends a state-changing transaction calls `simulateTransaction` (or an SDK-equivalent wrapper) first, and the result is checked before proceeding to `sendTransaction`.
- Unresolved: simulation is called in some transaction paths but not others, or simulation results are fetched but never actually checked before sending.
- Missing: no simulation calls found anywhere in the transaction-sending code.

**How to classify:** "All state-changing operations" means every instruction that writes on-chain state — not just the one shown in a demo. If the project has three transaction-sending flows and only one simulates first, this is unresolved, not resolved.

**What not to assume:** Do not assume simulation happens implicitly through wallet adapter behavior — most wallet adapters do not simulate by default; the project's own code must call it explicitly.

**Output wording:** "Pre-submission simulation: [confirmed for all N state-changing paths / confirmed for N of M paths — list unsimulated paths / no simulation found]."

---

## C4 — Spending Circuit Breaker or Hard Cap

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | MEDIUM | MEDIUM | **BLOCKER** |

**Conditional applicability:** This criterion applies only when the program or app actually transfers, custodies, or moves SOL or tokens. If the project is read-only or never transfers value (e.g., a registry, oracle, or display-only dApp), C4 = LOW in every context regardless of the table above — do not apply the BLOCKER severity to a non-financial app.

**What to check:** Whether there is an enforced maximum amount the program or client will move in a single transaction or session, independent of what the caller requests.

**Command:**
```
grep -R "transfer\|sendAndConfirmTransaction\|createTransferInstruction\|token" src/ app/ programs/
```
Use this to first confirm whether fund movement exists in the codebase at all — if it doesn't, mark C4 LOW/not-applicable and move on. If it does, look for an explicit cap check (a constant, a config value, or an on-chain account constraint) that bounds the transferred amount before the instruction executes.

**Evidence examples:**
- Resolved: a hardcoded or configurable maximum transfer amount is enforced in the program's instruction logic or in client-side pre-flight checks, and the cap cannot be bypassed by caller-supplied input alone.
- Unresolved: transfer logic exists with no enforced cap — the amount transferred is whatever the caller requests, with no upper bound.
- Missing / not applicable: no transfer, `sendAndConfirmTransaction`, `createTransferInstruction`, or token-movement logic found anywhere — record this explicitly rather than leaving the criterion ambiguous.

**How to classify:** A cap enforced only in a frontend form (e.g., an input field `max` attribute) is not sufficient — it must be enforced in the program or in server-side logic the caller cannot bypass by calling the program directly.

**What not to assume:** Do not assume the absence of a cap is acceptable because "the user controls their own funds" — for MAINNET_WITH_FUNDS, a missing cap on a transfer path is exactly the kind of unbounded-exposure risk this criterion exists to catch.

**Output wording:** "Spending cap: [not applicable — no fund movement found / confirmed — capped at <amount/logic> enforced in <program/server> / unresolved — transfer logic found with no enforced cap]."

**Fix when unresolved, MAINNET_WITH_FUNDS (and fund movement confirmed present):** Add an enforced maximum transfer amount inside the program instruction itself (not just the client UI), so the cap holds even if the program is called directly, bypassing the frontend.

---

## Safety Boundaries (Domain C)

- This module never sends, simulates for execution purposes, or broadcasts any transaction — all simulation references above describe what the *project's own code* should do, not an action this skill performs.
- Never test an RPC endpoint's reliability or rate limits by sending live requests against it.
- Never recommend embedding a private RPC API key directly in public client-side code — if a dedicated RPC URL contains an API key, flag that it belongs in a server-side proxy or environment variable, not a client bundle.
- Do not assume an RPC provider's quality, uptime, or rate limits without evidence — this module checks configuration and code, not live provider performance.
