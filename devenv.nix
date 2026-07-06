{ config, pkgs, ... }:
{
  env.LIMA_INSTANCE = "nixodus-riscv-test";

  packages = with pkgs; [
    coreutils
    git
    gperf
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
        limactl create --name "$LIMA_INSTANCE" \
          "${config.git.root}/lima.yaml" ||
          true

        limactl start --name "$LIMA_INSTANCE"
      '';

      ready = {
        period = 1;

        exec = ''
          status="$(limactl list "$LIMA_INSTANCE" --format '{{ .Status }}')"
          [ "$status" = "Running" ]
        '';
      };

      restart.on = "never";
      before = [ "devenv:enterShell" ];
    };
  };

  scripts = {
    nixodus-test.exec = ''
      echo "########################################"
      echo "#            NATIVE MACHINE            #"
      echo "########################################"

      set -ex

      result="$(nix build --print-out-paths --no-link .#nixodus-test)"
      pkgs="$result/bin/nixodus-packages"

      "$pkgs" hello --version
      "$pkgs" sqlite3 --version
      "$pkgs" psql --version
      "$pkgs" postgres --version
      "$result/bin/pg_ctl" --version

      (
        set +x

        echo "########################################"
        echo "#    UBUNTU RISCV64 VIRTUAL MACHINE    #"
        echo "########################################"
      )

      resultRISCV="$(
        nix build --print-out-paths --no-link .#nixodus-test-riscv64
      )"

      limactl copy -r "$resultRISCV" "$LIMA_INSTANCE:/tmp/resultRISCV"

      limactl copy "$(realpath "$resultRISCV/bin/nixodus-packages")" \
        "$LIMA_INSTANCE:/tmp/nixodus-packages"

      (
        set +x

        lima sudo sh -c '
          set -ex

          resultRISCV="/tmp/resultRISCV"
          pkgsRISCV="$resultRISCV/bin/nixodus-packages"

          rm "$pkgsRISCV"
          ln -s /tmp/nixodus-packages "$pkgsRISCV"
          "$pkgsRISCV" hello --version
          "$pkgsRISCV" sqlite3 --version
          "$pkgsRISCV" psql --version
          "$pkgsRISCV" postgres --version
          "$resultRISCV/bin/pg_ctl" --version
        '
      )
    '';
  };
}
