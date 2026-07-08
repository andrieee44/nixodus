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
	type options struct {
		Nixpkgs     string
		Nixodus     string
		NixAppImage string
		System      string
		Packages    []string
		useJSON     bool
	}

	var (
		opts     options
		optsFile *os.File
		cmd      *exec.Cmd
		err      error
	)

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, `Usage: %[1]s [OPTION]... <PACKAGE>...
Bundle multiple Nix PACKAGE(S) into a single multicall binary

Examples:
  %[1]s hello dos2unix
  %[1]s --system riscv64-linux hello
  echo '{"packages": ["hello"]}' | %[1]s --json

Flags:
`, os.Args[0])

		flag.PrintDefaults()
	}

	flag.StringVar(
		&opts.Nixpkgs,
		"nixpkgs",
		"github:NixOS/nixpkgs/nixos-26.05",
		"nixpkgs flake reference",
	)

	flag.StringVar(
		&opts.Nixodus,
		"nixodus",
		"github:andrieee44/nixodus",
		"nixodus flake reference",
	)

	flag.StringVar(
		&opts.NixAppImage,
		"nix-appimage",
		"github:ralismark/nix-appimage",
		"nix-appimage flake reference",
	)

	flag.StringVar(
		&opts.System,
		"system",
		"CURRENT",
		`Target platform e.g. "x86_64-linux"`,
	)

	flag.BoolVar(
		&opts.useJSON,
		"json",
		false,
		"Read JSON from stdin",
	)

	flag.Parse()

	optsFile, err = os.CreateTemp(os.TempDir(), "nixodus-*.json")
	if err != nil {
		return err
	}
	defer os.Remove(optsFile.Name())
	defer optsFile.Close()

	opts.Packages = flag.Args()
	if opts.useJSON {
		err = json.NewDecoder(os.Stdin).Decode(&opts.Packages)
		if err != nil {
			return err
		}
	}

	err = json.NewEncoder(optsFile).Encode(opts)
	if err != nil {
		return err
	}

	cmd = exec.Command(
		"nix", "build", "--impure", "--no-link", "--print-out-paths",
		"--argstr", "argsFile", optsFile.Name(),
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
