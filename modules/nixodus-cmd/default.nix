{
  perSystem =
    { pkgs, self', ... }:
    let
      nixodus = self'.packages.nixodus;
    in
    {
      checks.nixodus = nixodus;
      packages.nixodus = pkgs.callPackage ./_src { };

      apps.nixodus = {
        inherit (nixodus) meta;
        program = nixodus;
      };
    };
}
