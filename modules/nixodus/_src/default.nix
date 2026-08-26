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

  inherit (crossPkgs) buildPackages;

  codegen = buildPackages.buildGoModule {
    doCheck = true;
    meta.mainProgram = "codegen";
    name = "codegen";
    src = ./codegen;
    vendorHash = null;

    checkPhase = ''
      runHook preCheck
      go vet ./...
      runHook postCheck
    '';
  };

  nixodusPackagesList = buildPackages.writeText "nixodus-packages-list" (
    builtins.toJSON (crossPackages crossPkgs)
  );

  nixodusPackages = crossPkgs.stdenv.mkDerivation {
    dontUnpack = true;
    meta.mainProgram = "nixodus-packages";
    name = "nixodus-packages";

    nativeBuildInputs = [
      buildPackages.gperf
      codegen
    ];

    buildPhase = ''
      mkdir -p "$out/bin"

      codegen "$out/bin" \
        < "${nixodusPackagesList}" \
        > "nixodus-packages.gperf"

      gperf --output-file "nixodus-packages.c" "nixodus-packages.gperf"

      $CC -Wall -Wextra -Werror \
        -o "$out/bin/nixodus-packages" \
        "nixodus-packages.c"
    '';
  };

  staticCallPackage = crossPkgs.pkgsStatic.callPackage;

  nixodusAppImage =
    staticCallPackage "${nix-appimage}/mkAppImage.nix"
      {
        mkappimage-apprun = staticCallPackage "${nix-appimage}/appruns/userns-chroot" { };
        mkappimage-runtime = staticCallPackage "${nix-appimage}/runtimes/appimage-type2-runtime" { };
      }
      {
        program = lib.getExe nixodusPackages;
      };
in
buildPackages.runCommand "nixodus-packages-final"
  {
    nativeBuildInputs = [ buildPackages.lndir ];
  }
  ''
    mkdir -p "$out/bin"
    lndir "${nixodusPackages}" "$out"
    rm "$out/bin/nixodus-packages"
    ln -s "${nixodusAppImage}" "$out/bin/nixodus-packages"
  ''
