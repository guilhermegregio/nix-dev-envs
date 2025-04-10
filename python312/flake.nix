{
  description =
    "A Nix-flake-based Python 312 development environment with uv tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (self: super: { python = super.python312Full; }) ];

        pkgs = import nixpkgs { inherit overlays system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs;
            [ python uv ] ++ (with pkgs.python312Packages; [ numpy ipython ]);

          shellHook = ''
            ${pkgs.python}/bin/python --version

            # Activate virtual environmnet if exists
            # VENV=.venv
            # if test -d $VENV; then
            #   source ./$VENV/bin/activate
            # fi

          '';
        };
      });
}
