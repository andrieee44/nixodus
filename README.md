# nixodus

## NAME

nixodus - NIX eXODUS - portable multicall binary builder

## LIBRARY

Nix library with [flakes](https://wiki.nixos.org/wiki/Flakes) support.

## SYNOPSIS

In your `flake.nix`:

```nix
inputs.nixodus.url = "github:andrieee44/nixodus";
```

### nixodus.legacyPackages."${system}".nixodus

```haskell
nixodus.legacyPackages."${system}".nixodus :: {
  crossPackages :: AttrSet -> [ Derivation ];
  crossSystem :: String;
} -> Derivation
```

## DESCRIPTION

nixodus is a [Nix flake](https://wiki.nixos.org/wiki/Flakes) library that
builds a portable, [busybox](https://www.busybox.net/)-style multicall
binary from an arbitrary set of [Nix](https://nixos.org/) packages. The
result is a single [AppImage](https://appimage.org/), produced via
[nix-appimage](https://github.com/ralismark/nix-appimage), bundling every
binary from the requested packages together with symlink shortcuts for
each one. The binary is independent of Nix and runs on any Linux
environment with kernel support for AppImage, provided the architecture
matches the `crossSystem` argument.

This exists to deliver Nix-built software to environments where Nix,
containers, or on-target compilation are unavailable or impractical,
such as shared servers with restricted storage, CPU, or container access.
Where [nix-appimage](https://github.com/ralismark/nix-appimage) packages a
single binary with its dependencies, nixodus extends this to multiple
packages at once, deduplicating shared dependencies (e.g.
[glibc](https://www.gnu.org/software/libc/)) across binaries to minimize
artifact size. Builds favor cache hits for same-architecture targets,
keep build complexity on the host, and require nothing on the target
beyond AppImage support; where
[FUSE](https://www.kernel.org/doc/html/latest/filesystems/fuse/fuse.html) is
unavailable, the AppImage `--extract-and-run` flag may be used instead.

For quick, ad hoc builds, the [Nixodus CLI](./modules/nixodus-cmd/README.md)
is available as a thin wrapper over this library, removing the need to set up
a flake to use it. It does not handle deployment concerns such as SSH transfer
or `rsync`; it is limited to building the multicall binary.

## PARAMETERS

### crossPackages :: AttrSet -> [ Derivation ]

crossPackages is a function that takes a cross-compilation-ready instance of
[nixpkgs](https://github.com/NixOS/nixpkgs) and returns a list of packages.

```nix
crossPkgs: with crossPkgs; [
  hello
  postgresql
  sqlite
]
```

### crossSystem :: String

crossSystem is the target system.

```nix
"riscv64-linux"
```

## RETURN VALUE

The function `nixodus` returns a
[derivation](https://nix.dev/manual/nix/stable/language/derivations.html)
package that contains the multicall binary and the symlink shortcuts.

## EXAMPLES

See the `checks` attribute of [`default.nix`](./modules/nixodus/default.nix).

## REPORTING BUGS

Open a GitHub issue at
[github.com/andrieee44/nixodus](https://github.com/andrieee44/nixodus/issues).

## COPYRIGHT

See [`LICENSE`](./LICENSE). Uses
[AGPLv3 or later](https://www.gnu.org/licenses/agpl-3.0.html).

## SEE ALSO

- [AppImage](https://appimage.org/)
- [GitHub repository](https://github.com/andrieee44/nixodus)
- [Nix flakes](https://wiki.nixos.org/wiki/Flakes)
- [Nix](https://nixos.org/)
- [Nixodus CLI](./modules/nixodus-cmd/README.md)
- [Nixpkgs](https://github.com/NixOS/nixpkgs)
- [nix-appimage](https://github.com/ralismark/nix-appimage)
