#!/usr/bin/env bash
set -euo pipefail
zig build
qemu-system-i386 -kernel zig-out/bin/kernel -display gtk 2>&1 &
QEMU_PID=$!
sleep 240
kill $QEMU_PID 2>/dev/null
echo "QEMU launched and terminated successfully"
