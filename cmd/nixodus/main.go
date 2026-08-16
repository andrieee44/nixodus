package main

import (
	_ "embed"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
)

//go:embed main.nix
var mainNix string

func run() error {
	type nixArgs struct {
		NixAppImage string
		Nixodus     string
		Nixpkgs     string
		Packages    []string
		System      string
	}

	var (
		args     nixArgs
		flagJSON bool
		argsFile *os.File
		cmd      *exec.Cmd
		err      error
	)

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, `Usage: %[1]s [OPTION]... <PACKAGE>...
Bundle multiple Nix PACKAGE(S) into a single multicall binary

Examples:
  %[1]s hello haskell.compiler.ghcHEAD
  %[1]s --system riscv64-linux hello haskell.compiler.ghcHEAD
  echo '[ "hello", "haskell.compiler.ghcHEAD" ]' | %[1]s --json

Flags:
`, os.Args[0])

		flag.PrintDefaults()
	}

	flag.StringVar(
		&args.NixAppImage,
		"nix-appimage",
		"github:ralismark/nix-appimage",
		"nix-appimage flake reference",
	)

	flag.StringVar(
		&args.Nixodus,
		"nixodus",
		"github:andrieee44/nixodus",
		"nixodus flake reference",
	)

	flag.StringVar(
		&args.Nixpkgs,
		"nixpkgs",
		"github:NixOS/nixpkgs/nixos-26.05",
		"nixpkgs flake reference",
	)

	flag.StringVar(
		&args.System,
		"system",
		"CURRENT",
		`Target platform e.g. "x86_64-linux"`,
	)

	flag.BoolVar(
		&flagJSON,
		"json",
		false,
		"Read JSON from stdin",
	)

	flag.Parse()

	args.Packages = flag.Args()
	if flagJSON {
		err = json.NewDecoder(os.Stdin).Decode(&args.Packages)
		if err != nil {
			return err
		}
	}

	argsFile, err = os.CreateTemp(os.TempDir(), "nixodus-*.json")
	if err != nil {
		return err
	}

	err = json.NewEncoder(argsFile).Encode(args)
	if err != nil {
		return err
	}

	err = argsFile.Close()
	if err != nil {
		return err
	}

	cmd = exec.Command(
		"nix", "build", "--impure", "--no-link", "--print-out-paths",
		"--argstr", "argsFile", argsFile.Name(),
		"--expr", mainNix,
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		return err
	}

	err = os.Remove(argsFile.Name())
	if err != nil {
		return err
	}

	return nil
}

func main() {
	var err error

	err = run()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
