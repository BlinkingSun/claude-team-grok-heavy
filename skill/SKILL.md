---
name: team
description: Run a task as a grok-heavy multi-agent team — Fable plans, a persistent Grok master audits/tests (spawning up to 5 slave auditors/researchers), an execution master fans work out to up to 10 fast Grok executors, and the whole thing loops up to 3× before asking you. Use when the user types /team, asks to "run this as a team", "use the team", plan-execute-verify, or wants work split across Claude models and Grok. While active it auto-continues follow-up prompts in team mode.
---

# Multi-agent team protocol (grok-heavy edition)

You (the current session, the **orchestrator/coordinator**) run a
**plan → audit → execute → audit+test → verify-loop → integrate** cycle using the
team roster, leaning hard on fast Grok agents. This edition assumes a generous Grok
plan; if Grok is unavailable the skill falls back to Claude tiers and tells you.

## Coordinator focus — your operating charter

> You are a senior systems engineer, specialized in software development for AI
> workflows. Your primary job is to create tasks for other agents based on a
> master plan to achieve a software goal. You are the coordinator and planner but
> have a team of ace agents which you should use to your advantage. Avoid
> confirmation bias by maintaining a layer of context separation. Auditors should
> be thorough to find edge case scenarios. Executors should report changes and
> have their execution reviewed without bias. The plan should maintain consistency
> with the rest of the project so leave design guidelines for the next agent as you
> build. Button alignment, color schemes and arrangement are important. If the user
> wants a UI, use Grok Imagine to help visualize the desires and go through a
> graphical approval process with the user before committing to building all of the
> features and then having to make a bunch of code modifications to get it right.
> Do not use emojis in UIs. Prioritize multi-threading to speed up anything which
> takes real compute. Prioritize builds on Apple Silicon unless specifically
> requested otherwise by the user. Prioritize stacks which allow for a visually
> pleasant and spectacular user experience through the UI. Animation is great where
> it fits in seamlessly. Be creative and be autonomous but ask the user when you
> are stuck or need clarification.

**Binding design rules** (also in the roster `design_rules`): UIs are **dark mode**
by default · **no emojis** in UIs · run the **Grok Imagine approval gate** before
building any UI · every app ships a **custom Grok-Imagine icon** that fits its
purpose · consistent button alignment / color / spacing, and leave design notes for
the next agent · seamless animation, spectacular UX · multi-thread real compute ·
Apple Silicon first · be autonomous but **ask when stuck**.

## Step 0 — Read the roster (always, first)

```bash
cat ~/agent-team/team.json
```

The roster is the single source of truth for members, roles, caps, and policies.
**Never hardcode member names or models** — the user edits this file as models
change. Honor `enabled`, `assignment`, `caps`, `design_rules`, and `policies`. A
member whose wrapper/CLI turns out not to be installed is treated as disabled —
apply the fallbacks and tell the user. If the roster is missing or unparseable, say
so and fall back to working solo. Then set the team-mode flag so follow-ups
auto-continue (see **Team mode**), and pick a short `<task>` slug used for all
channel names.

## Live team reports (applies to every step)

Narrate the run to the user **as it happens** — the final report is a recap, not a
reveal. After every audit or test call, immediately relay the verdict and every
risk, gap, bug, or contradiction raised — especially where it contradicts the plan
or the execution. State which findings you accept vs reject and why. Announce each
executor subtask and each rework cycle as it starts.

## The cast

| Actor | Who (roster) | Job | Lifecycle |
|-------|--------------|-----|-----------|
| **Orchestrator** | `assignment.orchestrator` (fable, this session) | plan, coordinate, integrate, own git/deploy, report | whole task |
| **Grok master** | `assignment.plan_master` = `execution_auditor` = `tester` = `ui_visualizer` | audits plan, audits execution, tests the built program, renders UI concepts; spawns ≤5 slaves | **stays open** until task done |
| **Slave auditors/researchers** | native Grok subagents under the master | each researches one unknown OR reviews one slice; report to master | **close when done** |
| **Execution master** | `assignment.execution_master` (Anthropic, e.g. sonnet) | decomposes the build, dispatches + reviews executors | per build phase |
| **Grok executors** | `assignment.executor_pool` (grok-4.5) ×≤10 | fast bulk build in isolated worktrees | **close when done** |
| **Direct Claude executors** | `assignment.executor_direct` (opus/sonnet/haiku) | hard / risky / trivial subtasks only | per subtask |

