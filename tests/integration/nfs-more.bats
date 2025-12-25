#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/helpers/common"

setup() {
  setup_test_root
  export KIOSK_RETROPIE_DRY_RUN=1
}

teardown() {
  teardown_test_root
}

@test "mount-nfs records not-configured path" {
  unset NFS_SERVER NFS_ROMS_PATH
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs:not-configured"
}

@test "mount-nfs records legacy-nfs-path when NFS_PATH is used" {
  # Legacy: NFS_PATH used to configure ROMs export.
  unset NFS_ROMS_PATH
  export NFS_PATH=/export/roms
  unset NFS_SERVER

  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs:legacy-nfs-path"
}

@test "mount-nfs records already-mounted path" {
  export NFS_SERVER=server
  export NFS_ROMS_PATH=/export
  export MOUNTPOINT_PATHS="$TEST_ROOT/mnt/kiosk-retropie-roms\n"
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs:already-mounted"
}

@test "mount-nfs records mount-failed path (fail-open)" {
  export KIOSK_RETROPIE_DRY_RUN=0
  export NFS_SERVER=server
  export NFS_ROMS_PATH=/export
  export MOUNT_EXIT_CODE=32
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs:mount-attempt"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs:mount-failed"
}

@test "mount-nfs records mount-success path" {
  export KIOSK_RETROPIE_DRY_RUN=0
  export NFS_SERVER=server
  export NFS_ROMS_PATH=/export
  export MOUNT_EXIT_CODE=0
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs:mount-success"
}

@test "mount-nfs-backup disabled path" {
  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=0
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs-backup:disabled"
}

@test "mount-nfs-backup not-configured path" {
  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=1
  unset KIOSK_RETROPIE_SAVE_BACKUP_NFS_SERVER KIOSK_RETROPIE_SAVE_BACKUP_NFS_PATH NFS_SERVER NFS_ROMS_PATH NFS_SAVE_BACKUP_PATH
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs-backup:not-configured"
}

@test "mount-nfs-backup records legacy server/path IDs when old vars are set" {
  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=1

  # Legacy vars should be ignored/translated, but still tracked for coverage.
  export KIOSK_RETROPIE_SAVE_BACKUP_NFS_SERVER=legacy-server
  export KIOSK_RETROPIE_SAVE_BACKUP_NFS_PATH=/export/backup

  # Keep current vars unset so script exits via not-configured without attempting mount.
  unset NFS_SERVER NFS_SAVE_BACKUP_PATH

  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs-backup:legacy-server-ignored"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs-backup:legacy-path"
}

@test "mount-nfs-backup already-mounted path" {
  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=1
  export NFS_SERVER=server
  export NFS_SAVE_BACKUP_PATH=/export
  export MOUNTPOINT_PATHS="$TEST_ROOT/mnt/kiosk-retropie-backup\n"
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs-backup:already-mounted"
}

@test "mount-nfs-backup mount-failed path (fail-open)" {
  export KIOSK_RETROPIE_DRY_RUN=0
  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=1
  export NFS_SERVER=server
  export NFS_SAVE_BACKUP_PATH=/export
  export MOUNT_EXIT_CODE=32
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs-backup:mount-attempt"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs-backup:mount-failed"
}

@test "mount-nfs-backup mount-success path" {
  export KIOSK_RETROPIE_DRY_RUN=0
  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=1
  export NFS_SERVER=server
  export NFS_SAVE_BACKUP_PATH=/export
  export MOUNT_EXIT_CODE=0
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/mount-nfs-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH mount-nfs-backup:mount-success"
}

@test "sync-roms skips when rsync missing" {
  export NFS_SERVER=server
  export NFS_ROMS_PATH=/export
  export MOUNTPOINT_PATHS="$TEST_ROOT/mnt/kiosk-retropie-roms\n"
  make_isolated_path_with_stubs dirname mountpoint mount
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/sync-roms.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:rsync-missing"
}

