#!/usr/bin/env bash
#
# Package this plasmoid as a .deb or .rpm.
#
#   packaging/build.sh <deb|rpm> [suite]
#
# Prints the path of the package it built. Everything comes from
# metadata.json, so this file is identical in every neiam plasmoid repo
# — copy it, don't fork it.
#
# A plasmoid is QML and nothing else: there is nothing to compile, so
# one `Architecture: all` / `noarch` package installs on any Plasma 6
# system, and the "build" is laying files out under
# /usr/share/plasma/plasmoids/<Id>/.
#
#   suite        deb only — appended as `+<suite>`, because the same
#                package published to two suites needs two filenames to
#                sit in the forge's pool
#   MAINTAINER   control field (default: the first author in metadata.json)
#   HOMEPAGE     control field (default: KPlugin.Website)
#   NFPM_IMAGE   container used when nfpm isn't on PATH
#
# Builds with nfpm if it's installed, otherwise runs it in docker or
# podman — so the runner needs neither dpkg-deb nor rpmbuild.
set -euo pipefail

format=${1:?usage: build.sh <deb|rpm> [suite]}
suite=${2:-}
case $format in deb | rpm) ;; *) echo "unknown format: $format" >&2; exit 2 ;; esac
if [ "$format" = rpm ] && [ -n "$suite" ]; then
  echo "rpm has no suites; drop the second argument" >&2
  exit 2
fi

root=$(cd -- "$(dirname -- "$0")/.." && pwd)
m() { jq -er "$1" "$root/metadata.json"; }

id=$(m .KPlugin.Id)
# Named from the plugin Id, not the repo: a repo name like
# `lambent_ex-plasmoid` isn't a legal Debian package name.
pkg=plasma-applet-${id##*.}
version=$(m .KPlugin.Version)

commit=$(git -C "$root" rev-parse HEAD)
# The COMMIT's date, not the clock: the same commit always builds the
# same version, and the .deb and .rpm of one run agree on it.
stamp=$(git -C "$root" show -s --format=%cd --date=format:%Y%m%d%H%M%S HEAD)
SOURCE_DATE_EPOCH=$(git -C "$root" show -s --format=%ct HEAD)
export SOURCE_DATE_EPOCH

maintainer=${MAINTAINER:-"$(m '.KPlugin.Authors[0].Name') <$(m '.KPlugin.Authors[0].Email')>"}
homepage=${HOMEPAGE:-$(m .KPlugin.Website)}

# plasma-workspace brings Plasma, Kirigami and Qt Quick with it. These
# are the QML modules it doesn't, added only where a plasmoid imports
# them. rpm gets a file dependency instead: /usr/bin/plasmashell is the
# same path on Fedora and openSUSE though the package names differ.
deb_depends=(plasma-workspace)
uses() { grep -rqE "^[[:space:]]*import $1([[:space:]]|$)" "$root/contents"; }
uses 'QtQuick\.Dialogs' && deb_depends+=(qml6-module-qtquick-dialogs)
uses 'org\.kde\.notification' && deb_depends+=(qml6-module-org-kde-notifications)
uses 'org\.kde\.kcmutils' && deb_depends+=(qml6-module-org-kde-kcmutils)

out=$root/dist
mkdir -p "$out"
config=$out/nfpm-$format${suite:+-$suite}.yaml

# Every scalar goes through jq's @json, so a description with a colon
# or a quote is still valid YAML.
y() { jq -rn --arg v "$1" '$v|@json'; }

cat > "$config" <<EOF
name: $(y "$pkg")
arch: all
platform: linux
version: $(y "$version")
# '~' sorts before the release: 0.5.0~ci… upgrades cleanly to 0.5.0.
prerelease: $(y "ci${stamp}.g${commit:0:12}")
version_metadata: $(y "$suite")
release: "1"
maintainer: $(y "$maintainer")
homepage: $(y "$homepage")
license: GPL-3.0
section: kde
# First line is the synopsis (and the forge's package card); the rest
# is the extended description.
description: $(y "$(m .KPlugin.Name) — $(m .KPlugin.Description)
A Plasma 6 widget, installed system-wide as $id.
Built from commit $commit.")
contents:
  - src: ./metadata.json
    dst: /usr/share/plasma/plasmoids/$id/metadata.json
    file_info: { mode: 0644 }
  - src: ./contents/
    dst: /usr/share/plasma/plasmoids/$id/contents/
    type: tree
  - src: ./LICENSE.md
    dst: /usr/share/doc/$pkg/copyright
    file_info: { mode: 0644 }
overrides:
  deb:
    depends: $(jq -cn '$ARGS.positional' --args "${deb_depends[@]}")
  rpm:
    depends: ["/usr/bin/plasmashell"]
EOF

# nfpm names the file itself; find what it made by listing before and
# after rather than reconstructing its naming rules here.
before=$(ls -1 "$out" | sort)

rel_config=${config#"$root/"}
if command -v nfpm >/dev/null 2>&1; then
  nfpm=nfpm
else
  # nfpm is one static binary; lift it out of its image rather than
  # running the image. On the CI runner the job is itself a container
  # talking to the host's daemon, so a bind mount of the checkout names
  # a path the daemon can't see — but create/cp go over the API and
  # need no shared filesystem.
  image=${NFPM_IMAGE:-docker.io/goreleaser/nfpm:v2.41.0}
  nfpm=$out/.bin/nfpm-${image##*:}
  if [ ! -x "$nfpm" ]; then
    if command -v docker >/dev/null 2>&1; then engine=docker
    elif command -v podman >/dev/null 2>&1; then engine=podman
    else echo "need nfpm, docker or podman" >&2; exit 1
    fi
    mkdir -p "$out/.bin"
    container=$("$engine" create "$image")
    trap '"$engine" rm -f "$container" >/dev/null' EXIT
    "$engine" cp "$container:/usr/bin/nfpm" "$nfpm.tmp" >&2
    chmod +x "$nfpm.tmp" && mv "$nfpm.tmp" "$nfpm"
  fi
fi
(cd "$root" && "$nfpm" package -f "$rel_config" -p "$format" -t dist/) >&2

made=$(comm -13 <(echo "$before") <(ls -1 "$out" | sort) | grep "\.$format\$" || true)
if [ "$(echo "$made" | grep -c .)" != 1 ]; then
  # Same version already in dist/ from an earlier run: nfpm overwrote it.
  made=$(ls -1t "$out" | grep "\.$format\$" | head -1)
fi
echo "$out/$made"
