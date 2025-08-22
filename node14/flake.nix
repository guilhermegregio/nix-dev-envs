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
      # Nixpkgs com Node.js 14
      node14Pkgs = import (builtins.fetchGit {
        name = "nixpkgs-node14";
        url = "https://github.com/nixos/nixpkgs-channels/";
        ref = "refs/heads/nixpkgs-unstable";
        rev = "f76bef61369be38a10c7a1aa718782a60340d9ff";
      }) { inherit system; };

      overlays = [
        (self: super: rec {
          nodejs = node14Pkgs.nodejs-14_x;
        })
      ];
      pkgs = import nixpkgs { inherit overlays system; };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ node2nix nodejs ];

        shellHook = ''
          echo "node `${pkgs.nodejs}/bin/node --version`"
          export PATH="$PWD/node_modules/.bin/:$PATH"
        '';
      };
    });
}
