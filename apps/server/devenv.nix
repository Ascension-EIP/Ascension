{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  dotenv.disableHint = true;

  # https://devenv.sh/basics/
  # env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [
    pkgs.air
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
    server.exec = "dev";
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

    minio = {
      enable = true;
      package = pkgs.minio;
      accessKey = "accesskey";
      secretKey = "secretkey";
    };

    rabbitmq = {
      enable = true;
    };
  };

  # https://devenv.sh/scripts/
  scripts.install.exec = ''
    go mod download
  '';

  scripts.update.exec = ''
    go get -u ./...
    go mod tidy
  '';

  scripts.format.exec = ''
    go fmt ./...
  '';

  scripts.lint.exec = ''
    go vet ./...
  '';

  scripts.build.exec = ''
    go build -o bin/server ./cmd/server
  '';

  scripts.test.exec = ''
    go test ./...
  '';

  scripts.dev.exec = ''
    LOG_LEVEL=debug air ./cmd/server
  '';

  scripts.clean.exec = ''
    rm -rf bin
  '';

  scripts.schemas-generate.exec = ''
    	quicktype --src-lang schema $DEVENV_ROOT/../../schemas/*.schema.json \
            -o $DEVENV_ROOT/internal/shared/models.go --lang go --just-types-and-package --package shared
  '';

  # https://devenv.sh/basics/
  # enterShell = ''
  #   hello         # Run scripts directly
  #   git --version # Use packages
  # '';

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
