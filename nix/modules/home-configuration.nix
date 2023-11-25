{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./emacs.nix
    ./i3.nix
    ./input-devices.nix
    ./nix-configuration.nix
    ./shell.nix
    ./vcs.nix
  ];

  fonts.fontconfig.enable = true;

  # FIXME: This and `config.home.activation.aliasApplications` below _may_ be
  #        needed because the alias (rather than symlink) things into
  #        ~/Applications/Home Manager Apps. If that turns out to be the case,
  #        we should open an issue against home-manager to switch to aliasing on
  #        darwin.
  disabledModules = ["targets/darwin/linkapps.nix"];

  home = {
    activation = {
      # TODO: This should be removed once
      #       https://github.com/nix-community/home-manager/issues/1341 is
      #       closed.
      aliasApplications =
        lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        (lib.hm.dag.entryAfter ["writeBoundary"] ''
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
            $DRY_RUN_CMD ${pkgs.mkalias}/bin/mkalias "$app" "$tmp_path/$(basename $app)"
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
      # ABCL’s init file (https://abcl.org/)
      ".abclrc".source =
        ../../home/${config.lib.local.xdg.config.rel}/common-lisp/init.lisp;
      # Allegro CL’s init file
      # (https://franz.com/support/documentation/10.1/doc/startup.htm#init-files-1)
      ".clinit.cl".source =
        ../../home/${config.lib.local.xdg.config.rel}/common-lisp/init.lisp;
      # CLISP’s init file (https://clisp.sourceforge.io/impnotes/clisp.html)
      ".clisprc.lisp".source =
        ../../home/${config.lib.local.xdg.config.rel}/common-lisp/init.lisp;
      # DARCS’ ignore file
      ".darcs/boring".source =
        ../../home/${config.lib.local.xdg.config.rel}/darcs/boring;
      # ECL’s init file
      # (https://ecl.common-lisp.dev/static/manual/Invoking-ECL.html#Invoking-ECL)
      ".ecl".source =
        ../../home/${config.lib.local.xdg.config.rel}/common-lisp/init.lisp;
      # SBCL’s init file
      # (https://www.sbcl.org/manual/index.html#Initialization-Files)
      ".sbclrc".text = ''
        (load #p"${config.home.homeDirectory}/${config.xdg.configFile."common-lisp".target}/init.lisp")

        (defvar asdf::*source-to-target-mappings* '((#p"/usr/local/lib/sbcl/" nil)))
      '';
      # Clozure CL’s init file
      # (https://ccl.clozure.com/docs/ccl.html#the-init-file)
      "ccl-init.lisp".text = ''
        (setf *default-file-character-encoding* :utf-8)
        (load #p"${config.home.homeDirectory}/${config.xdg.configFile."common-lisp".target}/init.lisp")
      '';
      # CMUCL’s init file
      # (https://cmucl.org/docs/cmu-user/html/Command-Line-Options.html#Command-Line-Options)
      "init.lisp".source =
        ../../home/${config.lib.local.xdg.config.rel}/common-lisp/init.lisp;
      # NB: This currently gets put in `config.xdg.cacheHome`, since most of the
      #     stuff in `$CARGO_HOME` is cached data. However, this means that the
      #     Cargo config can be erased (until the next `home-manager switch`) if
      #     the cache is cleared.
      "${config.lib.local.removeHome config.home.sessionVariables.CARGO_HOME}/config.toml".text = lib.generators.toINI {} {
        build.target-dir = "${config.lib.local.xdg.state.rel}/cargo";
        install.root = config.lib.local.xdg.local.home;
      };
      # There’s no $XDG_BIN_HOME in the spec for some reason, so these files
      # aren’t managed under the xdg module.
      # TODO: Can’t just link the directory, because `executable = true` doesn’t
      #       work then. See nix-community/home-manager#3594.
      "${config.lib.local.xdg.bin.rel}/edit" = {
        executable = true;
        source = ../../home/${config.lib.local.xdg.bin.rel}/edit;
      };
      "${config.lib.local.xdg.bin.rel}/emacs-pager" = {
        executable = true;
        source = ../../home/${config.lib.local.xdg.bin.rel}/emacs-pager;
      };
    };

    ## TODO: Replace these with my ./locale.nix module
    ## TODO: Only set these if the locale is available on the system.
    language = {
      base = "en_US.UTF-8";
      time = "en_DK.UTF-8"; # “joke” value for getting ISO datetimes
    };

    ## Ideally, packages are provided by projects (e.g., Nix flakes + direnv)
    ## rather than installed globally. This allows for, say, the correct
    ## compiler version to be used for each project. However, some things are
    ## useful outside of a project, and those get installed more broadly (see
    ## ./darwin-configuration.nix#homebrew for where to install various
    ## packages, including here). Between those two extremes, there is
    ## ./emacs.nix, which is where most packages are managed, behind a Emacs
    ## interface (`config.programs.emacs.extraPackages`), but there are
    ## exceptions for a few reasons: (inexhaustive)
    ##
    ## • the package contains something that needs to run as a service or
    ##   otherwise be available outside of the Emacs process;
    ## • there are reasons to have the package even when Emacs is not working,
    ##   etc. for some reason (e.g., we want to have Nix itself and VCSes
    ##   available so we can pull new versions and build things when we need
    ##   to);
    ## • the package has its own GUI that we prefer over any Emacs interface; or
    ## • we need TRAMP to be able to use the program _on a remote host_ (e.g.,
    ##   encryption needs to run on the host that the keys live on, so
    ##  `pkgs.age` should be everywhere; but Flyspell should always use
    ##  `pkgs.ispell` from the local host, which means it can be restricted to
    ##   Emacs).
    ##
    ## The last case is not ideal. It would be fantastic if a TRAMP connection
    ## could somehow wind up with the `PATH`, etc. that Emacs on that host would
    ## see; and if it could also see the project-specific `PATH` set up by
    ## direnv on that host. We could still embed packages that we want to have
    ## available outside of projects, but project-specific versions should be
    ## able to override that and we should also be happy for a binary to not
    ## exist when we’re not in an appropriate project.
    packages = let
      fonts = [
        # https://brailleinstitute.org/freefont
        {package = pkgs.atkinson-hyperlegible;}
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
    in
      [
        pkgs._1password # This is the CLI, needed by VSCode 1Password extension
        pkgs._1password-gui
        pkgs.age
        pkgs.agenix
        pkgs.awscli
        pkgs.bash-strict-mode
        pkgs.dtach
        # pkgs.discord # currently subsumed by ferdium
        # pkgs.element-desktop # currently subsumed by ferdium
        pkgs.ghostscript
        # pkgs.gitter # currently subsumed by ferdium
        pkgs.imagemagick
        pkgs.jekyll
        pkgs.magic-wormhole
        (pkgs.nerdfonts.override {
          fonts =
            lib.concatMap
            (font:
              if font ? nerdfont
              then [font.nerdfont]
              else [])
            fonts;
        })
        # pkgs.slack # currently subsumed by ferdium
        pkgs.synergy
        pkgs.tailscale
        pkgs.tikzit
        # pkgs.wire-desktop # currently subsumed by ferdium
      ]
      ++ map (font: font.package) fonts
      ++ lib.optionals (pkgs.system != "aarch64-linux") [
        pkgs.zoom-us
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.karabiner-elements
        pkgs.mas
        pkgs.terminal-notifier
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.anki # doesn’t contain darwin GUI
        pkgs.bitcoin # doesn’t contain darwin GUI
        pkgs.calibre # marked broken on darwin
        pkgs.dosbox # DOS game emulator # fails to build on darwin
        # pkgs.github-desktop # not supported on darwin # in 23.05, still uses OpenSSL 1.1.1u
        pkgs.hdhomerun-config-gui # not supported on darwin
        pkgs.inotify-tools # needed so Emacs’ TRAMP can connect # not supported on Darwin
        pkgs.mumble # not supported on darwin
        pkgs.obs-studio # not supported on darwin
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
      ALTERNATIVE_EDITOR = "${pkgs.emacs}/bin/emacs";
      CABAL_CONFIG = "${config.home.homeDirectory}/${config.xdg.configFile."cabal/config".target}";
      CABAL_DIR = "${config.xdg.stateHome}/cabal";
      CARGO_HOME = "${config.xdg.cacheHome}/cargo";
      # set by services.emacs on Linux, but not MacOS.
      EDITOR = "${pkgs.emacs}/bin/emacsclient";
      IRBRC = "${config.home.homeDirectory}/${config.xdg.configFile."irb/irbrc".target}";
      LW_INIT = "${config.home.homeDirectory}/${config.xdg.configFile."lispworks/init.lisp".target}";
      MAKEFLAGS = "-j$(nproc)";
      NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
      OCTAVE_INITFILE = "${config.home.homeDirectory}/${config.xdg.configFile."octave/octaverc".target}";
      ## TODO: Make emacs-pager better (needs to handle ANSI escapes, like I do
      ##       in compilation buffers).
      # PAGER = "${config.lib.local.xdg.bin.home}/emacs-pager";
      PSQLRC = "${config.home.homeDirectory}/${config.xdg.configFile."psql/psqlrc".target}";
      # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPYCACHEPREFIX
      PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
      # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
      PYTHONUSERBASE = "${config.xdg.stateHome}/python";
      R_ENVIRON_USER = "${config.xdg.configHome}/r/environ";
      RUSTUP_HOME = "${config.xdg.stateHome}/rustup";
      STACK_XDG = "1";
      VISUAL = "${pkgs.emacs}/bin/emacsclient";
      # May be able to remove this after wakatime/wakatime-cli#558 is fixed.
      WAKATIME_HOME = "${config.xdg.configHome}/wakatime";
    };

    shellAliases = let
      # A builder for quick dev environments.
      #
      # TODO: Since this uses both `nix` and the containing flake, it seems like
      #       there should be a better way to get that information to the
      #       command than having the shell look it up.
      devEnv = devShell: "nix develop " + ../../. + "#" + devShell;
      template = template: "nix flake init -t " + ../../. + "#" + template;
    in {
      grep = "grep --color";

      # Some of the long flag names aren’t widely supported, so this alias
      # should be equivalent to `ls --almost-all --human-readable --color`.
      ls = "ls -Ah --color";

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

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "23.05";
  };

  launchd.agents = {
    # derived from https://www.emacswiki.org/emacs/EmacsAsDaemon#h5o-8
    "gnu.emacs.daemon" = {
      config = {
        Label = "gnu.emacs.daemon";
        ProgramArguments = ["emacs" "--daemon"];
        RunAtLoad = true;
      };
      enable = true;
    };
  };

  lib.local = {
    defaultFontSize = 12.0;
    # NB: These faces need to be listed in `home.packages`.
    defaultMonoFont = "Fira Mono";
    defaultSansFont = "Atkinson Hyperlegible";
    programmingFont = "Fira Code";

    defaultFont =
      config.lib.local.defaultSansFont
      + " "
      + builtins.toString config.lib.local.defaultFontSize;

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
      runtime = {
        home = config.lib.local.addHome config.lib.local.xdg.runtime.rel;
        rel = config.lib.local.xdg.cache.rel;
      };
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

  manual.html.enable = true;

  news.display = "show";

  nix = {
    package = pkgs.nix;
    settings = {
      ## TODO: was required for Nix on Mac at some point -- review
      allow-symlinked-store = pkgs.stdenv.hostPlatform.isDarwin;
      ## Prevent the gc from removing current dependencies from the store.
      keep-failed = true;
      keep-outputs = true;
      log-lines = 50;
    };
  };

  programs = {
    direnv = {
      config.global = {
        # Ideally could set this for specific projects, see direnv/direnv#793.
        strict_env = true;
        # Nix flakes tend to take a while. This is probably still too short.
        warn_timeout = "60s";
      };
      enable = true;
      nix-direnv.enable = true;
    };

    firefox = {
      enable = pkgs.system == "x86_64-linux";
      # Nix really wanted to build the default package from scratch.
      package = pkgs.firefox-bin;
      profiles.default = {
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          # add-to-deliveries
          # amazon-assistant
          c-c-search-extension # prefix search bar with `cc ` to search C/C++ docs
          display-_anchors
          facebook-container
          ghostery
          onepassword-password-manager
          rust-search-extension # prefix search bar with `rs ` to search Rust docs
          tree-style-tab
        ];
        settings = {
          "browser.contentblocking.category" = "strict";
          "font.default.x-unicode" = "sans-serif";
          "font.default.x-western" = "sans-serif";
          "font.name.monospace.x-unicode" = config.lib.local.defaultMonoFont;
          "font.name.monospace.x-western" = config.lib.local.defaultMonoFont;
          "font.name.sans-serif.x-unicode" = config.lib.local.defaultFont;
          "font.name.sans-serif.x-western" = config.lib.local.defaultFont;
          "font.size.monospace.x-unicode" =
            builtins.floor config.lib.local.defaultFontSize;
          "font.size.monospace.x-western" =
            builtins.floor config.lib.local.defaultFontSize;
          "font.size.variable.x-unicode" =
            builtins.floor config.lib.local.defaultFontSize;
          "font.size.variable.x-western" =
            builtins.floor config.lib.local.defaultFontSize;
        };
        userChrome = ''
          /* Hide tab bar in FF Quantum */
          @-moz-document url("chrome://browser/content/browser.xul") {
            #TabsToolbar {
              visibility: collapse !important;
              margin-bottom: 21px !important;
            }

            #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
              visibility: collapse !important;
            }
          }
        '';
      };
    };

    gpg = {
      enable = true;
      homedir = "${config.xdg.configHome}/gnupg/";
      settings.no-default-keyring = true;
    };

    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    info.enable = true;

    keychain = {
      enable = true;
      enableXsessionIntegration = true;
      keys = ["id_ed25519"];
    };

    man.generateCaches = true;

    ssh = {
      controlMaster = "auto";
      # This moves the default `controlPath`, but also changes %n to %h, so we
      # share the connection even if we typed different hostnames on the
      # command-line.
      controlPath = "${config.lib.local.xdg.runtime.home}/ssh/master-%r@%h:%p";
      enable = true;
      extraConfig = ''
        AddKeysToAgent yes
      '';
      forwardAgent = true;
      userKnownHostsFile = "${config.xdg.stateHome}/ssh/known_hosts";
    };

    ## This is for pairing with VSCode users, including Ronnie. Would be ideal
    ## if there were something like Foobits, but that seems effectively dead.
    vscode = {
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
            sha256 = "sha256-ySfC3PVRezevItW3kWTiY3U8GgB9p223ZiC8XaJ3koM=";
          }
          {
            ## Unfortunately, the nixpkgs version doesrn’t seem to work on darwin.
            name = "vsliveshare";
            publisher = "MS-vsliveshare";
            version = "1.0.5831";
            sha256 = "sha256-QViwZBxem0z62BLhA0zbFdQL3SfoUKZQx6X+Am1lkT0=";
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
  };

  services = {
    emacs = {
      defaultEditor = true;
      # FIXME: Triggers infinite recursion on Linux
      enable = false; # pkgs.stdenv.hostPlatform.isLinux; # because it relies on systemd
    };

    gpg-agent = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      extraConfig = ''
        ## See magit/magit#4076 for the struggles
        ## re: getting Magit/TRAMP/GPG working.
        allow-emacs-pinentry
      '';
      pinentryFlavor = "tty";
    };

    home-manager.autoUpgrade = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      frequency = "daily";
    };

    keybase.enable = pkgs.stdenv.hostPlatform.isLinux;

    mako = {
      enable = pkgs.stdenv.hostPlatform.isLinux;
      font = config.lib.local.defaultFont;
    };

    screen-locker.lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 000000";
  };

  targets.darwin = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    defaults = {
      NSGlobalDomain = {
        AppleFirstWeekday.gregorian = 2; # Monday
        AppleICUDateFormatStrings."1" = "y-MM-dd"; # Iso
        AppleICUForce24HourTime = 1;
        AppleInterfaceStyleSwitchesAutomatically = true;
        AppleLanguages = ["en"];
        AppleLocale = "en_US";
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = true;
        AppleICUNumberSymbols = let
          decimalSeparator = ".";
          groupSeparator = " "; # NARROW NO-BREAK SPACE
        in {
          "0" = decimalSeparator;
          "1" = groupSeparator;
          "10" = decimalSeparator;
          "17" = groupSeparator;
        };
        AppleTemperatureUnit = "Celsius";
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
            "with" = "¯\_(ツ)_/¯";
          }
          {
            replace = "*tableflip*";
            "with" = "(╯°□°)╯︵ ┻━┻";
          }
        ];
        ## Pairs of open/close quotes, in order of nesting.
        NSUserQuotesArray = ["“" "”" "‘" "’"];
        "com.apple.sound.beep.flash" = 1;
      };
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
      "com.apple.universalaccess" = {
        closeViewScrollWheelToggle = true;
        reduceTransparency = true;
      };
    };
    search = "DuckDuckGo";
  };

  xdg = {
    # The files produced here should be echoed in the .gitignore file.
    configFile = {
      "breezy/breezy.conf".text = ''
        [DEFAULT]
        email = ${config.lib.local.primaryEmailAccount.realName} <${config.lib.local.primaryEmailAccount.address}>
      '';
      # TODO: I don’t know how to relocate `$HOME/.cabal/setup-exe-cache` and
      #       `$HOME/.cabal/store`. Hopefully they use `CABAL_DIR`.
      "cabal/config".text = ''
        remote-repo: hackage.haskell.org:http://hackage.haskell.org/packages/archive
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
      ## NB: This isn’t a config file for a specific implementation, but rather
      ##     is `load`ed by various implementations, so we put the common bits
      ##     in one place.
      "common-lisp".source =
        ../../home/${config.lib.local.xdg.config.rel}/common-lisp;
      "emacs" = {
        # Because there are unmanaged files like elpa and custom.el as well as
        # generated managed files.
        recursive = true;
        source = ../../home/${config.lib.local.xdg.config.rel}/emacs;
      };
      "emacs/gnus/.gnus.el".text = ''
        (setq gnus-select-method
              '(nnimap "${config.lib.local.primaryEmailAccount.imap.host}")
              message-send-mail-function 'smtpmail-send-it
              send-mail-function 'smtpmail-send-it
              smtpmail-smtp-server
              "${config.lib.local.primaryEmailAccount.smtp.host}")
      '';
      "gdb/gdbinit".text = ''
        set history filename ${config.xdg.stateHome}/gdb/history
        set history save on
      '';
      "irb/irbrc".text = ''
        IRB.conf[:EVAL_HISTORY] = 200
        IRB.conf[:HISTORY_FILE] = "${config.xdg.stateHome}/irb/history"
        IRB.conf[:SAVE_HISTORY] = 1000
      '';
      # LispWorks init file
      # (http://www.lispworks.com/documentation/lwu41/readme/LIR_73.HTM)
      "lispworks/init.lisp".text = ''
        #+lispworks  (mp:initialize-multiprocessing)

        (load #p"${config.home.homeDirectory}/${config.xdg.configFile."common-lisp".target}/init.lisp")

        (ql:quickload "swank")
        (swank:create-server :port 4005)
      '';
      "npm/npmrc".text = ''
        cache = "${config.xdg.cacheHome}/npm"
      '';
      "octave/octaverc".text = ''
        history_file("${config.xdg.stateHome}/octave/history")
      '';
      "psql/psqlrc".text = ''
        \set HISTFILE ${config.xdg.stateHome}/psql/history
      '';
      "r/environ".text = ''
        R_HISTFILE="${config.xdg.stateHome}/r/history"
        R_PROFILE_USER="${config.xdg.configHome}/r/profile"
      '';
      "r/profile".source = ../../home/${config.lib.local.xdg.config.rel}/r/profile;
      "stack/config.yaml".text = lib.generators.toYAML {} {
        nix.enable = true;
        templates.params = {
          author-name = config.lib.local.primaryEmailAccount.realName;
          author-email = config.lib.local.primaryEmailAccount.address;
          copyright = config.lib.local.primaryEmailAccount.realName;
          github-username = config.programs.git.extraConfig.github.user;
        };
      };
    };
    enable = true;
    userDirs = {
      createDirectories = true;
      enable = pkgs.stdenv.hostPlatform.isLinux;
      videos =
        lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        "${config.home.homeDirectory}/Movies";
      extraConfig = {
        # I used to store these in `$XDG_DOCUMENTS_DIR`, but that directory is
        # often synced (like Dropbox, iCloud, etc.), so this is a parallel
        # directory for things that shouldn’t be synced – like
        # version-controlled directories.
        XDG_PROJECTS_DIR = "${config.lib.local.xdg.userDirs.projects.home}";
      };
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
