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
    name = "codegen";
    src = ./codegen;
    vendorHash = null;

    checkPhase = ''
      runHook preCheck
      go vet ./...
      runHook postCheck
    '';

    meta = {
      license = lib.licenses.agpl3Plus;
      mainProgram = "codegen";
    };
  };

  nixodusPackagesList = buildPackages.writeText "nixodus-packages-list" (
    builtins.toJSON (crossPackages crossPkgs)
  );

  nixodusPackages = crossPkgs.stdenv.mkDerivation {
    dontUnpack = true;
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

    meta = {
      license = lib.licenses.agpl3Plus;
      mainProgram = "nixodus-packages";
    };
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
    meta.license = lib.licenses.agpl3Plus;
    nativeBuildInputs = [ buildPackages.lndir ];
  }
  ''
    mkdir -p "$out/bin"
    lndir "${nixodusPackages}" "$out"
    rm "$out/bin/nixodus-packages"
    ln -s "${nixodusAppImage}" "$out/bin/nixodus-packages"
  ''
