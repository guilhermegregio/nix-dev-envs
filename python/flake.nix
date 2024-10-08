{
  description = "A Nix-flake-based Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:/DavHau/mach-nix";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , mach-nix
    }:

    flake-utils.lib.eachDefaultSystem (system:
    let
      overlays = [
        (self: super: {
          machNix = mach-nix.defaultPackage.${system};
          python = super.python311;
        })
      ];

      pkgs = import nixpkgs { inherit overlays system; };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ python machNix  ] ++
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
