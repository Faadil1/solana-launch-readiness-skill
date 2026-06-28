# Security — Domain A: Program Security & Authority

## Purpose

This module evaluates launch authority control, build verifiability, interface/IDL evidence, vulnerability status, and external security review status for a Solana program. It does not perform a formal audit and does not substitute for one. It checks whether the *evidence* that a launch-blocking security control exists is present — not whether the code is correct.

Severity for every criterion below is read from the launch context classified in `SKILL.md` STEP 0. Do not apply these severities without that classification.

---

## A1 — Upgrade Authority Is Not a Hot Wallet

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| HIGH | HIGH | HIGH | **BLOCKER** |

**What to check:** Who or what can upgrade this program right now.

**Command:**
```
solana program show <PROGRAM_ID>
```
Read the `Authority` field. Acceptable resolutions:
- A Squads multisig address
- A hardware wallet address (verify out of band — this skill cannot confirm wallet type from on-chain data alone)
- `none` (upgrade authority revoked — program is immutable)

**Evidence examples:**
- Resolved: `solana program show` output shows authority = known Squads multisig address (cross-check against app.squads.so), or authority = `none`.
- Unresolved: authority is a single keypair address with no multisig or hardware-wallet confirmation, and the user has not stated otherwise.
- Missing: program ID not provided, or `solana program show` cannot be run (no RPC access, program not found).

**How to classify:**
- Do not assume an address is a multisig because it "looks complex" or has many transactions. Confirm via Squads UI or ask the user directly.
- Do not assume a hot wallet is "probably fine for now" on MAINNET_WITH_FUNDS — this is the one criterion most directly tied to fund-drain risk.

**What not to assume:**
- Do not assume revoked authority is always the right answer — a project still iterating on devnet/demo should keep authority, just not on a bare hot wallet once funds are real.
- Do not infer wallet custody type (hot vs hardware) from the address alone.

**Output wording:** "Upgrade authority is `<address>`. This is [an unconfirmed single-signer keypair / a confirmed Squads multisig / revoked]." Never phrase this as "looks fine" without one of the three resolutions above.

**Fix when unresolved, MAINNET_WITH_FUNDS:**
```
solana program set-upgrade-authority <PROGRAM_ID> --new-upgrade-authority <SQUADS_MULTISIG_ADDRESS>
```
Or, if the program is feature-complete and no further upgrades are intended:
```
solana program set-upgrade-authority <PROGRAM_ID> --final
```

---

## A2 — Program Build Is Verifiable

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | MEDIUM | HIGH | HIGH |

**What to check:** Whether the deployed on-chain binary can be independently verified to match the published source code.

**Commands:**
```
anchor build --verifiable
anchor verify -p <PROGRAM_NAME> <PROGRAM_ID>
```

**Evidence examples:**
- Resolved: `anchor verify` succeeds, or the program ID is listed as verified on otter.so or verify.ellipsis.fi.
- Unresolved: build was done with plain `anchor build` (non-verifiable), no verification record exists anywhere checked.
- Missing: user has not provided the program ID, or the project is not Anchor-based and no equivalent reproducible-build process exists.

**How to classify:** A verifiable build claim requires either a passing `anchor verify` run or a third-party verification registry hit. A successful local `anchor build --verifiable` alone is not sufficient — it must be checked against the deployed program.

**What not to assume:** Do not assume a program is verifiable just because it uses Anchor. Anchor makes verification *possible*, not automatic.

**Output wording:** "Build verifiability: [confirmed via otter.so / confirmed via anchor verify / not verified — no record found]."

---

## A3 — IDL or Interface Documentation Published

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | MEDIUM | HIGH | HIGH |

**Anchor programs — what to check:** Whether the IDL is published on-chain.

**Command:**
```
anchor idl fetch <PROGRAM_ID>
```
Resolved if this returns a non-empty IDL. Unresolved if it returns empty or errors.

