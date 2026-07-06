# dskd

A lightweight Bash daemon for monitoring disk usage on a configured path, with threshold alerting, automatic log rotation, and automatic unmount when usage meets or exceeds the configured threshold.

---

## What it does

`dskd` runs as a background process and, on a configurable interval:

- Records the size of a watched directory (`du`)
- Records the percentage used of the filesystem containing it (`df`)
- Appends a timestamped entry to a log file
- Raises a `[WARN]` entry if filesystem usage crosses the configured threshold
- Unmounts the watched path automatically if usage meets or exceeds the threshold
- Rotates the log file once it grows past a configured line count

## Configuration

All settings live in `dsk-daemon.conf`, sourced by the daemon at startup:

| Variable | Description |
|---|---|
| `WATCH_PATH` | Directory to monitor |
| `LOG_FILE` | Path to the usage log |
| `INTERVAL` | Seconds between each check |
| `WARN_PERCENT` | Filesystem usage % that triggers a warning and unmount |
| `MAX_LOG_LINES` | Log rotates once it exceeds this many lines |

## Installation

**1. Copy the systemd unit file:**
```bash
sudo cp dsk-daemon.service /etc/systemd/system/
```

**2. Set the correct paths inside the unit file:**

Open `dsk-daemon.service` and update `ExecStart` to point to your script and config:
```bash
ExecStart=/path/to/dsk-daemon.sh run
```

**3. Ensure the script is executable:**
```bash
chmod +x dsk-daemon.sh
```

**4. Edit the config file:**

Add your paths and settings to match your machine:

```bash
vi dsk-daemon.conf
``` 

**5. Reload systemd and start the daemon:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now dsk-daemon
```

**6. Verify it is running:**
```bash
sudo systemctl status dskd
```

## Acknowledgements

Daemon lifecycle structure (start/stop/status/run via PID file, systemd unit layout) adapted from steps shared by tlp.

---

Copyright © 2026 Usman Olanrewaju. Licensed under the MIT License — see [LICENSE](./LICENSE) for details.
