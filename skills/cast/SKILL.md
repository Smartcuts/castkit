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

Asking about **content** is different, and expected: an alias or a title is
something only the user knows. Ask for those. Never ask about dependencies,
paths, ports or formats.

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

## Listing

`cast list` prints the recent recordings as
`Datetime | Alias | Length | Shared`. Run it whenever the user refers to a
recording vaguely — "the one from this morning", "the parser one" — and show
them the table rather than guessing which they mean.

## Playing

`cast play` needs a selector: a recording id, an alias, or a path. Get one
from `cast list`. A leading fragment of an id resolves when it is unambiguous,
and says so when it is not.

It serves a local page and blocks until ctrl+c, so run it in the background or
hand the command to the user rather than hanging the turn.

## Sharing

`cast share <selector> <alias>` attaches the alias and writes
`~/Downloads/<alias>/` holding `<alias>.cast` and `<alias>.gif`. The `.cast` is
the artifact to attach; the `.gif` is the preview to paste where an animation
renders inline. Give the user the folder path when it finishes.

**Ask for the alias if the user has not given one.** It is a name a person
will read in Slack, so it is theirs to choose, not yours to invent. One short
question, and offer the recording's title as the obvious default.

**Pass what they say, verbatim.** Do not slugify it yourself — the command
normalises it, and doing it twice in two places is how the two drift apart:

    cast share 20260910-1814 "Fixing the parser"
    -> ~/Downloads/fixing-the-parser/

Accents are folded to ASCII, punctuation and emoji become separators, the
result is capped, and an alias that normalises to nothing falls back to the
recording id. So a title typed naturally is always safe to hand over.

Say once, plainly, that both files hold everything that was on screen in
cleartext, so they should be read before being sent.

## Recordings live in `~/casts`

Named `<date>-<time>-<slug>.cast`, with aliases and share dates in
`~/casts/index.json`. `CAST_DIR` moves the lot.
