# Demo & Submission Confidence — Domain E

## Purpose

This module evaluates whether the project can actually be demonstrated, reviewed, or submitted without launch-critical ambiguity — not whether the pitch is compelling. It does not write or polish a pitch. It checks whether the demo and submission evidence supports the launch verdict: a verdict claiming LAUNCH_READY is undermined if the "live demo" only runs on localhost, or if the submission is missing the artifacts a reviewer needs to evaluate it at all.

Severity for every criterion below is read from the launch context classified in `SKILL.md` STEP 0. Do not apply these severities without that classification.

---

## E1 — Live Demo Runs on Target Network Without Localhost Dependencies

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| HIGH | HIGH | HIGH | HIGH |

**What to check:** Whether the demo a reviewer would actually access runs against a real, reachable deployment — not a local development server only the builder can reach.

**Command:**
```
grep -R "localhost\|127.0.0.1" README.md docs/ app/ src/
```
Treat a match inside README/docs as a stronger signal than a match in source — a `localhost` reference in a setup script for local development is expected; the same reference as the only access path for reviewers is the actual failure mode.

**Evidence examples:**
- Resolved: README or submission links to a deployed, externally reachable URL (Vercel, Netlify, Cloud Run, Render, or a devnet/mainnet program address with a working frontend) that does not require the reviewer to run anything locally.
- Unresolved: the only documented way to see the demo is "clone the repo and run `npm run dev`," with no deployed URL provided.
- Missing: no demo access path documented at all — neither a URL nor instructions.

**How to classify:** If both a deployed URL and local setup instructions exist, this criterion is resolved by the deployed URL alone — local setup instructions are a reasonable addition, not a problem, as long as they are not the *only* path.

**What not to assume:** Do not assume a demo "probably works" because the code looks complete — this criterion is about reachability, not code quality. Do not assume a deployed link is currently live without checking that it resolves to something other than an error or placeholder page, if a check is possible.

**Output wording:** "Demo reachability: [confirmed — live at <URL>, no localhost dependency / unresolved — only local setup instructions found, no deployed URL / no demo access path found]."

---

## E2 — Demo Wallet Funded Only to Minimum Needed

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| HIGH | MEDIUM | HIGH | **BLOCKER** |

**What to check:** Whether any wallet used for demo purposes holds only the minimum funds needed to run the demo — not idle excess that turns a public demo into an unnecessary funded-wallet exposure.

**Evidence handling:** This module never queries a wallet balance autonomously. Wallet balance is accepted only as evidence the user directly provides (a stated balance, a screenshot description, or an explicit confirmation). Do not look up or expose a wallet's holdings on your own initiative.

**Evidence examples:**
- Resolved: the user states the demo wallet balance and it is reasonably scoped to the demo's actual needs (e.g., a few dollars of SOL for transaction fees on a funds-moving demo, not an arbitrary large balance).
- Unresolved: the user states or implies the demo wallet holds significantly more than the demo requires, with no stated reason (e.g., it's the same wallet used for other production funds).
- Missing: no information about the demo wallet's funding has been provided — ask the user directly rather than assuming either a safe or unsafe state.

**How to classify:** "Minimum needed" is contextual — a demo that only signs read-only or simulated transactions needs near-zero balance; a demo that actually moves tokens needs enough to cover that movement plus fees, and no meaningful excess beyond it. Judge against the demo's actual on-chain actions, not a fixed number.

**What not to assume:** Do not assume a demo wallet is safe because "it's just for the hackathon" — a publicly shared demo wallet address with real funds is exploitable by anyone watching the demo or reading the repo, regardless of intent. Do not request the wallet's private key or seed phrase to check this yourself under any circumstance.

**Output wording:** "Demo wallet funding: [user-confirmed — balance scoped to demo needs / user-confirmed — balance appears to exceed demo needs, recommend reducing / not disclosed — ask user before continuing]."

**Fix when unresolved, MAINNET_WITH_FUNDS:** Move excess funds out of the demo wallet to a separate wallet not exposed in any public demo, repo, or video, leaving only the minimum balance required for the demo's actual on-chain actions plus transaction fees.

---

## E3 — Submission Package Complete

| DEMO_HACKATHON | DEVNET | MAINNET_NO_FUNDS | MAINNET_WITH_FUNDS |
|---|---|---|---|
| HIGH | HIGH | HIGH | HIGH |

**What to check:** Whether the basic artifacts a reviewer needs to evaluate the submission are actually present: README, a demo link or video, a public repository, and a license.

**Commands:**
```
ls README.md LICENSE
git remote -v
git status --short
grep -R "demo\|video\|youtube\|loom\|vercel\|netlify\|cloud run\|render" README.md docs/
```
`git remote -v` confirms whether the repo has a remote at all (a strong signal it could be public); it does not by itself confirm public visibility — ask the user to confirm the repo's visibility setting directly rather than inferring it from the remote URL alone. `git status --short` confirms there are no uncommitted changes that would make the submitted state different from what a reviewer actually checks out.

**Evidence examples:**
- Resolved: `README.md` and `LICENSE` both exist, a demo link or video is referenced in the README or docs, the repo has a remote and the user confirms it is public, and `git status --short` shows no uncommitted changes at submission time.
- Unresolved: one or more of the above exists but is incomplete (e.g., README exists but has no demo link; LICENSE file is present but empty).
- Missing: `README.md` or `LICENSE` does not exist at all, or the user confirms the repository is still private.

**How to classify:** Treat each artifact independently and report which specific ones are missing rather than a single pass/fail — a submission missing only a demo video has a different fix than one missing a LICENSE entirely.

**What not to assume:** Do not assume a repository is public because it has a `git remote -v` entry pointing to GitHub — private repos also have remotes. Confirm visibility with the user directly. Do not assume uncommitted local changes will be included in what a reviewer sees — only committed, pushed state matters for submission completeness.

**Output wording:** "Submission package: [complete — README, LICENSE, demo link, public repo all confirmed / incomplete — missing: <list> / repo visibility unconfirmed, ask user]."

---

## Safety Boundaries (Domain E)

- Never request a private key or seed phrase for any wallet, demo or otherwise.
- Never query or look up a wallet's balance or holdings autonomously — accept only balance information the user explicitly provides.
- Never encourage funding a demo wallet beyond what the demo's actual on-chain actions require.
- Never claim a demo is live or reachable without an actual URL or other concrete evidence — do not assume reachability from the presence of deployment-related code alone.
- This module does not publish, push, or submit anything — it reads current repository and documentation state and reports gaps for the user to act on.
