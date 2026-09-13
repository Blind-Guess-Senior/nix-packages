{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.movie-pool;

  # movie-pool lives in the toy packages, so the `full` overlay is needed here:
  # the `default` one only carries the serious packages.
  repoPkgs = pkgs.extend (import ../../../../../overlays).full;
in
{
  options.services.movie-pool = {
    enable = lib.mkEnableOption "the movie pool web app";

    package = lib.mkPackageOption repoPkgs "movie-pool" {
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
      default = 8080;
      description = "Port the web server listens on.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open {option}`port` in the firewall.";
    };

    period = lib.mkOption {
      type = lib.types.str;
      default = "168h";
      example = "24h";
      description = ''
        Length of one phase, as understood by Go's {manpage}`time.ParseDuration(1)`.
        Exactly one movie is drawn per phase.
      '';
    };

    drawWeekday = lib.mkOption {
      type = lib.types.enum [
        "sun"
        "mon"
        "tue"
        "wed"
        "thu"
        "fri"
        "sat"
      ];
      default = "wed";
      description = "Weekday of the draw.";
    };

    drawTime = lib.mkOption {
      type = lib.types.strMatching "[0-2][0-9]:[0-5][0-9]";
      default = "20:00";
      example = "21:30";
      description = "Time of day of the draw, in the local time zone of the service.";
    };

    limit = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = "How many movies one user may submit per cycle.";
    };

    siteTitle = lib.mkOption {
      type = lib.types.str;
      default = "今天看什么";
      description = "Title shown in the web UI.";
    };

    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "movie-pool";
      description = "Name of the systemd state directory holding `state.json`.";
    };

    timeZone = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "Asia/Shanghai";
      description = ''
        Time zone used to interpret {option}`drawTime` and to display times.
        Defaults to the system time zone.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.movie-pool = {
      description = "Movie pool — collect movie wishes, draw one at random every phase";
      documentation = [ "https://github.com/Blind-Guess-Senior/movie-pool" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        MOVIE_POOL_ADDR = "${cfg.address}:${toString cfg.port}";
        MOVIE_POOL_DATA = "/var/lib/${cfg.stateDirectory}/state.json";
        MOVIE_POOL_PERIOD = cfg.period;
        MOVIE_POOL_DRAW_WEEKDAY = cfg.drawWeekday;
        MOVIE_POOL_DRAW_TIME = cfg.drawTime;
        MOVIE_POOL_LIMIT = toString cfg.limit;
        MOVIE_POOL_SITE_TITLE = cfg.siteTitle;
      }
      // lib.optionalAttrs (cfg.timeZone != null) {
        TZ = cfg.timeZone;
      };

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;

        DynamicUser = true;
        StateDirectory = cfg.stateDirectory;
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/${cfg.stateDirectory}";

        Restart = "on-failure";
        RestartSec = 5;

        # The app is one self contained binary whose only persistent state is
        # the JSON file in its state directory.
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