@test "sync-roms skips when not mounted" {
  export NFS_SERVER=server
  export NFS_ROMS_PATH=/export
  unset MOUNTPOINT_PATHS
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/sync-roms.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:not-mounted"
}

@test "sync-roms with allowlist + exclude + delete" {
  export NFS_SERVER=server
  export NFS_ROMS_PATH=/export
  export MOUNTPOINT_PATHS="$TEST_ROOT/mnt/kiosk-retropie-roms\n"

  # Fake NFS tree under KIOSK_RETROPIE_ROOT.
  mkdir -p "$TEST_ROOT/mnt/kiosk-retropie-roms/nes" "$TEST_ROOT/mnt/kiosk-retropie-roms/snes"
  export KIOSK_RETROPIE_ROMS_SYSTEMS="nes,snes"
  export KIOSK_RETROPIE_ROMS_EXCLUDE_SYSTEMS="snes"
  export KIOSK_RETROPIE_ROMS_SYNC_DELETE=1

  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/sync-roms.sh"
  assert_success

  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:delete-enabled"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:allowlist"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:excluded"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:chown"
}

@test "sync-roms records legacy-subdir-ignored + src-missing" {
  # Avoid mount-nfs creating the mountpoint directory.
  export NFS_SERVER=
  export NFS_ROMS_PATH=

  missing_mp="$TEST_ROOT/mnt/kiosk-retropie-roms-missing"
  export KIOSK_RETROPIE_NFS_MOUNT_POINT="$missing_mp"
  export MOUNTPOINT_PATHS="$missing_mp\n"

  export KIOSK_RETROPIE_NFS_ROMS_SUBDIR=subdir
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/sync-roms.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:legacy-subdir-ignored"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:src-missing"
}

@test "sync-roms records discover + missing-system" {
  export NFS_SERVER=server
  export NFS_ROMS_PATH=/export
  export MOUNTPOINT_PATHS="$TEST_ROOT/mnt/kiosk-retropie-roms\n"

  mkdir -p "$TEST_ROOT/mnt/kiosk-retropie-roms/nes"
  export KIOSK_RETROPIE_ROMS_SYSTEMS="nes,snes"

  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/sync-roms.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:allowlist"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:missing-system"

  # Now switch to discovery mode.
  unset KIOSK_RETROPIE_ROMS_SYSTEMS
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/sync-roms.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH sync-roms:discover"
}

@test "save-backup records rsync-missing when mounted but rsync absent" {
  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=1
  # systemctl stub uses 0 for active; set to 1 = inactive (not in Retro mode).
  export SYSTEMCTL_ACTIVE_RETRO=1

  # Mark backup as mounted.
  export MOUNTPOINT_PATHS="$TEST_ROOT/mnt/kiosk-retropie-backup\n"

  # Remove rsync from PATH by isolating it.
  make_isolated_path_with_stubs dirname mountpoint systemctl

  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/save-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH save-backup:rsync-missing"
}

@test "save-backup backup-saves and backup-states with delete" {
  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=1
  # Not in Retro mode.
  export SYSTEMCTL_ACTIVE_RETRO=1

  # Backup mounted.
  export MOUNTPOINT_PATHS="$TEST_ROOT/mnt/kiosk-retropie-backup\n"

  mkdir -p "$TEST_ROOT/var/lib/kiosk-retropie/retropie/saves" "$TEST_ROOT/var/lib/kiosk-retropie/retropie/states"
  export KIOSK_RETROPIE_SAVE_BACKUP_DELETE=1

  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/save-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH save-backup:delete-enabled"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH save-backup:backup-saves"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH save-backup:backup-states"
}

@test "save-backup records disabled/retro-active/not-mounted paths" {
  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=0
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/save-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH save-backup:disabled"

  export KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=1
  export SYSTEMCTL_ACTIVE_RETRO=0
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/save-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH save-backup:retro-active"

  export SYSTEMCTL_ACTIVE_RETRO=1
  unset MOUNTPOINT_PATHS
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/nfs/save-backup.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH save-backup:not-mounted"
}
