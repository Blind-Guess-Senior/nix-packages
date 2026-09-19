{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.game-stats;

  # game-stats lives in the toy packages, so the `full` overlay is needed here:
  # the `default` one only carries the serious packages.
  repoPkgs = pkgs.extend (import ../../../../../overlays).full;
in
{
  options.services.game-stats = {
    enable = lib.mkEnableOption "the game-stats web app";

    package = lib.mkPackageOption repoPkgs "game-stats" {
      pkgsText = "repoPkgs";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      example = "127.0.0.1";
      description = "Address the web server binds to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8787;
      description = "Port the web server listens on.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open {option}`port` in the firewall.";
    };

    basePath = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "/game-stats";
      description = ''
        Fallback for a reverse proxy that strips a path prefix and cannot say
        which one. It is exported as BASE_PATH.

        Normally nothing goes here. The app works out its own prefix per
        request, so one build serves the root and any number of prefixes at
        the same time:

        - proxy forwards the path unchanged — the prefix is read from the path;
        - proxy strips it — set `proxy_set_header X-Forwarded-Prefix /game-stats;`
          and that header decides for the request;
        - no proxy — root deployment.
      '';
      apply = value: lib.removeSuffix "/" (if value == "" || lib.hasPrefix "/" value then value else "/" + value);
    };

    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "game-stats";
      description = "Name of the systemd state directory holding the SQLite file.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.game-stats = {
      description = "game-stats — score keeping for a handful of games";
      documentation = [ "https://github.com/Rhynic-Studio/GameStats" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        HOST = cfg.address;
        PORT = toString cfg.port;
        DB_PATH = "/var/lib/${cfg.stateDirectory}/stats.db";
      }
      // lib.optionalAttrs (cfg.basePath != "") {
        BASE_PATH = cfg.basePath;
      };

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;

        DynamicUser = true;
        StateDirectory = cfg.stateDirectory;
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/${cfg.stateDirectory}";

        Restart = "on-failure";
        RestartSec = 5;

        # The app is one node process whose only persistent state is the SQLite
        # file in its state directory.
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
