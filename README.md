# flakectl

A small, opinionated TUI for managing your Nix flake. Build, switch, rollback, push, update — all through an interactive [gum](https://github.com/charmbracelet/gum)-powered menu. Tags every generation in git so you always know which commit produced which system state.

Works with nix-darwin and NixOS. Platform is auto-detected.

> I've only tested this on darwin so far. NixOS support is there but unverified — if something's off, please [open an issue](https://github.com/szympajka/flakectl/issues) or send a PR.

## Why

I got tired of running `nix build`, `darwin-rebuild switch`, tagging, pushing — all manually, every time. I wanted a single `nix run .#menu` that gives me a nice picker and handles the boring bits. I also wanted my git tree to be clean before every build, so flakectl suggests a commit message from the diff when it's not.

This started as a few shell scripts in my [nix config](https://github.com/szympajka/nixos-config). It grew into something reusable, so here we are.

## Credits

This project wouldn't exist without [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config). I used Dustin's project to bootstrap my own nix setup — the app scripts, the per-architecture layout, the whole approach to managing darwin and NixOS from one repo. It's a fantastic starting point and I can't recommend it enough. ❤️

## Getting started

Add flakectl to your `flake.nix`:

```nix
{
  inputs.flakectl.url = "github:szympajka/flakectl";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" ];
      imports = [ inputs.flakectl.flakeModule ];

      perSystem = { system, ... }: {
        flakectl = {
          enable = true;
          # The flake attribute that produces your system derivation.
          # For nix-darwin it's typically this. For NixOS: nixosConfigurations.<host>.config.system.build.toplevel
          buildTarget = "darwinConfigurations.${system}.system";
        };
      };
    };
}
```

Then run `nix run .#menu` and pick what you need.

## Built-in apps

| App | What it does |
|---|---|
| `menu` | Interactive picker — auto-discovers all registered apps |
| `build` | Build only, no switch |
| `build-switch` | Build, switch, tag the generation — suggests a commit if tree is dirty |
| `rollback` | Roll back to a previous generation |
| `push` | Review stacked local commits and push to remote |
| `update-flake` | Update flake inputs — interactive or via CLI flags |

## Make it yours

### Pick which apps you want

```nix
flakectl.enabledApps = [ "build-switch" "push" "menu" ];
```

### Add your own

```nix
flakectl.extraApps = {
  deploy = ./apps/deploy;
};
```

Your scripts get the same `PATH` (git, gum, jq) and env vars. They show up in the menu automatically — no extra wiring.

### Extra packages in PATH

```nix
flakectl.extraPackages = [ pkgs.ripgrep ];
```

### Override platform detection

Auto-detected from your system string, but you can force it:

```nix
flakectl.platform = "nixos";
```

## How commit suggestion works

When `build-switch` finds a dirty git tree, it parses the changed file paths and generates a conventional commit message. Scope comes from the parent directory:

- `modules/darwin/homebrew/casks.nix` → `chore(homebrew): update casks`
- `modules/darwin/services.nix` → `chore(darwin): update services`
- `flake.nix` → `chore(flake): update flake`

You can accept it, edit it, or abort. Nothing gets committed without your say-so.

## Environment variables

Scripts (both built-in and your own) get these:

| Variable | Example |
|---|---|
| `FLAKECTL_SYSTEM` | `aarch64-darwin` |
| `FLAKECTL_PLATFORM` | `darwin` |
| `FLAKECTL_FLAKE_ATTR` | `darwinConfigurations.aarch64-darwin.system` |

## Testing

```bash
bash tests/lib_test.sh
```
