# Changelog

## [Unreleased]

### Changed
- New binding standing rule: **no autonomous destructive enforcement.** Members
  must never arm automated guards/watchdogs that kill processes or revert state;
  guards observe and alert only, with destructive responses requiring the
  orchestrator's fresh explicit go-ahead. Born from a real incident: a
  supervisor's stale-context build guard killed three legitimate integration
  builds whose authorization it hadn't seen.

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-07-17

Initial release of the **grok-heavy** edition of the `/team` skill — a sibling to
[claude-team-skill](https://github.com/BlinkingSun/claude-team-skill) for users on
a generous Grok plan (SuperGrok Heavy / X Premium+).

### Added
- **Persistent Grok master.** One Grok 4.5 session (channel `master-<task>`) stays
  open for the whole task and serves as plan auditor, execution auditor, tester,
  and UI visualizer. It decides how to deploy up to **5 native slave subagents**
  (each researches one unknown or reviews one slice), consolidates, and reports up.
- **Claude execution master + 10-wide Grok executor pool.** A Claude model
  decomposes the build and dispatches it to up to **10 Grok executors** in isolated
  worktrees; build work defaults to Grok, with Claude tiers (opus/sonnet/haiku)
  reserved for hard/risky subtasks.
- **Test-what-you-build.** Programs are expected to expose an API; the Grok master
  runs the built program headlessly and drives its API to confirm each feature,
  screenshotting visual features against the approved mockup.
- **Grok Imagine UI gate.** For any UI, the master renders concept mockups and a
  candidate app icon with Grok's in-session `image_gen` tool for graphical sign-off
  before feature code is written (requires Grok Build CLI ≥ 0.2.102).
- **Bounded verify loop.** Execute → audit → test → rework repeats up to 3 cycles,
  then stops and asks the user.
- **Auto-continue team mode.** `bin/team-mode-hook.py`, a `UserPromptSubmit` hook
  registered by the installer, routes follow-up prompts through the skill while a
  task is active; plain-language toggles ("exit team mode" / "enter team mode").
- **Memory hygiene.** `bin/team-cleanup` reaps stray Grok leader daemons and clears
  finished channel state at integrate.
- **Design charter + rules** in the roster: dark-mode UIs, no emojis, Grok Imagine
  approval gate, custom app icon per app, multi-threading, Apple Silicon first.
- **Live team reports** — the orchestrator narrates audit/test/verify verdicts and
  contradictions as they happen, not just in the final summary.
- Roster caps (`slave_auditors`, `grok_executors`, `verify_loops`) and the
  `execution_master` / `executor_pool` / `executor_direct` role split.
- Installer with idempotent hook registration (backs up `settings.json`,
  `--no-hook` opt-out, never overwrites an existing roster) and a dependency check.

### Requires
- Claude Code CLI; `python3` + `perl`.
- Grok Build CLI (SuperGrok Heavy / X Premium+) ≥ 0.2.102 and
  [claude-grok-bridge](https://github.com/BlinkingSun/claude-grok-bridge). Without
  Grok, the skill falls back to Claude tiers — use the lighter `claude-team-skill`.