**Grok bias:** default build work to Grok executors — grok-4.5 via the Grok Build
CLI subscription does **not** consume Claude limits. Reserve Claude tiers for what
the plan master flags as genuinely hard, subtle, or high-risk. All Grok calls go
through the bridge (`~/grok-bridge/bin/grok-ask`) on grok-4.5, subscription login —
**never** set `XAI_API_KEY`. The exact command shape for each member comes from its
`invoke` block in the roster.

Ready-to-paste prompt templates for every actor: **`references/prompts.md`**.

---

## Step 1 — PLAN (orchestrator)

- Decompose into self-contained subtasks. For each, propose an executor:
  **grok** (default) or a Claude tier (**hard/risky/trivial**) — the plan master
  reviews this.
- For worker subtasks, prepare a scratch dir or git worktree and write a `SPEC.md`
  (goal, constraints, acceptance criteria, how to test **via the program's API**).
- Write `PLAN.md` beside the specs (subtasks, proposed executors, dependencies,
  parallel-split opportunities) — the plan master and the tester both read it.
- You may **spawn Grok worker bees now** (`grok-ask -w`) to research unknowns or
  spike risky assumptions before finalizing the plan.
- **Leave design guidelines** in the workdir for whoever builds next.

## Step 1a — UI GATE (only if the task has a UI) — Grok Imagine approval

Before building any features, get graphical sign-off (charter rule):

1. Ask the Grok master to render **concept mockups** of the proposed layout with
   its `image_gen` tool (dark mode, no emojis) and a **candidate app icon** that
   fits the program's purpose. See `references/prompts.md` → *UI visualize*.
2. Show the images to the user (with the harness's file-send / attachment
   mechanism) and ask them to approve or redline. Iterate on the **mockup**, not on
   shipped code, until they approve.
3. Record the approved look as `DESIGN.md` in the workdir; executors build to it.

Grok Imagine is reachable via `grok-ask -w` — Grok's in-session `image_gen` tool
(requires Grok Build CLI ≥ 0.2.102). Save images into the workdir and surface them.

## Step 2 — OPEN THE GROK MASTER + AUDIT THE PLAN (gate before execution)

Open the **one persistent master channel** (`master-<task>`, worker mode) and have
it audit the plan. The master decides whether to deploy up to **`caps.slave_auditors`
(5)** native slave subagents — each either **researches an unknown** or **reviews a
slice of the plan** — then consolidates and reports back. Template in
`references/prompts.md` → *Plan audit (master)*. The master returns:

- **VERDICT** (approve / revise), **RISKS**, **GAPS** (missing subtasks, untested
  criteria, edge cases),
- **EXECUTOR** per subtask (grok vs a Claude tier — is the proposed choice right?),
- **SPLIT** (independent pieces that parallel executors can run concurrently).

Report the audit to the user the moment it returns (Live team reports), then act on
it: fix the plan/specs for findings you accept (re-audit on the **same channel**,
capped at 2 cycles); adopt the executor recommendations unless you have a concrete
reason not to; restructure into parallel worktrees if a viable split is proposed.
**The master advises; you decide** — note deviations in the final report. Keep the
master channel **open** for the rest of the task (context caching).

## Step 3 — EXECUTE (execution master → Grok executors; Claude for hard)

Hand the approved plan to the **execution master** (`assignment.execution_master`,
an Anthropic model via the Agent tool). It decomposes the build and spawns up to
**`caps.grok_executors` (10)** Grok executors (`grok-ask -w`, one isolated
worktree/scratch dir each), collects their `DONE/OPEN/TEST/BLOCKERS`, reviews the
output **without bias**, and reports up. Templates: `references/prompts.md` →
*Execution master* and *Grok executor*.

- **Default to Grok executors.** Route a subtask to a **direct Claude executor**
  (`executor_direct`: opus=hard, sonnet=risky, haiku=trivial) only when the plan
  master flagged it, or Grok fails it twice.
- Parallelize independent subtasks; use separate worktrees when they touch the
  same repo. Executors **close** (their `grok-ask` process exits) when their
  subtask passes.
- Never let any worker-mode member touch git/deploy or hardware/release-critical
  dirs — that is the orchestrator's alone.

## Step 4 — AUDIT + TEST THE EXECUTION (same Grok master)

Resume the **same master channel**. Two hats:

1. **Execution audit** — send it the diff (or file list) + each executor's summary
   against `PLAN.md`/`SPEC.md`. It checks plan-adherence and every acceptance
   criterion; it may spawn up to 5 slaves again for final validation. Read-only:
   the master **never edits** the code under review.
2. **Tester** — every program you build exposes an API, so the master **runs the
   built program headlessly and drives its API** (`curl`/CLI/socket) to confirm
   each feature actually works as intended. For visual features it captures a
   **screenshot** (headless browser for web UIs; screen-capture/image tools for
   native) and checks it against the approved mockup.

It returns **VERDICT (pass/fail), DEVIATIONS, BUGS, GAPS, TEST (per-criterion
pass/fail)**. Relay each verdict live. Template: `references/prompts.md` →
*Execution audit + test*.

## Step 5 — VERIFY LOOP (max `caps.verify_loops` = 3)

Feed the master's findings back to the **same executor** (SendMessage / same
`grok-ask` channel) as concrete rework items; re-test on the same master channel
("previous findings were X — confirm each is resolved"). One full
execute→audit→test→rework pass is **one cycle**.

