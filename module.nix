{inputs}: let
  flake-parts = inputs.flake-parts;
  scriptsDir = ./scripts;
  builtinApps = ["build" "build-switch" "menu" "push" "rollback" "update-flake"];
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

      cli = {
        enable = lib.mkEnableOption "global flakectl CLI command";

        name = lib.mkOption {
          type = lib.types.str;
          default = "flakectl";
          description = "Name of the global CLI command.";
        };

        flakePath = lib.mkOption {
          type = lib.types.str;
          description = "Absolute path to your flake directory, e.g. /Users/you/nixos-config";
        };
      };
    };

    config = let
      cfg = config.flakectl;

      runtimePath = lib.makeBinPath ([pkgs.git pkgs.gum pkgs.jq] ++ cfg.extraPackages);

      wrapScript = name: scriptPath: let
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
      };

      builtinAppSet = lib.listToAttrs (map (name: {
        inherit name;
        value = wrapScript name "${scriptsDir}/${name}";
      }) cfg.enabledApps);

      extraAppSet = lib.mapAttrs (name: path: wrapScript name (toString path)) cfg.extraApps;

      cliPackage = pkgs.writeShellScriptBin cfg.cli.name ''
        cd ${lib.escapeShellArg cfg.cli.flakePath} && nix run ".#''${1:-menu}" -- "''${@:2}"
      '';
    in
      lib.mkIf cfg.enable {
        apps = builtinAppSet // extraAppSet;
        packages.${cfg.cli.name} = lib.mkIf cfg.cli.enable cliPackage;
      };
  });
}
