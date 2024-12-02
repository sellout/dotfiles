{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.wakatime;
in {
  options.programs.wakatime = {
    enable = lib.mkEnableOption "[Wakatime](https://wakatime.com/)";

    package = lib.mkPackageOption pkgs "Wakatime" {default = ["wakatime"];};

    apiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The file containing the Wakatime API key. It should generally point to
        something from agenix or Nix-SOPS.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        The “settings” section of the wakatime.cfg file.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    ## TODO: Use `xdg.stateFile.` once next Home Manager release is out (see
    ##       nix-community/home-manager#2439)
    home = {
      file."${config.xdg.stateHome}/wakatime/.wakatime.cfg".text = lib.generators.toINI {} {
        settings =
          cfg.settings
          // (
            if cfg.apiKeyFile == null
            then {}
            else {
              api_key_vault_cmd =
                lib.concatStringsSep " " ["cat" cfg.apiKeyFile];
            }
          );
      };

      packages = [cfg.package];

      # May be able to remove this after wakatime/wakatime-cli#558 is fixed.
      sessionVariables.WAKATIME_HOME = "${config.xdg.stateHome}/wakatime";
    };
  };
}
