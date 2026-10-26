#!/usr/bin/env bash
set -euo pipefail

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

curl -fsSL --retry 2 https://teamwork-graph.atlassian.com/cli/install.pkg -o "$workdir/install.pkg"
/usr/sbin/installer -pkg "$workdir/install.pkg" -target CurrentUserHomeDirectory >/dev/null
