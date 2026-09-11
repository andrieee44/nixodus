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

          nixodusTest =
            system:
            lib.getExe (
              (import pkgs.path {
                inherit (pkgs.stdenv.buildPlatform) system;
                crossSystem = system;
              }).writeShellApplication
                {
                  name = "nixodus-test-${system}";

                  runtimeInputs = [
                    (self'.legacyPackages.nixodus {
                      crossSystem = system;

                      crossPackages =
                        crossPkgs: with crossPkgs; [
                          coreutils
                          hello
                          postgresql
                          sqlite
                        ];
                    })
                  ];

                  text = ''
                    modprobe fuse
                    pg_ctl --version
                    [ "$(TESTVAR=1 printenv TESTVAR)" = "1" ]

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
