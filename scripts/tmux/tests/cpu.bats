#!/usr/bin/env bats

setup() {
  SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/cpu"
  SNAP1="$(mktemp)"
  SNAP2="$(mktemp)"
}

teardown() {
  rm -f "$SNAP1" "$SNAP2"
}

@test "cpu outputs integer 87 when /proc/stat shows 87% activity" {
  # snap1: all idle (total=1000, active=0, idle=1000)
  echo "cpu  0 0 0 1000 0 0 0 0 0 0" > "$SNAP1"
  # snap2: 870 active, 130 idle added (delta_total=1000, delta_active=870, delta_idle=130)
  echo "cpu  870 0 0 1130 0 0 0 0 0 0" > "$SNAP2"
  CPU_SAMPLE_INTERVAL=0 PROC_STAT_1="$SNAP1" PROC_STAT_2="$SNAP2" run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "87" ]
}

@test "cpu outputs 0 when system is fully idle" {
  echo "cpu  0 0 0 1000 0 0 0 0 0 0" > "$SNAP1"
  echo "cpu  0 0 0 2000 0 0 0 0 0 0" > "$SNAP2"
  CPU_SAMPLE_INTERVAL=0 PROC_STAT_1="$SNAP1" PROC_STAT_2="$SNAP2" run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "cpu outputs integer 0-100 from real /proc/stat" {
  CPU_SAMPLE_INTERVAL=0 run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [ "$output" -ge 0 ]
  [ "$output" -le 100 ]
}
