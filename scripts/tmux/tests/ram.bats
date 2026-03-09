#!/usr/bin/env bats

setup() {
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/ram"
}

teardown() {
  rm -rf "$MOCK_BIN"
}

@test "ram outputs integer 0-100 from mocked free output" {
  cat > "$MOCK_BIN/free" << 'EOF'
#!/bin/bash
echo "               total        used        free      shared  buff/cache   available"
echo "Mem:        16000000     4000000    10000000      200000     2000000    11500000"
echo "Swap:        8000000           0     8000000"
EOF
  chmod +x "$MOCK_BIN/free"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  local val="$output"
  [ "$val" -ge 0 ] && [ "$val" -le 100 ]
}

@test "ram outputs 25 when used is 25 percent of total" {
  cat > "$MOCK_BIN/free" << 'EOF'
#!/bin/bash
echo "               total        used        free      shared  buff/cache   available"
echo "Mem:        16000000     4000000    12000000           0           0    12000000"
echo "Swap:              0           0           0"
EOF
  chmod +x "$MOCK_BIN/free"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "25" ]
}
