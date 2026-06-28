# Documentation & Discoverability — Domain D

## Purpose

This module evaluates whether the project's documentation contains the minimum evidence a user, judge, integrator, or reviewer needs to avoid launch-critical confusion. It is not a copywriting guide and does not assess writing quality, tone, or formatting. It checks whether documentation gaps create a real risk — a wrong program ID, a swallowed error, or no path to report a vulnerability — not whether the README reads well.

Severity for every criterion below is read from the launch context classified in `SKILL.md` STEP 0. Do not apply these severities without that classification.

---

## D1 — README Shows Correct Network Program ID

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| MEDIUM | LOW | HIGH | **BLOCKER** |

**What to check:** Whether the program ID published in the README (or other primary docs) matches the network the project is actually claiming to be live on — specifically, that a mainnet-launch claim is not paired with a devnet program ID left over from earlier development.

**Command:**
```
grep -R "program id\|programId\|declare_id!\|mainnet\|devnet" README.md docs/ programs/ app/ src/
```
Cross-reference the program ID found in `declare_id!()` (source of truth in code) against the program ID published in README/docs, and against the network the project claims to be deployed on.

**Evidence examples:**
- Resolved: README states the network (e.g., "deployed on mainnet-beta") and the listed program ID matches the `declare_id!()` value, and that ID is independently confirmed to exist on the claimed network (cross-check against the security module's `solana program show` evidence if already gathered).
- Unresolved: README claims mainnet deployment but the published program ID is the devnet program ID (a common leftover from development), or no network is stated at all alongside the program ID.
- Missing: no program ID published in any documentation — ask the user directly rather than guessing one.

**How to classify:** A mismatch between the README's claimed network and the program ID's actual deployed network is the specific failure this criterion exists to catch. If the project has both a devnet and mainnet deployment with different IDs, confirm the README clearly labels which ID belongs to which network — an unlabeled dual listing is unresolved.

**What not to assume:** Do not invent or guess a program ID under any circumstance. Do not infer which network a program ID belongs to from a transaction signature or address pattern alone — confirm against `declare_id!()` in source or ask the user directly.

**Output wording:** "Program ID documentation: [confirmed — README program ID matches <network> deployment / mismatch — README claims <network> but program ID corresponds to <other network> / no program ID published]."

**Fix when unresolved, MAINNET_WITH_FUNDS:** Update the README to show the actual mainnet program ID confirmed via `solana program show <PROGRAM_ID>` against the mainnet cluster, and remove or clearly separate any devnet ID so a user cannot mistakenly interact with the wrong network.

---

## D2 — Error Codes Mapped to User-Facing Messages

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | MEDIUM | MEDIUM | HIGH |

**What to check:** Whether the client surfaces a program's specific error to the end user, rather than swallowing it into a generic failure message or an unhandled exception.

**Command:**
```
grep -R "AnchorError\|errorCode\|error_code\|ProgramError\|catch" src/ app/ lib/
```

**Evidence examples:**
- Resolved: client code catches the specific `AnchorError`/`ProgramError`, reads `error.errorCode.code` (or equivalent), and maps it to a user-facing message that reflects what actually went wrong (e.g., "Insufficient balance" rather than "Transaction failed").
- Unresolved: errors are caught but the user sees only a generic message ("Something went wrong") regardless of which on-chain error fired, or the specific error code is logged to console but never surfaced to the UI.
- Missing: no error handling found around transaction calls — failures would propagate as unhandled exceptions or silent no-ops.

**How to classify:** "Mapped" requires an actual branch or lookup from error code to message — not just that an error object exists somewhere in a catch block. A catch block that only does `console.error(e)` with no user-facing surface is unresolved, not partially resolved.

**What not to assume:** Do not assume an error is handled because a `try/catch` wraps the transaction call — check whether the catch block does anything beyond logging. Do not assume a generic "transaction failed" toast satisfies this criterion; the requirement is that the *specific* error reaches the user in some readable form.

**Output wording:** "Error surfacing: [confirmed — N of M known error codes mapped to user-facing messages / errors caught but only logged, not surfaced / no error handling found]."

---

## D3 — Security Contact or Disclosure Process Documented

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | LOW | MEDIUM | HIGH |

**What to check:** Whether there is a documented way for someone who finds a security issue to report it responsibly, rather than no path existing at all.

**Commands:**
```
ls SECURITY.md .github/SECURITY.md
grep -R "security@\|disclosure\|vulnerability\|bug bounty" README.md SECURITY.md .github/ docs/
```

**Evidence examples:**
- Resolved: a `SECURITY.md` file exists (root or `.github/`), or the README contains a clearly labeled section with a contact email, disclosure process, or bug bounty link.
- Unresolved: a security-related mention exists but lacks an actual contact method (e.g., "please report responsibly" with no email or process named).
- Missing: no `SECURITY.md` exists and no relevant section appears in README or other docs.

**How to classify:** A disclosure process requires a concrete point of contact or process step — an email address, a form link, or a named bug bounty platform. A vague statement of intent without a way to actually act on it is unresolved.

**What not to assume:** Do not claim a disclosure process exists because the project has a general "Contact" section — that section must specifically address security reporting, not general support inquiries, to count as resolved here.

**Output wording:** "Security disclosure process: [confirmed — <contact method/process found> / mentioned but no actionable contact found / not documented]."

---

## Safety Boundaries (Domain D)

- Never invent or guess a program ID under any circumstance — every program ID referenced in output must come from source code, on-chain query, or direct user statement.
- Never infer which network a program ID or transaction belongs to from a signature or address pattern alone without corroborating evidence.
- Never state that a security disclosure process exists unless it is actually documented somewhere checked.
- This module reads and reports on documentation only — it does not rewrite, edit, or publish any public-facing docs.
