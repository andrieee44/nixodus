{ inputs, ... }: {
  perSystem =
    {
      lib,
      pkgs,
      self',
      system,
      ...
    }:
    {
      legacyPackages.nixodus =
        { crossPackages, crossSystem }:
        pkgs.callPackage ./_src {
          inherit (inputs) nix-appimage;
          inherit crossPackages crossSystem;
        };

      checks =
        let
          nixmax = inputs.nixmax.legacyPackages."${system}";

          crossPkgs =
            system:
            import pkgs.path {
              inherit (pkgs.stdenv.buildPlatform) system;
              crossSystem = system;
            };

          nixodusBuild =
            system:
            self'.legacyPackages.nixodus {
              crossSystem = system;

              crossPackages =
                crossPkgs: with crossPkgs; [
                  hello
                  postgresql
                  sqlite
                ];
            };

          nixodusTest =
            system:
            lib.getExe (
              (crossPkgs system).writeShellApplication {
                name = "nixodus-test";
                runtimeInputs = [ (nixodusBuild system) ];

                text = ''
                  modprobe fuse
                  pg_ctl --version

                  for program in hello postgres psql sqlite3; do
                    nixodus-packages "$program" --version
                  done
                '';
              }
            );
        in
        {
          nixodus-x86_64-linux = nixmax.nixmax-alpine-x86_64 (nixodusTest "x86_64-linux");
          nixodus-aarch64-linux = nixmax.nixmax-alpine-aarch64 (nixodusTest "aarch64-linux");
          nixodus-riscv64-linux = nixmax.nixmax-alpine-riscv64 (nixodusTest "riscv64-linux");
        };
    };
}
