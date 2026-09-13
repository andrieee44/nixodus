# nixodus

## NAME

nixodus - NIX eXODUS - portable multicall binary builder

## SYNOPSIS

```shell
nix run github:andrieee44/nixodus -- [OPTION]... <PACKAGE>...
```

```shell
nixodus [OPTION]... <PACKAGE>...
```

## DESCRIPTION

nixodus is a thin wrapper over the [Nixodus Library](./../../README.md),
removing the need to set up a flake for quick, ad hoc builds. It does not
handle deployment concerns such as SSH transfer or `rsync`; it is limited to
building the multicall binary.

## OPTIONS

### -cross-system :: String

Target platform e.g. "aarch64-linux" (default "CURRENT")

### -json :: Bool

Read JSON from stdin

## EXAMPLES

```shell
nix run github:andrieee44/nixodus -- nixpkgs#hello nixpkgs#tree
```

```shell
nixodus nixpkgs#hello nixpkgs#tree
```

```shell
nixodus -cross-system aarch64-darwin nixpkgs#hello nixpkgs#tree
```

```shell
echo '[ "nixpkgs#hello", "nixpkgs#tree" ]' | nixodus -json
```

## COPYRIGHT

See [`LICENSE`](./../../LICENSE). Uses
[AGPLv3 or later](https://www.gnu.org/licenses/agpl-3.0.html).

## SEE ALSO

- [GitHub repository](https://github.com/andrieee44/nixodus)
- [Nix flakes](https://wiki.nixos.org/wiki/Flakes)
- [Nix](https://nixos.org/)
- [Nixodus Library](./../../README.md)
- [Nixpkgs](https://github.com/NixOS/nixpkgs)
- [nix-appimage](https://github.com/ralismark/nix-appimage)
