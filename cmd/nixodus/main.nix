{ argsFile }:
let
  args = builtins.fromJSON (builtins.readFile argsFile);
  pkgs = (builtins.getFlake args.Nixpkgs).legacyPackages.${builtins.currentSystem};
  lib = pkgs.lib;

  nixodus = (builtins.getFlake args.Nixodus).lib.mkNixodus {
    inherit pkgs;
    nix-appimage = builtins.getFlake args.NixAppImage;
    crossSystem = if args.System == "CURRENT" then builtins.currentSystem else args.System;
    crossPackages =
      crossPkgs: map (pkg: lib.getAttrFromPath (lib.splitString "." pkg) crossPkgs) args.Packages;
  };
in
pkgs.runCommand "nixodus-packages-real" { } ''
  mkdir -p "$out/bin"
  cp -r "${nixodus}/bin/." "$out/bin"
  cp -L --remove-destination \
    "${nixodus}/bin/nixodus-packages" "$out/bin/nixodus-packages"
''
