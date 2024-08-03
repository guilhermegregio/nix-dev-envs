{
  description = "A Nix-flake-based iOS Development environment with Kotlin KMP and other tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      javaVersion = 17;

      overlays = [
        (self: super: rec {
          jdk = super."jdk${toString javaVersion}";
          gradle = super.gradle.override {
            java = jdk;
          };
          kotlin = super.kotlin.override {
            jre = jdk;
          };
        })
      ];

      pkgs = import nixpkgs { inherit overlays system; };

      commonPackages = with pkgs; [
        gcc
        gradle
        kdoctor
        kotlin
        ncurses
        patchelf
        python3
        zlib
      ];
    in
    {
      devShells.default = pkgs.mkShell {
        packages = commonPackages;

        shellHook = ''
          echo "Ambiente de desenvolvimento pronto!"
          echo "Kotlin version:"
          ${pkgs.kotlin}/bin/kotlin -version

          echo "Python version:"
          ${pkgs.python3}/bin/python3 --version

          echo "Verificando a configuração com o KDoctor..."
          ${pkgs.kdoctor}/bin/kdoctor

          # Instrução para Xcode
          echo "Certifique-se de que o Xcode e as ferramentas de linha de comando estejam instalados e configurados corretamente."
        '';
      };
    });
}
