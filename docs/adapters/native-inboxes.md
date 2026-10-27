# Existing Claude Code and Antigravity receivers

Both adapters connect to existing local processes only. They never start an Agent, restore one by argv, change its model or permissions, or use cloud control. AI-initiated DJ MCP/API and Skill installation remain independent of these outgoing transports.

## Prepare an endpoint

Run `dj native configure --input PRIVATE_JSON` with a private JSON file containing `tool`, `pid`, `directory`, `workspace_ref`, `instance_id`, `native_namespace`, `output_directory`, and `process_helper_ref`. The helper is the package's `libexec/dj-process-info`. For Antigravity include the observed local `base_url`; for Claude include its native `registry_path`. `--help` shows the fields. All paths are operator-selected local paths; no process is launched by this command.

The command verifies the same-user PID, executable, process birth and actual listening socket. It creates new owner-private `endpoint.json` and, for Antigravity, `credential.json`; it refuses to overwrite them. Merge the endpoint object into `agent_endpoints` in the service configuration explicitly. It does not modify client settings, subscriptions, permissions or trust. A client restart changes the process epoch; configure a fresh endpoint and explicitly rebind rather than silently reusing an old PID or endpoint.

## Antigravity

The endpoint targets the existing App language server's Connect JSON API on loopback HTTPS. Bootstrap reads that process's CSRF argument in memory and captures only its public TLS certificate. Authenticated requests use the exact certificate as CA and pin its SHA-256; no global trust changes, redirects or credential output. Every call rechecks PID birth and listener ownership.

Discovery uses native trajectory summaries restricted to the exact workspace URI. Probe uses current cascade status. Sending reads the latest user configuration from at most 128 native steps, preserves its actual model and configuration, and submits one `SendUserCascadeMessage` with `WHEN_IDLE`. An API acceptance is not model completion. A missing model/configuration or an oversized tail refuses the send before transmission; ambiguous transmission remains unknown and is not retried.

Message reads cover a bounded native tail, not full history. They use `GetCascadeTrajectorySteps`, preserve real native message IDs, omit thinking and tool content, and enforce a 1 MiB response ceiling. Cursors bind the original session and step offset; a stale cursor beyond 128 steps must be refreshed. Full-history coverage, native idempotency, creation, lifecycle control and completion observation are unsupported. Receipt keys correlate DJ dispatches; they do not invent a native message ID.

## Claude Code

Requires a running Claude Code with native cross-session messaging and `notify_idle` support, its PID registry, and its actual Unix socket. A running Claude Desktop chat window or an old JSONL alone is insufficient. No Channels opt-in, Remote Control, pairing, extension, permission relay or new CLI is substituted.

DJ creates only its own private callback socket in the existing native socket directory, using its own PID. It sends native `msgV:1` frames with its truthful `uds:` reply address and no impersonated permission mode or child token. `notify_when_idle` provides bounded native idle evidence; one outstanding watcher per receiver avoids accumulating subscriptions. Sending requires fresh idle evidence and uses the existing target's accept/hold/refuse policy. Only correlated `peer_message_status: delivered` is accepted; held/no ACK is unknown and never automatically resent. Explicit denied/refused/expired/dropped outcomes are final. Late delivered receipts support positive-only lookup within bounded process-local retention; restart cannot reconstruct them and returns unknown.

Optional registry-bound JSONL reading is a bounded tail of the original session's user/assistant text, with native IDs and byte-offset pagination. It is never proof of a live receiver. Thinking and tool blocks are excluded. Closing the adapter removes only its own callback inode and never stops Claude.

Native protocol reference: [Claude Code cross-session messaging](https://code.claude.com/docs/en/cross-session-messaging). Real-client results and missing receivers are recorded separately from local protocol fixtures in the delivery report.
