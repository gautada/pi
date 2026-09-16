# pi s6 service — env-switched launcher

`run` is a drop-in `/etc/services.d/pi/run` (s6) that starts ren in one of two
mutually exclusive modes, chosen by the `PI_TYPE` container env var:

| `PI_TYPE` (case-insensitive) | Mode | Notes |
|---|---|---|
| `web` | `pi-web-ui --port 8080` | multi-conversation web dashboard |
| anything else / empty / unset | `tmux + pi` (session `ren`) | bridge-native single session; attach with `tmux attach -t ren` |

slack-bridge auto-loads (autoConnect in `~/.pi/slk-bridge.json`) in **both**
modes — comes up already connected to Slack.

## Install (in the image / container)

```sh
install -m 0755 run /etc/services.d/pi/run
```

## ⚠️ Deployment gotcha — remove the old service dir

The current image ships the web launcher under a **different** service name:
`/etc/services.d/pi-web-ui/run`. s6 runs **every** dir under `services.d`, so if
you add `/etc/services.d/pi/` WITHOUT deleting `/etc/services.d/pi-web-ui/`,
you'll get pi-web-ui AND this launcher both running (two harnesses, port clash /
double Slack socket). Delete the old one:

```sh
rm -rf /etc/services.d/pi-web-ui
```

(Or repurpose that dir: replace its `run` with this file. Just don't keep both.)

## Why tmux is the default

pi-slack-bridge is built for one pi process → one Socket-Mode connection. The
tmux single-session model gives exactly one socket (no orphaned WSS → no silent
dropped replies) and backs the bridge's `new`/`resume`/`handover` commands.
See wayfinder map #15 (decision 001) for the orphan-socket root cause.
