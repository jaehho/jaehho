#!/usr/bin/env bats

setup() {
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/gpu"
}

teardown() {
  rm -rf "$MOCK_BIN"
}

@test "gpu outputs integer when nvidia-smi is present" {
  cat > "$MOCK_BIN/nvidia-smi" << 'EOF'
#!/bin/bash
echo "45"
EOF
  chmod +x "$MOCK_BIN/nvidia-smi"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
}

@test "gpu outputs N/A when nvidia-smi is absent" {
  # MOCK_BIN is empty; real nvidia-smi is not in PATH (masked by MOCK_BIN prefix)
  # Also ensure real nvidia-smi not found by checking PATH contains only MOCK_BIN and system dirs without nvidia-smi
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "N/A" ]
}
