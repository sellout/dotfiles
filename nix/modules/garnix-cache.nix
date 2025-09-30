{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.garnix.cache;
in {
  options.garnix.cache = {
    enable = lib.mkEnableOption "garnix cache";

    config = lib.mkOption {
      type = lib.types.enum ["on" "trusted" "off"];
      default = "trusted";
      example = "on";
      description = ''
        Whether the garnix cache should be `"on"`, `"trusted"`, or `"off"` in
        the Nix config.
      '';
    };

    netrcFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        The path to the netrc file to use. This allows the settings to be stored
        outside of the Nix store, and to use encryption like agenix or sops-nix,
        which can be important for multi-user machines.
      '';
    };

    ## TODO: See if this exists elsewhere in the config, and default to that, if
    ##       so.
    githubUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The GitHub user name for access to private build artifacts.
      '';
    };

    accessToken = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The garnix access token to access the cache for private build artifacts.
        An access token can be created at https://garnix.io/account.
      '';
    };
  };

  config.nix.settings = lib.mkIf cfg.enable (lib.mkMerge [
    (
      if cfg.config == "on"
      then {
        extra-substituters = ["https://cache.garnix.io"];
        extra-trusted-public-keys = [
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        ];
      }
      else if cfg.config == "trusted"
      then {
        extra-trusted-public-keys = [
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        ];
        extra-trusted-substituters = ["https://cache.garnix.io"];
      }
      else {}
    )
    (
      if cfg.netrcFile != null
      then {
        narinfo-cache-positive-ttl = 3600;
        netrc-file = cfg.netrcFile;
      }
      else if cfg.githubUser != null && cfg.accessToken != null
      then {
        narinfo-cache-positive-ttl = 3600;
        netrc-file = pkgs.writeTextFile {
          name = "netrc";
          text = ''
            machine cache.garnix.io
              login ${cfg.githubUser}
              password ${cfg.accessToken}
          '';
        };
      }
      else {}
    )
  ]);
}
