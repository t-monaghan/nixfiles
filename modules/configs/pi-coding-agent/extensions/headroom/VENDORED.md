# Vendored: @ryan_nookpi/pi-extension-headroom

Source: https://www.npmjs.com/package/@ryan_nookpi/pi-extension-headroom
Upstream repo: https://github.com/Jonghakseo/pi-extension/tree/main/packages/headroom
Vendored version: 0.1.2
License: MIT

## Why vendored

Sticks with the existing pattern of shipping pi extensions as .ts source under
`modules/configs/pi-coding-agent/extensions/`, declaratively managed via
home-manager, with no runtime npm dependency.

## Local modifications

- Rewrote imports `@earendil-works/pi-{coding-agent,ai,agent-core}` →
  `@mariozechner/pi-*` to match the package names exposed by the locally
  installed pi runtime. These are `import type` only, so they affect TS
  type-checking only, not runtime behaviour.
- Changed `STATUS_KEY` from `"headroom"` to `"zz-headroom"` so it sorts to
  the end of pi's alphabetical footer status line (after `status-line`).
- Added a **proxy-routing mode** (`routeProvider`, default `true`) that diverges
  from upstream: instead of the `/v1/compress` sidecar, the extension registers a
  `baseUrl` override (`pi.registerProvider`) so pi's real traffic flows through
  the local proxy. This is what makes proxied requests show up on the Headroom
  dashboard (the sidecar path is not ledger-backed). The proxy is launched with
  `--no-ccr-inject-tool` (compression-only) because pi cannot service the
  injected `headroom_retrieve` tool. The footer reads the proxy's `/stats`
  (cumulative, ledger-backed) in this mode. The upstream sidecar behaviour is
  preserved under `routeProvider: false`.

  Because of this divergence, refreshing from upstream (below) will not carry
  these changes forward — re-apply the routing logic in `index.ts`,
  `config.ts`, `types.ts`, and `proxy-manager.ts` after any refresh.

## Refreshing

```bash
TARBALL=$(curl -sS https://registry.npmjs.org/@ryan_nookpi/pi-extension-headroom/latest \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["dist"]["tarball"])')
curl -sSL "$TARBALL" | tar -xz --strip-components=1 -C "$(mktemp -d)" \
  package/{index,bridge,client,config,proxy-manager,types}.ts package/README.md
# Then re-apply the @earendil-works → @mariozechner rewrite (see above).
```
