# /fix-blockers

Convert a prior `/launch-check` result into an ordered remediation plan using `skill/remediation.md` as the source of truth. This command does not re-derive fixes — it pulls them from that module. It does not re-run the full launch check unless the user explicitly asks for that.

## Procedure

**STEP 1 — Get the source verdict.**
Use the most recent `/launch-check` result available in this conversation. If none exists, stop and instruct the user to run `/launch-check` first — do not guess at a verdict or context to proceed without one.

**STEP 2 — Extract from that verdict:**
- detected launch context
- the verdict itself
- every named BLOCKER
- every named HIGH risk
- any criteria listed under missing evidence

**STEP 3 — Load `skill/remediation.md`.** For each BLOCKER and HIGH extracted in STEP 2, find that criterion's entry in `remediation.md` and use its fix, verification step, and "what not to do" guidance exactly as written there. Do not invent a fix not present in `remediation.md`.

**STEP 4 — Order the plan:**
1. BLOCKERs first, in the order they appeared in the source verdict
2. HIGH risks second
3. Missing evidence that is currently preventing a criterion from being classified at all

**STEP 5 — Mark judgment calls.** Any fix that `remediation.md` labels as requiring a decision only the user can make (e.g., selecting multisig signers, engaging an external auditor, deciding where to move excess demo funds) must be marked `requires human approval: yes` with a one-line explanation of what the user needs to decide. All other fixes are `requires human approval: no`.

**STEP 6 — Handle a clean verdict.** If the source verdict is `LAUNCH_READY`, do not produce a BLOCKER/HIGH fix plan — state that none is needed, and optionally list any MEDIUM advisories from the source verdict if present.

## Safety Boundaries

Never execute any command in the plan. Never request a private key, seed phrase, or keypair file content, under any phrasing. Never move funds or change an upgrade authority — only present the exact command for the user to run themselves. Never instruct the user to paste a secret into chat.

## Required Output Format

```
# Solana Launch Fix Plan

Source verdict: <LAUNCH_READY | LAUNCH_READY_WITH_RISKS | NOT_LAUNCH_READY>
Detected launch context: <context>

## Priority 1 — BLOCKERs
1. <ID> — <title>
   Why it blocks: <reason>
   Fix:
   ```bash
   <exact command if applicable>
   ```
   Verify:
   ```bash
   <verification command/check>
   ```
   Human approval: <yes/no, explain if yes>

## Priority 2 — HIGH Risks
1. <ID> — <title>
   Why it matters: <reason>
   Fix: <command/action>
   Verify: <verification check>
   Human approval: <yes/no, explain if yes>

## Missing Evidence
- <ID> — <what is needed to classify this criterion>

## Do Not Do
- <safety boundary relevant to this plan's fixes>

## Re-check Command
Run `/launch-check` again after completing the fixes above.
```

If the source verdict has zero BLOCKERs and zero HIGH risks, output only:
```
No blocker fix plan needed. Re-run /launch-check only after material changes.
```
followed by any MEDIUM advisories from the source verdict, if present.

## Output Discipline

- Do not invent a fix, command, or verification step that is not present in `skill/remediation.md` for that criterion ID.
- Do not reproduce the full contents of `remediation.md` — pull only the entries relevant to the BLOCKERs and HIGH risks named in the source verdict.
- Keep every fix command-oriented: a concrete command, file edit, or named action — not a general instruction to "improve" or "review" something.
