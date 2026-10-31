# Configuration Guide

This guide covers the WSL-specific parts of the `moshpitcodes.wsl.nix`
configuration and how to customize it.

## Layout

```
flake.nix            # entry point: inputs, customsecrets loader, wsl host
hosts/wsl/           # single WSL host (hostname + stateVersion + optional NAS modules)
modules/core/        # system-level: nix, wsl, system (locale/tz), user, docker,
                     # nas-mount/samba, and a minimal root bootstrap package set
modules/home/        # Home Manager: shell, zsh, editor, agents, theme, and ALL
                     # user-facing packages (dev.nix, packages.nix, language-servers.nix)
overlays/            # local package overlays (sidecar, td, terraform, cpplint,
                     # switch-to-configuration)
justfile             # repo tasks: rebuild / test / build / update / fmt / lint / check
secrets.nix.example  # secret template (copy to secrets.nix)
```

## Package ownership

`modules/core/packages.nix` deliberately contains only a small root-usable
bootstrap set (git, vim, curl, ...). Every user-facing tool lives exactly once
in home-manager:

- `modules/home/dev.nix` — dev/DevOps toolchain (go, rust via rustup, k8s, terraform, ...)
- `modules/home/packages.nix` — general CLI tools and terminal extras
- `modules/home/language-servers.nix` — LSP servers, formatters, linters per language

To add or remove a tool, touch the one matching file above.

## Theme (`modules/home/theme.nix`)

The Everforest palette is defined once and exposed to all home modules as the
`palette` module argument. btop, fzf, lazygit, and nvim consume it — switching
themes means editing this single file.

## WSL integration (`modules/core/wsl.nix`)

WSL networking is self-contained here: it sets `wslConf.network.generateHosts`
and `generateResolvConf` so the WSL-managed `/etc/hosts` and `/etc/resolv.conf`
are used. The upstream `network.nix` (NetworkManager + custom nameservers) is
**intentionally excluded** because it conflicts with this WSL networking model.

Other WSL settings (interop, systemd, `useWindowsDriver`) are configured via the
`nixos-wsl` flake input's `nixosModules.default`. Tune them in
`hosts/wsl/default.nix` or `modules/core/wsl.nix`.

## System polish (`modules/core/system.nix`)

Portable system settings ported from upstream, minus anything already owned by
`nix.nix`, `flake.nix` (`allowUnfree`), or `hosts/wsl/default.nix`
(`stateVersion`):

- `time.timeZone` (default `Europe/Berlin`)
- `i18n.defaultLocale` + `extraLocaleSettings` (default `en_US.UTF-8`)
- `console.keyMap` (default `de`)

Adjust these to your locale in `modules/core/system.nix`.

## Shell (`modules/home/zsh/`)

A full zsh setup with FZF-Tab, history settings, completion init, and
WSL-specific fixes (mouse-tracking guard under `WSL_DISTRO_NAME`, GPG_TTY,
SSH key auto-load). `direnv` and `zoxide` live here too.

Notable aliases (repo-aware for this WSL repo):

- `cdnix` - `cd ~/Code/MoshPitCodes/moshpitcodes.wsl.nix`
- `ns` / `rebuild` - rebuild this flake with `--impure` (must run from the
  repo root; a missing `secrets.nix` fails evaluation)
- `winhome` - `cd /mnt/c/Users`

The repo `justfile` provides the same operations outside zsh:
`just rebuild` / `test` / `build` / `update` / `fmt` / `lint` / `check`.

## Editor (nvf)

`modules/home/nvim.nix` enables `nvf` (a Neovim distribution) via the `nvf`
flake input. `vimAlias`/`viAlias` provide `nvim`/`vi`; nvf supplies the neovim
package itself (plain `vim` in `modules/core/packages.nix` is only the root
bootstrap fallback).

Language enablement is synchronized with `modules/home/language-servers.nix`
through the `_module.args.lspLanguages` arg — change a language flag in
`language-servers.nix` and both the LSP servers and the nvf language module
update together.

## Secrets

See [SECRETS.md](../SECRETS.md). Secrets are file-based (`secrets.nix`),
loaded impurely, so rebuilds use `--impure`. API keys are optional; agents read
them from the environment at runtime (Doppler aliases) when not baked in.

## Coding agents (`modules/home/coding-agents/`)

