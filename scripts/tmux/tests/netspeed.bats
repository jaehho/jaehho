#!/usr/bin/env bats

setup() {
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  FIXTURE_DIR="$(mktemp -d)"
  SCRIPT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/netspeed"
  export SLEEP_INTERVAL=0

  # Mock ip route to return a known interface name
  cat > "$MOCK_BIN/ip" << 'EOF'
#!/bin/bash
echo "default via 192.168.1.1 dev eth0 proto dhcp metric 600"
EOF
  chmod +x "$MOCK_BIN/ip"

  # Create a /proc/net/dev fixture with two reads worth of data in the same file.
  # The netspeed script reads the file twice (before and after sleep).
  # With PROC_NET_DEV fixture, both reads see the same file — delta will be 0.
  # To test non-zero delta, we need the script to support PROC_NET_DEV_2 for the second read,
  # OR we accept that delta=0 and verify the output format only.
  # Decision: verify format only (delta=0 is valid: ↓0 ↑0 KB/s).
  cat > "$FIXTURE_DIR/proc_net_dev" << 'EOF'
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
  eth0: 1073741824    1024    0    0    0     0          0         0  536870912     512    0    0    0     0       0          0
EOF
  export PROC_NET_DEV="$FIXTURE_DIR/proc_net_dev"
  export FIXTURE_DIR
}

teardown() {
  rm -rf "$MOCK_BIN" "$FIXTURE_DIR"
}

@test "netspeed outputs KB/s format string" {
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  # Format: ↓N ↑N KB/s  (N is a non-negative integer)
  [[ "$output" =~ ^↓[0-9]+\ ↑[0-9]+\ KB/s$ ]]
}

@test "netspeed outputs exact delta when bytes change between reads" {
  local fixture1="$FIXTURE_DIR/proc_net_dev_1"
  local fixture2="$FIXTURE_DIR/proc_net_dev_2"

  # t=0: eth0 rx=1024, tx=0
  cat > "$fixture1" << 'EOF'
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
  eth0:    1024       1    0    0    0     0          0         0        0       0    0    0    0     0       0          0
EOF

  # t=1: eth0 rx=2048, tx=1024 → delta rx=1024, tx=1024 → ↓1 ↑1 KB/s
  cat > "$fixture2" << 'EOF'
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
  eth0:    2048       2    0    0    0     0          0         0     1024       1    0    0    0     0       0          0
EOF

  SLEEP_INTERVAL=0 PROC_NET_DEV_1="$fixture1" PROC_NET_DEV_2="$fixture2" run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "↓1 ↑1 KB/s" ]
}
