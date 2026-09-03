# Development Shells

This repository ships a Nix development shell for working on the flake itself.

## Default shell

**Usage:**
```bash
nix develop
# or explicitly
nix develop .#default
```

**Features:**
- Nix toolchain (`nil`, `nixfmt`)
- Version control (`git`, `just`)
- The formatter `nixfmt` (matches `formatter` in `flake.nix` and
  `treefmt.toml`)

## Formatting

The repository formatter is `nixfmt`, which implements RFC 166 style. The old
`nixfmt-rfc-style` attribute is now a deprecated alias for it. Format the whole
tree with:

```bash
nix fmt                # uses flake.nix `formatter`
# or
treefmt                # uses treefmt.toml (also nixfmt)
```

`treefmt.toml` is configured as:

```toml
[formatter.nix]
command = "nixfmt"
includes = ["*.nix"]
```

## Editor (nvf)

`modules/home/nvim.nix` enables `nvf`, an opinionated Neovim distribution, as
the system editor (`vimAlias`/`viAlias` provide `nvim`/`vi`). It is wired to
`modules/home/language-servers.nix` via `_module.args.lspLanguages`, so the LSP
servers enabled in `language-servers.nix` are also enabled as nvf language
modules.

To change which languages get LSP + treesitter + formatting, edit the
`languages` attrset in `modules/home/language-servers.nix`.

## Repo tasks (justfile)

The repo root ships a `justfile` with the common operations:

```bash
just              # list recipes
just rebuild      # nixos-rebuild switch --flake .#wsl --impure
just test         # activate without a boot entry
just build        # build the closure without activating (result symlink)
just update       # nix flake update
just fmt          # format all Nix files
just lint         # statix check + deadnix
just check        # nix flake check --impure
```

## Common commands

`--impure` is required whenever the NixOS configuration is evaluated, because
`secrets.nix` is git-ignored and resolved via `$PWD` (run from the repo root):

```bash
nix flake check --impure --show-trace   # validate the flake
nix flake update                        # update flake inputs
nix build .#nixosConfigurations.wsl.config.system.build.toplevel --impure --show-trace
nix develop --command echo ok           # smoke-test the dev shell
```

## Linting

CI (`.github/workflows/test-flake.yml`) runs `statix check`, `deadnix --fail`,
and a `nixfmt --check` pass on every PR — `just lint` and `just fmt`
run the same tools locally.
