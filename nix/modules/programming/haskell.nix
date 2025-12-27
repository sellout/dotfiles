{
  config,
  lib,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    # TODO: I don’t know how to relocate `$HOME/.cabal/setup-exe-cache` and
    #       `$HOME/.cabal/store`. Hopefully they use `CABAL_DIR`.
    CABAL_CONFIG = "${pkgs.writeTextFile {
      name = "cabal-config";
      text = ''
        repository hackage.haskell.org
          url: http://hackage.haskell.org/packages/archive
        remote-repo-cache: ${config.xdg.cacheHome}/cabal/packages
        world-file: ${config.xdg.stateHome}/cabal/world
        extra-prog-path: ${config.xdg.dataHome}/cabal/bin
        build-summary: ${config.xdg.stateHome}/cabal/logs/build.log
        remote-build-reporting: anonymous
        jobs: $ncpus
        install-dirs user
          prefix: ${config.xdg.stateHome}/cabal
          bindir: ${config.xdg.dataHome}/cabal/bin
          datadir: ${config.xdg.dataHome}/cabal
      '';
    }}";
    CABAL_DIR = "${config.xdg.stateHome}/cabal";
    STACK_XDG = "1";
  };

  xdg.configFile = {
    "stack/config.yaml".text = lib.generators.toYAML {} {
      nix.enable = true;
      templates.params = {
        author-name = config.lib.local.primaryEmailAccount.realName;
        author-email = config.lib.local.primaryEmailAccount.address;
        copyright = config.lib.local.primaryEmailAccount.realName;
        github-username = config.programs.git.settings.github.user;
      };
    };
  };
}
