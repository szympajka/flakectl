# nix-apps

A configurable app framework for Nix flakes. Provides interactive build, switch, rollback, push, and update workflows with generation tagging and commit suggestions.

Works with both nix-darwin and NixOS — platform is auto-detected from your system type.

## Usage

Add to your `flake.nix`:

```nix
{
  inputs.nix-apps.url = "github:szympajka/nix-apps";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" ];
      imports = [ inputs.nix-apps.flakeModule ];

      perSystem = { system, ... }: {
        nix-apps = {
          enable = true;
          buildTarget = "darwinConfigurations.${system}.system";
        };
      };
    };
}
```

Then: `nix run .#menu`, `nix run .#build-switch`, etc.

## Built-in apps

| App | Description |
|---|---|
| `menu` | Interactive app picker — auto-discovers all registered apps |
| `build` | Build only (no switch) |
| `build-switch` | Build, switch, tag generation — suggests a commit if tree is dirty |
| `rollback` | Roll back to a previous generation |
| `push` | Review and push local commits to remote |
| `update-flake` | Interactive or CLI-driven flake input updater |

## Customisation

### Pick which built-in apps to include

```nix
nix-apps.enabledApps = [ "build-switch" "push" "menu" ];
```

### Add your own apps

```nix
nix-apps.extraApps = {
  deploy = ./apps/deploy;
};
```

Custom apps get the same `PATH` (git, gum, jq) and env vars (`NIXAPPS_SYSTEM`, `NIXAPPS_PLATFORM`, `NIXAPPS_FLAKE_ATTR`). They also appear in the menu automatically.

### Add extra packages to PATH

```nix
nix-apps.extraPackages = [ pkgs.ripgrep ];
```

### Override platform detection

Platform is auto-detected (`*-darwin` → darwin, otherwise → nixos), but you can override:

```nix
nix-apps.platform = "nixos";
```

## Environment variables available to scripts

| Variable | Description | Example |
|---|---|---|
| `NIXAPPS_SYSTEM` | Nix system string | `aarch64-darwin` |
| `NIXAPPS_PLATFORM` | `darwin` or `nixos` | `darwin` |
| `NIXAPPS_FLAKE_ATTR` | Flake attribute to build (from `buildTarget`) | `darwinConfigurations.aarch64-darwin.system` |

## Commit suggestion

When `build-switch` detects a dirty git tree, it suggests a conventional commit message based on changed file paths. Scope is inferred from the parent directory:

| Changed file | Suggested scope |
|---|---|
| `modules/darwin/homebrew/casks.nix` | `homebrew` |
| `modules/darwin/services.nix` | `darwin` |
| `apps/aarch64-darwin/build` | `aarch64-darwin` |
| `flake.nix` | `flake` |

Multiple files in the same scope → single scoped message. Mixed scopes → scope omitted.

## Testing

```bash
bash tests/lib_test.sh
```
