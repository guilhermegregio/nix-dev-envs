{
  description = "A Nix-flake-based Node.js development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:

    flake-utils.lib.eachDefaultSystem (system:
    let
      overlays = [
        (self: super: rec {
          nodejs = super.nodejs_22;
          pnpm = super.pnpm;
          yarn = (super.yarn.override { inherit nodejs; });
        })
      ];
      pkgs = import nixpkgs { inherit overlays system; };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ nodejs pnpm yarn ];

        shellHook = ''
          echo "node `${pkgs.nodejs}/bin/node --version`"
          export PNPM_HOME="$HOME/.pnpm"
          export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"
          export PATH="$PWD/node_modules/.bin/:$PATH"
        '';
      };
    });
}
