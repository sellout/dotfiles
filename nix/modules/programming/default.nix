{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./common-lisp
    ./haskell.nix
    ./javascript
    ./r
    ./rust.nix
  ];

  home = {
    sessionVariables = {
      IRBRC = config.lib.local.addHome config.xdg.configFile."irb/irbrc".target;
      LEIN_HOME = "${config.xdg.dataHome}/lein";
      MAKEFLAGS = "-j$(nproc)";
      OCTAVE_INITFILE = "${config.lib.local.addHome config.xdg.configFile."octave/octaverc".target}";
      PSQLRC = "${config.lib.local.addHome config.xdg.configFile."psql/psqlrc".target}";
      # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPYCACHEPREFIX
      PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
      # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
      PYTHONUSERBASE = "${config.xdg.stateHome}/python";
      # May be able to remove this after wakatime/wakatime-cli#558 is fixed.
      WAKATIME_HOME = "${config.xdg.stateHome}/wakatime";
    };

    shellAliases = let
      # A builder for quick dev environments.
      #
      # TODO: Since this uses both `nix` and the containing flake, it seems like
      #       there should be a better way to get that information to the
      #       command than having the shell look it up.
      devEnv = devShell: "nix develop " + "env#" + devShell;
      template = template: "nix flake init -t " + "env#" + template;
    in {
      # Show all the flakes relative to the user’s home directory
      list-flakes = "find \"$HOME\" -name flake.nix -exec dirname {} \\; 2>/dev/null | sed -e \"s|^$HOME/||\"";
      list-repos = "find \"$HOME\" \( -name _darcs -o -name .git -o -name .pijul \) -exec dirname {} \\; 2>/dev/null | sed -e \"s|^$HOME/||\"";

      # Takes a path to a derivation (/nix/store/<hash>-foo-<version>) and
      # prints out everything that depends on it, transitively.
      #
      # TODO: `find` all the derivations that match a simple package name to
      #       make this easier to use.
      nix-reverse-deps = "nix-store --query --referrers-closure";

      nix-bash = devEnv "bash";
      nix-c = devEnv "c";
      nix-emacs-lisp = devEnv "emacs-lisp";
      nix-haskell = devEnv "haskell";
      nix-rust = devEnv "rust";
      nix-scala = devEnv "scala";

      nix-bash-template = template "bash";
      nix-c-template = template "c";
      nix-default-template = template "default";
      nix-emacs-lisp-template = template "emacs-lisp";
      nix-haskell-template = template "haskell";
    };
  };

  ## This is for pairing with VSCode users, including Ronnie. Would be ideal
  ## if there were something like Foobits, but that seems effectively dead.
  programs.vscode = {
    enable = true;
    enableExtensionUpdateCheck = false; # Nervous about these two, see how
    enableUpdateCheck = false; # they actually affect things.
    extensions = let
      vpkgs = pkgs.vscode-extensions;
    in
      [
        vpkgs._1Password.op-vscode
        # vpkgs.ms-vsliveshare.vsliveshare
        vpkgs.WakaTime.vscode-wakatime
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "ginfuru-better-solarized-dark-theme";
          publisher = "ginfuru";
          version = "0.9.5";
          hash = "sha256-ySfC3PVRezevItW3kWTiY3U8GgB9p223ZiC8XaJ3koM=";
        }
        {
          name = "unison";
          publisher = "unison-lang";
          version = "1.2.0";
          hash = "sha256-ulm3a1xJxtk+SIQP1sByEqgajd1a4P3oEfVgxoF5GcQ=";
        }
        {
          ## Unfortunately, the nixpkgs version doesrn’t seem to work on darwin.
          name = "vsliveshare";
          publisher = "MS-vsliveshare";
          version = "1.0.5831";
          hash = "sha256-QViwZBxem0z62BLhA0zbFdQL3SfoUKZQx6X+Am1lkT0=";
        }
      ];
    ## TODO: Would like to disable this, but seems like if it’s not mutable,
    ##       then extensions.json never gets created, so VSCode thinks it has
    ##       no extensions.
    # mutableExtensionsDir = false; # See comment on `enable*`.
    package = pkgs.vscodium; # Without non-MIT MS telemetry, etc.
    userSettings = {
      "editor.fontFamily" = pkgs.lib.concatStringsSep ", " [
        "'${config.lib.local.programmingFont}'"
        "'${config.lib.local.defaultMonoFont}'"
        "monospace"
      ];
      "editor.fontLigatures" = true;
      "editor.fontSize" = config.lib.local.defaultFontSize;
      "workbench.colorTheme" = "Solarized Dark";
    };
  };

  xdg = {
    configFile = {
      "gdb/gdbinit".text = ''
        set history filename ${config.xdg.stateHome}/gdb/history
        set history save on
      '';
      "irb/irbrc".text = ''
        IRB.conf[:EVAL_HISTORY] = 200
        IRB.conf[:HISTORY_FILE] = "${config.xdg.stateHome}/irb/history"
        IRB.conf[:SAVE_HISTORY] = 1000
      '';
      "octave/octaverc".text = ''
        history_file("${config.xdg.stateHome}/octave/history")
      '';
      "psql/psqlrc".text = ''
        \set HISTFILE ${config.xdg.stateHome}/psql/history
      '';
    };

    # I used to store these in `$XDG_DOCUMENTS_DIR`, but that directory is often
    # synced (like Dropbox, iCloud, etc.), so this is a parallel directory for
    # things that shouldn’t be synced – like version-controlled directories.
    userDirs.extraConfig.XDG_PROJECTS_DIR =
      config.lib.local.xdg.userDirs.projects.home;
  };
}
