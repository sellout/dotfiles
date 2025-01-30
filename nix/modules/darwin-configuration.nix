### Most configuration should be managed per-user via home-manager. This only
### contains things that are provided globally for some reason.
{
  config,
  dotfiles,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./games.nix
    ./input-devices.nix
    ./nix-configuration.nix
    ./nixpkgs-configuration.nix
    ./vcs
  ];

  environment = {
    etc.hosts.source = ../../root/etc/hosts;
    extraOutputsToInstall = ["devdoc" "doc"];
    pathsToLink = ["/share/fonts"];
    ## TODO: This is a workaround for LnL7/nix-darwin#947.
    profiles = lib.mkOrder 801 [
      "$XDG_STATE_HOME/nix/profile"
      "$HOME/.local/state/nix/profile"
    ];
    systemPackages = [
      ## remote connections
      pkgs.mosh
      ## Nix
      pkgs.home-manager
      # pkgs.nix-du # fails to build on aarch64
      pkgs.nox
      ## system
      pkgs.cacert
      pkgs.coreutils
      pkgs.gnupg
      pkgs.yubikey-manager
      pkgs.yubikey-personalization
    ];
    systemPath = [
      # TODO: Support this via the homebrew module.
      config.homebrew.brewPrefix
    ];
  };

  fonts.packages = [
    pkgs.inconsolata
    pkgs.lexica-ultralegible
  ];

  # The preferred location of applications is, in order:
  # 1. home.nix#home.packages (~/Applications/Home Manager Apps)
  # 1a. pkgs.nixcasks
  # 2. environment.systemPackages (/Applications/Nix Apps)
  # 3. homebrew.casks (/Applications/Homebrew Apps)
  # 4. homebrew.masApps (/Applications)
  # 5. manually installed (~/Applications)
  #
  # NB: The last two may also end up with some additional apps in them, because
  #     some apps do not like to be run from other locations. E.g., 1Password is
  #     managed by `homebrew.casks`, but is installed in /Applications so that
  #     the browser plugins can communicate with it. These apps should have
  #     comments by them indicating where they live and why.
  #
  # NB: Ideally this would be managed in home.nix, but that's not yet supported.
  homebrew = {
    caskArgs = {
      appdir = "/Applications/Homebrew Apps";
      fontdir = "/Library/Fonts/Homebrew Fonts";
    };
    ## NB: `greedy = true;` in here means that I’ve ensured that the app _won’t_
    ##     auto-update. However, that will not apply when this transfers to a
    ##     new machine, so need a better approach. See
    ##     https://docs.brew.sh/FAQ#why-arent-some-apps-included-during-brew-upgrade
    ##     Use
    ##   > brew info --cask --json=v2 $(brew ls --cask) \
    ##   >   | nix shell nixpkgs#jq \
    ##   >     --command jq -r '.casks[]|select(.auto_updates==true)|.token'
    ##     to see which casks need `greedy = true;` in order to be upgraded by
    ##     Homebrew.
    casks = [
      ## This is also installed by home.nix#home.packages, but that _probably_
      ## has even more of the “wrong location” issue mentioned below, as it’s
      ## simply an alias to the Nix store, so keep this around until I’m willing
      ## to fight with that.
      {
        name = "1password";
        ## Doesn’t integrate with browsers properly if moved. Search email for
        ## #PKL-58745-842 for more info.
        args = {appdir = "/Applications";};
        greedy = true;
      }
      "bitcoin-core"
      "bowtie"
      # "delicious-library" # perhaps removed?
      "eagle" # doesn't respect appdir # not available on darwin via Nix
      "google-drive" # doesn't respect appdir
      "psi"
      "r" # doesn't respect appdir
      "racket"
      "spotify" # not available on darwin via Nix
      "timemachineeditor"
      # "virtualbox" # requires Intel architecture
      {
        # not available on darwin via Nix
        name = "vlc";
        greedy = true;
      }
      "webex-meetings" # I don’t know how to control auto-update
      # "whatsapp" # currently subsumed by ferdium
      # "wire" # currently subsumed by ferdium
      # not available on darwin via Nix, but seems like it should be
      "xquartz" # doesn't respect appdir # broken in Nix
      "yousician"
    ];
    enable = true;
    global.brewfile = true;
    masApps = {
      "1Password for Safari" = 1569813296;
      BaseCamp = 411052274; # Garmin, not DHH
      "Blink Lite" = 431473881;
      "Clozure CL" = 489900618;
      Deliveries = 290986013;
      FocusMask = 435999818;
      GarageBand = 682658836;
      Harvest = 506189836;
      iMovie = 408981434;
      Keynote = 409183694;
      Numbers = 409203825;
      "ODAT Tracker" = 448831531;
      Pages = 409201541;
      "Picture Window" = 507262984;
      "Prime Video" = 545519333;
      reMarkable = 1276493162;
      "Remote Mouse" = 403195710;
      SoundCloud = 412754595;
      # Twitter = 409789998; # currently subsumed by ferdium
      Xcode = 497799835;
    };
    ## NB: These settings unfortunately make `darwin-rebuild switch`
    ##     non-idempotent, but the alternative is having Homebrew just be
    ##     outdated forever (because I’ll never do it manually).
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    ## Runs `nix-store --optimise` on a timer.
    optimise.automatic = true;
  };

  nixpkgs.overlays = [dotfiles.overlays.darwin];

  programs = {
    bash = {
      enable = true;
      completion.enable = true;
      interactiveShellInit = ''
        # System-wide .bashrc file for interactive bash(1) shells.
        if [ -z "$PS1" ]; then
          return
        fi

        PS1='\h:\W \u\$ '
        # Make bash check its window size after a process completes
        shopt -s checkwinsize

        [ -r "/etc/bashrc_$TERM_PROGRAM" ] && . "/etc/bashrc_$TERM_PROGRAM"
      '';
    };
    zsh = {
      enable = true;
      enableSyntaxHighlighting = true;
      interactiveShellInit = ''
        # Correctly display UTF-8 with combining characters.
        if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
          setopt combiningchars
        fi

        disable log
      '';
      loginShellInit = ''
        # system-wide environment settings for zsh(1)
        if [ -x /usr/libexec/path_helper ]; then
          eval `/usr/libexec/path_helper -s`
        fi
      '';
    };
  };

  security.pam.enableSudoTouchIdAuth = true;

  services = {
    nix-daemon.enable = true;

    tailscale = {
      enable = true;
      ## TODO: Remove this (from nix-darwin, too) once tailscale/tailscale#8436
      ##       is fixed.
      overrideLocalDns = true;
    };
  };

  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
}
