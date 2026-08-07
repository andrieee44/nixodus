{
  crossPackages,
  crossSystem,
  lib,
  nix-appimage,
  pkgs,
}:
let
  crossPkgs = import pkgs.path {
    inherit (pkgs.stdenv.buildPlatform) system;
    inherit crossSystem;
  };

  buildPackages = crossPkgs.buildPackages;

  codegen = buildPackages.buildGoModule {
    meta.mainProgram = "codegen";
    name = "nixodus-codegen";
    src = ./cmd/codegen;
    vendorHash = null;
  };

  target-packages = buildPackages.writeText "nixodus-target-packages" (
    builtins.toJSON (crossPackages crossPkgs)
  );

  nixodus-packages = crossPkgs.stdenv.mkDerivation {
    dontUnpack = true;
    meta.mainProgram = "nixodus-packages";
    name = "nixodus-packages";

    nativeBuildInputs = [
      buildPackages.gperf
      codegen
    ];

    buildPhase = ''
      mkdir -p "$out/bin"

      "${lib.getExe codegen}" "$out/bin" \
        < "${target-packages}" > "nixodus-packages.gperf"

      gperf "nixodus-packages.gperf" --output-file "nixodus-packages.c"
      $CC -o "$out/bin/nixodus-packages" "nixodus-packages.c"
    '';
  };

  staticCallPackage = crossPkgs.pkgsStatic.callPackage;

  appImage =
    staticCallPackage "${nix-appimage}/mkAppImage.nix"
      {
        mkappimage-apprun = staticCallPackage "${nix-appimage}/appruns/userns-chroot" { };
        mkappimage-runtime = staticCallPackage "${nix-appimage}/runtimes/appimage-type2-runtime" { };
      }
      {
        program = lib.getExe nixodus-packages;
      };

  final =
    crossPkgs.runCommand "nixodus-packages"
      {
        nativeBuildInputs = [ buildPackages.lndir ];
      }
      ''
        mkdir -p "$out/bin"
        lndir "${nixodus-packages}" "$out"
        rm "$out/bin/nixodus-packages"
        ln -s "${appImage}" "$out/bin/nixodus-packages"
      '';
in
final
