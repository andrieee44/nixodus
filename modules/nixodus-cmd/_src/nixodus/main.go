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
		CrossSystem string
		Nixodus     string
		Nixpkgs     string
		Packages    []string
	}

	var (
		args     nixArgs
		flagJSON bool
		argsFile *os.File
		cmd      *exec.Cmd
		err      error
	)

	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, `Usage: nixodus [OPTION]... <PACKAGE>...
Bundle multiple Nix PACKAGE(S) into a single multicall binary

Examples:
  nix run github:andrieee44/nixodus -- nixpkgs#hello nixpkgs#tree
  nixodus nixpkgs#hello nixpkgs#tree
  nixodus -cross-system aarch64-linux nixpkgs#hello nixpkgs#tree
  echo '[ "nixpkgs#hello", "nixpkgs#tree" ]' | nixodus -json

Flags:`)

		flag.PrintDefaults()
	}

	flag.StringVar(
		&args.CrossSystem,
		"cross-system",
		"CURRENT",
		`Target platform e.g. "aarch64-linux"`,
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
		"github:NixOS/nixpkgs/nixos-unstable",
		"nixpkgs flake reference",
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

	defer func() {
		_ = os.Remove(argsFile.Name())
	}()

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
