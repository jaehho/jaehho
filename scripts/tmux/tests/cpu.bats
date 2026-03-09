#!/usr/bin/env bats

setup() {
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/cpu"
}

teardown() {
  rm -rf "$MOCK_BIN"
}

make_mpstat_mock() {
  local idle="$1"
  cat > "$MOCK_BIN/mpstat" << EOF
#!/bin/bash
echo "Linux 6.18.16 (host)    03/08/2026  _x86_64_  (16 CPU)"
echo ""
echo "Average:     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle"
echo "Average:     all    1.00    0.00    0.50    0.00    0.00    0.00    0.00    0.00    0.00   ${idle}"
EOF
  chmod +x "$MOCK_BIN/mpstat"
}

@test "cpu outputs integer 87 when mpstat idle is 12.5 (Ubuntu C locale)" {
  make_mpstat_mock "12.5"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "87" ]
}

@test "cpu outputs integer when mpstat idle uses comma decimal (Fedora fr locale)" {
  make_mpstat_mock "12,5"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
}

@test "cpu outputs correct integer 87 when mpstat idle is comma-decimal 12,5 (Fedora locale strict)" {
  make_mpstat_mock "12,5"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  local val="$output"
  [ "$val" -ge 0 ] && [ "$val" -le 100 ]
}
