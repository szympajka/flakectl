{
  description = "Configurable app framework for Nix flakes — build, switch, rollback, push, and more.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs: {
    flakeModule = import ./module.nix {inherit inputs;};
  };
}
