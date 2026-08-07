{ config, pkgs, ... }:
{
  packages = with pkgs; [
    git
    jq
    lima-full
    nixfmt
  ];

  languages = {
    go.enable = true;
    nix.enable = true;
  };

  processes = {
    limactl = {
      exec = ''
        limactl create --name "nixodus-riscv-test" \
          "${config.git.root}/lima.yaml" ||
          true

        limactl start --name "nixodus-riscv-test"
      '';

      ready = {
        period = 1;

        exec = ''
          status="$(
            limactl list "nixodus-riscv-test" --format '{{ .Status }}'
          )"

          [ "$status" = "Running" ]
        '';
      };

      restart.on = "never";
      before = [ "devenv:enterShell" ];
    };
  };

  scripts = {
    nixodus-test.exec = ''
      set -euo pipefail

      echo "########################################"
      echo "#            NATIVE MACHINE            #"
      echo "########################################"

      set -x

      result="$(
        nix build --print-out-paths --no-link ${config.git.root}#nixodus-test
      )"

      pkgs="$result/bin/nixodus-packages"

      "$pkgs" hello --version
      "$pkgs" sqlite3 --version
      "$pkgs" psql --version
      "$pkgs" postgres --version
      "$result/bin/pg_ctl" --version

      set +x

      echo "########################################"
      echo "#    UBUNTU RISCV64 VIRTUAL MACHINE    #"
      echo "########################################"

      set -x

      nixpkgs="github:NixOS/nixpkgs/$(
        jq -r '
          .nodes.[.root].inputs.nixpkgs as $nixpkgs |
            .nodes[$nixpkgs].locked.rev
        ' "${config.git.root}/flake.lock"
      )"

      nix_appimage="github:ralismark/nix-appimage/$(
        jq -r '
          .nodes.[.root].inputs."nix-appimage" as $nix_appimage |
            .nodes[$nix_appimage].locked.rev
        ' "${config.git.root}/flake.lock"
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

      limactl shell nixodus-riscv-test sudo rm -rf /tmp/result
      limactl copy -r "$result" "nixodus-riscv-test:/tmp/result"

      set +x

      limactl shell nixodus-riscv-test sudo sh -c '
        set -eux

        result="/tmp/result"
        pkgs="$result/bin/nixodus-packages"

        "$pkgs" hello --version
        "$pkgs" sqlite3 --version
        "$pkgs" psql --version
        "$pkgs" postgres --version
        "$result/bin/pg_ctl" --version
      '
    '';
  };
}
