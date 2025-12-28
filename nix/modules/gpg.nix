{
  config,
  lib,
  pkgs,
  ...
}: let
  ## This returns an attrSet to use for all XDG references for a particular
  ## program.
  xdgPathsFor = program: {
    cacheDir = "${config.xdg.cacheHome}/${program}";
    configDir = "${config.xdg.configHome}/${program}";
    dataDir = "${config.xdg.dataHome}/${program}";
    stateDir = "${config.xdg.stateHome}/${program}";
  };

  gpgDirSegment = "gnupg";
  gpgXdg = xdgPathsFor gpgDirSegment;
in {
  ## This helps ensure that we select the tty pinentry, and that it works. See
  ## https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html#index-GPG_005fTTY
  ## for details.
  home.sessionVariables.GPG_TTY = "$(tty)";

  programs.gpg = {
    enable = true;
    ## FIXME: Something in this line is causing “invalid regular expression ''”.
    homedir = gpgXdg.configDir;
    settings.no-default-keyring = true;
  };

  services.gpg-agent = let
    seconds = 1;
    minutes = 60 * seconds;
    hours = 60 * minutes;
    days = 24 * hours;
    weeks = 7 * days;
  in {
    ## NB: Despite having a launchd configuration, this module also has a
    ##     linux-only assertion.
    enable = pkgs.stdenv.hostPlatform.isLinux;
    ## FIXME: Modify these based on system configuration. E.g., if
    ## `pinentry_mac` lets me use my fingerprint, then the times can be quite
    ## short. But if I have to re-enter the GPG password, then extend them,
    ## because that password is annoying.
    ##
    ## Time since last GPG command that credentials will remain cached.
    defaultCacheTtl = 1 * hours;
    ## Time since last password entry that credentials will remain cached.
    maxCacheTtl = 2 * hours;
    extraConfig = lib.concatLines [
      ## Enabling debugging globally, because pinentry causes so many
      ## problems. Better to have the info than to have to rebuild to debug.
      "debug-pinentry"
      "debug ipc" # required for `debug-pinentry` to have an effect
      "log-file ${gpgXdg.stateDir}/agent.log"
    ];
    pinentry.package = pkgs.pinentry-tty;
  };

  ## Ensure the state directory for GPG exists.
  ##
  ## TODO: Extract this pattern somewhere. It is used to ensure certain
  ## directories exist, because apps sometimes just silently fail to write their
  ## output if the target directory doesn’t exist.
  home.activation.createGpgStateDir =
    lib.hm.dag.entryAfter ["writeBoundary"]
    "mkdir -p ${lib.escapeShellArg gpgXdg.stateDir}";

  ## TODO: This is stolen from the Home Manager module, because that only works
  ##       for Linux.
  xdg.configFile."${gpgDirSegment}/gpg-agent.conf" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
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
        ++ lib.optional (cfg.pinentry.package != null)
        "pinentry-program ${lib.getExe cfg.pinentry.package}"
        ++ [cfg.extraConfig]);
  };
}
