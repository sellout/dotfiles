{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./ntfy.nix
    ./starship.nix
  ];

  home = {
    packages = [
      pkgs.mosh # SSH client replacement
      pkgs.tree
      pkgs.viddy # `watch` replacement
      pkgs.wget
    ];
    sessionVariables.LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    shellAliases.watch = "${pkgs.viddy}/bin/viddy";
  };

  programs = {
    ## cross-platform terminal emulator
    alacritty = {
      enable = true;
      ## Documented at https://alacritty.org/config-alacritty.html.
      settings = {
        colors = let
          solarized = config.lib.local.solarized "dark";
        in {
          inherit (solarized.ANSI) bright normal;
          cursor = {
            cursor = solarized.color.base0;
            text = solarized.background;
          };
          primary = {
            inherit (solarized) background;
            foreground = solarized.color.base0;
          };
        };
        font = {
          normal.family = config.lib.local.defaultFont.monoFamily;
          size = config.lib.local.defaultFont.size;
        };
      };
    };

    ## shell history database
    atuin = {
      enable = true;
      settings = {
        update_check = false;
        workspaces = true; # filters within whatever git repo you’re in
      };
    };

    bash = {
      enable = true;
      historyControl = ["erasedups" "ignoredups" "ignorespace"];
      historyFile = "${config.xdg.stateHome}/bash/history";
      initExtra = ''
        source "${pkgs.darcs}/share/bash-completion/completions/darcs"
      '';
    };

    ## NB: Running `neowofetch` will skip the pride colors.
    hyfetch = {
      enable = true;
      settings = {
        color_align.mode = "horizontal";
        preset = "nonbinary";
        pride_month_disable = false;
      };
    };

    ntfy = let
      shellIntegration = {
        foregroundToo = true;
        longerThan = 30; # seconds
      };
    in {
      enable = true;
      package = pkgs.ntfy.override {
        ## In Nixpkgs 25.05, this fails when building the requisite Python
        ## dependencies.
        withSlack = false;
      };
      bashIntegration = shellIntegration;
      ignoredCommands = ["emacs" "less" "man" "ssh"];
      zshIntegration = shellIntegration;
    };

    tmux = {
      clock24 = true;
      enable = false; # currently using Emacs’ detached for this
      extraConfig = ''
        bind r source-file ${config.home.homeDirectory}/${config.xdg.configFile."tmux/tmux.conf".target} \;
               display "Reloaded!"

        setw -g mode-mouse on

        set -g status-utf8 on
        set -g status-left "⟦#S⟧"
        set -g status-right "⟦#h⟧"

        setw -g monitor-activity on
        set -g visual-activity on
      '';
    };

    zsh = {
      dotDir = "${config.xdg.configHome}/zsh";
      enable = true;
      autosuggestion.enable = true;
      enableVteIntegration = true;
      history = {
        expireDuplicatesFirst = true;
        ignoreSpace = true;
        path = "${config.xdg.stateHome}/zsh/history";
      };
      initContent = ''
        compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"

        autoload -U colors && colors
      '';
      syntaxHighlighting.enable = true;
    };
  };
}
