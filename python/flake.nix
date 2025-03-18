{
  description = "A Nix-flake-based Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
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
        (self: super: {
          python = super.python311;
        })
      ];

      pkgs = import nixpkgs { inherit overlays system; };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ python poetry  ] ++
          (with pkgs.python311Packages; [ pip virtualenv ipython ]);

        shellHook = ''
          ${pkgs.python}/bin/python --version

          # Activate virtual environmnet if exists
          VENV=.venv
          if test -d $VENV; then
            source ./$VENV/bin/activate
          fi

        '';
      };
    });
}
