### Most configuration should be managed per-user via home-manager. This only
### contains things that are provided globally for some reason.
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./nix-configuration.nix
  ];

  environment = {
    etc.hosts.source = ../../root/etc/hosts;
    extraOutputsToInstall = ["devdoc" "doc"];
    pathsToLink = ["/share/fonts"];
    systemPackages = [
      ## source control -- good to have globally, so users can fetch initial
      ## configurations
      pkgs.breezy
      pkgs.cvs
      pkgs.darcs
      # not doing `git = super.gitFull` in the overlay, because then everything
      # gets rebuilt, but want it here for email support
      pkgs.gitFull
      pkgs.pijul
      pkgs.subversion
      ## remote connections
      pkgs.mosh
      ## Nix
      pkgs.home-manager
      pkgs.nix-du
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

  fonts = {
    fontDir.enable = false; # enabling this trashes manually-installed fonts
    fonts = [
      pkgs.atkinson-hyperlegible # https://brailleinstitute.org/freefont
      pkgs.inconsolata
    ];
  };

  # The preferred location of applications is, in order:
  # 1. home.nix#home.packages (~/Applications/Home Manager Apps)
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
      ## simply a symlink to the Nix store, so keep this around until I’m
      ## willing to fight with that.
      {
        name = "1password";
        ## Doesn’t integrate with browsers properly if moved. Search email for
        ## #PKL-58745-842 for more info.
        args = {appdir = "/Applications";};
        greedy = true;
      }
      {
        # license only works for version 6
        name = "ableton-live-standard";
        greedy = true;
      }
      {
        name = "acorn";
        greedy = true;
      }
      {
        name = "adium";
        greedy = true;
      }
      {
        name = "alfred";
        greedy = true;
      }
      "anki" # not available on darwin via Nix
      "arduino"
      {
        name = "bartender";
        greedy = true;
      }
      "beamer"
      "bowtie"
      "calibre"
      "controlplane"
      # "delicious-library" # perhaps removed?
      {
        # license only works for version 2
        name = "devonthink";
        greedy = true;
      }
      # "discord" # currently subsumed by ferdium
      "disk-inventory-x"
      "dosbox" # x86 game emulator
      {
        name = "dropbox";
        # I don’t know how to control auto-update
        greedy = true;
      }
      "eagle" # doesn't respect appdir # not available on darwin via Nix
      # "evernote" # currently subsumed by ferdium
      {
        name = "fantastical";
        greedy = true;
      }
      {
        # not available on darwin via Nix
        name = "ferdium";
        greedy = true;
      }
      {
        # not available on darwin via Nix
        name = "firefox";
        greedy = true;
      }
      "freemind"
      {
        # not available on darwin via Nix
        name = "github";
        # I don’t know how to control auto-update
        greedy = true;
      }
      "google-drive" # doesn't respect appdir
      "gotomeeting"
      "growlnotify"
      "hammerspoon"
      "handbrake"
      "imageoptim"
      {
        # not available on darwin via Nix
        name = "keybase";
        greedy = true;
      }
      {
        name = "kindle";
        greedy = true;
      }
      "lastfm"
      "marathon"
      "mendeley"
      "mumble" # not available on darwin via Nix
      "netnewswire"
      "obs" # not available on darwin via Nix
      {
        name = "omnifocus";
        greedy = true;
      }
      "omnigraffle"
      "omnioutliner"
      "openoffice"
      "plex" # not available on darwin via Nix
      "plex-media-server" # not available on darwin via Nix
      "pokemon-trading-card-game-online" # for the kids
      "processing"
      "psi"
      "quicksilver"
      "r" # doesn't respect appdir
      "racket"
      {
        name = "remarkable";
        # I don’t know how to control auto-update
        greedy = true;
      }
      "rowmote-helper"
      "screenflow"
      "scrivener"
      {
        # not available on darwin via Nix
        name = "signal";
        greedy = true;
      }
      "skitch"
      "skype" # doesn't respect appdir
      # "slate" # perhaps removed?
      "spotify" # not available on darwin via Nix
      "squeak" # not available on darwin via Nix
      # not available on darwin via Nix
      # I don’t know how to control auto-update
      "steam"
      "stellarium"
      # "sysbench" # not available on darwin via Nix and apparently removed from Hombrew
      "timemachineeditor"
      "tor-browser" # not available on darwin via Nix
      "tower"
      "transmission"
      "ukelele"
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
      Robotek = 462238382;
      SoundCloud = 412754595;
      # Twitter = 409789998; # currently subsumed by ferdium
      Xcode = 497799835;
    };
    onActivation.cleanup = "uninstall";
    taps = ["homebrew/cask"];
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    # TODO: Enable once NixOS/nix#7273 is fixed.
    settings.auto-optimise-store = false; # true;
  };

  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
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
    activate-system.enable = true;

    nix-daemon.enable = true;

    tailscale = {
      enable = true;
      ## TODO: Remove this (from nix-darwin, too) once tailscale/tailscale#8436
      ##       is fixed.
      overrideLocalDns = true;
    };
  };

  system = {
    # NB: It is also possible to set _some_ macOS defaults in home.nix:
    #    `targets.darwin.defaults`, which is the preferred location. Please
    #     check there before adding a setting here.
    defaults = {
      dock = {
        autohide = true;
        minimize-to-application = true;
        mru-spaces = false; # helps yabai work properly
        orientation = "left";
        showhidden = true;
      };
      finder = {
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXPreferredViewStyle = "Nlsv"; # list view
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      LaunchServices.LSQuarantine = false;
      NSGlobalDomain = {
        AppleInterfaceStyleSwitchesAutomatically = true;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
      };
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
      # FIXME: Errors with “Could not write domain com.apple.universalaccess;
      #        exiting” during activation. See mathiasbynens/dotfiles#1027.
      # universalaccess = {
      #   closeViewScrollWheelToggle = true;
      #   reduceTransparency = true;
      # };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    stateVersion = 4;
  };
}
