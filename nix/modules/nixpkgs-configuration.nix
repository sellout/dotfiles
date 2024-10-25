{
  config,
  lib,
  ...
}: let
  cfg = config.local.nixpkgs;
in {
  options.local.nixpkgs = {
    enable = lib.mkEnableOption "Local Nixpkgs settings";

    allowedUnfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        A list of package names that have been approved for unfree usage.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) cfg.allowedUnfreePackages;
  };
}
