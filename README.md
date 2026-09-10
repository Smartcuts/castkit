# castkit

Replay and share your vibe coding sessions. Built on top of
[asciinema](https://asciinema.org), which records the terminal as text
rather than pixels: a session is a small, greppable JSON file whose
text stays selectable on playback.

[github.com/Smartcuts/castkit](https://github.com/Smartcuts/castkit)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Smartcuts/castkit/main/install.sh | sh

# Checks installation
cast version
```

The installation script does three things:

1. Installs dependencies and necessary tools, such as `asciinema` and
   `agg`.
2. Installs the castkit binary and a utility skill to pair with it.
3. Enrolls your local coding agents in (default codex and claude
   code).

## Sessions record themselves

The third step in the installation script above, enrollment, wraps
coding agent binary with our own tooling so that every coding session
is automatically recorded from now on. Every session started from a
fresh shell is captured from its first prompt — there is no command to
remember and nothing to decide. The default enrolment is claude and
codex; `cast enroll` records any other CLI, and `command claude` runs
one unrecorded.

You can also manually enroll a coding agent:

```
cast enroll codex
```

And similarly, you can disenroll a coding agent, to not auto-record
its future sessions:

```
cast disenroll codex
```

## Using the skill

castkit ships a binary and a helper skill. The skill is often the
easier interface: you can describe a session instead of naming it
exactly.

```plain
/cast share the codex session at 5:12pm.
```

## Sharing sessions

To share a session with your team mate:

```
cast share <id|alias>
```

This creates a folder in your `~/Downloads/`, with two files:

- a `.cast` file, the original recording, and
- a `.gif` thumbnail.

The thumbnail is the last frame of the recording that actually drew
something, intended to help contextualize what's being shared.

You can send over the `.cast` file to your coworkers over Slack,
etc. And for the receiving person to view the recording, they also
need to [install `castkit`](#install), and then

```
cast play <path-to-.cast-file>
```

## Managing recordings

Recordings land in `~/.castkit/sessions` as
`<date>-<time>-<agent>.cast`, so the id says whether claude or codex
produced it. Idle gaps are capped at two seconds, which matters more
than it sounds: an agent session is mostly waiting on a model, so
uncapped the file is mostly dead air. `CAST_DIR` moves where they
land.

To list out all recordings, use the `list` subcommand:

```
> cast list

castkit — 10 recordings · 5.7 MB · claude 5.3 MB, codex 379.9 KB
Datetime          Agent   Alias                Length  Shared
2026-09-10 22:20  claude  —                    52:21   —
2026-09-10 22:21  codex   —                    0:17    —
2026-09-10 20:08  claude  claude               4:22    2026-09-10 20:11
2026-09-10 19:38  claude  —                    0:36    —
2026-09-10 19:38  codex   —                    0:15    —
2026-09-10 19:13  claude  —                    3:58    —
2026-09-10 19:06  claude  —                    2:15    —
2026-09-10 19:05  codex   castkit-walkthrough  2:01    2026-09-10 20:07
2026-09-10 18:54  codex   —                    0:00    —
2026-09-10 18:52  codex   —                    0:18    —
```

<kbd>enter</kbd> plays the highlighted recording, <kbd>s</kbd>
prompts for an alias and shares it, <kbd>d</kbd> deletes it after
confirming. The list scrolls, so a short terminal still reaches
everything.

**Piped or run without a terminal it prints the table instead**,
followed by the storage line. `--plain` forces the table at a terminal
too.

You can delete old recordings so they don't pile up.

```bash
cast purge                 # default, older than 60 days
cast purge --days 14
cast purge --dry-run       # list them, delete nothing
cast purge -y              # skip the confirmation
```

It prints what it is about to remove — with sizes, and marking anything that
was shared — then asks before deleting. That prompt is the one place the kit
deliberately does not decide for you: everything else it can redo, and this it
cannot. Index entries for deleted recordings go with them.

## Subcommands

| Subcommand                  | Function                                  |
| --------------------------- | ----------------------------------------- |
| `list`                      | browse recordings (table when piped)      |
| `play <id\|alias>`          | play in the web player                    |
| `share <id\|alias> [alias]` | stage a folder in ~/Downloads for sending |
| `purge`                     | delete recordings older than two months   |
| `rec [-t "title"]`          | starts session recording                  |
| `enroll <command>`          | record another CLI's sessions too         |
| `disenroll <command>`       | stop recording one                        |
| `version`                   | versions and paths, for a bug report      |

## About wrapping (the enrollment)

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

## Development

From a clone instead, which is the same thing without the download — the kit
runs from wherever it lives:

```bash
git clone https://github.com/Smartcuts/castkit && ./castkit/cast list
```

`CASTKIT_URL` overrides where the installer fetches from, and `CASTKIT_REF`
picks a branch or tag.

### Traps worth knowing

- **A thumbnail of a terminal session is the last frame that painted
  something** — which is neither the first frame nor, quite, the last. Three
  wrong turns, each of which looked right until the image was opened.
  Rendering the whole session gave a gif many times the size of the recording
  it previewed: 980 KB against a 132 KB cast. Trimming to the opening seconds
  fixed the size and rendered blank, because an agent session begins on an
  empty screen. Taking the true final frame rendered blank too for codex,
  which tears the terminal down on exit — its last output event is
  cursor-home plus erase-to-end-of-screen. So walk back to the last `o` event
  whose data survives having its escape sequences stripped. Only `o` events
  paint: `x` carries the exit status, whose data is a printable `"0"`, and
  counting that reproduces the blank exactly.
- **`list` must fall back to a table.** The browser is only for a terminal.
  The `/cast` skill runs `list` from an agent, which has none, so a
  TUI-only `list` would break the path the kit is mostly used through.
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

## Licence and third-party code

castkit is Apache-2.0, © Smartcuts. See [LICENSE](LICENSE).

**Redistributed here:** `vendor/` holds
[asciinema-player](https://github.com/asciinema/asciinema-player) — Apache-2.0,
© Marcin Kulik — shipped verbatim, with its licence kept alongside it at
`vendor/LICENSE.asciinema-player`.

**Not redistributed:** the [asciinema](https://github.com/asciinema/asciinema)
CLI and [agg](https://github.com/asciinema/agg) are both GPL-3.0, and castkit
neither bundles nor links them. It runs them as separate processes, and the
installer has your own machine fetch them from Homebrew or cargo. Invoking a
program at arm's length does not make a combined work, and nothing here
distributes them — so no copyleft obligation reaches castkit, your recordings,
or anything you build with it.

That paragraph exists because a licence scan will flag "GPL dependency" and
someone will have to answer for it.
