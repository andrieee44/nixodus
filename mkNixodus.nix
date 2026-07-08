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
    name = "nixodus-codegen";
    src = ./cmd/codegen;
    vendorHash = null;
    meta.mainProgram = "codegen";
  };

  packageList = buildPackages.writeText "nixodus-package-list" (
    builtins.concatStringsSep "\n" (crossPackages crossPkgs)
  );

  program =
    let
      name = "nixodus-packages";
    in
    crossPkgs.stdenv.mkDerivation {
      inherit name;
      dontUnpack = true;
      meta.mainProgram = name;

      nativeBuildInputs = [
        buildPackages.gperf
        codegen
      ];

      buildPhase = ''
        mkdir -p "$out/bin"

        ${lib.getExe codegen} "${name}" "$out/bin" \
          < "${packageList}" > "${name}.gperf"

        gperf "${name}.gperf" --output-file "${name}.c"
        $CC -o "$out/bin/${name}" "${name}.c"
      '';
    };

  appImageBin =
    let
      staticCallPackage = crossPkgs.pkgsStatic.callPackage;

      appImage =
        staticCallPackage "${nix-appimage}/mkAppImage.nix"
          {
            mkappimage-apprun = staticCallPackage "${nix-appimage}/appruns/userns-chroot" { };
            mkappimage-runtime = staticCallPackage "${nix-appimage}/runtimes/appimage-type2-runtime" { };
          }
          {
            program = lib.getExe program;
          };
    in
    crossPkgs.runCommand "nixodus-packages"
      {
        nativeBuildInputs = [ buildPackages.lndir ];
      }
      ''
        mkdir -p "$out/bin"
        lndir "${program}" "$out"
        rm "$out/bin/nixodus-packages"
        ln -s "${appImage}" "$out/bin/nixodus-packages"
      '';
in
appImageBin
