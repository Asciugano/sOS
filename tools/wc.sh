#!/bin/sh
# Esegue un comando OpenWatcom nel container, mantenendo gli stessi percorsi dell'host
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec docker run --rm --platform linux/amd64 \
  -v "$ROOT":"$ROOT" -w "$PWD" watcom "$@"
