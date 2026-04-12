#!/usr/bin/env bash
# 7.10 — SQLite WAL-aware backup script
#
# Uses the SQLite3 Online Backup API via the `.backup` dot-command, which is
# WAL-safe: it can run concurrently with readers/writers without blocking them
# and produces a consistent snapshot regardless of WAL state.
#
# Usage:
#   ./infra/backup.sh <db_path> <dest_path>
#
# Example (production):
#   ./infra/backup.sh /data/jido_builder.db /data/backups/jido_builder_$(date +%Y%m%dT%H%M%S).db
#
# CI smoke-test (restores into a scratch dir and reruns the test suite):
#   ./infra/backup.sh jido_builder_test.db /tmp/jido_builder_backup.db && \
#     env DATABASE_URL="ecto:///tmp/jido_builder_backup.db" mix test

set -euo pipefail

DB_PATH="${1:?Usage: $0 <db_path> <dest_path>}"
DEST_PATH="${2:?Usage: $0 <db_path> <dest_path>}"

if [[ ! -f "$DB_PATH" ]]; then
  echo "ERROR: database file not found: $DB_PATH" >&2
  exit 1
fi

DEST_DIR="$(dirname "$DEST_PATH")"
mkdir -p "$DEST_DIR"

echo "Backing up $DB_PATH → $DEST_PATH (WAL-safe)"

# The .backup command calls sqlite3_backup_init/step/finish under the hood,
# which is the only safe way to copy a WAL-mode database while it is live.
sqlite3 "$DB_PATH" ".backup '$DEST_PATH'"

echo "Backup complete: $DEST_PATH"

# Verify the backup is a valid SQLite3 file
if sqlite3 "$DEST_PATH" "PRAGMA integrity_check;" | grep -q "^ok$"; then
  echo "Integrity check passed."
else
  echo "WARNING: integrity_check did not return 'ok' — inspect $DEST_PATH" >&2
  exit 2
fi
