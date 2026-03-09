#!/usr/bin/env bats

setup() {
  MOCK_BIN="$(mktemp -d)"
  SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/gpu"
}

teardown() {
  rm -rf "$MOCK_BIN"
}

@test "gpu outputs percentage when nvidia-smi is present" {
  cat > "$MOCK_BIN/nvidia-smi" << 'EOF'
#!/bin/bash
echo "45"
EOF
  chmod +x "$MOCK_BIN/nvidia-smi"
  export PATH="$MOCK_BIN:/usr/bin:/bin"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+%$ ]]
}

@test "gpu outputs N/A when nvidia-smi is absent" {
  run env PATH="$MOCK_BIN" "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "N/A" ]
}

@test "gpu outputs N/A when nvidia-smi fails (driver not loaded)" {
  cat > "$MOCK_BIN/nvidia-smi" << 'EOF'
#!/bin/bash
echo "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver." >&2
exit 1
EOF
  chmod +x "$MOCK_BIN/nvidia-smi"
  export PATH="$MOCK_BIN:/usr/bin:/bin"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "N/A" ]
}
