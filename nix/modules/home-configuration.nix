{
  config,
  dotfiles,
  lib,
  pkgs,
  self,
  ...
}: {
  imports = [
    ./emacs
    ./i3.nix
    ./input-devices.nix
    ./nix-configuration.nix
    ./nixpkgs-configuration.nix
    ./shell.nix
    ./tex.nix
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
    file = let
      toml = pkgs.formats.toml {};
    in {
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
      # ECL’s init file
      # (https://ecl.common-lisp.dev/static/manual/Invoking-ECL.html#Invoking-ECL)
      ".ecl".source =
        ../../home/${config.lib.local.xdg.config.rel}/common-lisp/init.lisp;
      # SBCL’s init file
      # (https://www.sbcl.org/manual/index.html#Initialization-Files)
      ".sbclrc".text = ''
        (load #p"${config.lib.local.addHome config.xdg.configFile."common-lisp".target}/init.lisp")

        (defvar asdf::*source-to-target-mappings* '((#p"/usr/local/lib/sbcl/" nil)))
      '';
      # Clozure CL’s init file
      # (https://ccl.clozure.com/docs/ccl.html#the-init-file)
      "ccl-init.lisp".text = ''
        (setf *default-file-character-encoding* :utf-8)
        (load #p"${config.lib.local.addHome config.xdg.configFile."common-lisp".target}/init.lisp")
      '';
      # CMUCL’s init file
      # (https://cmucl.org/docs/cmu-user/html/Command-Line-Options.html#Command-Line-Options)
      "init.lisp".source =
        ../../home/${config.lib.local.xdg.config.rel}/common-lisp/init.lisp;
      # NB: This currently gets put in `config.xdg.cacheHome`, since most of the
      #     stuff in `$CARGO_HOME` is cached data. However, this means that the
      #     Cargo config can be erased (until the next `home-manager switch`) if
      #     the cache is cleared.
      "${config.lib.local.removeHome config.home.sessionVariables.CARGO_HOME}/config.toml".source = toml.generate "Cargo config.toml" {
        ## NB: Relative paths aren’t relative to the workspace, as one would
        ##     hope. See rust-lang/cargo#7843.
        build.target-dir = "${config.xdg.stateHome}/cargo";
        ## Cargo writes executables to the bin/ subdir of this path.
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
        pkgs._1password # This is the CLI, needed by VSCode 1Password extension
        # pkgs._1password-gui # doesn’t get installed in the correct location
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
        # pkgs.slack # currently subsumed by ferdium
        pkgs.synergy
        pkgs.tailscale
        pkgs.tikzit
        # pkgs.wire-desktop # currently subsumed by ferdium
        pkgs.xdg-ninja # home directory complaining
      ]
      ++ map (font: font.package) fonts
      ++ lib.optionals (pkgs.system != "aarch64-linux") [
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
        # pkgs.nixcasks.bartender # currently failing to build
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
        pkgs.nixcasks.handbrake
        pkgs.nixcasks.imageoptim
        pkgs.nixcasks.keybase # not available on darwin via Nix
        pkgs.nixcasks.kiibohd-configurator
        pkgs.nixcasks.kindle
        pkgs.nixcasks.lastfm
        pkgs.nixcasks.marathon
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
        pkgs.nixcasks.remarkable
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
      CABAL_CONFIG = config.lib.local.addHome config.xdg.configFile."cabal/config".target;
      CABAL_DIR = "${config.xdg.stateHome}/cabal";
      CARGO_HOME = "${config.xdg.cacheHome}/cargo";
      IRBRC = config.lib.local.addHome config.xdg.configFile."irb/irbrc".target;
      LEIN_HOME = "${config.xdg.dataHome}/lein";
      LW_INIT = "${config.lib.local.addHome config.xdg.configFile."lispworks/init.lisp".target}";
      MAKEFLAGS = "-j$(nproc)";
      NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
      OCTAVE_INITFILE = "${config.lib.local.addHome config.xdg.configFile."octave/octaverc".target}";
      PGPASSFILE = "$XDG_CONFIG_HOME/pg/pgpass";
      ## TODO: Make emacs-pager better (needs to handle ANSI escapes, like I do
      ##       in compilation buffers).
      # PAGER = "${config.lib.local.xdg.bin.home}/emacs-pager";
      PSQLRC = "${config.lib.local.addHome config.xdg.configFile."psql/psqlrc".target}";
      # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPYCACHEPREFIX
      PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
      # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
      PYTHONUSERBASE = "${config.xdg.stateHome}/python";
      RANDFILE = "${config.xdg.stateHome}/openssl/rnd";
      R_ENVIRON_USER = "${config.xdg.configHome}/r/environ";
      RUSTUP_HOME = "${config.xdg.stateHome}/rustup";
      STACK_XDG = "1";
      # May be able to remove this after wakatime/wakatime-cli#558 is fixed.
      WAKATIME_HOME = "${config.xdg.configHome}/wakatime";
      XAUTHORITY = "${config.lib.local.xdg.runtimeDir}/Xauthority";
    };

    shellAliases = let
      # A builder for quick dev environments.
      #
      # TODO: Since this uses both `nix` and the containing flake, it seems like
      #       there should be a better way to get that information to the
      #       command than having the shell look it up.
      devEnv = devShell: "nix develop " + "sys#" + devShell;
      template = template: "nix flake init -t " + "sys#" + template;
    in {
      grep = "grep --color";

      # Some of the long flag names aren’t widely supported, so this alias
      # should be equivalent to `ls --almost-all --human-readable --color`.
      ls = "ls -Ah --color";

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

      ## Set paths to XDG-compatible places
      keychain = "keychain --dir ${config.lib.local.xdg.runtimeDir}/keychain --absolute";
      wget = "wget --hsts-file=${config.xdg.dataHome}/wget-hsts";

      ## Include dotfiles.
      tree = "tree -a";
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

  manual.html.enable = true;

  news.display = "show";

  nix = {
    package = pkgs.nix;
    registry.sys.flake = self;
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
      enable = pkgs.system != "aarch64-linux";
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
        search.default = "DuckDuckGo";
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
      controlPath = "${config.lib.local.xdg.runtimeDir}/ssh/master-%r@%h:%p";
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
            sha256 = "ySfC3PVRezevItW3kWTiY3U8GgB9p223ZiC8XaJ3koM=";
          }
          {
            name = "unison";
            publisher = "unison-lang";
            version = "1.2.0";
            sha256 = "ulm3a1xJxtk+SIQP1sByEqgajd1a4P3oEfVgxoF5GcQ=";
          }
          {
            ## Unfortunately, the nixpkgs version doesrn’t seem to work on darwin.
            name = "vsliveshare";
            publisher = "MS-vsliveshare";
            version = "1.0.5831";
            sha256 = "QViwZBxem0z62BLhA0zbFdQL3SfoUKZQx6X+Am1lkT0=";
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

  ## FIXME: SSH doesn’t create the directory for the `ControlPath`, so if this
  ##        isn’t done, SSH doesn’t work on new machines. It seems like a bug
  ##        in SSH to me. Or, at least, SSH should give a better error message
  ##        when this occurs.
  home.activation.sshControlPath = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p '${config.lib.local.xdg.runtimeDir}/ssh'
  '';

  services = {
    gpg-agent = {
      ## NB: Despite having a launchd configuration, this module also has a
      ##     linux-only assertion.
      enable = pkgs.stdenv.hostPlatform.isLinux;
      pinentryPackage = pkgs.pinentry-tty;
      ## TODO: These values are just copied from my manual config. Figure out if
      ##       they’re actually good.
      defaultCacheTtl = 600;
      maxCacheTtl = 7200;
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
      "org.hammerspoon.Hammerspoon".MJConfigFile = "${config.xdg.configHome}/hammerspoon/init.lua";
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
        repository hackage.haskell.org
          url: http://hackage.haskell.org/packages/archive
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
      "gdb/gdbinit".text = ''
        set history filename ${config.xdg.stateHome}/gdb/history
        set history save on
      '';
      ## TODO: This is stolen from the Home Manager module, because that only
      ##       works for Linux. Extract this to a local module with the linux
      ##       config next to it or, even better, fix the upstream module.
      "gnupg/gpg-agent.conf".text = let
        cfg = config.services.gpg-agent;
        optional = lib.optional;
      in
        lib.concatStringsSep "\n"
        (optional (cfg.enableSshSupport) "enable-ssh-support"
          ++ optional cfg.grabKeyboardAndMouse "grab"
          ++ optional (!cfg.enableScDaemon) "disable-scdaemon"
          ++ optional (cfg.defaultCacheTtl != null)
          "default-cache-ttl ${toString cfg.defaultCacheTtl}"
          ++ optional (cfg.defaultCacheTtlSsh != null)
          "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}"
          ++ optional (cfg.maxCacheTtl != null)
          "max-cache-ttl ${toString cfg.maxCacheTtl}"
          ++ optional (cfg.maxCacheTtlSsh != null)
          "max-cache-ttl-ssh ${toString cfg.maxCacheTtlSsh}"
          ++ optional (cfg.pinentryPackage != null)
          "pinentry-program ${lib.getExe cfg.pinentryPackage}"
          ++ [cfg.extraConfig]);
      "irb/irbrc".text = ''
        IRB.conf[:EVAL_HISTORY] = 200
        IRB.conf[:HISTORY_FILE] = "${config.xdg.stateHome}/irb/history"
        IRB.conf[:SAVE_HISTORY] = 1000
      '';
      # LispWorks init file
      # (http://www.lispworks.com/documentation/lwu41/readme/LIR_73.HTM)
      "lispworks/init.lisp".text = ''
        #+lispworks  (mp:initialize-multiprocessing)

        (load #p"${config.lib.local.addHome config.xdg.configFile."common-lisp".target}/init.lisp")

        (ql:quickload "swank")
        (swank:create-server :port 4005)
      '';
      "npm/npmrc".source = ../../home/${config.lib.local.xdg.config.rel}/npm/npmrc;
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
        (config.lib.local.addHome "Movies");
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
