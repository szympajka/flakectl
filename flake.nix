{
  description = "A gum-powered menu that runs your Nix flake for you.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs: {
    flakeModule = import ./module.nix {inherit inputs;};
  };
}
