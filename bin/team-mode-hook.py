#!/usr/bin/env python3
"""UserPromptSubmit hook — /team auto-continue mode.

While ~/agent-team/state/active exists, inject a reminder that routes every
prompt through the /team skill so a project keeps running in team mode without
re-typing /team. Recognizes on/off phrases to toggle the flag itself, so the
user can leave at any time with a plain-language phrase.

Contract: Claude Code passes the UserPromptSubmit event as JSON on stdin
(field: "prompt"). We emit JSON additionalContext on stdout and exit 0.
"""
import json
import pathlib
import sys

STATE = pathlib.Path.home() / "agent-team" / "state"
FLAG = STATE / "active"

OFF_PHRASES = (
    "exit team mode", "leave team mode", "team mode off", "stop team mode",
    "end team mode", "solo mode", "disband the team", "disband team",
)
ON_PHRASES = (
    "enter team mode", "team mode on", "start team mode", "resume team mode",
)


def emit(ctx: str) -> None:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": ctx,
        }
    }))


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}
    prompt = (data.get("prompt") or "")
    lc = prompt.lower()

    STATE.mkdir(parents=True, exist_ok=True)

    # OFF wins if both appear — safety: user asking to leave always leaves.
    if any(p in lc for p in OFF_PHRASES):
        try:
            FLAG.unlink()
        except FileNotFoundError:
            pass
        emit("TEAM MODE DEACTIVATED — the team-mode flag was cleared. "
             "Handle prompts normally now; do not route through /team unless "
             "the user asks again.")
        return 0

    if any(p in lc for p in ON_PHRASES):
        FLAG.write_text("activated: manual\n")

    if FLAG.exists():
        emit(
            "TEAM MODE IS ACTIVE. Continue the current project using the /team "
            "skill (~/.claude/skills/team/SKILL.md), reading ~/agent-team/team.json "
            "fresh: PLAN (fable) -> PLAN AUDIT (grok-master + up to 5 slave "
            "auditors/researchers) -> UI gate if any UI (Grok Imagine mockup + "
            "icon, user sign-off) -> EXECUTE (execution-master spawns up to 10 "
            "grok executors; Claude tiers only for hard/risky subtasks) -> "
            "EXECUTION AUDIT + TEST (same grok-master, drives the program's API) "
            "-> VERIFY LOOP (max 3 cycles, then ask the user) -> INTEGRATE "
            "(fable, then team-cleanup). Treat THIS prompt as the next team "
            "instruction or answer, not a one-off. The user exits with "
            "'exit team mode'."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
