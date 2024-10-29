{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.configHome}/gnupg/";
    settings.no-default-keyring = true;
  };

  services.gpg-agent = {
    ## NB: Despite having a launchd configuration, this module also has a
    ##     linux-only assertion.
    enable = pkgs.stdenv.hostPlatform.isLinux;
    pinentryPackage = pkgs.pinentry-tty;
    ## TODO: These values are just copied from my manual config. Figure out if
    ##       they’re actually good.
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
  };

  ## TODO: This is stolen from the Home Manager module, because that only works
  ##       for Linux.
  xdg.configFile."gnupg/gpg-agent.conf" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    text = let
      cfg = config.services.gpg-agent;
    in
      lib.concatStringsSep "\n"
      (lib.optional (cfg.enableSshSupport) "enable-ssh-support"
        ++ lib.optional cfg.grabKeyboardAndMouse "grab"
        ++ lib.optional (!cfg.enableScDaemon) "disable-scdaemon"
        ++ lib.optional (cfg.defaultCacheTtl != null)
        "default-cache-ttl ${toString cfg.defaultCacheTtl}"
        ++ lib.optional (cfg.defaultCacheTtlSsh != null)
        "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}"
        ++ lib.optional (cfg.maxCacheTtl != null)
        "max-cache-ttl ${toString cfg.maxCacheTtl}"
        ++ lib.optional (cfg.maxCacheTtlSsh != null)
        "max-cache-ttl-ssh ${toString cfg.maxCacheTtlSsh}"
        ++ lib.optional (cfg.pinentryPackage != null)
        "pinentry-program ${lib.getExe cfg.pinentryPackage}"
        ++ [cfg.extraConfig]);
  };
}
