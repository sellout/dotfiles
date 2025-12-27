## source control – good to have globally, so users can fetch initial
## configurations
##
## TODO: Package some repository analysis tooling like
##     • [Git of
##       Theseus](https://erikbern.com/2016/12/05/the-half-life-of-code.html) or
##     • [Hercules](https://github.com/src-d/hercules#readme)
{
  config,
  flaky,
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
  config = flaky.lib.multiConfig options {
    darwinConfig = {
      environment.systemPackages =
        commonPackages
        ++ [
          darcsPackage
          gitPackage
          mercurialPackage
        ];
    };
    homeConfig = {
      home = {
        file = builtins.listToAttrs (map (command:
          lib.nameValuePair
          "${config.lib.local.xdg.bin.rel}/${command}"
          {
            executable = true;
            source = ./${command};
          }) [
          "git-bare"
          "git-gc-branches"
          "git-ls-subtrees"
        ]);
        packages =
          commonPackages
          ++ [
            pkgs.difftastic
            pkgs.git-revise # unfortunately not supported by magit
            pkgs.git-standup
            pkgs.mergiraf
          ];
        sessionVariables.BRZ_LOG = "${config.xdg.stateHome}/breezy/log";
        shellAliases.svn = "svn --config-dir '${config.xdg.configHome}/subversion'";
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
          enable = true;
          ## NB: not doing `git = super.gitFull` in the overlay, because then
          ##     everything gets rebuilt, but want it here for email support.
          package = gitPackage;
          attributes = [
            "* merge=mergiraf"
            "*.lisp diff=lisp"
          ];
          ignores = ignores;
          lfs.enable = true;
          settings = {
            alias = {
              ## List contributors ordered by number of commits.
              brag-commits = "shortlog --numbered --summary";
              ## Log output that approximates Magit under Solarized.
              lg = "log --color --graph --pretty=format:\"%Cblue%h%Creset %Cgreen%D%Creset %s %>|($((\"$COLUMNS\" - 7)))%C(cyan)%an%Creset %>(6,trunc)%cr\"";
            };
            diff = {
              algorithm = "histogram";
              external = "difft";
              tool = "difftastic";
            };
            difftool = {
              difftastic.cmd = "difft \"$MERGED\" \"$LOCAL\" \"abcdef1\" \"100644\" \"$REMOTE\" \"abcdef2\" \"100644\"";
              prompt = false;
            };
            init = {
              defaultBranch = "main";
              templateDir = "${./git/template}";
            };
            log.showSignatures = true;
            merge = {
              conflictStyle = "diff3";
              mergiraf = {
                name = "mergiraf";
                driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
              };
            };
            pager.difftool = true;
            rebase.autosquash = true;
            sendemail.identity = config.lib.local.primaryEmailAccountName;
            user = {
              email = config.lib.local.primaryEmailAccount.address;
              name = config.lib.local.primaryEmailAccount.realName;
            };
            ## TODO: Stuff from my old .gitconfig that needs to be reviewed
            diff.lisp.xfuncname = "^(\\((def|test).*)$";
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
          signing.signByDefault = true;
        };

        mercurial = {
          enable = true;
          ignores = ignores;
          package = pkgs.mercurial;
          userEmail = config.lib.local.primaryEmailAccount.address;
          userName = config.lib.local.primaryEmailAccount.realName;
        };
      };

      xdg.configFile = {
        "breezy/breezy.conf".text = ''
          [DEFAULT]
          email = ${config.lib.local.primaryEmailAccount.realName} <${config.lib.local.primaryEmailAccount.address}>
        '';
      };
    };
    nixosConfig = {
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
  };
}
