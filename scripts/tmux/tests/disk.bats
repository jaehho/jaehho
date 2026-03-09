#!/usr/bin/env bats

setup() {
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/disk"
}

teardown() {
  rm -rf "$MOCK_BIN"
}

@test "disk outputs percentage string from mocked df output" {
  cat > "$MOCK_BIN/df" << 'EOF'
#!/bin/bash
echo "Filesystem      Size  Used Avail Use% Mounted on"
echo "/dev/sda3       500G  210G  290G  42% /"
EOF
  chmod +x "$MOCK_BIN/df"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "42%" ]
}

@test "disk outputs percentage string matching pattern NN%" {
  cat > "$MOCK_BIN/df" << 'EOF'
#!/bin/bash
echo "Filesystem      Size  Used Avail Use% Mounted on"
echo "/dev/nvme0n1p3  1.0T  750G  250G  75% /"
EOF
  chmod +x "$MOCK_BIN/df"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+%$ ]]
}
