---
name: cast
description: |
  Record, watch and share a terminal session as an asciinema cast, using the
  local cast-kit — no third-party service. Use when asked to record a session,
  set up session recording, watch or replay a recording, or share an agent
  session with someone. Also covers installing asciinema and the player, which
  it does automatically without asking.
allowed-tools:
  - Bash
  - Read
---

# cast

Three commands, all of which take no arguments in the normal case. Run them;
do not ask the user to choose anything.

```bash
cast-rec      # record the agent — the user runs this, not you (see below)
cast-view     # watch the most recent recording
cast-share    # bundle the most recent recording into one shareable .html
```

## Setup is automatic — never ask

Every command runs `install --ensure` itself, which installs asciinema,
vendors the player, writes the marker-key config and links the commands onto
PATH. It is silent when there is nothing to do. So: just run the command. Do
not check dependencies first, do not offer to install anything, and do not ask
which options the user wants.

If a command is not on PATH, the kit has not been installed yet. Locate it and
run the installer once:

```bash
kit=$(cd "$(dirname "$(readlink -f ~/.claude/skills/cast)")/.." && pwd)
"$kit/install"
```

## Recording cannot be started from in here

A session recording has to wrap the agent from outside. By the time you are
running, the TUI is already live and nothing wraps it in a PTY — shelling out
to `asciinema rec` would record a child process, not this conversation.

So when asked to record a session, do not try. Tell the user to start their
next session with `cast-rec` instead of `claude`, and offer the title form:

```bash
cast-rec -t "what this session is about"
```

To check whether the *current* session is being recorded, look for the
variable asciinema sets inside a recorded session:

```bash
echo "${ASCIINEMA_SESSION:-not recorded}"
```

If it is set, the session is being captured and `cast-share` will be able to
bundle it once the session ends. If it is not, say so plainly rather than
implying the conversation is being saved.

## Sharing

`cast-share` with no arguments bundles the most recent recording into a single
self-contained `.html` — player, stylesheet and recording inlined, no server
and no network needed. Run it, then give the user the path it prints. Use
SendUserFile to hand over the file when that tool is available.

Say once, plainly, that the bundle contains everything that was on screen in
cleartext, so it should be read before being sent anywhere.

## Watching

`cast-view` serves the most recent recording on loopback and opens a browser.
It blocks until stopped with ctrl+c, so run it in the background or tell the
user to run it themselves rather than hanging the turn.

## Recordings live in `~/casts`

Named `<date>-<slug>.cast`. `CAST_DIR` moves that. To act on a specific
recording rather than the newest, pass its path:
`cast-view <file>`, `cast-share <file>`.
