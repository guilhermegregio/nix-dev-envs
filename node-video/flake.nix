{
  description = "A Nix-flake-based Node.js video development environment (ffmpeg, headless browser, uv)";

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
          nodejs = super.nodejs_24;
          pnpm = super.pnpm;
        })
      ];
      pkgs = import nixpkgs { inherit overlays system; };

      fontsConf = pkgs.makeFontsConf {
        fontDirectories = with pkgs; [
          inter
          dejavu_fonts
          noto-fonts
          noto-fonts-color-emoji
        ];
      };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs
          pnpm
          ffmpeg-full
          playwright-driver.browsers
          uv
          python312
          yt-dlp
          jq
          yq-go
          inter
          dejavu_fonts
          noto-fonts
          noto-fonts-color-emoji
        ];

        shellHook = ''
          export FONTCONFIG_FILE=${fontsConf}

          export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
          export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

          unset HYPERFRAMES_BROWSER_PATH
          for candidate in \
            "$PLAYWRIGHT_BROWSERS_PATH"/chromium_headless_shell-*/chrome-linux/headless_shell \
            "$PLAYWRIGHT_BROWSERS_PATH"/chromium_headless_shell-*/chrome-linux64/headless_shell \
            "$PLAYWRIGHT_BROWSERS_PATH"/chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell; do
            if [ -x "$candidate" ]; then
              export HYPERFRAMES_BROWSER_PATH="$candidate"
              break
            fi
          done

          export HYPERFRAMES_EXTRACT_CACHE_DIR="$HOME/.cache/hyperframes/extract"
          export HYPERFRAMES_NO_TELEMETRY=1
          export HYPERFRAMES_NO_UPDATE_CHECK=1
          export HYPERFRAMES_SKIP_SKILLS=1
          mkdir -p "$HYPERFRAMES_EXTRACT_CACHE_DIR"

          export UV_PYTHON=${pkgs.python312}/bin/python3
          export UV_PYTHON_DOWNLOADS=never

          export PNPM_HOME="$HOME/.pnpm"
          export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"

          export PATH="$PWD/node_modules/.bin/:$PATH"

          echo "node `${pkgs.nodejs}/bin/node --version`"
          echo "`${pkgs.ffmpeg-full}/bin/ffmpeg -hide_banner -version | head -n1`"
          echo "`${pkgs.uv}/bin/uv --version`"
          if [ -n "''${HYPERFRAMES_BROWSER_PATH:-}" ]; then
            echo "headless_shell: $HYPERFRAMES_BROWSER_PATH"
          else
            echo "aviso: headless_shell não encontrado em $PLAYWRIGHT_BROWSERS_PATH (HYPERFRAMES_BROWSER_PATH não definido)"
          fi
        '';
      };
    });
}
