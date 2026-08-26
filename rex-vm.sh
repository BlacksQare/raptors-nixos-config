#!/usr/bin/env bash

# Configuration
FLAKE_TARGET=".#rex-vm"
NIX_CMD="nix --extra-experimental-features nix-command --extra-experimental-features flakes"
PID_FILE=".rex-vm.pid"
LOG_FILE="rex-vm.log"
# The VM state disk matches your NixOS hostname. Using a wildcard for safety.
DISK_IMAGE="*.qcow2" 

start_vm() {
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "VM is already running (PID: $(cat "$PID_FILE"))."
    exit 1
  fi
  
  echo "Building and starting VM... This can take a long time, check logs for more information"
  echo "Logs will be written to $LOG_FILE"
  
  # Run the VM in the background (without QEMU_OPTS)
  nohup $NIX_CMD run "$FLAKE_TARGET" > "$LOG_FILE" 2>&1 &
  
  # Immediately capture the PID of that background process and write it to the file
  echo $! > "$PID_FILE"
  
  echo "VM started in the background (PID: $(cat "$PID_FILE"))."
}

stop_vm() {
  if [ -f "$PID_FILE" ]; then
    echo "Stopping VM..."
    # Gracefully terminate the QEMU process
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
    echo "VM stopped."
  else
    echo "VM is not running (or $PID_FILE is missing)."
  fi
}

remove_vm() {
  stop_vm
  echo "Removing VM persistent state..."
  if ls $DISK_IMAGE 1> /dev/null 2>&1; then
    rm -f $DISK_IMAGE
    echo "State removed. The next start will be a completely fresh boot."
  else
    echo "No state file ($DISK_IMAGE) found."
  fi
}

rebuild_vm() {
  echo "Rebuilding and restarting VM..."
  stop_vm
  start_vm
}

# Command router
case "$1" in
  start)   start_vm ;;
  stop)    stop_vm ;;
  rebuild) rebuild_vm ;;
  remove)  remove_vm ;;
  *)
    echo "Usage: $0 {start|stop|rebuild|remove}"
    exit 1
    ;;
esac