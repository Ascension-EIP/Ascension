{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # https://devenv.sh/basics/
  # env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [
    pkgs.quicktype
  ];

  # https://devenv.sh/languages/
  languages = {
    go = {
      enable = true;
      version = "1.27.1";
    };
  };

  # https://devenv.sh/processes/
  processes = {
    server = {
      exec = ''
        secretspec run -- go run ./cmd/server/main.go
      '';
      cwd = "${config.git.root}/apps/server";
      restart = {
        on = "on_failure";
        max = 5;
      };
      ready = {
        http.get = {
          port = 8080;
          path = "/healthz";
          # host = "127.0.0.1"; # default
          # scheme = "http"; # default
        };
      };
      watch = {
        paths = [
          ./.
        ];
        extensions = [
          "go"
          "sum"
          "mod"
        ];
      };
    };
    cron = {
      exec = ''
        secretspec run -- go run ./cmd/cron/main.go
      '';
      cwd = "${config.git.root}/apps/server";
      restart = {
        on = "on_failure";
        max = 5;
      };
      watch = {
        paths = [
          ./.
        ];
        extensions = [
          "go"
          "sum"
          "mod"
        ];
      };
    };
  };

  # https://devenv.sh/services/
  services = {
    postgres = {
      enable = true;
      package = pkgs.postgresql_18;
      initialDatabases = [
        {
          name = "name";
          user = "user";
          pass = "pass";
        }
      ];
      listen_addresses = "localhost";
      port = 5432;
    };

    rustfs = {
      enable = true;
      port = 9000;
      consoleEnable = true;
      consolePort = 9001;
      accessKey = "accesskey";
      secretKey = "secretkey";
    };

    rabbitmq = {
      enable = true;
    };
  };

  # https://devenv.sh/scripts/
  scripts.schemas-generate.exec = ''
    	quicktype --src-lang schema $DEVENV_ROOT/../../schemas/*.schema.json \
            -o $DEVENV_ROOT/internal/shared/models.go --lang go --just-types-and-package --package shared
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    echo server devenv loaded !
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  # enterTest = ''
  #   echo "Running tests"
  #   git --version | grep --color=auto "${pkgs.git.version}"
  # '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
