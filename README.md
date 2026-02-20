# nix-apps

A configurable app framework for Nix flakes. Provides interactive build, switch, rollback, push, and update workflows with generation tagging and commit suggestions.

## Usage

Add to your `flake.nix`:

```nix
{
  inputs.nix-apps.url = "github:szympajka/nix-apps";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.nix-apps.flakeModule ];

      perSystem = { system, ... }: {
        nix-apps = {
          enable = true;
          flakeAttr = "darwinConfigurations.${system}.system";
          # systemType defaults to the current system, override if needed:
          # systemType = "aarch64-darwin";
        };
      };
    };
}
```

Then run apps with `nix run .#menu`, `nix run .#build-switch`, etc.

## Built-in apps

| App | Description |
|---|---|
| `menu` | Interactive app picker |
| `build` | Build only (no switch) |
| `build-switch` | Build, switch, and tag generation — suggests a commit if tree is dirty |
| `rollback` | Roll back to a previous generation |
| `push` | Review and push local commits to remote |
| `update-flake` | Interactive or CLI-driven flake input updater |

## Customisation

### Pick which apps to include

```nix
nix-apps.enabledApps = [ "build-switch" "push" "menu" ];
```

### Add your own apps

```nix
nix-apps.extraApps = {
  my-script = ./apps/my-script;
};
```

Your script gets the same `PATH` (git, gum, jq) and env vars (`NIXAPPS_SYSTEM_TYPE`, `NIXAPPS_FLAKE_ATTR`). Source `lib.sh` from the nix-apps scripts dir for shared helpers.

### Add extra packages to PATH

```nix
nix-apps.extraPackages = [ pkgs.ripgrep ];
```
