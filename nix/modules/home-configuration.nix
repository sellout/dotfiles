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
    ./audio.nix
    ./communication.nix
    ./direnv.nix
    ./emacs
    ./firefox.nix
    ./garnix-cache.nix
    ./gpg.nix
    ./i18n.nix
    ./i3.nix
    ./input-devices.nix
    ./locale.nix
    ./nix-configuration.nix
    ./nixos-wiki.nix
    ./nixpkgs-configuration.nix
    ./pim.nix
    ./programming
    ./shell
    ./ssh.nix
    ./storage.nix
    ./tex.nix
    ./vcs
    ./wakatime.nix
    ./xdg.nix
  ];

  ## TODO: The default for this isn’t actually a path, but rather
  ##       expands to a path in the shell. See ryantm/agenix#300.
  age.secretsDir = "${config.lib.local.xdg.runtimeDir}/agenix";

  garnix.cache = {
    enable = true;
    config = "on";
  };

  home = {
    activation = {
      ## TODO: Should move a version of this to Home Manager itself.
      setUpErrorTrap = lib.hm.dag.entryBefore ["checkLaunchAgents"] ''
        trap '_iError "Home Manager activation failed with $? at $(basename $0):$LINENO"; exit 1' ERR
      '';

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
    ## ./darwin/default.nix#homebrew for where to install various
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
    packages =
      [
        pkgs.age
        pkgs.agenix
        ## doesn’t contain darwin GUI
        (config.lib.local.maybeCask "anki" null)
        pkgs.awscli
        pkgs.bash-strict-mode
        (config.lib.local.maybeCask "bitcoin" "bitcoin-core")
        ## DOS game emulator # fails to build on darwin # x86 game emulator
        (config.lib.local.maybeCask "dosbox" null)
        pkgs.ghostscript
        pkgs.imagemagick
        pkgs.jekyll
        pkgs.magic-wormhole
        pkgs.nix-output-monitor # prettier Nix build output
        ## not available on darwin via Nix
        (config.lib.local.maybeCask "obs-studio" "obs")
        pkgs.python3Packages.opentype-feature-freezer
        pkgs.synergy
        pkgs.tailscale
        pkgs.tikzit
        pkgs.xdg-ninja # home directory complaining
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system != "aarch64-linux") [
        pkgs.unison-ucm # Unison dev tooling
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.mas
        pkgs.brewCasks.acorn
        (pkgs.brewCasks.alfred.overrideAttrs (old: {
          ## From BatteredBunny/brew-nix#15
          unpackPhase = "${lib.getExe pkgs.gnutar} -xvzf $src";
        }))
        pkgs.brewCasks.beamer
        pkgs.brewCasks.controlplane
        pkgs.brewCasks.disk-inventory-x
        pkgs.brewCasks.dropbox
        pkgs.brewCasks.freemind
        pkgs.brewCasks.github
        pkgs.brewCasks.hammerspoon
        (pkgs.brewCasks.imageoptim.overrideAttrs (old: {
          ## From BatteredBunny/brew-nix#15
          unpackPhase = "${lib.getExe pkgs.gnutar} -xvJf $src";
        }))
        pkgs.brewCasks.kiibohd-configurator
        pkgs.brewCasks.omnigraffle
        pkgs.brewCasks.omnioutliner
        pkgs.brewCasks.plex # not available on darwin via Nix
        pkgs.brewCasks.plex-media-server # not available on darwin via Nix
        (pkgs.brewCasks.powerphotos.overrideAttrs (old: {
          src = pkgs.fetchurl {
            url = builtins.head old.src.urls;
            hash = "sha256-ryPaLb2N8y6rkN5swkfhcj2NGWzYmbSehbqqiQoAf1A=";
          };
        }))
        pkgs.brewCasks.processing
        pkgs.brewCasks.quicksilver
        pkgs.brewCasks.rowmote-helper
        pkgs.brewCasks.screenflow
        pkgs.brewCasks.scrivener
        pkgs.brewCasks.squeak # not available on darwin via Nix
        pkgs.brewCasks.stellarium
        (pkgs.brewCasks.timemachineeditor.overrideAttrs (old: {
          src = pkgs.fetchurl {
            url = builtins.head old.src.urls;
            hash = "sha256-UPd3rClEpo4EpVkgOOWlrc8HcRCzBhE/do0/fLuVvwA=";
          };
        }))
        pkgs.brewCasks.transmission
        pkgs.brewCasks.ukelele
        pkgs.brewCasks.vlc
        pkgs.brewCasks.xquartz
        pkgs.terminal-notifier
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.github-desktop # not supported on darwin
        pkgs.hdhomerun-config-gui # not supported on darwin
        pkgs.plex # (server) not supported on darwin
        pkgs.powertop # not supported on darwin
        pkgs.racket # doesn’t contain darwin GUI
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        pkgs.eagle # not supported on darwin
        pkgs.plex-desktop # not supported on darwin
        pkgs.tor-browser # not supported on darwin
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
        "affine"
        "arity"
        "boulderers"
        "bugfix"
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
        "formatter"
        "freedive"
        "freediving"
        "intricacies"
        "kell"
        "kells"
        "palantir"
        "parametricity"
        "pessimize"
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
      monoFamily = "FiraMono Nerd Font";
      programmingFamily = "FiraCode Nerd Font";
      sansFamily = "Lexica Ultralegible";
      serifFamily = "Times New Roman";
      size = 12.0;
      string =
        config.lib.local.defaultFont.sansFamily
        + " "
        + builtins.toString config.lib.local.defaultFont.size;
    };

    ## For packages that should be gotten from brewCasks on darwin. The second
    ## argument may be null, but if the brewCasks package name differs from
    ## the Nixpkgs name, then it needs to be set.
    maybeCask = pkg: caskPkg:
      if pkgs.stdenv.hostPlatform.isDarwin
      then let
        realCaskPkg =
          if caskPkg == null
          then pkg
          else caskPkg;
      in
        pkgs.brewCasks.${realCaskPkg}
      else pkgs.${pkg};

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

    /**
      Returns a path relative to `HOME` that points to either the appropriate XDG
      dir or the corresponding darwin-specific location.

      Some tools (e.g., anything that relies on the
      [platformdirs](tox-dev/platformdirs#4) Python libray) don’t respect (or
      allow us to explicitly set) [XDG base
      directory](https://specifications.freedesktop.org/basedir-spec/) vars on
      darwin. This uses appropriate macOS directories in those cases.

    # Examples

    ``` nix
    darwinXdg "x86_64-darwin" "cache" null
    =>
    "Library/Caches"
    ```

    ``` nix
    darwinXdg "x86_64-linux" "cache" null
    =>
    ".cache"
    ```

    ``` nix
    darwinXdg "x86_64-darwin" "config" null
    =>
    "Library/Application Support"
    ```

    ``` nix
    darwinXdg "x86_64-linux" "config" null
    =>
    ".config"
    ```

    However, some applications want to write to "Library/Preferences", despite
    that being reserved for `NSUserDefaults`. In that case, you can set an
    explicit override, which will only be respected on darwin:

    ``` nix
    darwinXdg "x86_64-darwin" "config" "Library/Preferences"
    =>
    "Library/Preferences"
    ```

    ``` nix
    darwinXdg "x86_64-linux" "config" "Library/Preferences"
    =>
    ".config"
    ```

    # Type

    ```
    darwinXdg :: String -> String -> Optional String -> String
    ```

    # Arguments

    system
    : The Nix system string

    var
    : The XDG variable type. E.g., For `XDG_DATA_HOME`, use `"data"`.

    darwinOverride
    : A relative path to use on darwin. If this is `null`, it uses a default
      path corresponding to the XDG variable name, but some applications have
      their own ideas where files should live, so you can pass the relative path
      explicitly in that case. The most common scenario is `… "config"
      "Library/Preferences"`.
    */
    darwinXdg = system: var: darwinOverride:
      if lib.hasSuffix "-darwin" system
      then
        if darwinOverride == null
        then
          if var == "cache"
          then "Library/Caches"
          # NB: “Library/Preferences” is another option for `config`, but
          #     https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/MacOSXDirectories/MacOSXDirectories.html#//apple_ref/doc/uid/20002282-101001
          #     says, “You should never create files in [Library/Preferences]
          #     yourself. To get or set preference values, you should always use
          #     the `NSUserDefaults` class or an equivalent system-provided
          #     interface.”
          else "Library/Application Support"
        else darwinOverride
      else config.lib.local.xdg.${var}.rel;

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
      "eagle"
      "plex-desktop"
      "plexmediaserver"
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

  nixpkgs = {
    config.permittedInsecurePackages = [
      ## FIXME: Duplicated from elsewhere, because this list isn’t being merged
      ##        correctly or something.
      "python-2.7.18.12"
      ## TODO: Not sure what this is a dependency of, but it’s obsolete.
      "qtwebengine-5.15.19"
    ];
    overlays = [dotfiles.overlays.home];
  };

  programs = {
    ## We let Project Manager provide Home Manager to projects that have
    ## `homeConfigurations`.`
    home-manager.enable = false;

    info.enable = true;

    man.generateCaches = true;

    ## Declarative management of VCS repos
    mr.enable = true;

    ## Tools for exploring Nixpkgs
    ## • `nix-locate` – figure out which derivations provide files
    ## • `,` – run commands without installing them
    ## • shell integration to report which package to install when a command
    ##   isn’t found
    ##
    ## TODO: At least the shell integration (and probably nix-locate) should be
    ##       installed system-wide.
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
  };

  services = {
    home-manager = {
      ## This helps keep the size of the Nix store down by periodically expiring
      ## old generations then running `nix-collect-garbage`.
      autoExpire = {
        # Can change this to `true` once
        # https://github.com/nix-community/home-manager/commit/20974416338898f0725a87832e4cd9bd82cbdaad
        # is on the version of Home Manager we use (probably 25.11).
        enable = pkgs.stdenv.hostPlatform.isLinux;
        frequency = "weekly";
        store.cleanup = true;
      };
      autoUpgrade = {
        enable = pkgs.stdenv.hostPlatform.isLinux;
        frequency = "daily";
      };
    };

    ## NB: On a new user account, it’s important to run `keybase login` to avoid
    ##   > ▶ [WARN keybase kbfs_pin_tlfs.go:161] 062 TLF Pin operation failed: Login required: no sessionArgs available since no login path worked [tags:PIN=IMq0lVNJdY1P]
    keybase.enable = pkgs.stdenv.hostPlatform.isLinux;

    ## notification daemon for Wayland
    mako = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      settings.font = config.lib.local.defaultFont.string;
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
      };

      ## Opt out of Apple Intelligence.
      "com.apple.AppleIntelligenceReport".reportDuration = 0;
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
