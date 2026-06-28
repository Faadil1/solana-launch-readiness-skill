# Testing — Domain B: Testing Evidence

## Purpose

This module evaluates whether launch-relevant test evidence exists for the program's core logic, error paths, and integration behavior on a live network. It does not measure full coverage and does not prove correctness. It checks whether the *evidence* needed to support a launch verdict is present — a passing test suite reduces launch risk; it does not eliminate it.

Severity for every criterion below is read from the launch context classified in `SKILL.md` STEP 0. Do not apply these severities without that classification.

---

## B1 — Core Instruction Tests Present, Not Happy-Path Only

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| MEDIUM | HIGH | HIGH | HIGH |

**What to check:** Whether every core on-chain instruction has a test that exercises it beyond the single expected success path.

**Commands:**
```
anchor test
cargo test
grep -R "LiteSVM\|litesvm" tests/ programs/
```

LiteSVM is the preferred evidence type for Solana-native test execution — it runs the actual program against a lightweight SVM rather than mocking it. If the project does not use LiteSVM, a plain `cargo test` suite that directly invokes program logic (without a full validator) is acceptable evidence as long as it exercises the same instructions. Do not require LiteSVM specifically — require that *some* test exercises each core instruction.

**Evidence examples:**
- Resolved: `anchor test` or `cargo test` passes, and a `grep` for `LiteSVM`/`litesvm` or equivalent instruction-level test calls shows each core instruction is invoked at least once with a non-trivial input, not just the default success case.
- Unresolved: tests exist but only cover one instruction, or all tests use the same minimal "happy path" input with no edge cases.
- Missing: no `tests/` directory, or test commands fail to run (missing dependencies, build errors).

**How to classify:** "Covering core instructions" means every instruction a user can call in production has at least one test. A program with five instructions and tests for only two has unresolved evidence for the other three, even if the two tested ones are thorough.

**What not to assume:** Do not assume a single passing `anchor test` run means all instructions are tested — check which instructions are actually invoked in the test file, not just that the suite is green. Do not invent or assume test coverage percentages; report only what is directly observed.

**Output wording:** "Core instruction test coverage: [N of M instructions have direct test invocation — list untested instructions / all instructions tested, single-path only / all instructions tested with multiple input cases / no test evidence found]."

---

## B2 — Error Paths Tested

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | MEDIUM | MEDIUM | HIGH |

**What to check:** Whether each custom error variant the program can return has a test that deliberately triggers it and asserts the rejection.

**Command:**
```
grep -R "assert_err\|AnchorError\|error_code" tests/ programs/
```

**Evidence examples:**
- Resolved: every `#[error_code]` variant defined in the program has a corresponding test that triggers the failing condition and asserts on the specific error (not just "any error").
- Unresolved: some error variants are defined but never deliberately triggered in tests, or tests assert generic failure without checking which error fired.
- Missing: no `error_code` enum found, or no error-path tests exist at all.

**How to classify:** Count the defined error variants against the ones with a matching test assertion. Partial coverage (some but not all variants tested) is unresolved, not resolved — state the gap explicitly rather than rounding up.

**What not to assume:** Do not assume an error path is tested because the happy-path test "would fail if something broke" — that is not the same as a deliberate test of the rejection condition.

**Output wording:** "Error path coverage: [N of M error variants have a dedicated rejection test / no error-path tests found / unable to enumerate error variants]."

---

## B3 — Live Integration Test Executed Recently

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| LOW | HIGH | HIGH | HIGH |

**What to check:** Whether the program has been exercised against a live network (devnet, or Surfpool's local validator fork) recently, not just in isolated unit tests.

**Evidence to request:** Surfpool run output, devnet integration test logs, or a CI run timestamp within the last 48 hours. Acceptable forms:
- A CI job log showing a devnet integration test run with a timestamp
- A Surfpool session transcript or log file
- A manually reported test run with timestamp and outcome, stated directly by the user

**Evidence examples:**
- Resolved: a log, CI run, or direct user statement shows a successful integration run against devnet or Surfpool within the last 48 hours.
- Unresolved: integration tests exist in the repo but no evidence of an actual recent run is available (last known run is stale or undated).
- Missing: no integration test setup exists at all — only unit-level tests.

**How to classify:** "Recent" means within 48 hours of the launch-readiness check. A test suite that exists but was last run a week ago is unresolved, not resolved — the program or its dependencies may have changed since.

**What not to assume:** Do not treat the mere existence of an integration test file as evidence it was run. Do not assume a successful unit test suite substitutes for a live network run — they test different failure modes (logic errors vs. network/runtime behavior).

**Output wording:** "Live integration evidence: [confirmed — <source>, run at <timestamp> / integration tests exist but no recent run evidence / no integration tests found]."

---

## B4 — No Test-Only Keypairs in Production Code Paths

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| MEDIUM | HIGH | HIGH | **BLOCKER** |

**What to check:** Whether any keypair generated or loaded for testing purposes is reachable from a code path that runs in production.

**Command:**
```
grep -R "#\[cfg(test)\].*Keypair\|Keypair::new\|read_keypair_file" programs/ src/ app/
```

**Evidence examples:**
- Resolved: every `Keypair::new()` or `read_keypair_file()` call is confined to a `#[cfg(test)]` block, a `tests/` directory, or an explicitly test-only binary/script that is never invoked by the production deployment.
- Unresolved: a `Keypair::new()` or hardcoded test keypair appears in a file under `programs/`, `src/`, or `app/` outside a `#[cfg(test)]` guard, with no clear separation from the production build path.
- Missing: cannot determine build/deploy boundaries from available files — ask the user which files are actually included in the production build.

**How to classify:** The grep above is a starting signal, not a final verdict — review each match manually. A match inside a `#[cfg(test)] mod tests { ... }` block is resolved; the same call sitting in a shared utility module imported by both tests and the production binary is unresolved.

**What not to assume:** Do not assume a keypair is test-only just because the variable is named `test_keypair` — check whether the code path that uses it is actually excluded from the production build. Do not assume the absence of a grep match means none exist — dynamically constructed keypair logic may not match the pattern.

**Output wording:** "Test-keypair isolation: [confirmed — all test keypair generation is scoped to #[cfg(test)] or tests/ / unresolved — test keypair generation found in <file path>, reachable from production path]."

**Fix when unresolved, MAINNET_WITH_FUNDS:** Move the flagged keypair generation behind a `#[cfg(test)]` attribute or into a file under `tests/` that is excluded from the production build, then re-run the grep to confirm no remaining matches outside test scope. This BLOCKER cannot be waived by stating intent to fix later — it must show zero matches before the verdict changes.

---

## Safety Boundaries (Domain B)

- Do not invent or assume passing test results — only report what `anchor test`, `cargo test`, or a provided log actually shows.
- Do not claim a coverage percentage unless a coverage tool actually produced one; describe coverage in terms of "N of M instructions/errors" instead.
- Do not treat a happy-path-only test suite as sufficient evidence for B1 or B2 regardless of launch context — happy-path coverage downgrades the resolution status, it does not satisfy it.
- This module never modifies production code or test files — it reads and reports only.
