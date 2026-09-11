package main

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

//go:embed main.gperf
var mainGperf string

func hexString(s string) string {
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

func run() error {
	var (
		outBin, name, prevPkg string
		cmds                  map[string]string
		pkgs                  []string
		entries               []os.DirEntry
		fi                    os.FileInfo
		keys, keyVals         strings.Builder
		i, j                  int
		ok                    bool
		err                   error
	)

	outBin = os.Args[1]
	cmds = make(map[string]string)

	err = json.NewDecoder(os.Stdin).Decode(&pkgs)
	if err != nil {
		return err
	}

	for i = range pkgs {
		entries, err = os.ReadDir(filepath.Join(pkgs[i], "bin"))
		if err != nil {
			return err
		}

		for j = range entries {
			fi, err = entries[j].Info()
			if err != nil {
				return err
			}

			if fi.IsDir() || fi.Mode()&0111 == 0 {
				continue
			}

			name = entries[j].Name()

			prevPkg, ok = cmds[name]
			if ok {
				return fmt.Errorf(
					"%q: duplicate binary %q (used by %q)",
					pkgs[i], name, prevPkg,
				)
			}

			cmds[name] = pkgs[i]
			fmt.Fprintf(&keys, "%s,\n", hexString(name))

			fmt.Fprintf(
				&keyVals,
				"%s, %s\n",
				hexString(name),
				hexString(filepath.Join(pkgs[i], "bin", name)),
			)

			err = os.Symlink("nixodus-packages", filepath.Join(outBin, name))
			if err != nil {
				return err
			}
		}
	}

	_, err = strings.NewReplacer(
		"{{ GPERF KEY-VALUES }}", keyVals.String(),
		"{{ GPERF KEYS }}", keys.String(),
	).WriteString(os.Stdout, mainGperf)
	if err != nil {
		return err
	}

	return nil
}

func main() {
	var err error

	err = run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "codegen: %v\n", err)
		os.Exit(1)
	}
}
