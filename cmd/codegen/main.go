package main

import (
	"bufio"
	_ "embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

//go:embed main.gperf
var mainGperf string

func cString(s string) string {
	var (
		b       byte
		builder strings.Builder
	)

	builder.WriteByte('"')

	for _, b = range []byte(s) {
		fmt.Fprintf(&builder, "\\x%02x", b)
	}

	builder.WriteByte('"')

	return builder.String()
}

func walkPackages(program, outBin string) (string, string, error) {
	var (
		scanner       *bufio.Scanner
		cmds          map[string]string
		keyVals, keys strings.Builder
		pkg, prevPkg  string
		entries       []os.DirEntry
		entry         os.DirEntry
		info          fs.FileInfo
		ok            bool
		err           error
	)

	scanner = bufio.NewScanner(os.Stdin)
	cmds = make(map[string]string)

	for scanner.Scan() {
		pkg = scanner.Text()

		entries, err = os.ReadDir(filepath.Join(pkg, "bin"))
		if err != nil {
			return "", "", err
		}

		for _, entry = range entries {
			info, err = entry.Info()
			if err != nil {
				return "", "", err
			}

			if entry.IsDir() || info.Mode()&0111 == 0 {
				continue
			}

			prevPkg, ok = cmds[entry.Name()]
			if ok {
				return "", "", fmt.Errorf(
					"%q: duplicate binary %q (used by %q)",
					pkg, entry.Name(), prevPkg,
				)
			}

			cmds[entry.Name()] = pkg

			fmt.Fprintf(
				&keyVals,
				"%s, %s\n",
				cString(entry.Name()),
				cString(filepath.Join(pkg, "bin", entry.Name())),
			)

			fmt.Fprintf(
				&keys,
				"%s,\n",
				cString(entry.Name()),
			)

			err = os.Symlink(program, filepath.Join(outBin, entry.Name()))
			if err != nil {
				return "", "", err
			}
		}
	}

	return keyVals.String(), keys.String(), scanner.Err()
}

func renderGperf(keyVals, keys, program string) error {
	var err error

	_, err = strings.NewReplacer(
		"{{ GPERF KEY-VALUES }}", keyVals,
		"{{ GPERF KEYS }}", keys,
		"{{ GPERF PROGRAM }}", cString(program),
	).WriteString(
		os.Stdout,
		mainGperf,
	)

	return err
}

func main() {
	var (
		keyVals, keys string
		err           error
	)

	keyVals, keys, err = walkPackages(os.Args[1], os.Args[2])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	err = renderGperf(keyVals, keys, os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
