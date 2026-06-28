# solana-launch-readiness-skill

solana-launch-readiness-skill doesn't help you ship faster — it tells your agent when NOT to ship yet.

Detects launch context (demo, devnet, mainnet-no-funds, mainnet-with-funds) and applies Solana-specific severity accordingly — a hot wallet authority is a warning on devnet and a hard BLOCKER on mainnet with funds.

Every BLOCKER comes with the exact fix command. No vague advice.

## What This Is

This is a default-deny Solana launch verdict engine, not a checklist. It assumes `NOT_LAUNCH_READY` until evidence proves otherwise, and it outputs exactly one verdict:

- `LAUNCH_READY`
- `LAUNCH_READY_WITH_RISKS`
- `NOT_LAUNCH_READY`

The verdict comes from 19 criteria across 5 domains:

- **Security & Authority** — upgrade authority, build verifiability, IDL/interface evidence, vulnerability status, external review
- **Testing Evidence** — core instruction coverage, error-path tests, live integration evidence, test-keypair isolation
- **RPC & Runtime Reliability** — dedicated RPC, retry logic, transaction simulation, spending caps
- **Documentation & Discoverability** — correct program ID, error mapping, security disclosure process
- **Demo & Submission Confidence** — reachable demo, demo wallet funding, submission completeness

Severity for every criterion depends on detected launch context — the same gap (e.g., a hot-wallet upgrade authority) can be a HIGH on devnet and a hard BLOCKER on mainnet with real funds.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Faadil1/solana-launch-readiness-skill/main/install.sh)
```

Or clone and install locally:

```bash
git clone https://github.com/Faadil1/solana-launch-readiness-skill.git
cd solana-launch-readiness-skill
./install.sh
```

## Usage

### Example 1 — `MAINNET_WITH_FUNDS` → `NOT_LAUNCH_READY`

Project has a hot-wallet upgrade authority and uses the shared public RPC endpoint.

```
> /launch-check
Context detected: MAINNET_WITH_FUNDS

NOT_LAUNCH_READY

BLOCKER A1 — Upgrade authority is a hot wallet.
  Fix: solana program set-upgrade-authority <PROGRAM_ID> <SQUADS_MULTISIG_ADDRESS>

BLOCKER C1 — Production RPC is api.mainnet-beta.solana.com.
  Fix: set RPC_URL to a dedicated Helius/Triton endpoint before launch.
```

### Example 2 — `DEVNET` → `LAUNCH_READY_WITH_RISKS`

Project is missing core instruction tests and has no recent integration evidence.

```
> /launch-check
Context detected: DEVNET

LAUNCH_READY_WITH_RISKS

HIGH B1 — Core instruction tests missing for 2 of 5 instructions.
  Fix: add LiteSVM or cargo test coverage for the untested instructions.

HIGH B3 — No integration test run found within the last 48 hours.
  Fix: run the integration suite against devnet or Surfpool and retain the dated log.
```

### Example 3 — `DEMO_HACKATHON` → `LAUNCH_READY`

Project has a working demo link, README and LICENSE present, and makes no real-funds claim.

```
> /launch-check
Context detected: DEMO_HACKATHON

LAUNCH_READY

No BLOCKERs. No unresolved HIGH risks.
```

## Commands

- **`/launch-check`** — runs the full verdict flow: classifies launch context, loads only the relevant domain modules, evaluates applicable criteria, and returns one of the three verdicts above with named BLOCKERs and HIGH risks.
- **`/fix-blockers`** — takes the most recent `/launch-check` result and produces an ordered fix plan, pulling exact commands from the remediation guide. Requires a prior `/launch-check` run.

## Rule

`no-shared-rpc` passively warns whenever `api.mainnet-beta.solana.com` (or `clusterApiUrl('mainnet-beta')`) appears in a project file, independent of running `/launch-check`. It does not assume launch context on its own — it points to `/launch-check` for the full context-aware verdict.

## Safety Boundaries

This skill never asks for private keys or seed phrases, never sends transactions, and never modifies wallet authorities or deployments directly. Every fix is presented as an exact command for the user to run themselves.

## License

MIT
