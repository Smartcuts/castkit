---
name: cast
description: |
  Record, play, list and share terminal sessions as asciinema casts, using the
  local cast-kit — nothing is uploaded to a third-party service. Use when asked
  to record a session, replay or watch a recording, list recordings, or share
  an agent session with someone. Dependencies install themselves; never ask the
  user about setup.
allowed-tools:
  - Bash
  - Read
---

# cast

```bash
cast rec [-t "title"]          start recording (records `claude` by default)
cast play <id|alias>           play in the web player — a selector is required
cast list                      recent recordings: Datetime | Alias | Length | Shared
cast share <id|alias> [alias]  attach an alias, stage a folder in ~/Downloads
```

## Setup is automatic — never ask about it

There is no install step. Every subcommand installs what it needs first
(asciinema, agg for the gif, the vendored player, the marker-key config, the
PATH link) and is silent when everything is already there. So just run the
command. Do not check dependencies, do not offer to install anything, do not
ask which options the user wants.

If `cast` is not yet on PATH, run it once by path — that run creates the link:

```bash
"$(dirname "$(readlink -f ~/.claude/skills/cast)")/../cast" list
```

## You cannot start a recording from in here

A recording has to wrap the agent from outside. By the time you are running,
the TUI is live and nothing wraps it in a PTY — shelling out to asciinema
would capture a child process, not this conversation.

So when asked to record, do not try. Tell the user to start their next session
with `cast rec` instead of `claude`, optionally `cast rec -t "what it is about"`.

To answer whether the *current* session is being recorded:

```bash
echo "${ASCIINEMA_SESSION:-not recorded}"
```

Set means it is being captured. Unset means it is not — say so plainly rather
than letting the user assume the conversation is being saved.

## Playing

`cast play` needs a selector: a recording id, an alias, or a path. Run
`cast list` first and use an id from the Datetime column's recording, or an
alias. A leading fragment of an id is enough when it is unambiguous.

It serves a local page and blocks until ctrl+c, so run it in the background or
hand the command to the user rather than hanging the turn.

## Sharing

`cast share <id> <alias>` attaches the alias, and writes
`~/Downloads/<alias>/` holding `<alias>.cast` and `<alias>.gif`. The `.cast` is
the artifact to attach; the `.gif` is the preview to paste inline where it will
render. Give the user the folder path when it finishes.

Say once, plainly, that both files hold everything that was on screen in
cleartext, so they should be read before being sent.

## Recordings live in `~/casts`

Named `<date>-<time>-<slug>.cast`, with aliases and share dates in
`~/casts/index.json`. `CAST_DIR` moves the lot.
