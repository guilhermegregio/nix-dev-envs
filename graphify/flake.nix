{
  description = "graphify - turn any folder of code/docs into a queryable knowledge graph";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # uv2nix toolchain: builds the Python app straight from graphify's uv.lock
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # graphify upstream source (provides pyproject.toml + uv.lock)
    graphify-src = {
      url = "github:safishamsi/graphify/v8";
      flake = false;
    };
  };

  outputs =
    { nixpkgs
    , flake-utils
    , uv2nix
    , pyproject-nix
    , pyproject-build-systems
    , graphify-src
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = nixpkgs.lib;

        # graphify requires Python >=3.10
        python = pkgs.python313;

        workspace = uv2nix.lib.workspace.loadWorkspace {
          workspaceRoot = graphify-src;
        };

        # Prefer prebuilt wheels (the tree-sitter parsers ship manylinux wheels
        # that get autoPatchelf'd for NixOS automatically).
        overlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel";
        };

        # Hook for per-package fixups, if any become necessary on updates.
        pyprojectOverrides = _final: _prev: { };

        pythonSet =
          (pkgs.callPackage pyproject-nix.build.packages {
            inherit python;
          }).overrideScope (lib.composeManyExtensions [
            pyproject-build-systems.overlays.default
            overlay
            pyprojectOverrides
          ]);

        # Self-contained venv exposing `graphify` and `graphify-mcp`.
        # `mcp` é extra opcional do graphify (graphifyy[mcp]) e é o que `graphify serve` /
        # `kb graph serve` precisam para expor o grafo via MCP stdio ao Claude Code.
        graphify = pythonSet.mkVirtualEnv "graphify-env" (workspace.deps.default // { graphifyy = [ "mcp" ]; });
      in
      {
        packages.default = graphify;
        packages.graphify = graphify;

        apps.default = {
          type = "app";
          program = "${graphify}/bin/graphify";
        };

        devShells.default = pkgs.mkShell {
          packages = [ graphify ];
          shellHook = ''
            echo "🕸️  graphify $(graphify --version 2>/dev/null | awk '{print $2}')"
            echo "   comandos: graphify install | graphify clone <url> | graphify-mcp"
          '';
        };
      });
}
