# cast-kit

Record a terminal session, watch it back with real playback controls, and hand
it to someone — without any of it touching a third-party service.

Built around [asciinema](https://asciinema.org), which records the terminal as
text rather than pixels: a session is a small, greppable JSON file whose text
stays selectable on playback.

## Use it

```bash
cast-rec      # record the agent — start sessions with this instead of `claude`
cast-view     # watch the most recent recording
cast-share    # bundle the most recent recording into one shareable .html
```

That is the whole interface. No arguments, no flags, no setup step.

## Nothing has to be run first

Every command runs `install --ensure` on startup. It is silent when there is
nothing to do, and otherwise installs asciinema, vendors the player, writes the
marker-key config, links the commands into `~/.local/bin` and installs the
`/cast` skill. So the first `cast-rec` on a new machine sets the machine up.

`./install` on its own does the same thing and reports what it found. Run it
by hand only when you want to see the state, or with `--refresh-player` to
re-vendor at the latest version, or `--marker-key C-g` to bind a different key.

## From inside a Claude Code session: `/cast`

The kit installs a skill. Ask the agent to watch or share a recording and it
runs these commands for you, setting up dependencies without asking.

**It cannot start a recording**, and neither can any skill. A recording has to
wrap the agent from outside — by the time anything runs inside a session, the
TUI is live and nothing wraps it in a PTY, so shelling out to `asciinema rec`
would capture a child process rather than the conversation. Start the session
with `cast-rec` instead. The skill will tell you exactly that, and can check
`ASCIINEMA_SESSION` to say whether the current session is being captured.

## Record — `cast-rec`

Wraps a command and records it. With no arguments it records `claude`.

```bash
cast-rec                          # the agent
cast-rec -t "fixing the parser"   # titled; the title also names the file
cast-rec -- npm test              # anything else
```

Recordings land in `~/casts` as `<date>-<slug>.cast`; `CAST_DIR` moves that.
Idle gaps are capped at two seconds, which matters more than it sounds: an
agent session is mostly waiting on a model, and uncapped the file is mostly
dead air. `-i` changes the cap, `-s 100x30` forces a recording size.

While recording: `ctrl+d` ends, `ctrl+\` pauses capture (useful before you
type a password), `ctrl+t` drops a marker.

## Watch — `cast-view`

Serves the player on a free loopback port and opens it. Pass a path to watch
something other than the newest recording. What you get over `asciinema play`,
which has none of it:

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

Starting state comes from the URL: `?speed=2`, `?idle=2`, `?autoplay=1`.

## Share — `cast-share`

Writes **one** self-contained `.html` next to the recording — player,
stylesheet and recording all inlined, around 200 KB. No server, no network, no
sibling files. Attach it to a message or drop it on any internal static host;
it opens by double-click. The `file://` fetch restriction does not apply
because nothing is fetched.

The shared page keeps the same speed and dead-air controls, because
`cast-share` builds it out of `player.html` rather than a second copy of the UI.

Two lighter options: send the `.cast` itself and let the other person run
`asciinema play`, or point them at a `.cast` on an internal host.

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
  program never sees it. The syntax is `"C-t"`; `"ctrl+t"` is rejected.
- **Scripts must resolve through their symlink.** They are linked into
  `~/.local/bin`, so `dirname "$0"` gives the link's directory, not the kit —
  hence `readlink -f` in bash and `os.path.realpath` in Python. Get this wrong
  and every command breaks under its bare name while still working as `./cmd`.
- **The viewer layout is load-bearing.** `main` is `flex: 1` with
  `min-height: 0` and the player uses `fit: "both"`. Under `fit: "width"` an
  80×24 terminal scales to fill the page, the player grows taller than the
  viewport, and its control bar ends up below the fold — in the DOM, invisible.
- **The player has no speed setter.** Its API is play/pause/seek/dispose. Each
  speed change rebuilds the player at the current position; reuse `mount()` if
  you add another option that cannot change live.
- **`--bind 127.0.0.1` is deliberate.** `python3 -m http.server` defaults to
  `0.0.0.0`, which would serve recordings to the whole network.
- **Format.** asciinema 3.x writes asciicast v3; the vendored player reads v1,
  v2 and v3, so no conversion is needed.

## Recordings contain everything

A `.cast` — and any `.html` built from one — is cleartext JSON of every
character that was on screen: keys, tokens printed in an error, the lot. Treat
one like a document containing our source code, because it is one. Read it
before sending it anywhere.
