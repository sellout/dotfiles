{
  config,
  flaky,
  options,
  ...
}: {
  config = flaky.lib.multiConfig options {
    homeConfig.home.sessionVariables = {
      # https://docs.python.org/3/using/cmdline.html#envvar-PYTHON_HISTORY
      PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
      # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPYCACHEPREFIX
      PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
      # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
      PYTHONUSERBASE = "${config.xdg.stateHome}/python";
    };
  };
}
