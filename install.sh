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
say "unpacked into $APP"

# The first run is the install: it installs asciinema and agg, links cast onto
# PATH and the skill into ~/.claude, and wraps the enrolled commands.
"$APP/cast" enroll

case ":${PATH}:" in
  *":$HOME/.local/bin:"*) ;;
  *) printf '\n  \033[33m!\033[0m %s is not on your PATH. Add it:\n      %s\n' \
       "$HOME/.local/bin" 'export PATH="$HOME/.local/bin:$PATH"' >&2 ;;
esac

printf '\n  open a new shell, then:  cast list\n'
