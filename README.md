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
2. Installs the castkit binary and an utility skill to pair with it.
3. Enrolls your local coding agents in (default codex and claude
   code).

## Sessions record themselves

The third step, enrollment, wraps coding agent binary with our own
tooling so that every coding session are automatically recorded from
now on. Every session started from a fresh shell is captured from its
first prompt — there is no command to remember and nothing to
decide. Those two are only the default; `cast enroll` records any
other CLI, and `command claude` runs one unrecorded.

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

This castkit ships binary and its helper skill. You can use the skill
as a more intuitive interface to all the capability. As an example, I
found it easier to export by:

```plain
/cast share the codex session at 5:12pm.
```

Instead of being specific about the exact name of the session.

## Sharing recordings

Attaches an alias to the recording and writes `~/Downloads/<alias>/`:

- `<alias>.cast` — **the artifact.** Attach this. It is the native format,
  it is tiny, and anyone with asciinema can play it.
- `<alias>.gif` — a **thumbnail**: a single still of the finished screen, for
  pasting where an image renders inline — a PR description, an issue, a Slack
  message. Around 50 KB regardless of how long the session ran, because its
  size follows the terminal's dimensions rather than the recording's length.

Pass the alias as ordinary text — `cast share 20260910-1814 "Fixing the
parser"` writes `~/Downloads/fixing-the-parser/`. Accents fold to ASCII,
punctuation and emoji become separators, the result is capped at 40
characters, and something that normalises to nothing falls back to the
recording id. Given no alias at all it reuses the one already attached, or
derives one from the recording's title.

An alias is also a selector, so it has to be unique: sharing under a name
another recording already holds is refused, and names the recording holding
it. Re-sharing the same recording under its own alias just re-stages it.

### What the person receiving it does

Attach the `.cast`, paste the `.gif`. On the other end, a `.cast` is only a
file until something can play it — so tell them one of these:

```bash
# already have asciinema
asciinema play <file>.cast

# or get the kit, and with it seeking, speed and the dead-air control
curl -fsSL https://raw.githubusercontent.com/Smartcuts/castkit/main/install.sh | sh
cast play <file>.cast
```

Nothing is uploaded either way: the file goes over whatever you already use,
and the player runs on their machine.

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

Press <kbd>enter</kbd> plays the highlighted recording, <kbd>s</kbd>
prompts for an alias and shares it, <kbd>d</kbd> deletes it after
confirming. The list scrolls, so a short terminal still reaches
everything.

**Piped or run without a terminal it prints the table instead**, followed by
the storage line. That fallback is not a flag — the `/cast` skill runs this
from an agent, which has no terminal, and a TUI-only `list` would break that
path entirely. `--plain` forces the table at a terminal too.

You can deletes old recordings so that we don't have TBs of recordings.

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

## Subcommand

| Subcommand                | Function                                  |
| ------------------------- | ----------------------------------------- |
| list                      | browse recordings (table when piped)      |
| play <id\|alias>          | play in the web player                    |
| share <id\|alias> [alias] | stage a folder in ~/Downloads for sending |
| purge                     | delete recordings older than two months   |
| rec [-t "title"]          | starts session recording                  |
| enroll <command>          | record another CLI's sessions too         |
| disenroll <command>       | stop recording one                        |
| version                   | versions and paths, for a bug report      |

### `cast rec`

Initiates a recording in the current terminal session. To stop
recording, `ctrl+d` and end the current terminal process; To pause,
`ctrl+\`. This is helpful before you type a password; And use `ctrl+t`
to drop a marker, which is useful for replays to quickly navigate back
to it.

### `cast play`

Takes a recording id, an alias, a printed datetime, or a path — a selector is
required, since playing "whatever was most recent" is rarely what is meant. A
leading fragment works when it is unambiguous, and an ambiguous one says so.

Serves the vendored player on a free loopback port. What you get over
`asciinema play`, which has none of it:

- **speed** — `0.5×` `1×` `1.5×` `2×` `4×`, switchable mid-playback
- **dead air** — cap idle gaps at 2s, toggled while watching
- a progress bar you can click, <kbd>←</kbd>/<kbd>→</kbd> to seek,
  <kbd>0</kbd>–<kbd>9</kbd> to jump by percent, <kbd>.</kbd> to step a
  frame while paused, <kbd>f</kbd> for fullscreen

## Recordings contain everything

A `.cast`, and the `.gif` rendered from it, hold every character that was on
screen: keys, tokens printed in an error, the lot. Treat one like a document
containing our source code, because it is one. Read it before sending it.

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
git clone https://github.com/Smartcuts/castkit ~/castkit && ~/castkit/cast list
```

`CASTKIT_URL` overrides where the installer fetches from, and `CASTKIT_REF`
picks a branch or tag.

### Traps worth knowing

- **A thumbnail of a terminal session is the last frame, not the first.** Two
  wrong turns are worth remembering. Rendering the whole session gave a gif
  many times the size of the recording it previewed — 980 KB against a 132 KB
  cast. Trimming to the opening seconds fixed the size and produced a blank
  image, because an agent session begins on an empty screen. What works is
  keeping every event, which is what makes the terminal state correct, and
  collapsing the timing so there is one frame left to draw.
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
