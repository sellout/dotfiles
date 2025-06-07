## Ntfy – CLI notfication sender – https://ntfy.readthedocs.io/en/
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.ntfy;

  yamlFormat = pkgs.formats.yaml {};

  shellIntegration = shell: {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Whether to configure ntfy for ${shell} shells.
      '';
    };

    foregroundToo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Also notify if shell is in the foreground.
      '';
    };

    longerThan = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.unsigned;
      default = null;
      example = 120;
      description = ''
        Only notify if the command runs longer than N seconds.
      '';
    };
  };
in {
  options.programs.ntfy = {
    enable = lib.mkEnableOption "[ntfy](https://ntfy.readthedocs.io/)";

    package = lib.mkPackageOption pkgs "ntfy" {};

    bashIntegration = shellIntegration "Bash";

    zshIntegration = shellIntegration "Zsh";

    ignoredCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["emacs" "less" "ssh"];
      description = ''
        A list of commands to not run ntfy for.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.nullOr yamlFormat.type;
      default = null;
      example = {
        backends = ["pushover"];
        pushover = {
          api_token = "avufhardk3sz8h93k9mwtk6zg81huy";
          user_key = "u9g3n146iyjz8eypa9rtkr3q9vsbmg";
        };
      };
      description = ''
        A YAML configuration value, as described in
        https://ntfy.readthedocs.io/#configuring-ntfy.
      '';
    };
  };

  config = lib.mkIf cfg.enable (let
    initExtra = shellCfg: let
      args =
        lib.optional shellCfg.foregroundToo "--foreground-too"
        ++ lib.optionals (shellCfg.longerThan != null) ["--longer-than" (builtins.toString shellCfg.longerThan)];
    in ''
      eval "$(ntfy shell-integration ${lib.escapeShellArgs args})"
    '';
  in {
    ## NB: ntfy currently uses the deprecated
    ##     [appdirs](https://github.com/ActiveState/appdirs/issues/188) Python
    ##     library for config locations, which doesn’t respect XDG on darwin.
    ##     Neither of the two contenders to replace it
    ##     ([platformdirs](https://github.com/tox-dev/platformdirs/issues/4) and
    ##     [config-path](https://github.com/barry-scott/config-path)) do either,
    ##     so it’s not worth advocating for ntfy to switch until a library steps
    ##     up.
    home = {
      file."${
        if pkgs.stdenv.isDarwin
        then "Library/Application Support"
        else config.xdg.configHome
      }/ntfy/ntfy.yml" = lib.mkIf (cfg.settings != null) {
        source = yamlFormat.generate "ntfy config" cfg.settings;
      };
      packages = [cfg.package];
      sessionVariables.AUTO_NTFY_DONE_IGNORE =
        lib.concatStringsSep " " cfg.ignoredCommands;
    };

    programs = {
      bash = lib.mkIf cfg.bashIntegration.enable {
        initExtra = initExtra cfg.bashIntegration;
      };
      zsh = lib.mkIf cfg.zshIntegration.enable {
        initContent = initExtra cfg.zshIntegration;
      };
    };
  });
}
