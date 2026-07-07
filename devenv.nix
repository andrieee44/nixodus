{ config, pkgs, ... }:
{
  env.LIMA_INSTANCE = "nixodus-riscv-test";

  packages = with pkgs; [
    git
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

      result="$(nix run . -- --system riscv64-linux hello sqlite postgresql)"
      limactl copy -r "$result" "$LIMA_INSTANCE:/tmp/result"

      (
        set +x

        lima sudo sh -c '
          set -ex

          result="/tmp/result"
          pkgs="$result/bin/nixodus-packages"

          "$pkgs" hello --version
          "$pkgs" sqlite3 --version
          "$pkgs" psql --version
          "$pkgs" postgres --version
          "$result/bin/pg_ctl" --version
        '
      )
    '';
  };
}
