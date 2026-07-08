{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-appimage.url = "github:ralismark/nix-appimage";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{
      flake-parts,
      systems,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (top: {
      systems = import systems;

      flake.lib.mkNixodus =
        {
          crossPackages,
          crossSystem,
          nix-appimage,
          pkgs,
        }:
        pkgs.callPackage ./mkNixodus.nix {
          inherit crossPackages;
          inherit crossSystem;
          inherit nix-appimage;
        };

      perSystem =
        {
          pkgs,
          self',
          system,
          ...
        }:
        {
          apps = {
            nixodus.program = pkgs.buildGoModule {
              name = "nixodus-cmd";
              src = ./cmd/nixodus;
              vendorHash = null;
              meta.mainProgram = "nixodus";
            };

            default = self'.apps.nixodus;
          };

          packages = {
            nixodus-test = top.config.flake.lib.mkNixodus {
              inherit (inputs) nix-appimage;
              inherit pkgs;
              crossSystem = system;

              crossPackages =
                crossPkgs: with crossPkgs; [
                  hello
                  postgresql
                  sqlite
                ];
            };
          };
        };
    });
}
