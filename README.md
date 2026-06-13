# Disk Daemon Management 

A lightweight Bash daemon for monitoring disk usage on a configured path, with threshold alerting and automatic log rotation.

**Status:** Testing

---

## What it does

`dskd` runs as a background process and, on a configurable interval:

- Records the size of a watched directory (`du`)
- Records the percentage used of the filesystem containing it (`df`)
- Appends a timestamped entry to a log file
- Raises a `[WARN]` entry if filesystem usage crosses a configured threshold
- Rotates the log file once it grows past a configured line count

## Files

- **`dsk-daemon.sh`** — the daemon itself: monitor loop, alerting, log rotation, lifecycle commands (`start` / `stop` / `status` / `run`)
- **`dskd.conf`** — all tunable values (watch path, log file, interval, threshold, rotation size)
- **`dskd.service`** — systemd unit for running as a managed service

## Configuration

All settings live in `dskd.conf`, sourced by the daemon at startup:

| Variable | Description |
|---|---|
| `WATCH_PATH` | Directory to monitor |
| `LOG_FILE` | Path to the usage log |
| `INTERVAL` | Seconds between checks |
| `WARN_PERCENT` | Filesystem usage % that triggers a warning |
| `MAX_LOG_LINES` | Log rotates once it exceeds this many lines |

## Usage

```bash
# Run in foreground (useful while testing)
./dsk-daemon.sh run

# Run in background
./dsk-daemon.sh start

# Check if it's running
./dsk-daemon.sh status

# Stop it
./dsk-daemon.sh stop
```

## Running as a systemd service

```bash
sudo cp dskd.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now dskd
```

## Why `df` and not just `du`

`du` reports the size of a directory tree — useful for tracking growth, but not directly comparable against a threshold since it returns human-readable units (e.g. `4.2G`). `df --output=pcent` reports how full the underlying filesystem actually is, as a clean integer — the value the threshold check is built around.

## Acknowledgements

Daemon lifecycle structure (start/stop/status via PID file, systemd unit layout) adapted from steps shared by tlp.
