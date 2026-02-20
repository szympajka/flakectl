{inputs, ...}: {
  flake-parts,
  lib,
  self,
  ...
}: let
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
    options.nix-apps = {
      enable = lib.mkEnableOption "nix-apps framework";

      systemType = lib.mkOption {
        type = lib.types.str;
        default = system;
        description = "System type string, e.g. aarch64-darwin. Defaults to the current system.";
      };

      flakeAttr = lib.mkOption {
        type = lib.types.str;
        description = "Flake attribute to build, e.g. darwinConfigurations.aarch64-darwin.system";
      };

      enabledApps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
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
      cfg = config.nix-apps;

      runtimePath = lib.makeBinPath ([pkgs.git pkgs.gum pkgs.jq] ++ cfg.extraPackages);

      mkApp = name: scriptPath: {
        type = "app";
        program = "${(pkgs.writeScriptBin name ''
          #!/usr/bin/env bash
          export PATH=${runtimePath}:$PATH
          export NIXAPPS_SYSTEM_TYPE=${lib.escapeShellArg cfg.systemType}
          export NIXAPPS_FLAKE_ATTR=${lib.escapeShellArg cfg.flakeAttr}
          echo "Running ${name} for ${cfg.systemType}"
          exec ${scriptPath} "$@"
        '')}/bin/${name}";
      };

      builtinAppSet = lib.listToAttrs (map (name: {
        inherit name;
        value = mkApp name "${scriptsDir}/${name}";
      }) (lib.filter (n: lib.elem n cfg.enabledApps) builtinApps));

      extraAppSet = lib.mapAttrs (name: path: mkApp name (toString path)) cfg.extraApps;
    in
      lib.mkIf cfg.enable {
        apps = builtinAppSet // extraAppSet;
      };
  });
}
