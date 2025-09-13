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
            [ python uv autoPatchelfHook ]
            ++ (with pkgs.python312Packages; [ numpy ipython ]);

          buildInputs = with pkgs; [ stdenv.cc.cc.lib zlib openssl ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc
            pkgs.zlib
            pkgs.openssl
          ];

          shellHook = ''
            ${pkgs.python}/bin/python --version

            # Activate virtual environmnet if exists
            # VENV=.venv
            # if test -d $VENV; then
            #   source ./$VENV/bin/activate
            # fi

            # Auto-patchear node se existir
            NODE_PATH=".venv/lib/python3.12/site-packages/nodejs_wheel/bin/node"
            if [ -f "$NODE_PATH" ]; then
              echo "Patching node binary..."
              autoPatchelf "$NODE_PATH" 2>/dev/null || true
            fi
          '';
        };
      });
}
