package main

import (
	_ "embed"
	"encoding/json"
	"errors"
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

func walkPackageBin(
	cmds map[string]string,
	target, pkg string,
	keyVals, keys *strings.Builder,
) error {
	var (
		entries       []os.DirEntry
		fi            os.FileInfo
		name, prevPkg string
		i             int
		ok            bool
		err           error
	)

	entries, err = os.ReadDir(filepath.Join(pkg, "bin"))
	if err != nil {
		return err
	}

	for i = range entries {
		fi, err = entries[i].Info()
		if err != nil {
			return err
		}

		if fi.IsDir() || fi.Mode()&0111 == 0 {
			continue
		}

		name = entries[i].Name()

		prevPkg, ok = cmds[name]
		if ok {
			return fmt.Errorf(
				"%q: duplicate binary %q (used by %q)",
				pkg, name, prevPkg,
			)
		}

		cmds[name] = pkg

		fmt.Fprintf(
			keyVals,
			"%s, %s\n",
			hexString(name),
			hexString(filepath.Join(pkg, "bin", name)),
		)

		fmt.Fprintf(
			keys,
			"%s,\n",
			hexString(name),
		)

		err = os.Symlink("nixodus-packages", filepath.Join(target, name))
		if err != nil {
			return err
		}
	}

	return nil
}

func walkPackages(target string, decoder *json.Decoder) error {
	var (
		keyVals, keys strings.Builder
		cmds          map[string]string
		pkg           string
		token         json.Token
		delim         json.Delim
		ok            bool
		err           error
	)

	cmds = make(map[string]string)

	for decoder.More() {
		err = decoder.Decode(&pkg)
		if err != nil {
			return err
		}

		err = walkPackageBin(cmds, target, pkg, &keyVals, &keys)
		if err != nil {
			return err
		}
	}

	token, err = decoder.Token()
	if err != nil {
		return err
	}

	delim, ok = token.(json.Delim)
	if !ok || delim != ']' {
		return errors.New("expected ']'")
	}

	_, err = strings.NewReplacer(
		"{{ GPERF KEY-VALUES }}", keyVals.String(),
		"{{ GPERF KEYS }}", keys.String(),
	).WriteString(
		os.Stdout,
		mainGperf,
	)
	if err != nil {
		return err
	}

	return nil
}

func run() error {
	var (
		target  string
		decoder *json.Decoder
		token   json.Token
		delim   json.Delim
		ok      bool
		err     error
	)

	target = os.Args[1]
	decoder = json.NewDecoder(os.Stdin)

	token, err = decoder.Token()
	if err != nil {
		return err
	}

	delim, ok = token.(json.Delim)
	if !ok || delim != '[' {
		return errors.New("expected '['")
	}

	err = walkPackages(target, decoder)
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
