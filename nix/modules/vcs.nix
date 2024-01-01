## source control – good to have globally, so users can fetch initial
## configurations
{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  commonPackages = [
    pkgs.breezy
    pkgs.cvs
    pkgs.pijul
    pkgs.subversion
  ];

  darcsPackage = pkgs.darcs;

  # not doing `git = super.gitFull` in the overlay, because then everything
  # gets rebuilt, but want it here for email support
  gitPackage = pkgs.gitFull;

  mercurialPackage = pkgs.mercurial;

  ## FIXME: This is shared between Git and Mercurial, but I don"t think the
  ##        syntax is actually the same, so need to post-process this list
  ##        appropriately.
  ignores =
    [
      ".cache/" # semi-standard XDG-like cache directory
      ".dir-locals-2.el" # Local emacs config for repos that have a config.
      ".local/" # less standard XDG-like local directory

      # Directories potentially created on network file systems
      ".AppleDB/" # created by Macs
      ".AppleDesktop" # created by Macs
      ".TemporaryItems/" # created by Macs
      ".apdisk" # created by Macs

      # Floobits
      ".floo"
      ".flooignore"
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      # https://en.wikipedia.org/wiki/AppleSingle_and_AppleDouble_formats#Usage
      ".AppleDouble/"
      # https://en.wikipedia.org/wiki/.DS_Store
      ".DS_Store"
      ".LSOverride"
      # https://en.wikipedia.org/wiki/AppleSingle_and_AppleDouble_formats#Usage
      "._*"
    ];
in {
  config =
    if options ? homebrew
    then {
      environment.systemPackages =
        commonPackages
        ++ [
          darcsPackage
          gitPackage
          mercurialPackage
        ];
    }
    else if options ? home
    then {
      home = {
        file = builtins.listToAttrs (map (command:
          lib.nameValuePair
          "${config.lib.local.xdg.bin.rel}/${command}"
          {
            executable = true;
            source = ../../home/${config.lib.local.xdg.bin.rel}/${command};
          }) [
          "git-bare"
          "git-gc-branches"
          "git-ls-subtrees"
        ]);
        packages =
          commonPackages
          ++ [
            pkgs.git-revise # unfortunately not supported by magit
          ];
        sessionVariables.BRZ_LOG = "${config.xdg.stateHome}/breezy/log";
      };

      programs = {
        darcs = {
          enable = true;
          package = darcsPackage;
          author = let
            account = config.lib.local.primaryEmailAccount;
          in ["${account.realName} <${account.address}>"];
          boring = [
            "(^|/)\.git($|/)"
            "(^|/)\.DS_Store$"
          ];
        };
        git = {
          aliases = {
            ## List contributors ordered by number of commits.
            brag-commits = "shortlog --numbered --summary";
            ## Log output that approximates Magit under Solarized.
            lg = "log --color --graph --pretty=format:\"%Cblue%h%Creset %Cgreen%D%Creset %s %>|($((\"$COLUMNS\" - 7)))%C(cyan)%an%Creset %>(6,trunc)%cr\"";
          };
          attributes = ["*.lisp diff=lisp"];
          enable = true;
          extraConfig = {
            diff.algorithm = "histogram";
            init = {
              defaultBranch = "main";
              templateDir = config.lib.local.addHome config.xdg.configFile."git/template".target;
            };
            log.showSignatures = true;
            merge.conflictStyle = "diff3";
            rebase.autosquash = true;
            sendemail.identity = config.lib.local.primaryEmailAccountName;
            ## TODO: Stuff from my old .gitconfig that needs to be reviewed
            diff."lisp".xfuncname = "^(\\((def|test).*)$";
            filter = {
              "hawser" = {
                clean = "git hawser clean %f";
                required = true;
                smudge = "git hawser smudge %f";
              };
              "media" = {
                clean = "git media clean %f";
                required = true;
                smudge = "git media smudge %f";
              };
            };
            mergetool.keepBackup = false;
          };
          ignores = ignores;
          lfs.enable = true;
          # not doing `git = super.gitFull` in the overlay, because then everything
          # gets rebuilt, but want it here for email support
          package = gitPackage;
          signing.signByDefault = true;
          userEmail = config.lib.local.primaryEmailAccount.address;
          userName = config.lib.local.primaryEmailAccount.realName;
        };

        mercurial = {
          enable = true;
          ignores = ignores;
          package = pkgs.mercurial;
          userEmail = config.lib.local.primaryEmailAccount.address;
          userName = config.lib.local.primaryEmailAccount.realName;
        };
      };

      xdg.configFile."git/template" = {
        recursive = true;
        source = ../../home/${config.lib.local.xdg.config.rel}/git/template;
      };
    }
    else {
      environment.systemPackages =
        commonPackages
        ++ [
          darcsPackage
          mercurialPackage
        ];
      programs.git = {
        enable = true;
        package = gitPackage;
      };
    };
}
