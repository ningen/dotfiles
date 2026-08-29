---
name: nix-env-maintainer
description: Maintain and troubleshoot the ningen/dotfiles Nix environment. Use when editing flake.nix, flake.lock, nix/hosts, nix/packages, Home Manager modules, nix-darwin settings, package lists, language servers, formatters, or when diagnosing nix flake check, home-manager, darwin-rebuild, or nix run .#switch failures.
---

# Nix Env Maintainer

Use this workflow for the personal Nix Flake, Home Manager, and nix-darwin configuration in `/Users/ningen/ghq/github.com/ningen/dotfiles`.

## Orientation

- Read `flake.nix` first to identify affected systems and host configurations.
- For common user packages and shell behavior, inspect `nix/hosts/common/home.nix` and the relevant file under `nix/packages/`.
- For macOS system changes, inspect `nix/hosts/ningen-mba/macos.nix`.
- For WSL-specific settings (clipboard bridge, open bridge, Emacs socket activation), inspect `nix/hosts/wsl/home.nix`.
- For npm CLI packages managed through Nix, use `nix/packages/node-packages.nix`; prefer `buildNpmPackage` for npm tarballs and Flake inputs when upstream exports packages.

## Editing Rules

1. Keep platform-specific packages guarded with `lib.optionals pkgs.stdenv.isLinux` or the appropriate Darwin/Linux module.
2. Prefer existing module boundaries: shared Home Manager settings in `nix/hosts/common`, package collections in `nix/packages`, WSL settings in `nix/hosts/wsl`, macOS system defaults in `nix/hosts/ningen-mba`.
3. Keep generated files untouched unless regenerating them with the documented generator.
4. When adding a CLI tool, decide whether it belongs in `nix/packages/dev-tools.nix`, `language-servers.nix`, `formatters.nix`, or node2nix-managed packages.
5. When current package or option names are uncertain, verify them with the available web search or official Nix documentation before editing.

## Verification

Use the narrowest check that matches the change:

```bash
nix flake check
nix build .#homeConfigurations."ningen@$HOSTNAME".activationPackage
nix build .#darwinConfigurations.ningen.system
```

Run `nix run .#switch` or `nix run .#update-lock` only when the user wants to apply the configuration on the current machine.
