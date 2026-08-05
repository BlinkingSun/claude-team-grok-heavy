# /team — prompt templates

Ready-to-paste prompts for each actor. Substitute `<task>`, `<dir>`, `<worktree>`,
`<n>`. All Grok calls: `GA=~/grok-bridge/bin/grok-ask` (grok-4.5, subscription).
Give worker-mode Bash calls a large timeout (300000–600000 ms) or run in background.

Context thrift (from /grok): seed a channel once, then send tiny deltas. The master
already has full history on `--resume`; never re-paste SPEC/PLAN/prior replies.

---

## Grok worker bee — planning-phase research (Fable spawns)

```bash
$GA -c spike-<task>-<topic> -d <dir> \
  "Research <unknown>. Return: ANSWER (3-5 bullets), CONFIDENCE (high/med/low), SOURCES (urls). No preamble."
```

Worker mode (`-w`) only if it must run a spike; otherwise consult (read/web only).

---

## UI visualize — Grok Imagine mockup + icon (master, worker)

```bash
$GA -w -c master-<task> -d <dir> \
  "Use your image_gen tool. Produce TWO images, dark mode, NO emojis, no lorem text:
   (1) a concept mockup of <app> — layout: <sidebar/panes/controls>; aesthetic: <modern/minimal/…>; save as design/mockup-1.png (16:9).
   (2) a candidate app ICON that fits the program's purpose (<what it does>), suitable for a macOS icon, save as design/icon-1.png (1:1).
   Reply with ONLY the two absolute file paths and their pixel dimensions."
```

Then `SendUserFile` both images and ask the user to approve or redline. Iterate:

```bash
$GA -w -c master-<task> -d <dir> \
  "Revise design/mockup-1.png: <one change>. Save as design/mockup-2.png. Reply path + dims only."
```

Record the approved look as `DESIGN.md`, then build to it.

---

## Plan audit — master opens + optionally spawns ≤5 slaves (worker)

```bash
$GA -w -c master-<task> -d <dir> -f PLAN.md \
  "You are the MASTER auditor for this task and stay open until I say we are done.
   Audit the attached PLAN before we execute. You MAY spawn up to 5 subagents (slaves):
   each either RESEARCHES one open unknown OR REVIEWS one slice of the plan. Wait for
   them, consolidate, and reply with:
     VERDICT: approve | revise
     RISKS: <bullets, incl. edge cases>
     GAPS: <missing subtasks / untested acceptance criteria>
     EXECUTOR: for each subtask -> grok | opus | sonnet | haiku, with a one-line reason
       (default to grok unless it is genuinely hard/subtle/high-risk)
     SPLIT: independent pieces two+ executors can run in parallel, with the boundary/
       interface between them; or 'serial: <why>'
     SLAVES_USED: <n> and what each did"
```

Re-audit on the **same channel** after edits (cap 2 cycles):

```bash
$GA -w -c master-<task> -d <dir> \
  "I revised the plan: <one-line delta per accepted finding>. Findings I rejected: <x, why>.
   Confirm each accepted item is addressed. Same reply format."
```

---

## Execution master — Anthropic model dispatches Grok executors

Agent-tool prompt (model = `assignment.execution_master`):

> You are the EXECUTION MASTER. Read `PLAN.md` and each `SPEC.md` in `<dir>`. For
> each build subtask, spawn a Grok executor with:
> `~/grok-bridge/bin/grok-ask -w -c exec-<task>-<n> -d <worktree-n> "<seed>"` — up to
> **10** in parallel across isolated worktrees. Default every subtask to Grok; only
> use a direct Claude executor if the plan master flagged it or Grok fails it twice.
> Collect each executor's `DONE/OPEN/TEST/BLOCKERS`, review the diffs **without
> bias**, and reply with: per-subtask status, the worktree paths, any subtask you
> re-routed and why, and BLOCKERS needing the orchestrator. Do not commit, push, or
> deploy.
> NEVER arm automated guards/watchdogs that kill processes or revert state — if you
> believe something unsafe is happening, ALERT the orchestrator and wait; your
> picture of what is authorized may be behind. Executors close (their process exits) once their subtask passes.

---

## Grok executor — seed (worker, isolated worktree)

```bash
$GA -w -c exec-<task>-<n> -d <worktree> \
  "Read SPEC.md. Implement it to satisfy every acceptance criterion. Multi-thread any
   real compute. If UI: dark mode, no emojis, match DESIGN.md. Run the tests described
   in SPEC.md (exercise the program's API). Update PROGRESS.md. Reply with ONLY:
     DONE: <bullets>  OPEN: <bullets>  TEST: pass|fail + one line  BLOCKERS: <if any>"
```

Delta (same channel, no re-paste):

```bash
$GA -w -c exec-<task>-<n> -d <worktree> \
  "TEST failed: <one error or path:line>. Fix only that, re-run the relevant test. Same reply format."
```

---

## Execution audit + test — same master (worker)

```bash
$GA -w -c master-<task> -d <dir> \
  "Execution is in. Two jobs, and you may spawn up to 5 slaves for final validation:
   1) EXECUTION AUDIT — compare the implementation in <worktrees/dir> against PLAN.md and
      each SPEC.md. Check every acceptance criterion and plan-adherence. You are READ-ONLY
      on the code: run it, do not edit it.
   2) TEST — the program exposes an API. Launch it headlessly and drive its API
      (curl/CLI/socket) to confirm each feature works as intended. For visual features,
      capture a screenshot (headless browser for web UIs; screencapture/image tools for
      native) and compare to design/mockup-*.png.
   Reply with:
     VERDICT: pass | fail
     DEVIATIONS: <from plan/spec>
     BUGS: <with repro>
     GAPS: <untested or unmet criteria>
     TEST: <criterion -> pass/fail>, one line each
     SLAVES_USED: <n> and what each did"
```

Re-test after rework (same channel):

```bash
$GA -w -c master-<task> -d <dir> \
  "Rework landed for: <finding ids>. Re-test only those + regressions. Same reply format."
```

---

## Notes

- **One master channel per task** (`master-<task>`), reused across steps 2, 4, 5 —
  that is what gives context caching. Executors get their own `exec-<task>-<n>`
  channels; slaves are native subagents inside the master call (no channel).
- **Close** = for `grok-ask`, just stop resuming the channel; the process already
  exited. At integrate, `team-cleanup --task <task>` reaps grok leaders and clears
  finished channel state. Never reap mid-task (master loses warm cache).
- If native subagents are ever unavailable in a run, the master simply does the
  audit itself and you fall back to explicit `slave-<task>-<n>` consult channels —
  same reports, more plumbing.
