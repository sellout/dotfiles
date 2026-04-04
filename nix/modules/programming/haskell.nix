{
  config,
  flaky,
  lib,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
    ## GHCup doesn’t currently work under Nix (and there’s not much motivation,
    ## because it doesn’t work on NixOS). If it were in brewCasks, we could at
    ## least move this to the project config, but since we have to get it from
    ## Homebrew directly, this installs it globally.
    darwinConfig.homebrew.brews = ["ghcup"];
    homeConfig = {
      ## Cabal
      xdg.configFile."cabal/config".text = ''
        builddir: ${config.xdg.cacheHome}/cabal/dist
        remote-build-reporting: anonymous
        repository hackage.haskell.org
          url: http://hackage.haskell.org/
      '';

      ## GHCup
      home.sessionVariables.GHCUP_USE_XDG_DIRS = "1";

      ## Haskeline
      ##
      ## Format & preferences described in
      ## https://blog.rcook.org/blog/2018/ghci-custom-key-bindings/
      home.file.".haskeline".text = ''
        bellStyle: VisualBell
        editMode: Emacs
        historyDuplicates: IgnoreConsecutive
        maxHistorySize: Just 1000
        ## Paredit-style brackets
        bind: ( ( ) left
        bind: ) right
        bind: [ [ ] left
        bind: ] right
        bind: { { } left
        bind: } right
        ## :reload (see
        ## https://blog.rcook.org/blog/2018/ghci-custom-key-bindings/)
        bind: f7 : r e l o a d
        keyseq: "\ESC[18~" f7
      '';

      ## Stack
      home.sessionVariables.STACK_XDG = "1";
      xdg.configFile."stack/config.yaml".text = lib.generators.toYAML {} {
        install-ghc = false;
        nix.enable = true;
        templates.params = {
          author-name = config.lib.local.primaryEmailAccount.realName;
          author-email = config.lib.local.primaryEmailAccount.address;
          copyright = config.lib.local.primaryEmailAccount.realName;
          github-username = config.programs.git.settings.github.user;
        };
        ## I don’t use Stack in my own projects. If I did, I would also have
        ## this in my Flaky config for Haskell.
        ##
        ## Unfortunately, this won’t put _all_ the work directories at the
        ## top-level of the project. It will also create .cache/stack-work in
        ## each package directory as well.
        ##
        ## NB: I didn’t change the directory name to “stack” to help tools that
        ##     look for “stack-work” still succeed. Although … those tools
        ##     should query the Stack `work-dir` value.
        work-dir = "${config.xdg.cacheHome}/stack-work";
      };
    };
  };
}
