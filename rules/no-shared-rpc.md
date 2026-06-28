# Rule: no-shared-rpc

## Trigger

Any of the following found in a project file:
- `api.mainnet-beta.solana.com`
- `clusterApiUrl('mainnet-beta')`
- `clusterApiUrl("mainnet-beta")`

## Behavior

This rule fires passively, independent of `/launch-check` — it does not run the full verdict flow and does not classify launch context on its own. It supports criterion C1 (`skill/rpc.md`). On match, insert the warning below before continuing whatever task is in progress.

Severity depends entirely on launch context, which this rule does not assume from the trigger alone:

| Context | Severity |
|---|---|
| DEMO_HACKATHON | LOW |
| DEVNET | MEDIUM if this pattern indicates accidental devnet config confusion; otherwise not applicable |
| MAINNET_NO_FUNDS | HIGH |
| MAINNET_WITH_FUNDS | BLOCKER |

If context is not already known from earlier in the conversation, state that severity is unresolved until classified — do not guess.

## Inline Warning

```text
⚠️ Shared public Solana mainnet RPC detected

Found: <matched pattern or file reference>
Criterion: C1 — Dedicated RPC endpoint in use
Context severity: unknown until /launch-check classifies launch context

If this project is MAINNET_WITH_FUNDS, C1 is a BLOCKER.
Fix direction: configure a dedicated provider endpoint through RPC_URL / NEXT_PUBLIC_RPC_URL.
Do not hardcode private RPC API keys in public client-side code.

Run /launch-check for the full context-aware verdict.
```

If the launch context is already established as `MAINNET_WITH_FUNDS` earlier in the conversation, state directly: "This is a BLOCKER under C1 until replaced with a dedicated RPC endpoint" — skip the "unknown until classified" line in that case.

## Safety Boundaries

- Never send a transaction or otherwise interact with the matched RPC endpoint.
- Never test, ping, or benchmark the endpoint to assess its reliability.
- Never edit the matched file or config automatically — this rule only warns.
- Never expose, request, or suggest pasting a private RPC API key.

## References

For full detail beyond this warning, see `skill/rpc.md` C1, `skill/remediation.md` C1, and the `/launch-check` command — this rule does not reproduce their content.