Claude Code, Codex, Kilo, Kiro, OpenCode, Pi, Antigravity, agent-browser (Playwright), and
T3 Code (a web GUI over the CLI agents — `t3`, no key of its own).
Most install themselves on first activation via native/npm installers so they
can self-update. API keys (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`,
`OPENROUTER_API_KEY`) are injected once in `coding-agents/default.nix` from
`customsecrets.apiKeys.*` (optional) — or loaded from Doppler at runtime via
the `*-doppler` aliases. Removing an agent is a one-line deletion in the
`imports` list of `coding-agents/default.nix`.

### MCP servers

`coding-agents/mcp-servers.nix` is the single source of truth: plain data, not a
module. Each agent module imports it and renders it into that agent's own
format, so a server is declared once and reaches every agent.

The official [Linear MCP server](https://linear.app/docs/mcp) is configured at
`https://mcp.linear.app/mcp` using Streamable HTTP. Each harness uses its native
remote transport; no API key or `mcp-remote` bridge is needed.

| Agent | Global configuration surface |
| --- | --- |
| Claude Code | `~/.claude/skills/mcp-servers/.mcp.json`, loaded as the personal `mcp-servers` skills-directory plugin |
| Codex | `-c mcp_servers.<name>.url=…` in the wrapper; its mutable `~/.codex/config.toml` stays writable |
| OpenCode (v2) | `~/.config/opencode/opencode.json`, under `mcp.servers` |
| Kilo | `~/.config/kilo/kilo.json`, under `mcp` |
| Kiro | `~/.kiro/settings/mcp.json`, under `mcpServers` |
| Pi | `~/.pi/agent/mcp.json`, under `mcpServers` (built-in MCP support in the current `@earendil-works/pi-coding-agent`) |
| Antigravity CLI | `~/.gemini/config/mcp_config.json`, under `mcpServers` with `serverUrl` |

T3 Code uses the configuration of the underlying CLI agent. `agent-browser` is
an automation tool, not an MCP client, so it needs no server configuration.

Authentication is deliberately **not** declarative. The Nix store is
world-readable, so no token belongs in any file here. Each harness requires a
one-time browser-based OAuth login, with credentials stored outside these
Home Manager files:

```bash
# After rebuilding, authenticate the harnesses you use:
codex mcp login linear
opencode mcp auth linear
kilo mcp auth linear
pi mcp login linear
```

For Claude Code, open `/mcp` inside a session and authenticate the Linear server
provided by the `mcp-servers` plugin (plugin server names are namespaced).
For Kiro, use `/mcp` and its authentication action (`/mcp auth` to retry).
For Antigravity, use `/mcp` and follow the server's authorization prompt.

Adding a server means one entry in `mcp-servers.nix` and a rebuild — all seven
harnesses consume the shared list. Home Manager owns the generated JSON files;
make server changes here, rather than using CLI add/remove commands or UI
config editing on those files. OAuth login remains interactive and writable.
If a target file already exists outside Home Manager, merge its custom entries
into the Nix configuration and move the old file aside before activating;
these new declarations deliberately do not force-overwrite existing files.

## NAS mount (`modules/core/nas-mount.nix`, `modules/core/samba.nix`)

The UGREEN NAS is mounted lazily at `/mnt/ugreen-nas` via CIFS, ported from the
upstream `moshpitcodes.nix` desktop/laptop hosts. The mount uses
`noauto` + `x-systemd.automount` + `_netdev` + `nofail`, so it only mounts on
first access and never blocks WSL boot when the network or NAS is unavailable.
Credentials are written to `/root/.secrets/samba-credentials` at activation
from `customsecrets.samba` (the script runs only when the `samba` block exists).
Avahi/mDNS from upstream is omitted: WSL NAT makes mDNS unreliable and the
share is addressed by IP (`customsecrets.nas.host`).

Configure in `secrets.nix`:

```nix
nas = { host = "192.168.178.144"; share = "personal_folder"; };
samba = { username = "nas-user"; password = "nas-password"; domain = "WORKGROUP"; };
```

Without a `nas` block the mount is not declared at all; without a `samba`
block the credential file is not written. Both modules are safe no-ops until
the secrets exist.

## NAS-dependent modules (inert by default)

- `modules/home/gpg.nix` - copies a backed-up `.gnupg` directory on activation.
  Active only when `customsecrets.gpgDir` is set.
- `modules/home/backup-repos.nix` - daily `~/Code` rsync to a NAS path
  with a systemd user service + timer. Active only when
  `customsecrets.backup.nasBackupPath` is non-empty. The `rsync --delete` run is
  guarded by a safety marker: create
  `touch <nasBackupPath>/.moshpit-backup-target` once on the NAS, otherwise the
  backup aborts (non-destructively) until the marker exists.

Without a `nas` block in `secrets.nix` the NAS mount is not declared, and
without `gpgDir` / `backup.nasBackupPath` both modules above stay disabled.
A missing `secrets.nix` fails evaluation entirely (see SECRETS.md).

## Overlays

`overlays/default.nix` aggregates local package overlays:

- `sidecar`, `td` — Go CLIs built from pinned flake inputs (bumping means
  updating the input tag in `flake.nix` *and* the overlay's `version` +
  `vendorHash`)
- `terraform` — pins an official binary release ahead of nixpkgs; delete once
  nixpkgs catches up
- `cpplint` — skips a broken upstream test suite
- `switch-to-configuration` — WSL DBus fix for `switch-to-configuration-ng`
