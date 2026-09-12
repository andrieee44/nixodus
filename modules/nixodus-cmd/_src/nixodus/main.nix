{ argsFile }:
let
  args = builtins.fromJSON (builtins.readFile argsFile);
  system = builtins.currentSystem;
  crossSystem = if args.CrossSystem == "CURRENT" then system else args.CrossSystem;
  pkgs = (builtins.getFlake "{{ NIXPKGS }}").legacyPackages."${system}";

  inherit (pkgs) buildPackages lib;

  parseFlake =
    flakeRef:
    let
      fields = lib.splitString "#" flakeRef;
      flakeStr = builtins.head fields;
      flake = builtins.getFlake flakeStr;
    in
    if builtins.length fields == 1 then
      let
        result = lib.findFirst (x: x != null) null [
          (lib.attrByPath [ "packages" crossSystem "default" ] null flake)
          (lib.attrByPath [ "defaultPackage" crossSystem "default" ] null flake)
        ];
      in
      lib.throwIfNot (result != null) (
        "flake '${flakeStr}' does not provide attribute "
        + "'packages.${crossSystem}.default' or "
        + "'defaultPackage.${crossSystem}.default'"
      ) result
    else
      let
        pathStr = builtins.concatStringsSep "#" (builtins.tail fields);
        path = lib.splitString "." pathStr;

        result = lib.findFirst (x: x != null) null [
          (lib.attrByPath ([ "packages" ] ++ [ crossSystem ] ++ path) null flake)
          (lib.attrByPath ([ "legacyPackages" ] ++ [ crossSystem ] ++ path) null flake)
          (lib.attrByPath path null flake)
        ];
      in
      lib.throwIfNot (result != null) (
        "flake '${flakeStr}' does not provide attribute "
        + "'packages.${crossSystem}.${pathStr}', "
        + "'legacyPackages.${crossSystem}.${pathStr}' or '${pathStr}'"
      ) result;

  nixodus-packages = (builtins.getFlake "{{ NIXODUS }}").legacyPackages."${system}".nixodus {
    inherit crossSystem;
    crossPackages = _: map parseFlake args.Packages;
  };
in
buildPackages.runCommand "nixodus-packages-real"
  {
    meta.license = lib.licenses.agpl3Plus;
  }
  ''
    mkdir -p "$out/bin"
    cp -r "${nixodus-packages}/bin/." "$out/bin"
    cp -L --remove-destination \
      "${nixodus-packages}/bin/nixodus-packages" "$out/bin/nixodus-packages"
  ''
