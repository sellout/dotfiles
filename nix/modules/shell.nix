{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./ntfy.nix];

  home = {
    packages = [
      pkgs.mosh # SSH client replacement
      pkgs.pinentry.tty
      pkgs.tree
      pkgs.viddy # `watch` replacement
      pkgs.wget
    ];
    sessionVariables.LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    shellAliases.watch = "${pkgs.viddy}/bin/viddy";
  };

  programs = {
    ## shell history database
    atuin = {
      enable = true;
      settings.update_check = false;
    };

    bash = {
      enable = true;
      historyControl = ["erasedups" "ignoredups" "ignorespace"];
      historyFile = "${config.xdg.stateHome}/bash/history";
      initExtra = ''
        source "${pkgs.darcs}/share/bash-completion/completions/darcs"
      '';
    };

    ## A shell prompt customizer (https://starship.rs/)
    starship = let
      ## Group some of the modules.
      environment = [
        "$nix_shell"
        "$guix_shell"
      ];
      language = [
        "$c"
        "$cmake"
        "$cobol"
        "$daml"
        "$dart"
        "$deno"
        "$dotnet"
        "$elixir"
        "$elm"
        "$erlang"
        "$fennel"
        "$golang"
        "$haskell"
        "$haxe"
        "$helm"
        "$java"
        "$julia"
        "$kotlin"
        "$gradle"
        "$lua"
        "$nim"
        "$nodejs"
        "$ocaml"
        "$opa"
        "$perl"
        "$php"
        "$pulumi"
        "$purescript"
        "$python"
        "$raku"
        "$rlang"
        "$red"
        "$ruby"
        "$rust"
        "$scala"
        "$solidity"
        "$swift"
        "$terraform"
        "$vlang"
        "$vagrant"
        "$zig"
      ];
      vcs = [
        "$pijul_channel"
        "$vcsh"
        "$fossil_branch"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$hg_branch"
      ];
    in {
      enable = true;
      settings = {
        directory.truncate_to_repo = false;
        format = lib.concatStrings (
          [
            "$username"
            "$hostname"
            "$localip"
            "$directory"
          ]
          ++ vcs
          ++ environment
          ++ language
          ++ ["$all"]
        );
        hostname = {
          ssh_symbol = "";
          ## TODO: Ideally the “:” would appear whenever there’s _anything_
          ##       before the path, likethe local non-logged-in user.
          format = "[$ssh_symbol$hostname]($style):";
        };
        nix_shell = {
          format = "[$symbol$state]($style) ";
          heuristic = true;
          impure_msg = "!";
          pure_msg = "";
          # Just removes the trailing space (which would be better in the
          # `format`, IMO).
          symbol = "❄️";
          unknown_msg = "?";
        };
        pijul_channel.disabled = false;
        shlvl = {
          disabled = false;
          symbol = "🪆";
        };
        ## TODO: Ideally the “@” would only appear when there’s a hostname, but
        ##       we need _something_ to separate the user from the path.
        ## TODO: Would like to use the ‘BUST IN SILHOUETTE’ emoji instead of the
        ##       actual username, but on macOS that codepoint gets Mac styling,
        ##       which doesn’t allow coloring (and setting this on remote Linux
        ##       machines doesn’t help because it still gets rendered by the
        ##       client-side Mac. Also, would be great if an ssh user could be
        ##       elided if it matches the local username.
        username.format = "[$user]($style)@";
      };
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
      dotDir = "${config.lib.local.xdg.config.rel}/zsh";
      enable = true;
      autosuggestion.enable = true;
      enableVteIntegration = true;
      history = {
        expireDuplicatesFirst = true;
        ignoreSpace = true;
        path = "${config.xdg.stateHome}/zsh/history";
      };
      initExtra = ''
        compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"

        autoload -U colors && colors
      '';
      syntaxHighlighting.enable = true;
    };
  };
}
