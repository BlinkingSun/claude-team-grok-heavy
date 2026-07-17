#!/bin/bash
# Grok-Heavy Team — installer for the /team (grok-heavy) Claude Code skill.
#
#   - copies the /team skill (+ references) to ~/.claude/skills/team/
#   - seeds ~/agent-team/ (roster + bridges + state dirs)
#   - registers the UserPromptSubmit auto-continue hook in ~/.claude/settings.json
#   - never overwrites an existing team.json (your roster is yours)
#
# Flags:
#   --no-hook    skip registering the auto-continue hook (you can add it later)
#
# This is the GROK-HEAVY edition: it uses Grok a lot (persistent master + up to 5
# slaves, up to 10 executors, all research/imagine). It expects a generous Grok
# plan (SuperGrok Heavy / X Premium+). On a light Grok plan, use the lighter
# github.com/BlinkingSun/claude-team-skill instead.

set -euo pipefail
cd "$(dirname "$0")"

WANT_HOOK=1
for a in "$@"; do
  case "$a" in
    --no-hook) WANT_HOOK=0 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "install: unknown flag: $a" >&2; exit 2 ;;
  esac
done

SKILL_DIR="$HOME/.claude/skills/team"
TEAM_DIR="$HOME/agent-team"
SETTINGS="$HOME/.claude/settings.json"
HOOK_CMD="$TEAM_DIR/bin/team-mode-hook.py"

mkdir -p "$SKILL_DIR/references" "$TEAM_DIR/bin" "$TEAM_DIR/channels" \
         "$TEAM_DIR/logs" "$TEAM_DIR/wt" "$TEAM_DIR/state" "$TEAM_DIR/scratch"

cp skill/SKILL.md "$SKILL_DIR/SKILL.md"
cp skill/references/prompts.md "$SKILL_DIR/references/prompts.md"
echo "installed skill   -> $SKILL_DIR/ (SKILL.md + references/prompts.md)"

for f in claude-ask team-mode-hook.py team-cleanup; do
  cp "bin/$f" "$TEAM_DIR/bin/$f"
  chmod +x "$TEAM_DIR/bin/$f"
done
echo "installed bridges -> $TEAM_DIR/bin/ (claude-ask, team-mode-hook.py, team-cleanup)"

if [[ -f "$TEAM_DIR/team.json" ]]; then
  echo "kept existing     -> $TEAM_DIR/team.json (template not applied)"
else
  cp team.json "$TEAM_DIR/team.json"
  echo "installed roster  -> $TEAM_DIR/team.json"
fi

# --- Register the auto-continue hook (idempotent, backs up settings.json) ------
if [[ $WANT_HOOK -eq 1 ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "WARN: python3 not found — skipping hook registration. Add it manually (see README)."
  else
    SETTINGS="$SETTINGS" HOOK_CMD="$HOOK_CMD" python3 - <<'PY'
import json, os, pathlib, shutil
settings = pathlib.Path(os.environ["SETTINGS"])
cmd = os.environ["HOOK_CMD"]
settings.parent.mkdir(parents=True, exist_ok=True)

data = {}
if settings.exists():
    try:
        data = json.loads(settings.read_text() or "{}")
    except Exception:
        print(f"WARN: {settings} is not valid JSON — not touching it. Add the hook manually.")
        raise SystemExit(0)
    shutil.copyfile(settings, str(settings) + ".bak")

hooks = data.setdefault("hooks", {})
ups = hooks.setdefault("UserPromptSubmit", [])
already = any(
    h.get("command") == cmd
    for group in ups if isinstance(group, dict)
    for h in group.get("hooks", []) if isinstance(h, dict)
)
if already:
    print(f"hook present      -> UserPromptSubmit already runs {cmd}")
else:
    ups.append({"hooks": [{"type": "command", "command": cmd}]})
    settings.write_text(json.dumps(data, indent=2) + "\n")
    print(f"registered hook   -> UserPromptSubmit -> {cmd}")
    print(f"                     (backup at {settings}.bak)")
PY
  fi
else
  echo "skipped hook      -> run with the hook later, or add it to $SETTINGS (see README)"
fi

# --- Dependency check ----------------------------------------------------------
echo
if [[ -x "$HOME/grok-bridge/bin/grok-ask" ]] || command -v grok-ask >/dev/null 2>&1; then
  echo "found grok-ask    -> Grok master/executors ready"
  if [[ -x "$HOME/.grok/bin/grok" ]]; then
    ver="$("$HOME/.grok/bin/grok" --version 2>/dev/null | awk '{print $2}')"
    echo "grok CLI version  -> ${ver:-unknown} (need >= 0.2.102 for Grok Imagine)"
  fi
else
  echo "NOTE: grok-ask not found. This GROK-HEAVY edition needs it for almost everything:"
  echo "  1. Grok Build CLI (SuperGrok Heavy / X Premium+):"
  echo "       curl -fsSL https://x.ai/cli/install.sh | bash && grok login"
  echo "  2. Bridge: https://github.com/BlinkingSun/claude-grok-bridge  (./install.sh)"
  echo "Without Grok, /team falls back to Claude tiers — at which point the lighter"
  echo "claude-team-skill is the better fit."
fi

echo
echo "Done. In any Claude Code session, try:  /team <your task>"
echo "Follow-ups auto-continue in team mode until you say 'exit team mode'."
echo "Edit $TEAM_DIR/team.json to add models, change caps, or rewire roles."
