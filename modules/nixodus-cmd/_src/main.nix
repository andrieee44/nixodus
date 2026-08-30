{ argsFile }:
let
  args = builtins.fromJSON (builtins.readFile argsFile);
  system = builtins.currentSystem;
  crossSystem = if args.CrossSystem == "CURRENT" then system else args.CrossSystem;
  pkgs = (builtins.getFlake args.Nixpkgs).legacyPackages."${system}";

  inherit (pkgs) buildPackages lib;

  tryAttr =
    before: after: flake:
    lib.attrByPath (before ++ [ crossSystem ] ++ after) null flake;

  flakeDefault =
    flakeStr:
    let
      flake = builtins.getFlake flakeStr;

      result = lib.findFirst (x: x != null) null [
        (tryAttr [ "packages" ] [ "default" ] flake)
        (tryAttr [ "defaultPackage" ] [ "default" ] flake)
      ];
    in
    if result != null then
      result
    else
      throw (
        "flake '${flakeStr}' does not provide attribute "
        + "'packages.${crossSystem}.default' or "
        + "'defaultPackage.${crossSystem}.default'"
      );

  flakeAttrs =
    flakeStr: attrs:
    let
      flake = builtins.getFlake flakeStr;
      pathStr = builtins.concatStringsSep "#" attrs;
      path = lib.splitString "." pathStr;

      result = lib.findFirst (x: x != null) null [
        (tryAttr [ "packages" ] path flake)
        (tryAttr [ "legacyPackages" ] path flake)
        (lib.attrByPath path null flake)
      ];
    in
    if result != null then
      result
    else
      throw (
        "flake '${flakeStr}' does not provide attribute"
        + "'packages.${crossSystem}.${pathStr}', "
        + "'legacyPackages.${crossSystem}.${pathStr}' or '${pathStr}'"
      );

  parseFlake =
    flakeRef:
    let
      fields = lib.splitString "#" flakeRef;
      flakeStr = builtins.head fields;
    in
    if builtins.length fields == 1 then
      flakeDefault flakeStr
    else
      flakeAttrs flakeStr (builtins.tail fields);

  nixodus = (builtins.getFlake args.Nixodus).legacyPackages."${system}".nixodus {
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
    cp -r "${nixodus}/bin/." "$out/bin"
    cp -L --remove-destination \
      "${nixodus}/bin/nixodus-packages" "$out/bin/nixodus-packages"
  ''
