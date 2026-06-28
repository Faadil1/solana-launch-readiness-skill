# /launch-check

Run the full Solana launch readiness verdict flow using `skill/SKILL.md` as the source of truth for severity, routing, and verdict logic. This command does not duplicate that logic — it invokes it.

## Default Assumption

Start every run from `NOT_LAUNCH_READY`. Do not move off this default until evidence for the relevant criteria has actually been checked.

## Procedure

**STEP 0 — Classify launch context.**
Determine one of: `DEMO_HACKATHON`, `DEVNET`, `MAINNET_NO_FUNDS`, `MAINNET_WITH_FUNDS`, per `skill/SKILL.md` STEP 0. If the project files do not make this unambiguous, ask exactly one clarifying question and stop — do not proceed to STEP 1 on an assumed context.

**STEP 1 — Classify project type.**
Determine one of: on-chain program, frontend-only dApp, documentation/submission review, full-stack Solana project.

**STEP 2 — Load only relevant modules**, per the routing table in `skill/SKILL.md`:
- on-chain program → `security.md` + `testing.md`
- frontend-only dApp → `rpc.md` + `demo.md`
- documentation/submission review → `docs.md` + `demo.md`
- full-stack project → all five domain modules
- if any BLOCKER or HIGH is found in STEP 3 → also load `remediation.md`

Do not load a module with no applicable criteria for the detected project type.

**STEP 3 — Evaluate only the criteria in the loaded modules.** For each, gather evidence per that module's "what to check" guidance and classify as resolved, unresolved, or missing. Apply the context-aware severity for the STEP 0 context, as defined in that criterion's section of `SKILL.md` and the relevant domain module — do not re-derive severity from memory; read it from the table.

**STEP 4 — Apply verdict logic** from `skill/SKILL.md`. Hard rule: never output `LAUNCH_READY` while any criterion that is BLOCKER-severity for the detected context remains unresolved. This rule cannot be overridden by narration, confidence, or stated intent to fix later.

**STEP 5 — If any BLOCKER or HIGH is unresolved**, pull the exact fix for each from `skill/remediation.md` — do not invent a fix; use the one defined there for that criterion ID.

## Safety Boundaries

Do not send transactions, change upgrade authorities, query private wallet data, or request private keys, seed phrases, or keypair file content at any point in this command. All fixes are presented as commands or actions for the user to run themselves.

## Required Output Format

```
# Solana Launch Readiness Verdict

Detected launch context: <context>
Project type: <type>
Loaded modules: <modules>

Verdict: <LAUNCH_READY | LAUNCH_READY_WITH_RISKS | NOT_LAUNCH_READY>

## BLOCKERs
- <ID> — <title>
  Evidence: <what was found/missing>
  Fix: <exact command/action from remediation.md>

## HIGH Risks
- <ID> — <title>
  Evidence: <what was found/missing>
  Fix: <recommended action>

## MEDIUM Advisories
- <ID> — <summary>

## Evidence Table
| ID | Status | Severity | Evidence |
|---|---|---|---|

## Missing Evidence
- <ID> — <what is needed>

## Next Fix
<single highest-priority next action>
```

If no BLOCKER, HIGH, or MEDIUM finding exists for the loaded modules, still output every section above — use `None` in place of list items rather than omitting the section. A clean result can legitimately produce `Verdict: LAUNCH_READY`.

## Output Discipline

- Verdict comes first, before any explanatory detail.
- Do not invent evidence — every line in the Evidence Table must trace to something actually checked, read, or stated by the user. If a criterion's evidence could not be gathered, list it under Missing Evidence instead of guessing.
- Do not reproduce the full 19-criteria severity table from `SKILL.md` in the output — reference the criterion ID and its severity for this run only.
- Keep BLOCKER and HIGH entries concrete: name the ID, the title, what was actually found or missing, and the fix — not a general statement that something needs attention.
