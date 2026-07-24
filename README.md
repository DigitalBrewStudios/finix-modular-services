# finix - modular services

Support for [Modular services](https://nixos.org/manual/nixos/unstable/#modular-services) for `finix`.

Services declared under `system.services` are converted into Finit version 5
service stanzas and rendered into `/etc/finit.d/<name>.conf`:

- `process.argv` becomes the stanza's `command`.
- `process.reloadCommand` (or the `process.reloadSignal` derivation) becomes the
  Finit version 5 `exec-reload` used by `initctl reload <service>`.
- `notificationProtocol.systemd` / `notificationProtocol.s6` set the Finit
  version 5 `notify` readiness mechanism.
- Sub-services are siphoned as dash-joined stanzas, e.g. the sub-service
  `reload.inner` of `reload` becomes `reload-inner`.

Inside a service, use `finit.service.*` to configure its own stanza (e.g.
`finit.service.runlevel = "2";`) and `finit.services.<name>.*` for additional
stanzas.

There is a Matrix room for discussions:

- https://matrix.to/#/#modular-services:nixos.org

Relevant links:

- https://github.com/NixOS/nixpkgs/pull/372170
- https://github.com/NixOS/nixpkgs/issues/428084
