# cast-viewer

Play asciinema recordings in the web player, entirely on this machine.

`asciinema play` has no progress bar, no seeking, and no way to change speed
mid-playback. The web player has all three. This is that player, vendored,
with a script to serve it locally — so a recording of our own terminal never
leaves the machine.

## Use

```bash
./cast-view ~/recordings/session.cast          # opens the browser
./cast-view ~/recordings/session.cast 9000     # different port
```

Then, in the page:

**In the header** — controls the player itself does not provide:

- **speed** — `0.5×` `1×` `1.5×` `2×` `4×`, switchable mid-playback. The
  player exposes no speed setter (its API is play/pause/seek/dispose only),
  so each click rebuilds it at the current position. Playback resumes where
  it was.
- **dead air** — toggles capping idle gaps at 2 seconds. The single most
  useful control for agent sessions, which are mostly waiting on a model.

**In the player's own control bar** — pinned open via `controls: true`:

| | |
|---|---|
| `space` | pause / resume |
| `←` `→` | seek 5s |
| `0`–`9` | jump to 0%–90% |
| `.` | step forward one frame (while paused) |
| `f` | fullscreen |

Query parameters set the starting state: `?speed=2`, `?idle=2`,
`?autoplay=1`, `?cast=other.cast`.

## Why it is built this way

- **Vendored, no CDN.** `vendor/` holds asciinema-player 3.17.0 (see
  `vendor/VERSION`). `player.html` references no external URL, so the page
  works offline and nothing observes that we loaded it.
- **Loopback only.** `cast-view` passes `--bind 127.0.0.1` to the server.
  The default is `0.0.0.0`, which would serve the recording to everyone on
  the network. Verified: the socket listens on `127.0.0.1` alone.
- **No server needed.** asciinema-*server* is the sharing app — accounts,
  uploads, permalinks. The *player* is a static JS library and needs none of
  it. We only need the server if we later want shareable links.
- **The layout is load-bearing.** `main` is `flex: 1` with `min-height: 0`
  and the player uses `fit: "both"`. With `fit: "width"` instead, an 80x24
  terminal scales to fill the page width, the player grows taller than the
  viewport, and its control bar ends up below the fold — present in the DOM,
  invisible on screen.
- **A page, not a file open.** The player fetches the cast, and browsers
  block `fetch()` from `file://`, so opening `player.html` by double-click
  shows an empty player. That is what the tiny server is for.

## Formats

Our CLI (asciinema 3.2.1) records **asciicast v3** by default. This player
handles v1, v2 and v3, so recordings play as-is. No conversion needed.

## Updating the player

```bash
npm pack asciinema-player && tar xzf asciinema-player-*.tgz
cp package/dist/bundle/asciinema-player.min.js \
   package/dist/bundle/asciinema-player.css vendor/
node -e 'console.log(require("./package/package.json").version)' > vendor/VERSION
rm -rf package asciinema-player-*.tgz
```

## Recordings contain everything

A `.cast` is cleartext JSON of every character that was on screen. Treat one
like a document containing our source code, because it is one — scrub before
putting it anywhere shared.
