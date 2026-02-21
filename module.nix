{inputs}: let
  flake-parts = inputs.flake-parts;
  scriptsDir = ./scripts;
  builtinApps = ["build" "build-switch" "menu" "push" "rollback" "update-flake"];
  appDescriptions = {
    menu = "Interactive app picker that auto-discovers flake apps.";
    build = "Build only (no switch).";
    "build-switch" = "Build and switch configuration, then tag generation.";
    rollback = "Roll back to a previous generation.";
    push = "Review and push local commits to remote.";
    "update-flake" = "Interactive or CLI-driven flake input updater.";
  };
in {
  options.perSystem = flake-parts.lib.mkPerSystemOption ({
    pkgs,
    lib,
    system,
    config,
    ...
  }: {
    options.flakectl = {
      enable = lib.mkEnableOption "flakectl framework";

      buildTarget = lib.mkOption {
        type = lib.types.str;
        description = "Flake attribute to build, e.g. darwinConfigurations.aarch64-darwin.system";
        example = "darwinConfigurations.aarch64-darwin.system";
      };

      platform = lib.mkOption {
        type = lib.types.enum ["darwin" "nixos"];
        default =
          if lib.hasSuffix "darwin" system
          then "darwin"
          else "nixos";
        description = "Platform type. Auto-detected from system, but can be overridden.";
      };

      enabledApps = lib.mkOption {
        type = lib.types.listOf (lib.types.enum builtinApps);
        default = builtinApps;
        description = "Which built-in apps to include. Defaults to all.";
      };

      extraApps = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = {};
        description = "Additional app scripts to register. Attrname becomes the app name, value is the script path.";
        example = lib.literalExpression ''{ my-script = ./apps/my-script; }'';
      };

      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Extra packages to add to the app scripts PATH.";
      };
    };

    config = let
      cfg = config.flakectl;

      runtimePath = lib.makeBinPath ([pkgs.git pkgs.gum pkgs.jq] ++ cfg.extraPackages);

      wrapScript = name: scriptPath: description: let
        wrapper = pkgs.writeScriptBin name ''
          #!/usr/bin/env bash
          export PATH=${runtimePath}:$PATH
          export FLAKECTL_SYSTEM=${lib.escapeShellArg system}
          export FLAKECTL_PLATFORM=${lib.escapeShellArg cfg.platform}
          export FLAKECTL_FLAKE_ATTR=${lib.escapeShellArg cfg.buildTarget}
          echo "Running ${name} for ${system}"
          exec ${scriptPath} "$@"
        '';
      in {
        type = "app";
        program = "${wrapper}/bin/${name}";
        meta.description = description;
      };

      builtinAppSet = lib.listToAttrs (map (name: {
        inherit name;
        value = wrapScript name "${scriptsDir}/${name}" appDescriptions.${name};
      }) cfg.enabledApps);

      extraAppSet = lib.mapAttrs (name: path: wrapScript name (toString path) "Custom flakectl app: ${name}.") cfg.extraApps;
    in
      lib.mkIf cfg.enable {
        apps = builtinAppSet // extraAppSet;
      };
  });
}
