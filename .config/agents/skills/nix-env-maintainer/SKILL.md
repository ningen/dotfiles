---
name: nix-env-maintainer
description: Maintain and troubleshoot the ningen/dotfiles Nix environment. Use when editing flake.nix, flake.lock, nix/hosts, nix/packages, Home Manager modules, nix-darwin settings, NixOS configuration, package lists, language servers, formatters, or when diagnosing nix flake check, home-manager, darwin-rebuild, nixos-rebuild, or nix run .#update failures.
---

# Nix Env Maintainer

Use this workflow for the personal Nix Flake, Home Manager, nix-darwin, and NixOS configuration in `/Users/ningen/ghq/github.com/ningen/dotfiles`.

## Orientation

- Read `flake.nix` first to identify affected systems and host configurations.
- For common user packages and shell behavior, inspect `nix/hosts/common/home.nix` and the relevant file under `nix/packages/`.
- For macOS system changes, inspect `nix/hosts/ningen-mba/macos.nix`.
- For NixOS desktop, NVIDIA, input, service, or system package changes, inspect `nix/hosts/nixos/configuration.nix`.
- For npm CLI packages managed through Nix, use the node2nix workflow in `AGENTS.md`; never edit `nix/node2nix/node-packages.nix` by hand.

## Editing Rules

1. Keep platform-specific packages guarded with `lib.optionals pkgs.stdenv.isLinux` or the appropriate Darwin/Linux module.
2. Prefer existing module boundaries: shared Home Manager settings in `nix/hosts/common`, package collections in `nix/packages`, macOS system defaults in `nix/hosts/ningen-mba`, and NixOS system services in `nix/hosts/nixos`.
3. Keep generated files untouched unless regenerating them with the documented generator.
4. When adding a CLI tool, decide whether it belongs in `nix/packages/dev-tools.nix`, `language-servers.nix`, `formatters.nix`, or node2nix-managed packages.
5. When current package or option names are uncertain, use the repository guidance for web lookup:

```bash
gemini -p "WebSearch: <query>"
```

## Verification

Use the narrowest check that matches the change:

```bash
nix flake check
nix build .#homeConfigurations."ningen@$HOSTNAME".activationPackage
nix build .#darwinConfigurations.ningen.system
nix build .#nixosConfigurations.myNixOS.config.system.build.toplevel
```

Run `nix run .#update`, `sudo darwin-rebuild switch --flake .#ningen`, or `sudo nixos-rebuild switch --flake .#myNixOS` only when the user wants to apply the configuration on the current machine.
