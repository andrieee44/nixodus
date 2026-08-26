{ argsFile }:
let
  args = builtins.fromJSON (builtins.readFile argsFile);
  system = builtins.currentSystem;
  pkgs = (builtins.getFlake args.Nixpkgs).legacyPackages."${system}";

  inherit (pkgs) buildPackages lib;

  nixodus = (builtins.getFlake args.Nixodus).legacyPackages."${system}" {
    crossSystem = if args.CrossSystem == "CURRENT" then system else args.CrossSystem;
    crossPackages =
      crossPkgs: map (pkg: lib.getAttrFromPath (lib.splitString "." pkg) crossPkgs) args.Packages;
  };
in
buildPackages.runCommand "nixodus-packages-real" { } ''
  mkdir -p "$out/bin"
  cp -r "${nixodus}/bin/." "$out/bin"
  cp -L --remove-destination \
    "${nixodus}/bin/nixodus-packages" "$out/bin/nixodus-packages"
''
