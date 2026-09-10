---
name: cast
description: |
  Record, play, list and share terminal sessions as asciinema casts, using the
  local castkit — nothing is uploaded to a third-party service. Use when asked
  to record a session, replay or watch a recording, list recordings, or share
  an agent session with someone. Dependencies install themselves; never ask the
  user about setup.
allowed-tools:
  - Bash
  - Read
---

# cast

```bash
cast rec [-t "title"]          record a session (the shell wrappers call this)
cast play <id|alias>           play in the web player — a selector is required
cast list                      recordings; a table when you run it
cast purge                     delete recordings older than two months
cast enroll [name]             record another CLI's sessions too
cast disenroll <name>          stop recording one
cast share <id|alias> [alias]  attach an alias, stage a folder in ~/Downloads
```

## Setup is automatic — never ask about it

There is no install step, because **installing is what the first command
does**. Every subcommand calls setup before it runs; on the first one that
means installing asciinema and agg, vendoring the player, writing the
marker-key config, linking `cast` into `~/.local/bin` and this skill into
`~/.claude/skills`, and wrapping the enrolled commands in the user's shell.
It then writes `~/.castkit/installed` and never repeats any of it — later runs
read that one file and get on with it.

So just run the command you actually wanted. Do not check dependencies, do not
offer to install anything, do not ask which options the user wants.

**The first run on a fresh machine can take a minute or two** — asciinema and
agg are compiled tools, and without Homebrew `cargo` builds them from source.
That is setup working, not a hang: let it finish rather than interrupting or
retrying. It prints a line per step. Afterwards, tell the user a new shell is
needed for the wrappers to take effect.

If setup fails part-way it writes no lock, so simply running the command again
retries the whole thing. Nothing needs to be cleaned up first.

Asking about **content** is different, and expected: an alias or a title is
something only the user knows. Ask for those. Never ask about dependencies,
paths, ports or formats.

If `cast` is not yet on PATH, run it once by path — that run creates the link.
This skill is installed under `~/.claude/skills` for Claude Code and
`~/.agents/skills` for Codex, so resolve through whichever exists:

```bash
d=$(readlink -f ~/.claude/skills/cast 2>/dev/null || readlink -f ~/.agents/skills/cast)
"$(dirname "$d")/../cast" list
```

## Recording already happened — you do not start it

Sessions record themselves. Setup installs shell wrappers so `claude` and
`codex` run under `cast rec`, which means every session started from a fresh
shell is captured from its first prompt. Nobody has to remember a command.

You still cannot start a recording of the session you are inside — by then the
TUI is live and nothing wraps it in a PTY. But that is no longer something to
work around, because the wrapper did it already.

When asked to record, check whether this session is captured:

```bash
echo "${ASCIINEMA_SESSION:-not recorded}"
```

**Set** — it is being recorded. Say so, and that `cast list` will show it once
it ends.

**Unset** — it is not. Say so plainly rather than letting the user assume it
is being saved, and do not offer to record the current session; nothing can.
The usual reasons: this shell predates the wrappers, the agent was launched
with `command claude`, or **this is not an interactive session**.

Non-interactive runs are deliberately never recorded — `claude -p`,
`codex exec`, anything piped or redirected, and the management subcommands.
Recording wraps a process in a PTY, which captures its stdout instead of
passing it through, so recording `claude -p "..." | jq` would hand jq
asciinema's diagnostics where the answer should be. If a user asks why one of
those was not recorded, that is why — it is protection, not a gap.

## Listing

`cast list` opens a browser at a terminal and prints a plain table
`Datetime | Agent | Alias | Length | Shared` everywhere else — which is what
you will get, since you have no terminal. It ends with a storage summary. Run
it
whenever the user refers to a recording vaguely — "the one from this morning",
"the codex one" — and show them the table rather than guessing which they mean.

The Datetime it prints can be pasted straight back as a selector:
`cast play "2026-09-10 18:45"` resolves.

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

## Enrolling other CLIs

`cast enroll` with no argument lists what is recorded; `cast enroll <name>`
adds one and `cast disenroll <name>` removes it. Use these when the user wants
a different agent recorded — they need no confirmation, since both are
reversible and neither touches existing recordings.

Tell the user a new shell is needed afterwards. Enrolling something not yet
installed is fine and expected.

## Purging

`cast purge` deletes recordings older than 60 days, `--days N` for another
window. **Only run it when the user asks.** Show `cast purge --dry-run` first
so they see what would go, and let them confirm — do not pass `-y` on their
behalf. Deleting recordings is the one irreversible thing here.

If the storage line in `cast list` is warning about size, mention it; do not
act on it.

## Recordings live in `~/.castkit/sessions`

Named `<date>-<time>-<agent>.cast` — the agent is `claude` or `codex`, so the
id says which produced it. Aliases and share dates live in
`~/.castkit/sessions/index.json`. `CAST_DIR` moves the lot.
