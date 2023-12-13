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
          nodejs = super.nodejs_18;
          pnpm = super.nodePackages.pnpm;
          yarn = (super.yarn.override { inherit nodejs; });
        })
      ];
      pkgs = import nixpkgs { inherit overlays system; };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ node2nix nodejs pnpm yarn ];

        shellHook = ''
          echo "node `${pkgs.nodejs}/bin/node --version`"
          export PATH="$PWD/node_modules/.bin/:$PATH"
        '';
      };
    });
}
