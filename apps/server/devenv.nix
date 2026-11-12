{
  pkgs,
  config,
  ...
}:

{
  dotenv.disableHint = true;

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
      after = [
        "devenv:processes:postgres"
        "devenv:processes:rabbitmq"
        "devenv:processes:rustfs"
      ];
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
      after = [
        "devenv:processes:postgres"
        "devenv:processes:rustfs"
      ];
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
          name = "ascension";
          user = "ascension";
          pass = "ascension";
        }
      ];
      listen_addresses = "localhost";
    };

    rustfs = {
      enable = true;
      consoleEnable = true;
      accessKey = "ascension";
      secretKey = "ascension";
    };

    rabbitmq = {
      enable = true;
      managementPlugin.enable = true;
      configItems = {
        default_user = "ascension";
        default_pass = "ascension";
      };
    };
  };

  # https://devenv.sh/scripts/
  scripts.schemas-generate.exec = ''
    	quicktype --src-lang schema $DEVENV_ROOT/../../schemas/*.schema.json \
            -o $DEVENV_ROOT/internal/shared/models.go --lang go --just-types-and-package --package shared
  '';

  scripts.setup.exec = "go install -tags postgres github.com/golang-migrate/migrate/v4/cmd/migrate@v4.19.1";

  scripts.install.exec = "go mod download";

  scripts.format.exec = "go fmt ./...";

  scripts.lint.exec = "go vet ./...";

  scripts.build.exec = "secretspec run -- go build -o bin/server ./cmd/server";

  scripts.test.exec = "secretspec run -- go test ./...";

  scripts.update.exec = ''
    go get -u ./...
    go mod tidy
  '';

  scripts.migrate-db.exec = ''
    echo "postgres://${config.secretspec.secrets.POSTGRES_USER}:${config.secretspec.secrets.POSTGRES_PASSWORD}@${
      config.secretspec.secrets.POSTGRES_HOST or "localhost"
    }:${
      config.secretspec.secrets.POSTGRES_PORT or "5432"
    }/${config.secretspec.secrets.POSTGRES_DB}?sslmode=disable"
        migrate -path internal/outbound/postgres/migrations \
          -database "postgres://${config.secretspec.secrets.POSTGRES_USER}:${config.secretspec.secrets.POSTGRES_PASSWORD}@${
            config.secretspec.secrets.POSTGRES_HOST or "localhost"
          }:${
            config.secretspec.secrets.POSTGRES_PORT or "5432"
          }/${config.secretspec.secrets.POSTGRES_DB}?sslmode=disable" \
          up
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
