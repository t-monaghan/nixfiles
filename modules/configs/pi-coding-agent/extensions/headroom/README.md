# @ryan_nookpi/pi-extension-headroom

This extension reclaims context window in pi by compressing conversation content through a local [Headroom](https://github.com/headroom-ai/headroom) proxy.

It supports two modes:

- **Proxy routing (default, `routeProvider: true`)** — the extension points the provider's `baseUrl` at the local Headroom proxy (health-gated), so pi's real LLM traffic flows through the proxy. The proxy compresses on the wire **and records every request to its savings ledger**, so the Headroom dashboard and the footer both reflect real cumulative usage. Routing is only registered once the proxy is confirmed online; if it is down, pi talks to the provider directly (no breakage).
- **Sidecar (`routeProvider: false`)** — the legacy behaviour: on each `context` event the extension sends an OpenAI-shaped copy of the conversation to the proxy's `/v1/compress` endpoint and applies the result only to oversized `toolResult` payloads under strict alignment guards. This never registers with the Headroom dashboard (it is a stateless compression primitive, not a proxied request).

## Install

```bash
pi install npm:@ryan_nookpi/pi-extension-headroom
```

You also need the Headroom proxy available on your machine:

```bash
pip install "headroom-ai[proxy]"
```

By default the extension auto-starts a local proxy (`headroom proxy --mode cache --no-cache --no-ccr-inject-tool`) on `http://127.0.0.1:8788` and leaves it running after pi exits.

- `--mode cache` freezes the already-cached prefix so the proxy does not invalidate Anthropic's prompt prefix-cache. This is the right default for a flat-rate Claude subscription, which is rate-limit- and latency-bound rather than billed per token: preserving cache reuse matters more than maximizing the raw "tokens saved" figure that `--mode token` chases. (Note: pi spoofs the `claude-cli/` User-Agent on OAuth, so Headroom already classifies its traffic as `SUBSCRIPTION` and applies its conservative, cache-protective compression policy regardless of mode.)
- `--no-cache` disables Headroom's own semantic/CCR cache; it is moot here because `--no-ccr-inject-tool` is set, and it is orthogonal to `--mode cache` (which is driven by `prefix_freeze_enabled`).
- `--no-ccr-inject-tool` keeps the proxy in compression-only mode: pi is a streaming client that cannot service the injected `headroom_retrieve` CCR tool, so it must not be added to requests.

## How it works (proxy routing)

- During the async extension factory, checks proxy health (starting it if needed) and, when online, calls `pi.registerProvider(provider, { baseUrl })` to route the provider through the proxy — applied before pi resolves the session model and issues its first request.
- The proxy transparently forwards to the real upstream (e.g. `https://api.anthropic.com`), preserving auth (including Claude subscription OAuth Bearer + `anthropic-beta` headers) while compressing tool-heavy history on the wire.
- The footer reads the proxy's `/stats` (ledger-backed lifetime savings), so it matches the dashboard and accumulates across sessions.
- `/headroom off` unregisters the override, restoring the provider's default endpoint. Note: toggling mid-session may only take full effect for the live model after a new session, since pi resolves the model's `baseUrl` at session start.

## How it works (sidecar, `routeProvider: false`)

- Listens on the `context` event fired before each LLM call.
- Skips entirely until context usage reaches the configured token threshold.
- Sends an OpenAI-shaped copy of the conversation to the proxy's `/v1/compress` endpoint.
- Applies the result only to large `toolResult` messages, preserving pi metadata (`toolName`, `details`, tool-call ids, images).
- Rejects any response that changes message count, roles, tool-call ids, or non-candidate content.

## Privacy

Compression sends conversation context to the proxy, so remote URLs are blocked by default. Only `localhost`/`127.0.0.1`/`::1` are allowed unless you explicitly set `PI_HEADROOM_ALLOW_REMOTE=1` for a proxy you trust.

## Commands

- `/headroom` — show current status and session stats.
- `/headroom on` — enable Headroom, ensure the proxy is running, and (in proxy-routing mode) register the provider override.
- `/headroom off` — disable Headroom for this session; in proxy-routing mode this also restores the provider's default endpoint. The proxy process is left running.
- `/headroom health` — check / start the proxy and report whether it is online.
- `/headroom stats` — print the proxy's own `/stats` output.
- `/headroom-health` — shortcut for `/headroom health`.

The footer shows a compact status (`✓ Headroom -42% (12,345 saved)`) once compression is applied.

## Configuration

Settings are read at startup from `~/.pi/agent/headroom/settings.json`. Values in this file override environment variables; environment variables remain supported as fallbacks.

Example:

```json
{
  "minContextTokens": 10000,
  "minMessageChars": 1000
}
```

| Setting key | Env fallback | Default | Description |
| --- | --- | --- | --- |
| `enabled` | `PI_HEADROOM_ENABLED` | `true` | Enable Headroom on start. |
| `routeProvider` | `PI_HEADROOM_ROUTE_PROVIDER` | `true` | Route the provider through the proxy (proxy compresses on the wire and records to the dashboard). Set `false` for the legacy `/v1/compress` sidecar. |
| `provider` | `PI_HEADROOM_PROVIDER` | `anthropic` | Provider whose `baseUrl` is overridden to the proxy in routing mode. |
| `baseUrl` (`url` also accepted) | `PI_HEADROOM_URL` (`HEADROOM_URL` / `HEADROOM_BASE_URL` also accepted) | `http://127.0.0.1:8788` | Proxy base URL. |
| `allowRemote` | `PI_HEADROOM_ALLOW_REMOTE` | `false` | Allow non-local proxy URLs. |
| `autoStart` | `PI_HEADROOM_AUTO_START` | `true` | Auto-start a local persistent proxy when offline. |
| `command` | `PI_HEADROOM_COMMAND` | `headroom` | Command used to launch the proxy. |
| `minContextTokens` | `PI_HEADROOM_MIN_CONTEXT_TOKENS` | `20000` | Sidecar mode only: skip compression below this context token count. |
| `minMessageChars` | `PI_HEADROOM_MIN_MESSAGE_CHARS` | `2000` | Sidecar mode only: compress tool results at or above this size. |
| `timeoutMs` | `PI_HEADROOM_TIMEOUT_MS` | `30000` | HTTP timeout for proxy requests. |

Boolean values accept JSON booleans, or strings such as `1/0`, `true/false`, `yes/no`, `on/off`.
