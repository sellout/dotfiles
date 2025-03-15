## Ntfy – CLI notfication sender – https://ntfy.readthedocs.io/en/
{
  lib,
  pkgs,
  ...
}: let
  initExtra = ''
    eval "$(ntfy shell-integration --foreground-too --longer-than 2)"
  '';
in {
  home = {
    packages = [pkgs.ntfy];
    sessionVariables.AUTO_NTFY_DONE_IGNORE = lib.concatStringsSep " " [
      "emacs"
      "less"
      "man"
      "ssh"
    ];
  };

  programs = {
    bash = {inherit initExtra;};
    zsh = {inherit initExtra;};
  };
}
