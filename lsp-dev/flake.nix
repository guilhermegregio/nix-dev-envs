{
  description = "A Nix-flake-based LSP servers and formatters environment (Zed-friendly)";

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
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          # Web / JS / TS
          vtsls
          biome
          tailwindcss-language-server
          vscode-langservers-extracted

          # Nix
          nixd
          nil
          nixfmt

          # YAML / Markdown / Shell
          yaml-language-server
          marksman
          bash-language-server
          shellcheck
        ];

        shellHook = ''
          echo "lsp-dev shell loaded"
        '';
      };
    });
}
