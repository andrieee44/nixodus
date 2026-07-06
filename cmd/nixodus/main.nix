{ argsFile }:
let
  args = builtins.fromJSON (builtins.readFile argsFile);
  nixpkgs = builtins.getFlake args.Nixpkgs;
  pkgs = nixpkgs.legacyPackages.${builtins.currentSystem};
  lib = pkgs.lib;
in
(builtins.getFlake args.Nixodus).lib.mkNixodus {
  inherit pkgs;
  nix-appimage = builtins.getFlake args.NixAppImage;
  crossSystem = if args.System == "CURRENT" then builtins.currentSystem else args.System;
  crossPackages =
    crossPkgs: map (pkg: lib.getAttrFromPath (lib.splitString "." pkg) crossPkgs) args.Packages;
}
