{
  description = "A Nix-flake-based Node.js video environment for macOS (ffmpeg, whisper.cpp, uv; Chrome managed by HyperFrames)";

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

      # Wheels binárias do PyPI (numpy, scipy, librosa…) procuram libstdc++.so.6 e
      # libz.so.1 por dlopen. Inofensivo no macOS, necessário no NixOS.
      pythonWheelLibs = pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
      ];

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
          whisper-cpp
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

          # Browser: NÃO usar o headless_shell do Playwright nem o Chrome do sistema.
          # O caminho rápido do HyperFrames (beginFrame + canvas.drawElementImage) só
          # existe no chrome-headless-shell pinado que o próprio CLI baixa com
          # `hyperframes browser ensure` (~/.cache/hyperframes/chrome). Por isso
          # HYPERFRAMES_BROWSER_PATH fica propositalmente indefinido aqui.
          unset HYPERFRAMES_BROWSER_PATH PRODUCER_HEADLESS_SHELL_PATH
          export PRODUCER_BROWSER_GPU_MODE=hardware   # macOS: software-only Chrome estoura timeout

          export HYPERFRAMES_EXTRACT_CACHE_DIR="$HOME/.cache/hyperframes/extract"
          export HYPERFRAMES_NO_TELEMETRY=1
          export HYPERFRAMES_NO_UPDATE_CHECK=1
          export HYPERFRAMES_SKIP_SKILLS=1            # `init` não checa/instala skills; use `hyperframes skills update`
          export HYPERFRAMES_WHISPER_PATH=${pkgs.whisper-cpp}/bin/whisper-cli   # evita `brew install whisper-cpp`
          mkdir -p "$HYPERFRAMES_EXTRACT_CACHE_DIR"

          export UV_PYTHON=${pkgs.python312}/bin/python3
          export UV_PYTHON_DOWNLOADS=never
          export LD_LIBRARY_PATH="${pythonWheelLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

          export PNPM_HOME="$HOME/.pnpm"
          export PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"
          export PATH="$PWD/node_modules/.bin/:$PATH"

          echo "node `${pkgs.nodejs}/bin/node --version`"
          echo "`${pkgs.ffmpeg-full}/bin/ffmpeg -hide_banner -version | head -n1`"
          echo "`${pkgs.uv}/bin/uv --version`"
          echo "whisper-cli: $HYPERFRAMES_WHISPER_PATH"
          if ls "$HOME/.cache/hyperframes/chrome" >/dev/null 2>&1; then
            echo "chrome (hyperframes): $HOME/.cache/hyperframes/chrome ($(ls "$HOME/.cache/hyperframes/chrome" | tr '\n' ' '))"
          else
            echo "aviso: Chrome pinado do HyperFrames ausente — rode \`hyperframes browser ensure\`"
          fi
        '';
      };
    });
}
