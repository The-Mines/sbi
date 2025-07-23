#!/bin/sh
# This script configures git to trust all directories
# Source this in your shell script before running git commands
git config --global --add safe.directory '*' 2>/dev/null || true