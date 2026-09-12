{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.lutris-coverup;
  wrappedPackage = pkgs.writeShellApplication {
    name = "lutris-coverup";

    text = ''
      api_key_file=${lib.escapeShellArg cfg.apiKeyFile}

      if [[ ! -r "$api_key_file" ]]; then
        echo "lutris-coverup: cannot read API key file: $api_key_file" >&2
        exit 1
      fi

      STEAMGRIDDB_API_KEY="$(<"$api_key_file")"
      export STEAMGRIDDB_API_KEY

      exec ${lib.getExe cfg.package} "$@"
    '';
  };

  repoPkgs = pkgs.extend (import ../../overlays).default;
in
{
  options.programs.lutris-coverup = {
    enable = lib.mkEnableOption "lutris-coverup";

    package = lib.mkPackageOption repoPkgs "lutris-coverup" {
      pkgsText = "repoPkgs";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.str;
      example = "/run/secrets/steamgriddb-api-key";
      description = ''
        Absolute path to a file containing the SteamGridDB API key.
        The file is read when lutris-coverup is executed.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ wrappedPackage ];
  };
}
