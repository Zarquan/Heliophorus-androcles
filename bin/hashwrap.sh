#!/bin/sh
# <meta:header>
#   <meta:licence>
#     Copyright (c) 2026, Manchester (http://www.manchester.ac.uk/)
#
#     This information is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This information is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this software. If not, see <http://www.gnu.org/licenses/>.
#   </meta:licence>
# </meta:header>
#
# AIMetrics: [
#     {
#     "name": "ChatGPT",
#     "model": "ChatGPT 5.2",
#     "contribution": {
#       "value": 100,
#       "units": "%"
#       }
#     }
#   ]
#
# hashwrap.sh - run a hash command on a target file or directory, optionally emitting JSON via jc.
#
# Environment:
#   INPUT - path to file or directory (default: /input)
#
# Parameters (positional):
#   1) HASH   - md5sum|shasum|sha256sum|sha512sum     (default: md5sum)
#   2) FORMAT - native|json                            (default: json)
#
# Notes:
#   - 'shasum' is normalized to SHA-256 by dispatching to `sha256sum`.
#   - If INPUT is a directory, all regular files are hashed recursively
#     in sorted order for deterministic output.
#
# Examples (container-style):
#   INPUT defaults to /input
#   hashwrap sha256sum
#
#   Override INPUT
#   INPUT=/some/path hashwrap sha256sum native

set -eu

INPUT="${INPUT:-/input}"
HASH="${1:-md5sum}"
FORMAT="${2:-json}"

die() {
  printf '%s\n' "ERROR: $*" >&2
  exit 2
}

# Validate HASH
case "$HASH" in
  md5sum|shasum|sha256sum|sha512sum) ;;
  *)
    die "Invalid HASH '$HASH'. Allowed: md5sum, shasum, sha256sum, sha512sum"
    ;;
esac

# Validate FORMAT
case "$FORMAT" in
  native|json) ;;
  *)
    die "Invalid FORMAT '$FORMAT'. Allowed: native, json"
    ;;
esac

# Validate INPUT (allow file or directory)
[ -e "$INPUT" ] || die "INPUT '$INPUT' does not exist"
[ -r "$INPUT" ] || die "INPUT '$INPUT' is not readable"

# Ensure required tools exist
command -v md5sum >/dev/null 2>&1 || die "md5sum not found"
command -v sha256sum >/dev/null 2>&1 || die "sha256sum not found"
command -v sha512sum >/dev/null 2>&1 || die "sha512sum not found"
command -v find >/dev/null 2>&1 || die "find not found"
command -v sort >/dev/null 2>&1 || die "sort not found"

if [ "$FORMAT" = "json" ]; then
  command -v jc >/dev/null 2>&1 || die "FORMAT=json requires 'jc' but it was not found in PATH"
fi

hash_one() {
  # $1 = path
  case "$HASH" in
    md5sum)    md5sum -- "$1" ;;
    sha256sum) sha256sum -- "$1" ;;
    sha512sum) sha512sum -- "$1" ;;
    shasum)    sha256sum -- "$1" ;;  # normalized to SHA-256 without perl
  esac
}

run_hash() {
  if [ -f "$INPUT" ]; then
    hash_one "$INPUT"
  elif [ -d "$INPUT" ]; then
    # Recursively hash all regular files in sorted order
    find "$INPUT" -type f -print | sort | while IFS= read -r file; do
      hash_one "$file"
    done
  else
    die "INPUT must be a regular file or directory"
  fi
}

if [ "$FORMAT" = "native" ]; then
  run_hash
else
  run_hash | jc --hashsum
fi

