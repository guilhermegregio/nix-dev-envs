{
  description = "Python development environment - minimal version";

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
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      python = pkgs.python311;

    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          # Python base
          python
          python.pkgs.pip
          python.pkgs.virtualenv
          python.pkgs.setuptools
          python.pkgs.wheel

          # Ferramentas úteis
          curl
          git
          cacert

          # Dependências de sistema
          gcc
          gnumake
          openssl
          libffi
          zlib
        ] ++ lib.optionals stdenv.isDarwin [
          darwin.apple_sdk.frameworks.CoreServices
          darwin.apple_sdk.frameworks.CoreFoundation
        ];

        shellHook = ''
          echo "🐍 Python Development Environment (Minimal)"
          echo "=========================================="
          echo "Python: $(python --version)"
          echo ""

          # Configurações para certificados
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

          # Detectar Netskope
          for cert in "/Library/Application Support/Netskope/STAgent/data/nscacert.pem" "$HOME/Library/Application Support/Netskope/STAgent/data/nscacert.pem"; do
            if [ -f "$cert" ]; then
              echo "📡 Certificado Netskope: $cert"
              export REQUESTS_CA_BUNDLE="$cert"
              export PIP_CERT="$cert"
              break
            fi
          done

          # Garantir que temos pip atualizado
          export PATH="$HOME/.local/bin:$PATH"

          # Função para instalar PDM
          install_pdm() {
            echo "📦 Instalando PDM..."
            python -m pip install --user --upgrade pdm
            echo "✅ PDM instalado em $HOME/.local/bin/pdm"
          }

          # Função para criar venv
          create_venv() {
            python -m venv .venv
            source .venv/bin/activate
            pip install --upgrade pip setuptools wheel
          }

          # Ativar venv se existir
          if [ -d ".venv" ]; then
            source .venv/bin/activate
          fi

          # Verificar se PDM está instalado
          if ! command -v pdm &> /dev/null; then
            echo "💡 PDM não encontrado. Instale com: install_pdm"
          else
            echo "✅ PDM disponível: $(pdm --version)"
          fi

          echo ""
          echo "💡 Comandos disponíveis:"
          echo "  - install_pdm    # Instalar PDM via pip"
          echo "  - create_venv    # Criar ambiente virtual"
          echo ""
        '';
      };
    });
}
