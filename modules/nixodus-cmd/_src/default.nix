{ lib, pkgs }:
pkgs.buildGoModule {
  doCheck = true;
  name = "nixodus";
  src = ./nixodus;
  vendorHash = null;

  checkPhase = ''
    runHook preCheck
    go vet ./...
    runHook postCheck
  '';

  meta = {
    description = "nixodus - NIX eXODUS - portable multicall binary builder";
    homepage = "https://github.com/andrieee44/nixodus";
    license = lib.licenses.agpl3Plus;
    mainProgram = "nixodus";
  };
}
