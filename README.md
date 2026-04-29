# sbox-server-native-linux

Dockerized s&box dedicated server, running natively on Linux (no Wine, no Proton).

## Requirements

- Docker / Docker Compose
- Linux host, or any platform that runs Linux containers

## Usage

Build the image:

```
docker build -t sbox-server:latest .
```

Run with the provided compose file:

```
docker compose up -d
```

Logs:

```
docker logs -f sbox-server
```

## Configuration

Edit the `command:` block in `docker-compose.yml` to change game, map, hostname, or pass additional flags.

To pin a server Steam ID across restarts, generate a token at https://steamcommunity.com/dev/managegameservers and uncomment the `+net_game_server_token` lines.

## Networking

The compose file uses `network_mode: host`.

s&box uses Steam Datagram Relay (SDR) by default, so no inbound port forwarding is required.

Host networking gave the most reliable results during testing.

## Volumes

- `/sbox/download`: workshop / asset downloads
- `/sbox/logs`: server logs
- `/sbox/data`: persistent data

## Known issues

**Do not add `tty: true` or `stdin_open: true` to the compose service.**

The server crashes on startup when either is set.

Run the container without an attached TTY and read output via `docker logs`.

## License

MIT
