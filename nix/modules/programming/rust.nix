{
  config,
  flaky,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
    homeConfig.home = {
      file = let
        toml = pkgs.formats.toml {};
      in {
        # NOTE: This currently gets put in `config.xdg.cacheHome`, since most of
        #       the stuff in `$CARGO_HOME` is cached data. However, this means
        #       that the Cargo config can be erased (until the next
        #       `home-manager switch`) if the cache is cleared.
        "${config.lib.local.removeHome config.home.sessionVariables.CARGO_HOME}/config.toml".source = toml.generate "Cargo config.toml" {
          ## WAIT: Currently, overriding this here causes it to be relative to
          ##       `HOME`, which makes every build overwrite every other. See
          ##       rust-lang/cargo#7843.
          # build.target-dir =
          #   "{workspace}/${config.lib.local.xdg.state.rel}/cargo";
          ## Cargo writes executables to the bin/ subdir of this path.
          install.root = config.lib.local.xdg.local.home;
        };
      };

      sessionVariables = {
        CARGO_HOME = "${config.xdg.cacheHome}/cargo";
        RUSTUP_HOME = "${config.xdg.stateHome}/rustup";
      };
    };
  };
}
