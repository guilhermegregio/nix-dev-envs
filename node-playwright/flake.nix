{
  description =
    "A Nix-flake-based Node.js + Playwright development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        nodejs = pkgs.nodejs_24;
        browsers = (builtins.fromJSON (builtins.readFile
          "${pkgs.playwright-driver}/browsers.json")).browsers;
        chromium-rev = (builtins.head
          (builtins.filter (x: x.name == "chromium") browsers)).revision;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            nodejs
            pkgs.pnpm
            pkgs.chromium
            pkgs.playwright-driver
            pkgs.playwright-driver.browsers
          ];

          shellHook = ''
            echo "node `${nodejs}/bin/node --version`"
            export PATH="$PWD/node_modules/.bin/:$PATH"
            export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
            export PLAYWRIGHT_NODEJS_PATH=${nodejs}/bin/node
            export PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH=${pkgs.playwright-driver.browsers}/chromium-${chromium-rev}/chrome-linux64/chrome
          '';
        };
      });
}
