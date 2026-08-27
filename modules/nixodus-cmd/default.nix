{
  perSystem =
    {
      lib,
      pkgs,
      self',
      ...
    }:
    let
      nixodus = self'.packages.nixodus;
    in
    {
      checks.nixodus = nixodus;

      apps.nixodus = {
        inherit (nixodus) meta;
        program = nixodus;
      };

      packages.nixodus = pkgs.buildGoModule {
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
          description = "nixodus - NIX eXODUS - portable multicall binary builder";
          homepage = "https://github.com/andrieee44/nixodus";
          license = lib.licenses.agpl3Plus;
          mainProgram = "nixodus";
        };
      };
    };
}
