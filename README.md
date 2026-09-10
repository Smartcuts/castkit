# cast-kit

Record a terminal session, play it back with real controls, and hand it to
someone — without any of it touching a third-party service.

Built around [asciinema](https://asciinema.org), which records the terminal as
text rather than pixels: a session is a small, greppable JSON file whose text
stays selectable on playback.

## One command, four verbs

```bash
cast rec [-t "title"]           # start recording — `claude` unless told otherwise
cast play <id|alias>            # play in the web player
cast list                       # recent recordings
cast share <id|alias> [alias]   # stage a folder in ~/Downloads for sending
```

They are subcommands rather than four binaries because bare `play` and `list`
would collide with things already on PATH.

## There is no install step

Every subcommand installs what it needs and then says nothing about it:
asciinema, `agg` for the gif, the vendored player, the marker-key config, and
the `cast` link in `~/.local/bin`. The first run on a new machine sets the
machine up; every run after that is silent. From a Claude Code session the
`/cast` skill does the same, without asking.

## `cast rec`

Wraps a command and records it, printing how to stop before it starts:
`ctrl+d` ends, `ctrl+\` pauses capture (before you type a password),
`ctrl+t` drops a marker.

Recordings land in `~/casts` as `<date>-<time>-<slug>.cast`, the slug taken
from the title. Idle gaps are capped at two seconds, which matters more than
it sounds: an agent session is mostly waiting on a model, so uncapped the file
is mostly dead air. `CAST_DIR` moves where they land.

**Recording has to wrap the agent from outside.** Start sessions with
`cast rec` instead of `claude`. Nothing running inside a session can record
that session — by then the TUI is live and nothing wraps it in a PTY.

## `cast play`

Takes a recording id, an alias, or a path — a selector is required, since
playing "whatever was most recent" is rarely what is meant. A leading fragment
of an id works when it is unambiguous, and an ambiguous one says so.

Serves the vendored player on a free loopback port. What you get over
`asciinema play`, which has none of it:

- **speed** — `0.5×` `1×` `1.5×` `2×` `4×`, switchable mid-playback
- **dead air** — cap idle gaps at 2s, toggled while watching
- a progress bar you can click, `←`/`→` to seek, `0`–`9` to jump by percent,
  `.` to step a frame while paused, `f` for fullscreen

## `cast list`

```
Datetime          Alias              Length  Shared
----------------  -----------------  ------  ----------------
2026-09-10 18:15  —                  0:00    —
2026-09-10 18:14  fixing-the-parser  0:03    2026-09-10 18:16
```

Aliases and share dates live in `~/casts/index.json`.

## `cast share`

Attaches an alias to the recording and writes `~/Downloads/<alias>/`:

- `<alias>.cast` — **the artifact.** Attach this. It is the native format,
  it is tiny, and anyone with asciinema can play it.
- `<alias>.gif` — a preview, for pasting where an animation renders inline:
  a PR description, an issue, a Slack message.

Given no alias it reuses the one already attached, or derives one from the
recording's title.

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
- **Flush before blocking.** `cast play` prints its URL then blocks on the
  server; without an explicit flush, a caller that backgrounds it sees nothing.

## Recordings contain everything

A `.cast`, and the `.gif` rendered from it, hold every character that was on
screen: keys, tokens printed in an error, the lot. Treat one like a document
containing our source code, because it is one. Read it before sending it.
