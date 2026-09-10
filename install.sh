#!/bin/sh
# castkit installer.
#
#   curl -fsSL https://raw.githubusercontent.com/Smartcuts/castkit/main/install.sh | sh
#
# Downloads the kit to ~/.castkit/app and runs it once — that first run is the
# install proper: it fetches asciinema and agg, vendors nothing (the player
# ships here), links `cast` onto your PATH and wraps your agents in your shell.
#
# Re-run it to update. Recordings, the enrolled set and the setup lock live
# beside the app directory and are never touched.
set -eu

REPO="${CASTKIT_REPO:-https://github.com/Smartcuts/castkit}"
REF="${CASTKIT_REF:-main}"
URL="${CASTKIT_URL:-$REPO/archive/refs/heads/$REF.tar.gz}"
APP="${CASTKIT_HOME:-$HOME/.castkit}/app"

say()  { printf '  \033[33m·\033[0m %s\n' "$*" >&2; }
die()  { printf 'castkit install: %s\n' "$*" >&2; exit 1; }

case "$(uname -s)" in
  Darwin|Linux) ;;
  *) die "$(uname -s) is not supported — run it under WSL on Windows" ;;
esac
for t in curl tar python3; do
  command -v "$t" >/dev/null || die "$t is required but not installed"
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp" "$APP.new"' EXIT

say "downloading castkit"
curl -fsSL "$URL" -o "$tmp/castkit.tar.gz" || die "could not download $URL"

# Unpack beside the old copy and swap, so a failed download cannot leave a
# half-written install behind.
rm -rf "$APP.new"
mkdir -p "$APP.new"
tar xzf "$tmp/castkit.tar.gz" -C "$APP.new" --strip-components=1 \
  || die "the download was not a castkit archive"
[ -f "$APP.new/cast" ] || die "the archive has no cast command in it"

mkdir -p "$(dirname "$APP")"
rm -rf "$APP.old"
[ -d "$APP" ] && mv "$APP" "$APP.old"
mv "$APP.new" "$APP"
rm -rf "$APP.old"
chmod +x "$APP/cast"

# Record what was installed. A tarball has no .git, so without this an
# installed copy cannot say which commit it is — and "re-run the install line"
# is the only update path, so that question comes up.
api=$(printf '%s' "$REPO" | sed 's|https://github.com/|https://api.github.com/repos/|')
curl -fsSL -H 'Accept: application/vnd.github.sha' "$api/commits/$REF" \
  -o "$APP/.version" 2>/dev/null || printf '%s' "$REF" > "$APP/.version"

say "unpacked into $APP ($(cut -c1-12 < "$APP/.version"))"

# Setup itself lives in `cast`, not here — it is the same code that repairs a
# moved install or a dependency that vanished, so duplicating it in shell
# would mean two implementations drifting apart. Running cast once triggers
# it: asciinema and agg, the marker-key config, the PATH and skill symlinks,
# and the shell wrappers.
say "running setup"
"$APP/cast" enroll

# The lock is written only after every setup step succeeded, so its absence
# means something failed quietly. Do not report success in that case.
LOCK="${CASTKIT_HOME:-$HOME/.castkit}/installed"
[ -f "$LOCK" ] || die "setup did not complete — no $LOCK was written"

printf '\n  castkit is installed.\n'
printf '    open a new shell, then:  cast list\n'
case ":${PATH}:" in
  *":$HOME/.local/bin:"*) ;;
  *) printf '    (%s is not on this shell'"'"'s PATH; the wrappers add it\n' \
       "$HOME/.local/bin"
     printf '     for new shells, so a new shell is what you want anyway)\n' ;;
esac
