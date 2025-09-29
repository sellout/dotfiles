{
  config,
  flaky,
  lib,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
    ## The Home Manager lorri module only works on Linux, so set it up
    ## system-wide on Darwin.
    darwinConfig.services.lorri = {
      enable = true;
      logFile = "/var/tmp/lorri.log";
    };

    homeConfig = {
      programs.direnv = {
        enable = true;
        config.global = {
          # Ideally could set this for specific projects, see direnv/direnv#793.
          strict_env = true;
          # Nix flakes tend to take a while. This is probably still too short.
          warn_timeout = "60s";
        };
        nix-direnv.enable = true;
      };

      ## Currently this requires running
      ## `systemctl --user daemon-reload && systemctl --user start lorri.socket`
      ## or rebooting after `switch`. See nix-community/lorri#118.
      services.lorri = {
        enable = !pkgs.stdenv.isDarwin;
        enableNotifications = true;
      };
      ## The systemd service isn’t supported on darwin. See
      ## https://github.com/nix-community/lorri#setup-on-other-platforms for
      ## darwin-ish instructions.
      home.packages =
        lib.optional pkgs.stdenv.isDarwin config.services.lorri.package;
    };
  };
}
