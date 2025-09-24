#!/usr/bin/env bash
# Allows symlink or nonsymlink versions of script. eg. if calling from symlink file in ~/.bin
src="$(dirname "$(readlink -f "$0")")"
bqn "$src/qbqn" "$@"
