# Grok-Heavy Team — a Claude Code `/team` skill

A `/team` skill for [Claude Code](https://claude.com/claude-code) that runs a task
as a **grok-heavy multi-agent team**. Claude (**Fable 5**) plans and integrates; a
**persistent Grok master** audits the plan, audits the execution, and **tests the
built program** — spawning up to **5 slave auditors/researchers** as needed; an
**execution master** fans the build out to up to **10 fast Grok executors**. The
verify loop runs up to **3×**, then asks you. While a task is active, follow-up
prompts **auto-continue in team mode** — no need to retype `/team`.

> **This is the grok-heavy edition.** It leans on Grok for almost everything —
> the persistent master + 5 slaves, the 10-wide executor pool, all research, all
> testing, and Grok Imagine for UI mockups. It expects a **generous Grok plan
> (SuperGrok Heavy / X Premium+)**. If your Grok usage is limited, use the lighter
> [claude-team-skill](https://github.com/BlinkingSun/claude-team-skill) instead,
> which uses Grok only for lightweight plan-audit and verification.

The payoff: **Ultracode-like multi-agent coverage while sparing your Claude plan.**
Almost all the compute — building, auditing, testing, research, image concepts —
rides your Grok subscription; your Claude tokens go mostly to planning, dispatch,
and integration.

```
                     ┌─────────────────────────────────────┐
                     │  your Claude Code session (Fable 5)  │
                     │  ORCHESTRATOR · plan · integrate · git│
                     └───┬───────────────┬──────────────┬───┘
        PLAN.md / specs  │               │              │  diff + summaries
                         ▼               ▼              ▼
     ┌───────────────────────────┐  ┌─────────────┐  ┌──────────────────────────┐
     │ EXECUTION MASTER (Claude) │  │ GROK MASTER │  │  verify loop, max 3×      │
     │ decomposes + dispatches   │  │ grok-4.5    │  │  findings ─► rework ─►    │
     │        │  up to 10         │  │ PERSISTENT  │  │  re-test on same master  │
     │        ▼                  │  │  · plan audit                            │
     │ ┌────────────────────┐    │  │  · exec audit  ┌───────────────────────┐ │
     │ │ GROK EXECUTORS ×≤10 │    │  │  · tester (API)│ SLAVES ×≤5 (subagents)│ │
     │ │ grok-4.5, worktrees │    │  │  · UI Imagine  │ research OR review,   │ │
     │ │ close when done     │    │  │  stays open    │ close when done       │ │
     │ └────────────────────┘    │  └─────────────┘  └───────────────────────┘ │
     │ (opus/sonnet/haiku only   │                                             │
     │  for hard/risky subtasks) │                                             │
     └───────────────────────────┘                                             │
```

Everything is **roster-driven**: one JSON file defines the members, caps, roles,
design rules, and binding policies. Add or remove models by editing JSON — the
skill never hardcodes a member.

## What makes it grok-heavy

- **A persistent Grok master.** One Grok session stays open for the whole task
  (context caching) and wears four hats: plan auditor, execution auditor, tester,
  and UI visualizer. It decides how to deploy up to **5 slave subagents** — each
  either researches an unknown or reviews a slice — then consolidates and reports.
- **A 10-wide Grok executor pool.** A Claude execution master decomposes the build
  and dispatches it to up to **10 Grok executors** running in isolated worktrees;
  build work defaults to Grok, and Claude tiers (opus/sonnet/haiku) are reserved
  for genuinely hard or risky subtasks.
- **It tests what it builds.** Every program is expected to expose an API, so the
  Grok master runs the built program headlessly and drives its API to confirm each
  feature actually works — capturing screenshots for visual features and comparing
  them to the approved mockup.
- **Grok Imagine UI gate.** For any UI, the master renders concept mockups and a
  candidate app icon with Grok's in-session `image_gen` tool, and you approve the
  look **before** a line of feature code is written. Iterate on the mockup, not on
  shipped code.
- **A bounded verify loop.** Execute → audit → test → rework repeats up to 3 times,
  then stops and asks you rather than looping forever.
- **Auto-continue team mode.** A `UserPromptSubmit` hook keeps a project flowing
  through the protocol across follow-up prompts until you say "exit team mode".

## Design defaults

Baked into the roster's `coordinator_focus` charter and `design_rules`: UIs are
**dark mode** with **no emojis**, run the **Grok Imagine approval gate** first, and
every app ships a **custom Grok-Imagine icon** that fits its purpose; consistent
button alignment / color / spacing with design notes left for the next agent;
seamless animation; multi-threaded compute; Apple Silicon first.

## Live team reports

The skill narrates the run in real time — you watch the models disagree, not just
read about it afterward: the Grok audit verdict and every risk/gap/contradiction,
which findings the orchestrator accepted vs rejected, each executor starting and
finishing, each test verdict as it lands, and every rework cycle.

## Install

The shipped roster is the author's reference setup, model-to-model and
prompt-to-prompt: Fable 5 orchestrating, a Claude execution master, Grok 4.5 as the
master auditor/tester and the executor pool, and opus/sonnet/haiku as direct
executors for hard/risky/trivial subtasks.

### 1. Grok Build CLI (the master, executors, and Imagine)

Requires a **SuperGrok Heavy or X Premium+** subscription (macOS or Linux):

```bash
curl -fsSL https://x.ai/cli/install.sh | bash
grok login          # authenticate with your X / xAI subscription (no API key)
```

Grok Imagine (UI mockups + icons) needs Grok Build CLI **≥ 0.2.102** — update with
`~/.grok/bin/grok update` if needed. Verify: `~/.grok/bin/grok --version`.

### 2. claude-grok-bridge (the `grok-ask` wrapper the roster invokes)

```bash
git clone https://github.com/BlinkingSun/claude-grok-bridge.git
cd claude-grok-bridge && ./install.sh
```

Installs the bridge to `~/grok-bridge/bin/grok-ask` — persistent channels,
consult/worker safety modes, native subagents, full audit logs.

### 3. This skill

```bash
git clone https://github.com/BlinkingSun/claude-team-grok-heavy.git
cd claude-team-grok-heavy && ./install.sh
```

The installer copies the skill (+ prompt templates) to `~/.claude/skills/team/`,
seeds `~/agent-team/` with the roster and bridges, and **registers the
auto-continue hook** in `~/.claude/settings.json` (idempotent; backs the file up
first; pass `--no-hook` to skip). It never overwrites an existing `team.json`.

Then, inside any Claude Code session:

```
/team build a small menu-bar app that shows disk usage, dark mode, with an icon
```

Follow-ups continue in team mode automatically until you say **"exit team mode"**.

### Requirements

- Claude Code CLI (`claude`) installed and authenticated.
- `python3` and `perl` on PATH (both ship with macOS; standard on Linux).
- Grok Build CLI + claude-grok-bridge (steps 1–2), on a generous Grok plan. Without
  Grok, the skill falls back to Claude tiers for audit/test/execute and tells you —
  at which point the lighter `claude-team-skill` is the better fit.

## How a run works

1. **PLAN** — the orchestrator decomposes the task, writes a `SPEC.md` per subtask
   and a master `PLAN.md`, and may spawn Grok worker bees to research unknowns.
2. **UI GATE** (if any UI) — the Grok master renders mockups + an app icon with
   Grok Imagine; you approve the look before features are built.
3. **AUDIT** — the persistent Grok master audits `PLAN.md` (spawning up to 5 slaves
   for research/review), returning verdict, risks, gaps, per-subtask executor
   picks, and parallel-split calls. Relayed to you live. Capped at 2 audit cycles.
4. **EXECUTE** — the Claude execution master dispatches the build to up to 10 Grok
   executors in isolated worktrees; Claude tiers only for hard/risky subtasks.
5. **AUDIT + TEST** — the same Grok master reviews the diff against the plan and
   **runs the program's API headlessly** to confirm each feature, screenshotting
   visual ones against the mockup.
6. **VERIFY LOOP** — findings go back to the same executor; re-test on the same
   master channel; up to 3 full cycles, then it asks you.
7. **INTEGRATE** — the orchestrator reviews the final diff, merges, runs the real
   build/tests, integrates the icon, commits per your rules, and reports what each
   member did and caught. Then `team-cleanup` reaps Grok daemons.

## The roster (`~/agent-team/team.json`)

| Role | Default | Notes |
|---|---|---|
| `orchestrator` / `planner` | fable (the current session) | plans, dispatches, integrates; owns git/sign/deploy |
| `plan_master` · `execution_auditor` · `tester` · `ui_visualizer` · `researcher` | grok-master | one persistent `master-<task>` channel; spawns ≤5 slaves |
| `execution_master` | sonnet (Claude) | decomposes the build, dispatches + reviews the executor pool |
| `executor_pool` | grok-executor ×≤10 | fast bulk build in isolated worktrees |
| `executor_direct.hard/risky/trivial` | opus / sonnet / haiku | direct Claude executors for what the master flags |

Caps live in `caps` (`slave_auditors: 5`, `grok_executors: 10`, `verify_loops: 3`).

Editing the layout:

- **Add a model** — add a `members[]` block: `name`, `provider`, `model`,
  `invoke.method` (`agent-tool` | `claude-ask` | `grok-ask` | `current-session`),
  `strengths`, `budget`, `enabled: true`.
- **Remove/bench a model** — set `enabled: false`. Fallbacks live in `policies`.
- **Change caps / rewire roles** — edit `caps` or repoint `assignment`.
- **Swap the second model** — Grok is the default, not a hard requirement. Wrap any
  CLI to expose the same interface (`-c` channel, `-w` worker, `-d` cwd, `-f`
  attach, text on stdout), drop it in `~/agent-team/bin/`, and point the roles at
  it. (Note: the UI-Imagine and native-subagent features are Grok-specific.)

Design invariants the skill enforces regardless of layout: every plan is audited
before execution (master advises, orchestrator decides); the auditor/tester is
never the member that wrote the code and is read-only on it; workers only in
scratch/worktrees; only the orchestrator commits/signs/deploys; UIs are dark-mode,
emoji-free, and go through the Grok Imagine approval gate.

## Auto-continue team mode

`bin/team-mode-hook.py` is a `UserPromptSubmit` hook the installer registers in
`~/.claude/settings.json`. While `~/agent-team/state/active` exists, every prompt
is routed through the skill so a project keeps running as a team without retyping
`/team`. It recognizes plain-language toggles: say **"exit team mode"** to stop (the
hook clears the flag itself), or "enter team mode" to force it on.

To remove it: delete the `UserPromptSubmit` entry from `~/.claude/settings.json`
(the installer left a `.bak`), or run `./install.sh --no-hook` on a fresh machine.

## Memory hygiene

Slaves and executors close when their task finishes (Grok bridge calls are
one-shot; native subagents die with their parent). Only the master channel
persists, for context caching. At integrate, `~/agent-team/bin/team-cleanup` reaps
stray Grok "leader" daemons and clears finished channel state; `--exit` also leaves
team mode. It is run at the end of a task, never mid-task (that would drop the
master's warm cache).

## Token economics

- Grok 4.5 (master, slaves, executor pool, research, testing, Imagine) rides your
  Grok plan — **free from the Claude budget's perspective**. This edition pushes as
  much as possible onto Grok on purpose.
- Your Claude plan is spent mostly on planning (Fable), dispatch (the execution
  master), and integration; opus/sonnet/haiku are reserved for hard/risky subtasks.
- Headless `claude -p` calls (via the bundled `claude-ask`) are metered like any
  session; per-call cost is logged to `~/agent-team/logs/<channel>.jsonl`.

## Layout

```
skill/SKILL.md              the /team protocol       -> ~/.claude/skills/team/
skill/references/prompts.md per-actor prompt templates -> ~/.claude/skills/team/references/
team.json                   roster template          -> ~/agent-team/
bin/claude-ask              headless Claude bridge    -> ~/agent-team/bin/
bin/team-mode-hook.py       auto-continue hook        -> ~/agent-team/bin/  (registered in settings.json)
bin/team-cleanup            end-of-task memory hygiene-> ~/agent-team/bin/
install.sh                  installer
CHANGELOG.md                release history
```

## License

MIT — see [LICENSE](LICENSE).
