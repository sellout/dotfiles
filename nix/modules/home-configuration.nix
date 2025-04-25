{
  agenix,
  config,
  dotfiles,
  lib,
  pkgs,
  ...
}: {
  imports = [
    agenix.homeManagerModules.age
    ./direnv.nix
    ./emacs
    ./firefox.nix
    ./gpg.nix
    ./i18n.nix
    ./i3.nix
    ./input-devices.nix
    ./locale.nix
    ./nix-configuration.nix
    ./nixpkgs-configuration.nix
    ./programming
    ./shell.nix
    ./ssh.nix
    ./tex.nix
    ./vcs
    ./wakatime.nix
  ];

  accounts = {
    calendar.basePath = "${config.xdg.stateHome}/calendar";
    contact.basePath = "${config.xdg.stateHome}/contact";
    email.maildirBasePath = "${config.xdg.stateHome}/Maildir";
  };

  ## TODO: The default for this isn’t actually a path, but rather
  ##       expands to a path in the shell. See ryantm/agenix#300.
  age.secretsDir = "${config.lib.local.xdg.runtimeDir}/agenix";

  fonts.fontconfig.enable = true;

  # FIXME: This and `config.home.activation.aliasApplications` below _may_ be
  #        needed because the alias (rather than symlink) things into
  #        ~/Applications/Home Manager Apps. If that turns out to be the case,
  #        we should open an issue against home-manager to switch to aliasing on
  #        darwin.
  disabledModules = ["targets/darwin/linkapps.nix"];

  home = {
    activation = {
      ## TODO: Should move a version of this to Home Manager itself.
      setUpErrorTrap = lib.hm.dag.entryBefore ["checkLaunchAgents"] ''
        trap '_iError "Home Manager activation failed with $? at $(basename $0):$LINENO"; exit 1' ERR
      '';

      # TODO: This should be removed once
      #       https://github.com/nix-community/home-manager/issues/1341 is
      #       closed.
      aliasApplications =
        lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        (lib.hm.dag.entryAfter ["writeBoundary"] ''
          IFS=$'\n'
          app_folder="Home Manager Apps"
          app_path="$(echo ~/Applications)/$app_folder"
          tmp_path="$(mktemp -dt "$app_folder.XXXXXXXXXX")" || exit 1
          # NB: aliasing ".../home-path/Applications" to
          #    "~/Applications/Home Manager Apps" doesn't work (presumably
          #     because the individual apps are symlinked in that directory, not
          #     aliased). So this makes "Home Manager Apps" a normal directory
          #     and then aliases each application into there directly from its
          #     location in the nix store.
          for app in \
            $(find "$newGenPath/home-path/Applications" -type l -exec \
              readlink -f {} \;)
          do
            $DRY_RUN_CMD ${pkgs.mkalias}/bin/mkalias "$app" "$tmp_path/$(basename "$app")"
          done
          # TODO: Wish this was atomic, but it’s only tossing symlinks
          $DRY_RUN_CMD [ -e "$app_path" ] && rm -r "$app_path"
          $DRY_RUN_CMD mv "$tmp_path" "$app_path"
        '');

      # Stolen from https://twitter.com/volpegabriel87/status/1585204086240346112
      reportChanges = let
        profiles = "/nix/var/nix/profiles/per-user/${config.home.username}/home-manager-*-link";
      in
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          # Disable nvd if there are less than 2 hm profiles.
          if [ $(ls -d1v ${profiles} 2>/dev/null | wc -l) -lt 2 ]; then
            echo "Skipping changes report..."
          else
            ${pkgs.nvd}/bin/nvd diff $(ls -d1v ${profiles} | tail -2)
          fi
        '';

      reviewXdgNinja = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${pkgs.xdg-ninja}/bin/xdg-ninja --skip-unsupported || true
      '';
    };

    extraOutputsToInstall = ["devdoc" "doc"];

    ## We try to keep config files in `config.xdg.configHome`, but this isn’t
    ## always possible. This section defines files that must be located
    ## elsewhere. If they’re not defined inline, they should exist in
    ## "../home/${config.lib.local.xdg.config.rel}" and be linked to their
    ## non-XDG-compliant location here.
    ##
    ## 1. use a `config.home.sessionVariables` entry to relocate the file under
    ##   `config.xdg.configHome` or
    ## 2. use the application’s preferred config file name (we don’t care if it
    ##    has a leading `.` or not, since we use `ls -A`, etc to make dotfiles
    ##    visible whenever possible.
    file = {
      # There’s no $XDG_BIN_HOME in the spec for some reason, so these files
      # aren’t managed under the xdg module.
      # TODO: Can’t just link the directory, because `executable = true` doesn’t
      #       work then. See nix-community/home-manager#3594.
      "${config.lib.local.xdg.bin.rel}/edit" = {
        executable = true;
        source = ./edit;
      };
      "${config.lib.local.xdg.bin.rel}/emacs-pager" = {
        executable = true;
        source = ./emacs-pager;
      };
      ## This is ostensibly used by a local SMTP daemon to forward emails to the
      ## appropriate account, but is also displayed by `finger`.
      ".forward".text = config.lib.local.primaryEmailAccount.address;
    };

    ## Ideally, packages are provided by projects (e.g., Nix flakes + direnv)
    ## rather than installed globally. This allows for, say, the correct
    ## compiler version to be used for each project. However, some things are
    ## useful outside of a project, and those get installed more broadly (see
    ## ./darwin-configuration.nix#homebrew for where to install various
    ## packages, including here). Between those two extremes, there is
    ## ./emacs/, which is where most packages are managed, behind an Emacs
    ## interface, but there are exceptions for a few reasons: (inexhaustive)
    ##
    ## • the package contains something that needs to run as a service or
    ##   otherwise be available outside of the Emacs process;
    ## • there are reasons to have the package even when Emacs is not working,
    ##   etc. for some reason (e.g., we want to have Nix itself and VCSes
    ##   available so we can pull new versions and build things when we need
    ##   to); or
    ## • the package has its own GUI that we prefer over any Emacs interface.
    packages = let
      fonts = [
        {package = pkgs.fira;}
        {
          package = pkgs.fira-code;
          nerdfont = "FiraCode";
        }
        {package = pkgs.fira-code-symbols;}
        {
          package = pkgs.fira-mono;
          nerdfont = "FiraMono";
        }
        {package = pkgs.lexica-ultralegible;}
        # https://github.com/liberationfonts
        {
          package = pkgs.liberation_ttf;
          nerdfont = "LiberationMono";
        }
        # https://opendyslexic.org/
        {
          package = pkgs.open-dyslexic;
          nerdfont = "OpenDyslexic";
        }
      ];

      ## For packages that should be gotten from nixcask on darwin. The second
      ## argument may be null, but if the nixcast package name differs from the
      ## Nixpkgs name, then it needs to be set.
      maybeNixcask = pkg: nixcastPkg:
        if pkgs.stdenv.hostPlatform.isDarwin
        then let
          realNixcastPkg =
            if nixcastPkg == null
            then pkg
            else nixcastPkg;
        in
          pkgs.nixcasks.${realNixcastPkg}
        else pkgs.${pkg};
    in
      [
        pkgs.age
        pkgs.agenix
        ## doesn’t contain darwin GUI
        (maybeNixcask "anki" null)
        pkgs.awscli
        pkgs.bash-strict-mode
        ## marked broken on darwin
        (maybeNixcask "calibre" null)
        ## DOS game emulator # fails to build on darwin # x86 game emulator
        (maybeNixcask "dosbox" null)
        # pkgs.discord # currently subsumed by ferdium
        # pkgs.element-desktop # currently subsumed by ferdium
        pkgs.ghostscript
        pkgs.git-standup
        # pkgs.gitter # currently subsumed by ferdium
        pkgs.imagemagick
        pkgs.jekyll
        pkgs.magic-wormhole
        ## not available on darwin via Nix
        (maybeNixcask "mumble" null)
        (pkgs.nerdfonts.override {
          fonts =
            lib.concatMap
            (font:
              if font ? nerdfont
              then [font.nerdfont]
              else [])
            fonts;
        })
        ## not available on darwin via Nix
        (maybeNixcask "obs-studio" "obs")
        pkgs.python3Packages.opentype-feature-freezer
        # pkgs.slack # currently subsumed by ferdium
        pkgs.synergy
        pkgs.tailscale
        pkgs.tikzit
        # pkgs.wire-desktop # currently subsumed by ferdium
        pkgs.xdg-ninja # home directory complaining
      ]
      ++ map (font: font.package) fonts
      ++ lib.optionals (pkgs.system != "aarch64-linux") [
        pkgs.spotify
        pkgs.unison-ucm # Unison dev tooling
        pkgs.zoom-us
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.mas
        pkgs.nixcasks.ableton-live-standard # license only works for version 6
        pkgs.nixcasks.acorn
        pkgs.nixcasks.adium
        pkgs.nixcasks.alfred
        pkgs.nixcasks.arduino
        pkgs.nixcasks.beamer
        # pkgs.nixcasks.bowtie # broken
        pkgs.nixcasks.controlplane
        pkgs.nixcasks.devonthink # license only works for version 2
        # pkgs.nixcasks.discord # currently subsumed by ferdium
        pkgs.nixcasks.disk-inventory-x
        pkgs.nixcasks.dropbox
        # pkgs.nixcasks.evernote # currently subsumed by ferdium
        pkgs.nixcasks.fantastical
        pkgs.nixcasks.ferdium # not available on darwin via Nix
        pkgs.nixcasks.fertigt-slate # TODO: remove in favor of Hammerspoon?
        pkgs.nixcasks.freemind
        pkgs.nixcasks.github
        pkgs.nixcasks.gotomeeting
        pkgs.nixcasks.hammerspoon
        pkgs.nixcasks.imageoptim
        pkgs.nixcasks.keybase # GUI not available on darwin via Nix
        pkgs.nixcasks.kiibohd-configurator
        pkgs.nixcasks.kindle
        pkgs.nixcasks.lastfm
        pkgs.nixcasks.mendeley
        pkgs.nixcasks.netnewswire
        pkgs.nixcasks.omnifocus
        pkgs.nixcasks.omnigraffle
        pkgs.nixcasks.omnioutliner
        pkgs.nixcasks.openoffice
        pkgs.nixcasks.plex # not available on darwin via Nix
        pkgs.nixcasks.plex-media-server # not available on darwin via Nix
        pkgs.nixcasks.processing
        # pkgs.nixcasks.psi # broken
        pkgs.nixcasks.quicksilver
        pkgs.nixcasks.rowmote-helper
        pkgs.nixcasks.screenflow
        pkgs.nixcasks.scrivener
        pkgs.nixcasks.signal # not available on darwin via Nix
        pkgs.nixcasks.skitch
        pkgs.nixcasks.skype # doesn't respect appdir
        pkgs.nixcasks.squeak # not available on darwin via Nix
        pkgs.nixcasks.stellarium
        pkgs.nixcasks.tor-browser # not available on darwin via Nix
        pkgs.nixcasks.tower
        pkgs.nixcasks.transmission
        pkgs.nixcasks.ukelele
        # pkgs.nixcasks.whatsapp # currently subsumed by ferdium # broken
        pkgs.terminal-notifier
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs._1password-gui # doesn’t get installed in the correct location on Darwin
        pkgs.bitcoin # doesn’t contain darwin GUI
        # pkgs.github-desktop # not supported on darwin # in 23.05, still uses OpenSSL 1.1.1u
        pkgs.hdhomerun-config-gui # not supported on darwin
        pkgs.plex # not supported on darwin
        pkgs.plex-media-player # fails to build on darwin
        pkgs.powertop # not supported on darwin
        pkgs.racket # doesn’t contain darwin GUI
      ]
      ++ lib.optionals (pkgs.system == "x86_64-linux") [
        pkgs.chrysalis # Atreus keyboard customizer # packaged as x86_64-linux binary
        pkgs.cider # we have Music.app on darwin
        pkgs.eagle # not supported on darwin
        pkgs.ferdium # not supported on darwin
        pkgs.keybase-gui # not supported on darwin
        pkgs.signal-desktop # not supported on darwin
        pkgs.tor-browser-bundle-bin # not supported on darwin
      ];

    sessionPath = [
      # TODO: This path should be managed by the xdg module, see
      #       https://github.com/nix-community/home-manager/issues/3357
      "$HOME/${config.lib.local.xdg.bin.rel}"
    ];

    sessionVariables = {
      PGPASSFILE = "$XDG_CONFIG_HOME/pg/pgpass";
      ## TODO: Make emacs-pager better (needs to handle ANSI escapes, like I do
      ##       in compilation buffers).
      # PAGER = "${config.lib.local.xdg.bin.home}/emacs-pager";
      RANDFILE = "${config.xdg.stateHome}/openssl/rnd";
      XAUTHORITY = "${config.lib.local.xdg.runtimeDir}/Xauthority";
    };

    shellAliases = {
      grep = "grep --color";

      # Some of the long flag names aren’t widely supported, so this alias
      # should be equivalent to `ls --almost-all --human-readable --color`.
      ls = "ls -Ah --color";

      ## Set paths to XDG-compatible places
      wget = "wget --hsts-file=${config.xdg.stateHome}/wget/hsts";

      ## Include dotfiles.
      tree = "tree -a";
    };
  };

  ## NB: Before removing something from these lists (because you think it is
  ##     part of the standard dictionary now), make sure it is in _all_ the
  ##     dictionaries that reference this list (and even then, better to have
  ##     a word stay a word then let a dictionary cull it later).
  i18n.spelling = {
    enable = true;
    dictionaries = {
      en = [
        "arity"
        "boulderers"
        "coroplast"
        "cortado"
        "coöperating"
        "coöperative"
        "coördinate"
        "coördinated"
        "coördinates"
        "coördinating"
        "coördination"
        "dozenal"
        "duoid"
        "duoids"
        "freedive"
        "freediving"
        "kell"
        "kells"
        "palantir"
        "tenkara"
        "topo"
      ];
      local = [
        "GitHub"
        "Skitch"
        "Rankine" # the temperature scale
        "Vizsla" # the dog breed
      ];
    };
  };

  lib.local = {
    defaultFont = {
      # NB: These faces need to be listed in `home.packages`.
      monoFamily = "Fira Mono";
      programmingFamily = "Fira Code";
      sansFamily = "Lexica Ultralegible";
      size = 12.0;
      string =
        config.lib.local.defaultFont.sansFamily
        + " "
        + builtins.toString config.lib.local.defaultFont.size;
    };

    ## Holds the name of the (first) account designated as `primary`, or `null`
    ## (which shouldn’t happen).
    primaryEmailAccountName =
      lib.foldlAttrs
      (acc: key: val:
        if acc == null && val.primary == true
        then key
        else acc)
      null
      config.accounts.email.accounts;

    primaryEmailAccount =
      config.accounts.email.accounts.${config.lib.local.primaryEmailAccountName};

    supportedOn = plat: pkg:
      if pkg.meta ? platforms
      then builtins.elem plat pkg.meta.platforms
      else true;

    ## Some settings are relative to `$HOME`, so these functions let us swap
    ## between the relative and absolute versions. It’s better to explicitly
    ## build the relative, then `addHome` when needed, but sometimes that isn’t
    ## possible, so there is also `removeHome`. absolute paths we have.
    addHome = path: config.home.homeDirectory + "/" + path;
    removeHome = lib.removePrefix (config.home.homeDirectory + "/");

    ## These make it easy to match the Solarized theme
    ## (https://ethanschoonover.com/solarized/) for modules that support color
    ## configuration.
    solarized = mode: let
      darkColors = {
        base03 = "#002b36";
        base02 = "#073642";
        base01 = "#586e75";
        base00 = "#657b83";
        base0 = "#839496";
        base1 = "#93a1a1";
        base2 = "#eee8d5";
        base3 = "#fdf6e3";
        blue = "#268bd2";
        cyan = "#2aa198";
        green = "#859900";
        magenta = "#d33682";
        orange = "#cb4b16";
        red = "#dc322f";
        violet = "#6c71c4";
        yellow = "#b58900";
      };
      color =
        if mode == "dark"
        then darkColors
        else
          darkColors
          // {
            base03 = darkColors.base3;
            base02 = darkColors.base2;
            base01 = darkColors.base1;
            base00 = darkColors.base0;
            base0 = darkColors.base00;
            base1 = darkColors.base01;
            base2 = darkColors.base02;
            base3 = darkColors.base03;
          };
    in {
      inherit color;
      background = color.base03;
      ANSI = {
        normal = {
          inherit (color) blue cyan green magenta red yellow;
          black = color.base02;
          white = color.base2;
        };
        bright = {
          black = color.base03;
          blue = color.base0;
          cyan = color.base1;
          green = color.base01;
          magenta = color.violet;
          red = color.orange;
          white = color.base3;
          yellow = color.base00;
        };
      };
    };

    # Variables that `config.xdg` doesn’t provide, but that I wish it would.
    xdg = {
      bin = {
        home = config.lib.local.addHome config.lib.local.xdg.bin.rel;
        rel = "${config.lib.local.xdg.local.rel}/bin";
      };
      cache.rel = config.lib.local.removeHome config.xdg.cacheHome;
      config.rel = config.lib.local.removeHome config.xdg.configHome;
      data.rel = config.lib.local.removeHome config.xdg.dataHome;
      local = {
        home = config.lib.local.addHome config.lib.local.xdg.local.rel;
        rel = lib.removeSuffix "/state" config.lib.local.xdg.state.rel;
      };
      state.rel = config.lib.local.removeHome config.xdg.stateHome;
      # Don’t know why this one isn’t in the `xdg` module.
      runtimeDir = config.home.sessionVariables.XDG_RUNTIME_DIR;
      userDirs = {
        projects = {
          home =
            config.lib.local.addHome config.lib.local.xdg.userDirs.projects.rel;
          rel = "Projects";
        };
      };
    };

    ## Show a list of all files under `path` that are neither managed by Nix
    ## nor excluded by the `whitelist` of allowed unmanaged paths (relative to
    ## the initial path).
    ##
    ## TODO: Have this return a Nix list rather than echoing.
    unmanagedPaths = path: whitelist: let
      whitelistString =
        builtins.concatStringsSep "\" -prune -o -path \"${path}/" whitelist;
    in ''
      find -P "${path}" \
          -path "${path}/${whitelistString}" -prune \
          -o -type d \
          -o -lname "/nix/*" \
          -o -print
    '';
  };

  local.nixpkgs = {
    enable = true;
    allowedUnfreePackages = [
      "1password"
      "1password-cli"
      "eagle"
      "onepassword-password-manager"
      "plexmediaserver"
      "spotify"
      "zoom"
    ];
  };

  manual.html.enable = true;

  news.display = "show";

  nix = {
    ## TODO: `nix.package` must be set in a configuration, but it gets
    ##       overridden when Home Manager is used as a module. This is a
    ##       workaround until nix-community/home-manager#5870 is resolved.
    package = lib.mkDefault pkgs.nix;
    settings = {
      ## TODO: was required for Nix on Mac at some point -- review
      allow-symlinked-store = pkgs.stdenv.hostPlatform.isDarwin;
      ## Prevent the gc from removing current dependencies from the store.
      keep-failed = true;
      keep-outputs = true;
      log-lines = 50;
      warn-dirty = false;
    };
  };

  nixpkgs.overlays = [dotfiles.overlays.home];

  programs = {
    ## We let Project Manager provide Home Manager to projects that have
    ## `homeConfigurations`.`
    home-manager.enable = false;

    info.enable = true;

    man.generateCaches = true;

    ## Declarative management of VCS repos
    mr.enable = true;
  };

  services = {
    home-manager.autoUpgrade = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      frequency = "daily";
    };

    keybase.enable = pkgs.stdenv.hostPlatform.isLinux;

    ## notification daemon for Wayland
    mako = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      font = config.lib.local.defaultFont.string;
    };

    screen-locker.lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 000000";
  };

  targets.darwin = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    defaults = {
      "NSGlobalDomain" = {
        AppleInterfaceStyleSwitchesAutomatically = true;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = true;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSUserDictionaryReplacementItems = map (item: {on = 1;} // item) [
          {
            replace = "omw";
            "with" = "On my way!";
          }
          {
            replace = "*shrug*";
            "with" = "¯\\_(ツ)_/¯";
          }
          {
            replace = "*tableflip*";
            "with" = "(╯°□°)╯︵ ┻━┻";
          }
        ];
        "com.apple.sound.beep.flash" = 1;
      };
      # Opt out of Apple Intelligence.
      "com.apple.CloudSubscriptionFeatures.optIn"."545129924" = false;
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.dock" = {
        autohide = true;
        expose-group-apps = true;
        minimize-to-application = true;
        mru-spaces = false; # helps yabai work properly
        orientation = "left";
        showhidden = true;
        size-immutable = false;
        tilesize = 256;
      };
      "com.apple.finder" = {
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        DesktopViewSettings = {
          GroupBy = "Kind";
          IconViewSettings = {
            labelOnBottom = 1;
            showIconPreview = 1;
            showItemInfo = 1;
            ## As large as possible rather than following system font size
            textSize = 16;
            ## Given the settings above, these are the sizes that allow it to
            ## integrate best with Sonoma’s desktop widgets.
            ##
            ## TODO: Calculate these using a function from
            ##     - labeOnBottom
            ##     - showItemInfo
            ##     - textSize
            ##     - desired widgit mapping (“2×1.5 means 2 icons horizontally in
            ##       one widget unit, and 3 icons for every two widgets of height)
            gridSpacing = 78;
            iconSize = 104;
            ## NB: Everything below here is the default value, but you can’t
            ##     partially set a value (currently), so we need to make them
            ##     explicit for everything in `DesktopViewSettings`.
            arrangeBy = "dateAdded";
            backgroundColorBlue = 1;
            backgroundColorGreen = 1;
            backgroundColorRed = 1;
            backgroundType = 0;
            gridOffsetX = 0;
            gridOffsetY = 0;
            viewOptionsVersion = 0;
          };
          CustomViewStyleVersion = 1;
        };
        FXPreferredViewStyle = "Nlsv"; # list view
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      "com.apple.LaunchServices".LSQuarantine = false;
      # I would remove Safari if I could, but we can’t, so at least configure
      # it.
      "com.apple.Safari" = {
        AutoFillCreditCardData = false;
        AutoFillPasswords = false;
        AutoOpenSafeDownloads = false;
        IncludeDevelopMenu = true;
        ShowOverlayStatusBar = true;
      };
      "com.apple.WindowManager" = {
        EnableTiledWindowMargins = 0;
        ## MacOS Sequoia (15.1) adds some new behavior that will auto-tile
        ## windows when you move them to a screen edge. These disable those.
        EnableTilingByEdgeDrag = 0;
        EnableTopTilingByEdgeDrag = 0;
      };
      "com.apple.universalaccess" = {
        closeViewScrollWheelToggle = true;
        reduceTransparency = true;
      };
      "org.hammerspoon.Hammerspoon".MJConfigFile = "${config.xdg.configHome}/hammerspoon/init.lua";
    };
    search = "DuckDuckGo";
  };

  xdg = {
    enable = true;
    userDirs = {
      createDirectories = true;
      enable = pkgs.stdenv.hostPlatform.isLinux;
      videos =
        lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        (config.lib.local.addHome "Movies");
    };
  };

  xresources.path = "${config.xdg.configHome}/x/resources";

  xsession = {
    enable = pkgs.stdenv.hostPlatform.isLinux;

    profilePath = "${config.lib.local.xdg.config.rel}/x/profile";
    # TODO: See if this path is actually managed well (i.e., will things _read_
    #       from this path (because appropriate enviroment vars get set), or
    #       will it be ignored?
    # scriptPath = "${xdgConfigRel}/x/session";
  };
}
