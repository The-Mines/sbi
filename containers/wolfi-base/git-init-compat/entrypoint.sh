#!/bin/sh
# This wrapper script handles git dubious ownership errors
# It's designed to be sourced or executed directly

# Configure git to trust all directories as a workaround for dubious ownership
git config --global --add safe.directory '*' 2>/dev/null || true

# If called with arguments, execute git-init
if [ $# -gt 0 ]; then
    exec /ko-app/git-init "$@"
fi