{
  config,
  flaky,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
    homeConfig.home.sessionVariables.R_ENVIRON_USER = pkgs.writeTextFile {
      name = "environ";
      text = ''
        R_HISTFILE="${config.xdg.stateHome}/r/history"
        R_PROFILE_USER="${./profile}"
      '';
    };
  };
}
