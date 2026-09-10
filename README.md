# cast-kit

Record a terminal session, watch it back with real playback controls, and
hand it to someone — without any of it touching a third-party service.

Built around [asciinema](https://asciinema.org), which records the terminal
as text rather than pixels: a session is a small, greppable JSON file whose
text stays selectable on playback.

```bash
./install                        # asciinema, the player, a marker key
./cast-rec -t "fixing the parser"  # records `claude` by default
./cast-view ~/casts/20260910-*.cast
./cast-share ~/casts/20260910-*.cast
```

## Record — `cast-rec`

Wraps a command and records it. With no arguments it records `claude`.

```bash
cast-rec                          # the agent
cast-rec -t "title"               # titled; the title also names the file
cast-rec -- npm test              # anything else
cast-rec -i 5                     # cap idle gaps at 5s (default 2)
cast-rec -s 100x30                # force a recording size
```

Recordings land in `~/casts` as `<date>-<slug>.cast`; set `CAST_DIR` to move
that. Idle capping is on by default at 2 seconds, which matters more than it
sounds: an agent session is mostly waiting on a model, and without it most of
the file is dead air.

**Recording has to wrap the agent from outside.** A skill invoked inside a
session cannot capture the TUI it is already running in — by then the terminal
is live and there is no PTY around it. That is why this is a shell command and
not a skill.

While recording: `ctrl+d` ends, `ctrl+\` pauses capture (useful before you
type a password), `ctrl+t` drops a marker.

## Watch — `cast-view`

```bash
cast-view session.cast [port]
```

Serves the player on loopback and opens it. What you get over `asciinema
play`, which has none of it:

**In the header** — controls the player itself does not provide:

- **speed** — `0.5×` `1×` `1.5×` `2×` `4×`, switchable mid-playback
- **dead air** — cap idle gaps at 2s, toggled while watching

**In the player's control bar:**

| | |
|---|---|
| `space` | pause / resume |
| `←` `→` | seek 5s |
| `0`–`9` | jump to 0%–90% |
| `.` | step forward one frame (while paused) |
| `f` | fullscreen |

Starting state comes from the URL: `?speed=2`, `?idle=2`, `?autoplay=1`,
`?cast=other.cast`.

## Share — `cast-share`

```bash
cast-share session.cast [-o out.html] [-n "label"]
```

Writes **one** self-contained `.html` — player, stylesheet and recording all
inlined, around 200 KB plus the recording. No server, no network, no sibling
files. Attach it to a message or drop it on any internal static host; it opens
by double-click. The `file://` fetch restriction does not apply because
nothing is fetched.

The shared page carries the same speed and dead-air controls as the local
viewer, because `cast-share` builds it out of `player.html` rather than
keeping a second copy of the UI.

Two lighter options, worth remembering: send the `.cast` itself and let the
other person run `asciinema play`, or point them at a `.cast` on an internal
host.

## Install — `install`

Idempotent; re-run it any time. Nothing already present is overwritten.

- **asciinema** — installs it if missing (homebrew, else cargo), then warns
  if the result is older than 3.x.
- **the player** — vendors asciinema-player from npm into `vendor/`.
  `--refresh-player` re-fetches at the latest version.
- **the config** — writes `~/.config/asciinema/config.toml` with a marker
  key, if you have no config yet. `--marker-key C-g` picks a different one.

## Why there is no asciinema-server here

Two different things share the name. **asciinema-player** is a static JS
library — that is what `vendor/` holds, and it is all playback needs.
**asciinema-server** is the sharing app: accounts, uploads, a browsable
library, permalinks. Stand one up if you want `asciinema upload` and shared
links; nothing here requires it.

The only thing that would send a recording off this machine is
`asciinema upload`, which defaults to asciinema.org. Set `server.url` in the
config to point it somewhere of ours instead.

## Traps worth knowing

- **A marker key is swallowed.** asciinema intercepts it, so the recorded
  program never sees it. Pick one nothing else uses. The syntax is `"C-t"`;
  `"ctrl+t"` is rejected outright.
- **The viewer layout is load-bearing.** `main` is `flex: 1` with
  `min-height: 0` and the player uses `fit: "both"`. Under `fit: "width"` an
  80×24 terminal scales to fill the page, the player grows taller than the
  viewport, and its control bar ends up below the fold — in the DOM,
  invisible on screen.
- **The player has no speed setter.** Its API is play/pause/seek/dispose.
  Each speed change rebuilds the player at the current position; reuse
  `mount()` if you add another option that cannot change live.
- **`--bind 127.0.0.1` is deliberate.** `python3 -m http.server` defaults to
  `0.0.0.0`, which would serve recordings to the whole network.
- **Format.** asciinema 3.x writes asciicast v3. The vendored player reads
  v1, v2 and v3, so no conversion is needed.

## Recordings contain everything

A `.cast` — and any `.html` built from one — is cleartext JSON of every
character that was on screen: keys, tokens printed in an error, the lot.
Treat one like a document containing our source code, because it is one.
Read it before sending it anywhere.
