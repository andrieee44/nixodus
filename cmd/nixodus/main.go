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
		Nixpkgs     string
		Nixodus     string
		NixAppImage string
		System      string
		Packages    []string
		useJSON     bool
	}

	var (
		args     nixArgs
		argsFile *os.File
		cmd      exec.Cmd
		err      error
	)

	flag.StringVar(
		&args.Nixpkgs,
		"nixpkgs",
		"github:NixOS/nixpkgs/nixos-26.05",
		"nixpkgs flake reference",
	)

	flag.StringVar(
		&args.Nixodus,
		"nixodus",
		"github:andrieee44/nixodus",
		"nixodus flake reference",
	)

	flag.StringVar(
		&args.NixAppImage,
		"nix-appimage",
		"github:ralismark/nix-appimage",
		"nix-appimage flake reference",
	)

	flag.StringVar(
		&args.System,
		"system",
		"CURRENT",
		`Target platform e.g. "x86-64_linux"`,
	)

	flag.BoolVar(
		&args.useJSON,
		"json",
		false,
		"Read JSON from stdin",
	)

	flag.Parse()

	argsFile, err = os.CreateTemp(os.TempDir(), "nixodus-*.json")
	if err != nil {
		return err
	}
	defer os.Remove(argsFile.Name())
	defer argsFile.Close()

	args.Packages = flag.Args()
	if args.useJSON {
		err = json.NewDecoder(os.Stdin).Decode(&args.Packages)
		if err != nil {
			return err
		}
	}

	err = json.NewEncoder(argsFile).Encode(args)
	if err != nil {
		return err
	}

	cmd = *exec.Command(
		"nix", "build", "--impure", "--no-link", "--print-out-paths",
		"--argstr", "argsFile", argsFile.Name(),
		"--expr", mainNix,
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

func main() {
	var err error

	err = run()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
