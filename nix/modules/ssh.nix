{
  config,
  lib,
  pkgs,
  ...
}: let
  runtimeDir = "${config.lib.local.xdg.runtimeDir}/ssh";

  ## `runtimeDir` intentionally gets wiped after the last logout, so we need to
  ## ensure that login shells recreate it.
  profileExtra = ''
    mkdir -p ${lib.escapeShellArg runtimeDir}
  '';
in {
  programs.bash = {inherit profileExtra;};
  programs.zsh = {inherit profileExtra;};
  xsession = {inherit profileExtra;};

  programs.ssh = {
    controlMaster = "auto";
    # This moves the default `controlPath`, but also changes %n to %h, so we
    # share the connection even if we typed different hostnames on the
    # command-line.
    controlPath = "${runtimeDir}/master-%r@%h:%p";
    # Don’t kill the socket as soon as the primary connection dies. Give us
    # 10 minutes to start a new session.
    controlPersist = "10m";
    enable = true;
    extraConfig = ''
      AddKeysToAgent yes
    '';
    ## See https://heipei.github.io/2015/02/26/SSH-Agent-Forwarding-considered-harmful/
    forwardAgent = false;
    package = pkgs.openssh;
    userKnownHostsFile = "${config.xdg.stateHome}/ssh/known_hosts";
  };
}
