{
  flaky,
  options,
  ...
}: {
  config = flaky.lib.multiConfig options {
    homeConfig.home.sessionVariables.NPM_CONFIG_USERCONFIG = ./npmrc;
  };
}
