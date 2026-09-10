# castkit

Record a terminal session, play it back with real controls, and hand it to
someone — without any of it touching a third-party service.

Built around [asciinema](https://asciinema.org), which records the terminal as
text rather than pixels: a session is a small, greppable JSON file whose text
stays selectable on playback.

## Sessions record themselves

Setup wraps `claude` and `codex` in your shell so both run under `cast rec`.
Every session started from a fresh shell is captured from its first prompt —
there is no command to remember and nothing to decide. Run one unrecorded with
`command claude`.

```bash
cast list                       # browse recordings (table when piped)
cast purge                      # delete recordings older than two months
cast play <id|alias>            # play in the web player
cast share <id|alias> [alias]   # stage a folder in ~/Downloads for sending
cast rec [-t "title"]           # what the wrappers call; rarely typed by hand
```

They are subcommands rather than separate binaries because bare `play` and
`list` would collide with things already on PATH.

## Setup runs once, on the first command

The first `cast` anything — or the first use of the `/cast` skill — installs
asciinema and `agg`, vendors the player, writes the marker-key config, links
`cast` into `~/.local/bin` and the skill into `~/.claude/skills`, and wraps
your agents in your shell. Then it writes `~/.castkit/installed` and never
does any of it again: later runs cost one small file read.

**The lock is written last.** If any step fails there is no lock, so the next
command retries the whole thing rather than leaving you half-installed. It
also records where the kit lives, so moving or re-cloning the repo re-runs
setup and repairs the symlinks instead of silently leaving them dangling. To
force a re-run, delete the file.

**`SETUP_VERSION` is the only thing that invalidates a lock, and it is
manual.** A moved kit is caught automatically, because the lock records where
the kit lives. Nothing else is: if you change *what setup does* — add a tool to
install, rename a config key, change where a symlink points — every existing
install keeps taking the fast path and never picks the change up. Bump
`SETUP_VERSION` in the same commit that changes a setup step, or the change
only reaches machines that have never run castkit.

**Installing is platform-specific.** Homebrew where it exists, otherwise
`cargo` — slower, since it compiles, but the route that reliably gets
asciinema 3.x, where distro packages are often a major version behind. Native
Windows has no build; use WSL.

**Wrapping follows your login shell**, read from `$SHELL`: `~/.zshrc` for zsh,
fish's own `function ... end` syntax in `~/.config/fish/config.fish`, and for
bash `~/.bash_profile` on macOS — where a login shell never reads `~/.bashrc`,
so a wrapper written there would never load. An unrecognised shell is reported
with the snippet to add by hand, and does not block the rest of setup.

## `cast rec`

Wraps a command and records it, printing how to stop before it starts:
`ctrl+d` ends, `ctrl+\` pauses capture (before you type a password),
`ctrl+t` drops a marker.

Recordings land in `~/.castkit/sessions` as `<date>-<time>-<agent>.cast`,
so the id says
whether claude or codex produced it. Idle gaps are capped at two seconds,
which matters more than it sounds: an agent session is mostly waiting on a
model, so uncapped the file is mostly dead air. `CAST_DIR` moves where they
land.

**Recording has to wrap the agent from outside** — nothing running inside a
session can record that session, because by then the TUI is live and nothing
wraps it in a PTY. That is precisely why the wrappers exist: they do it before
the agent starts, so it is never something anyone has to invoke.

Three things keep the wrapping safe.

**Only interactive sessions are recorded.** Recording wraps a process in a PTY
and captures its stdout rather than passing it through, so a recorded
`claude -p "..." | jq` hands jq asciinema's diagnostics where the answer
should be, and swallows stdin on the way. So `cast rec` hands off untouched
unless stdin and stdout are both TTYs and the invocation looks like a session:
not `-p`/`--print`, not `codex exec`, not `--version`, not a management
subcommand. An unrecognised word is treated as a prompt or a flag's value and
does record — erring that way costs a stray recording, erring the other way
corrupts someone's output.

**It cannot recurse.** `cast rec` resolves the agent to its absolute path via
PATH, which never sees a shell function.

**It refuses to nest.** Inside a session that is already recorded, it runs the
agent directly rather than starting a second capture.

## `cast play`

Takes a recording id, an alias, a printed datetime, or a path — a selector is
required, since playing "whatever was most recent" is rarely what is meant. A
leading fragment works when it is unambiguous, and an ambiguous one says so.

Serves the vendored player on a free loopback port. What you get over
`asciinema play`, which has none of it:

- **speed** — `0.5×` `1×` `1.5×` `2×` `4×`, switchable mid-playback
- **dead air** — cap idle gaps at 2s, toggled while watching
- a progress bar you can click, `←`/`→` to seek, `0`–`9` to jump by percent,
  `.` to step a frame while paused, `f` for fullscreen

## `cast list`

At a terminal it opens a browser built on stdlib `curses`, so it costs no
dependency:

```
castkit — 5 recordings · 885.5 KB · claude 590.8 KB, codex 294.7 KB
Datetime          Agent   Alias                Length  Shared
2026-09-10 19:13  claude  —                    3:58    —
2026-09-10 19:05  codex   castkit-walkthrough  2:01    2026-09-10 19:15
↑↓ move · enter play · s share · d delete · q quit
```

`enter` plays the highlighted recording, `s` prompts for an alias and shares
it, `d` deletes it after confirming. The list scrolls, so a short terminal
still reaches everything.

**Piped or run without a terminal it prints the table instead**, followed by
the storage line. That fallback is not a flag — the `/cast` skill runs this
from an agent, which has no terminal, and a TUI-only `list` would break that
path entirely. `--plain` forces the table at a terminal too.

The storage line totals the recordings and breaks them down by agent, and once
the total passes 500 MB it points at `cast purge`.

## `cast purge`

Deletes recordings older than two months.

```bash
cast purge                 # older than 60 days
cast purge --days 14
cast purge --dry-run       # list them, delete nothing
cast purge -y              # skip the confirmation
```

It prints what it is about to remove — with sizes, and marking anything that
was shared — then asks before deleting. That prompt is the one place the kit
deliberately does not decide for you: everything else it can redo, and this it
cannot. Index entries for deleted recordings go with them.

## `cast share`

Attaches an alias to the recording and writes `~/Downloads/<alias>/`:

- `<alias>.cast` — **the artifact.** Attach this. It is the native format,
  it is tiny, and anyone with asciinema can play it.
- `<alias>.gif` — a preview, for pasting where an animation renders inline:
  a PR description, an issue, a Slack message.

Pass the alias as ordinary text — `cast share 20260910-1814 "Fixing the
parser"` writes `~/Downloads/fixing-the-parser/`. Accents fold to ASCII,
punctuation and emoji become separators, the result is capped at 40
characters, and something that normalises to nothing falls back to the
recording id. Given no alias at all it reuses the one already attached, or
derives one from the recording's title.

An alias is also a selector, so it has to be unique: sharing under a name
another recording already holds is refused, and names the recording holding
it. Re-sharing the same recording under its own alias just re-stages it.

## Why there is no asciinema-server here

Two different things share the name. **asciinema-player** is a static JS
library — that is what `vendor/` holds, and it is all playback needs.
**asciinema-server** is the sharing app: accounts, uploads, permalinks. Stand
one up if you want those; nothing here requires it.

The only thing that would send a recording off this machine is
`asciinema upload`, which defaults to asciinema.org. Set `server.url` in the
config to point it somewhere of ours instead.

## Traps worth knowing

- **v3 event times are deltas, not absolutes.** The length of a recording is
  their sum. Taking the last or largest gives the longest single gap — for a
  six-second recording, 1.04s instead of 6.17s.
- **A marker key is swallowed.** asciinema intercepts it, so the recorded
  program never sees it. The syntax is `"C-t"`; `"ctrl+t"` is rejected.
- **`cast` must resolve through its symlink.** It is linked into
  `~/.local/bin`, so `os.path.abspath(__file__)` would give the link's
  directory and the player files would not be found. Hence `realpath`.
- **The viewer layout is load-bearing.** `main` is `flex: 1` with
  `min-height: 0` and the player uses `fit: "both"`. Under `fit: "width"` an
  80×24 terminal scales to fill the page, the player grows taller than the
  viewport, and its control bar ends up below the fold — in the DOM, invisible.
- **The player has no speed setter.** Its API is play/pause/seek/dispose. Each
  speed change rebuilds the player at the current position.
- **`--bind 127.0.0.1` is deliberate.** Python's http.server defaults to
  `0.0.0.0`, which would serve recordings to the whole network.
- **Editing a setup step means bumping `SETUP_VERSION`.** The lock is only
  invalidated by that constant or by the kit moving, so a setup change without
  a bump is invisible to everyone already installed — and invisible to you
  too, since your own machine takes the fast path as well. Symptom: it works
  on a fresh install and nowhere else.
- **Flush before blocking.** `cast play` prints its URL then blocks on the
  server; without an explicit flush, a caller that backgrounds it sees nothing.

## Recordings contain everything

A `.cast`, and the `.gif` rendered from it, hold every character that was on
screen: keys, tokens printed in an error, the lot. Treat one like a document
containing our source code, because it is one. Read it before sending it.