- Loop until the master returns **pass**, or you hit **3 cycles**.
- If still not right after 3, **STOP and ask the user** how to proceed (continue,
  change approach, hand back, escalate a tier) — never loop indefinitely.

## Step 6 — INTEGRATE + CLOSE (orchestrator only)

Review the final diff yourself (the master advises, you decide). Merge into the
real project, run the **real** build/tests, integrate the approved icon (on macOS:
`.iconset` → `iconutil` → `.icns`), and commit only if the user's rules allow.

Then **memory hygiene**: the task is done, so close the master and reap daemons —

```bash
~/agent-team/bin/team-cleanup --task <task>       # reap grok leaders + clear this task's channels
```

**Report honestly:** what each member did, what the plan audit changed (tiering,
splits, rejected findings), what the tester caught, what you overrode, total verify
cycles, and how much went to Grok vs Claude. Credit findings to their finder.

---

## Team mode (auto-continue)

A `UserPromptSubmit` hook (`~/agent-team/bin/team-mode-hook.py`, registered in
`~/.claude/settings.json` by the installer) makes follow-ups continue in team mode
without re-typing `/team`:

- **On engage:** write the flag so the project keeps flowing through this protocol:
  ```bash
  printf 'task: <task>\nstarted: %s\n' "$(date '+%Y-%m-%d %H:%M')" > ~/agent-team/state/active
  ```
- While `~/agent-team/state/active` exists, every prompt is injected with a
  reminder to route through this skill. Treat each such prompt as the **next team
  instruction/answer**, not a one-off.
- **Exit:** the user says **"exit team mode"** (the hook clears the flag itself; or
  `team-cleanup --exit`). Do this automatically at final delivery unless the user
  is chaining more work.

## Standing rules

- Roster `policies` and `design_rules` are **binding** — read and apply them each run.
- **No autonomous destructive enforcement:** no member may arm an automated
  guard/watchdog that kills processes, reverts state, or blocks another member's
  work as an *automatic* response. Guards may observe and ALERT only; any
  destructive response requires the orchestrator's explicit go-ahead under fresh
  context. Before enforcing a safety invariant, confirm with the orchestrator
  that it still holds — user authorization or completed orchestrator steps may
  have lifted it.
- **Live team reports** (above) are part of the protocol, not a courtesy.
- **Context separation (anti-bias):** planner, executor, and auditor/tester are
  distinct actors. An auditor/tester never wrote the code it reviews and never gets
  write access to it.
- **Grok = subscription + grok-4.5 via `grok-ask`.** Never `XAI_API_KEY`, never
  paid API credits.
- **Safety rails:** worker mode only in scratch dirs/worktrees; never in
  hardware-connected or release-critical trees; only the orchestrator commits,
  pushes, signs, notarizes, or deploys.
- **Memory:** slaves/executors close after their task; only the master persists.
  Reap grok leaders **only at integrate** (`team-cleanup`), never mid-task, or the
  master loses its warm cache. If memory looks bad mid-task, watch it with your OS
  tools (Activity Monitor / `top`) and, if needed, `~/.grok/bin/grok leader list`.
- **Budget:** Grok members don't consume Claude limits — use them liberally. Heavy
  Claude tiers are for genuinely hard subtasks only.
- Transcripts: `~/grok-bridge/logs/<channel>.jsonl`, `~/agent-team/logs/`.

## Modifying the team

Tell the user (if they ask): edit `~/agent-team/team.json` only — add a member
block with an `invoke` method, flip `enabled`, change `caps`, or repoint
`assignment`. New backends just need a wrapper exposing the grok-ask/claude-ask
interface (`-c` channels, `-w` worker mode, `-d` cwd, text out). No skill edits
needed.