**Non-Anchor programs — what to check:** This criterion does not apply in its IDL form to native/Pinocchio/non-Anchor programs. Instead require equivalent evidence:
- A published client SDK with documented instruction encoding, or
- A README/docs section that fully specifies instruction layout, account ordering, and expected data formats.

**Evidence examples:**
- Resolved (Anchor): `anchor idl fetch` returns the IDL.
- Resolved (non-Anchor): README or docs site documents every instruction's accounts and byte layout.
- Unresolved: program is Anchor-based but IDL was never published on-chain (common when `anchor idl init` was skipped after deploy).
- Missing: cannot determine whether the program uses Anchor at all from available files.

**What not to assume:** Do not require an on-chain IDL from a non-Anchor program — this is a framework-specific artifact, not a universal requirement. Do not treat the *absence* of Anchor as a deficiency in itself.

**Output wording:** "Interface evidence: [IDL published on-chain / IDL present locally but not published — fix below / non-Anchor program, client SDK docs found / non-Anchor program, no equivalent interface documentation found]."

**Fix when unresolved (Anchor, IDL not published):**
```
anchor idl init -f target/idl/<program_name>.json <PROGRAM_ID>
```

---

## A4 — No Known Critical/High Vulnerabilities

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| MEDIUM | HIGH | HIGH | **BLOCKER** |

**What to check:** Whether known-vulnerable dependencies exist in the program's dependency tree.

**Command:**
```
cargo audit
```

**Evidence examples:**
- Resolved: `cargo audit` runs clean (no critical or high advisories), and the user confirms no known unpatched vulnerability reports exist for the program logic itself.
- Unresolved: `cargo audit` reports one or more critical/high advisories, or has not been run at all.
- Missing: `Cargo.lock` not present or not accessible to run the command against.

**How to classify:** `cargo audit` clean is the floor, not the ceiling — it only catches known CVEs in dependencies, not logic bugs in the program's own instructions. State this limitation explicitly in output; do not let a clean `cargo audit` imply the program logic itself is vulnerability-free.

**What not to assume:** Do not treat a clean `cargo audit` as equivalent to "no vulnerabilities." It is one input, not a substitute for A5.

**Output wording:** "Dependency vulnerability scan: [clean — no critical/high advisories / N critical or high advisories found / not run]. Note: this does not cover custom program logic."

**Fix when unresolved, MAINNET_WITH_FUNDS:** Run `cargo audit`, address every critical/high advisory by upgrading the affected crate, and re-run until clean before considering this criterion resolved. A BLOCKER here cannot be waived by intent to fix later — it must show clean before verdict changes.

---

## A5 — External Security Review Completed

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | LOW | MEDIUM | HIGH |

**What to check:** Whether an external party has reviewed the program for security issues — not whether the team believes the code is sound.

**Evidence examples:**
- Resolved: a published audit report (Trail of Bits, OtterSec, Halborn, Neodyme) exists and is linked from the README, or the program passed a Superteam Bug Bash with a public report.
- Unresolved: no external review has occurred, or one is "in progress" with no completed report yet.
- Missing: cannot determine review status from available files — ask the user directly rather than assuming none exists.

**What not to assume:** Do not claim an audit exists unless a report or named reviewing entity is actually evidenced. Do not accept "we reviewed it ourselves" or "the AI reviewed it" as satisfying this criterion — it requires an external party.

**Output wording:** "External security review: [completed — <reviewer name>, report linked / not completed — no external review found]." Never state or imply that an audit has occurred without a named source.

---

## Safety Boundaries (Domain A)

- Never run, suggest running, or simulate an authority-change transaction on the user's behalf. Only provide the exact command for the user to run themselves.
- Never request a private key, seed phrase, or keypair file content.
- Never claim an external security review exists without a verifiable report or named reviewing entity as evidence.
- All commands above are read-only or are presented as copy-paste actions for the user — this module does not execute them.
