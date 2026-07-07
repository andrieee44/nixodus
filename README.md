# nixodus

Create a multicall binary, à la
[busybox](https://github.com/mirror/busybox), bundling multiple packages
and their dependencies into a single executable file with symlinks. Uses
[nix-appimage](https://github.com/ralismark/nix-appimage) under the hood
and supports cross-compiling to a different Nix double.

## Getting started

You'll need [Nix](https://nixos.org/) installed. Run nixodus via
[`nix run`](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-run.html),
replacing `hello` and `dos2unix` with the package(s) you want to build:

```sh
$ nix run github:andrieee44/nixodus hello dos2unix
```

This prints a derivation, a store path pointing to a tree of binaries
(don't worry if your derivation hash looks different):

```sh
$ nix run github:andrieee44/nixodus hello dos2unix
/nix/store/nksmy1yjxnh855ri2rv04znqvjngiriv-nixodus-packages-real

$ tree "$(nix run github:andrieee44/nixodus hello dos2unix)"
/nix/store/nksmy1yjxnh855ri2rv04znqvjngiriv-nixodus-packages-real
└── bin
    ├── dos2unix -> nixodus-packages
    ├── hello -> nixodus-packages
    ├── mac2unix -> nixodus-packages
    ├── nixodus-packages
    ├── unix2dos -> nixodus-packages
    └── unix2mac -> nixodus-packages

2 directories, 6 files

$ "$(nix run github:andrieee44/nixodus hello dos2unix)/bin/hello"
Hello, world!

$ "$(nix run github:andrieee44/nixodus hello dos2unix)/bin/nixodus-packages"
usage: nixodus-packages <binary> [args...]
   or: <binary> [args...]

available binaries:
  hello
  dos2unix
  mac2unix
  unix2dos
  unix2mac
```

The output is a single line, so it's easy to use directly in scripts. Pipe it,
store it in a variable, or pass it straight to another command. You can also
target another system, such as RISC-V. Consult
[doubles.nix](https://github.com/NixOS/nixpkgs/blob/master/lib/systems/doubles.nix)
for the list of supported Nix doubles.

```sh
file "$(nix run github:andrieee44/nixodus -- --system riscv64-linux hello)/bin/nixodus-packages"
/nix/store/zs6j7sdg11klv8g2mvqhiv3ahv1wd2vc-nixodus-packages-real/bin/nixodus-packages: ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), statically linked, not stripped
```

`hello` and `dos2unix` are automatically resolved against the target
system's cross-packages. To build packages from other flakes, or to get
more control over arguments such as overlays and package-level overrides,
use this flake's `lib.mkNixodus` instead of the CLI, since under the hood
the CLI just converts a string like `"rubyPackages.rails"` into a
`crosspkgs.rubyPackages.rails` attribute lookup, which limits what you
can express. See `flake.nix` for examples, in particular `nixodus-test`,
which shows how `mkNixodus` is meant to be called.

Run `nixodus --help` to see all available flags, including how to pin the
flake references (e.g., `--nixodus`, `--nixpkgs`, `--nix-appimage`).

## Caveats

Any issues with [nix-appimage](https://github.com/ralismark/nix-appimage)
will also apply here. Please check upstream first before reporting here.
