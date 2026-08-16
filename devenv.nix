{ config, pkgs, ... }:
{
  git-hooks.hooks = {
    # Bash
    shellcheck.enable = true;
    shfmt.enable = true;

    # Go
    gofmt.enable = true;
    golangci-lint.enable = true;

    # Markdown
    markdownlint = {
      enable = true;
      settings.configuration.MD013.code_blocks = false;
    };

    # Miscellaneous
    check-added-large-files.enable = true;
    check-merge-conflicts.enable = true;
    detect-private-keys.enable = true;
    end-of-file-fixer.enable = true;
    trim-trailing-whitespace.enable = true;

    # Nix
    deadnix.enable = true;
    nixfmt.enable = true;
    statix.enable = true;

    # Nixodus
    nixodus = {
      enable = true;
      entry = "devenv tasks run nixodus:test";
      pass_filenames = false;
    };

    # YAML
    check-yaml.enable = true;
    yamllint.enable = true;
  };

  languages = {
    go.enable = true;
    nix.enable = true;
  };

  packages = with pkgs; [
    git
    jaq
    nixfmt
  ];

  tasks."nixodus:test" = {
    before = [ "devenv:enterTest" ];

    exec = ''
      set -euo pipefail

      result="$(
        nix build \
          --print-out-paths \
          --no-link \
          "${config.git.root}#nixodus-test"
      )"

      "$result/bin/pg_ctl" --version

      for program in hello sqlite3 psql postgres; do
        "$result/bin/nixodus-packages" "$program" --version
      done

      nixpkgs="github:NixOS/nixpkgs/$(
        jaq -r '.nodes.[.nodes.[.root].inputs.nixpkgs].locked.rev' \
          "${config.git.root}/flake.lock"
      )"

      nix_appimage="github:ralismark/nix-appimage/$(
        jaq -r '.nodes.[.nodes.[.root].inputs."nix-appimage"].locked.rev' \
           "${config.git.root}/flake.lock"
      )"

      result="$(
        echo '[ "hello", "sqlite", "postgresql" ]' |
          nix run "${config.git.root}" -- \
            --json \
            --nix-appimage "$nix_appimage" \
            --nixodus "${config.git.root}" \
            --nixpkgs "$nixpkgs" \
            --system riscv64-linux
      )"
    '';
  };
}
