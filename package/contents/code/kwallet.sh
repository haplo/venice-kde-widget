#!/bin/sh
# Manages the Venice.ai API token in the Secret Service (KWallet on KDE).
#
# Subcommands:
#   load   -> prints the token on stdout (exit 0). Exit 1 if not present.
#   store  -> stores the token read from $VENICE_TOKEN env var.
#   clear  -> removes the stored token.
#
# The token is supplied via an environment variable rather than argv so it
# does not appear in process listings.

set -eu

SERVICE="venice-kde-widget"
ACCOUNT="api-token"
LABEL="Venice.ai API token"

if ! command -v secret-tool >/dev/null 2>&1; then
    echo "error: secret-tool (libsecret) is not installed" >&2
    exit 127
fi

case "${1:-}" in
    load)
        # secret-tool prints nothing and exits 1 when no match. Pass-through.
        exec secret-tool lookup service "$SERVICE" account "$ACCOUNT"
        ;;
    store)
        if [ -z "${VENICE_TOKEN:-}" ]; then
            echo "error: VENICE_TOKEN env var is empty" >&2
            exit 2
        fi
        printf %s "$VENICE_TOKEN" | secret-tool store \
            --label="$LABEL" \
            service "$SERVICE" \
            account "$ACCOUNT"
        ;;
    clear)
        exec secret-tool clear service "$SERVICE" account "$ACCOUNT"
        ;;
    *)
        echo "usage: $0 {load|store|clear}" >&2
        exit 64
        ;;
esac
