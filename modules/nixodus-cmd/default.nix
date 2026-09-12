{ inputs, self, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    let
      nixodus = self'.packages.nixodus;
    in
    {
      checks.nixodus = nixodus;

      apps.nixodus = {
        inherit (nixodus) meta;
        program = nixodus;
      };

      packages.nixodus = pkgs.callPackage ./_src {
        nixodusRev = self.rev;
        nixpkgsRev = inputs.nixpkgs.rev;
      };
    };
}
