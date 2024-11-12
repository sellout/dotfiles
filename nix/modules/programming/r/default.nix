{
  config,
  pkgs,
  ...
}: {
  home.sessionVariables.R_ENVIRON_USER = pkgs.writeTextFile {
    name = "environ";
    text = ''
      R_HISTFILE="${config.xdg.stateHome}/r/history"
      R_PROFILE_USER="${./profile}"
    '';
  };
}
