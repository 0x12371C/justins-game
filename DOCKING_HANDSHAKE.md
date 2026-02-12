# Docking Handoff Schema

Use this document when two agents collaborate on this repository.

## Rule Zero

- Commit small and often.
- After every new commit, perform a handshake.
- Receiving agent must verify before any new coding begins.

## Branch and PR Model

- Do not commit directly to `main` during normal feature work.
- Create one branch per task:
  - Example: `feature/fishing-ui`, `feature/inventory-flow`
- Open PR from feature branch into `main`.
- Require review before merge.
- After merge, both collaborators sync `main` before next task.

### Minimal Commands

```bash
git checkout main
git pull origin main
git checkout -b feature/my-task
git add .
git commit -m "Implement my task"
git push -u origin feature/my-task
```

After PR merge:

```bash
git checkout main
git pull origin main
```

## Required Skill Context To Share

Always include these project-relevant skills in each handoff:

- `roblox-dev-rapid`: fast Rojo + Studio iteration, preflight expectations, ownership rules.
- `roblox-ui-creation`: lightweight, modular Roblox UI workflow and validation.
- `roblox-rojo-asset-pipeline`: image asset ID upload/wiring workflow for Rojo projects.

Optional when relevant:

- `roblox-store-assets`: sourcing/validating Creator Store assets.

## Handoff Payload Schema

Send this payload in markdown code fences after each commit.

```yaml
docking_handoff:
  commit: "<full or short sha>"
  branch: "<branch>"
  author_agent: "<agent name>"
  receiver_agent: "<agent name>"
  timestamp_utc: "<YYYY-MM-DDTHH:MM:SSZ>"
  intent:
    summary: "<one-line purpose of commit>"
    scope: ["<file>", "<file>"]
  skills_shared:
    - name: "roblox-dev-rapid"
      why: "Preserve fast and reliable Studio+Rojo loop"
    - name: "roblox-ui-creation"
      why: "Keep UI modular, lean, and consistent"
    - name: "roblox-rojo-asset-pipeline"
      why: "Avoid broken/missing UI image assets"
  verification_required:
    checks:
      - "Review changed files line-by-line"
      - "Run Rojo sourcemap generation"
      - "Playtest touched interaction path in Studio"
      - "Confirm no unrelated files were modified"
    expected_response: "ACK_VERIFIED:<commit>"
  blockers: []
  next_action_owner: "<author_agent|receiver_agent>"
  next_action: "<single actionable next step>"
```

## Receiver Verification Contract

Receiver must reply with exactly one of:

- `ACK_VERIFIED:<commit>` when all checks pass.
- `ACK_BLOCKED:<commit>:<reason>` when checks fail or are incomplete.

No further coding until one of these is sent.

## Commit Handshake Procedure

1. Author creates commit.
2. Author posts `docking_handoff` payload with required skills context.
3. Receiver verifies commit + checks and sends required ACK.
4. Only after ACK, next commit work begins.

## Repository-Specific Verification Minimum

- Run:
  - `rojo sourcemap default.project.json -o sourcemap.json`
- If UI/fishing/inventory scripts changed:
  - Equip tool path still works.
  - Fishing UI appears only on fishing pole action.
  - Backpack inventory remains visible.
