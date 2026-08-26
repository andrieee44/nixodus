{
  perSystem =
    { pkgs, self', ... }:
    {
      checks.nixodus = self'.packages.nixodus;

      apps = {
        default = self'.apps.nixodus;

        nixodus = {
          inherit (self'.packages.nixodus) meta;
          program = self'.packages.nixodus;
        };
      };

      packages = {
        default = self'.packages.nixodus;

        nixodus = pkgs.buildGoModule {
          doCheck = true;
          name = "nixodus";
          src = ./_src;
          vendorHash = null;

          checkPhase = ''
            runHook preCheck
            go vet ./...
            runHook postCheck
          '';

          meta = {
            description = "CLI application for nixodus";
            mainProgram = "nixodus";
          };
        };
      };
    };
}
