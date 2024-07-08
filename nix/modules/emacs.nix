### This file primarily deals with two issues:
###
### 1. Emacs packages often depend on external binaries. If you haven’t
###    explicitly added those to your `home.packages`, then they won’t be able
###    to be located. This specifies explicit dependencies on them so that they
###    don’t need to be in your user environment.
###
### 2. Most Emacs packages have never heard of XDG. This relocates as many files
###    as possible to be XDG compatible.
###
### In future, these should be set in separate emacsPackages overlays, so that
### it can contain the correct settings for all packages, whether or not a
### particular user wants to install that package. However, it can cause an
### issue with packages like `flycheck`, that contain dozens of executable paths
### with any user only being interested in a subset. How to make it possible to
### configure the set of dependencies to add?
###
### NB: For config file locations, settings should generally be upstreamed to
###     the Emacs package, not a Nix overlay. See `emacs-config-home` for more.
###
### There are also settings in here that are just my personal settings that
### should _not_ be upstreamed to some overlay. Those will remain in this file
### in perpetuity.
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.emacs = let
    ## Many packages already put their configs under `user-emacs-directory`, which
    ## Emacs will initialize to `"$XDG_CONFIG_HOME/emacs/"` if the user is
    ## following XDG. Relying on `user-emacs-directory` rather than
    ## `config.xdg.configHome` means we can avoid customizing as many variables
    ## and that package configs are relative to the init file, leaving it up to
    ## users whether or not that is in `"$XDG_CONFIG_HOME/emacs/"`. However, if
    ## there is no init file, then `user-emacs-directory` will be set to
    ## `"~/.emacs.d/"`, not an XDG-compatible location. See
    ## https://www.gnu.org/software/emacs/manual/html_node/emacs/Find-Init.html
    ##
    ## Similarly, Emacs currently has a better approximation of XDG_RUNTIME_DIR
    ## than this Nix configuration does, so let Emacs do its thing.
    ##
    ## NB: This produces an s-exp that Emacs needs to eval, so it should generally
    ##     be prefixed with a `,` in the calls below, as the variables tend to be
    ##     quasi-quoted.
    emacs-config-home = file: "(expand-file-name \"${file}\" user-emacs-directory)";
    emacs-runtime-dir = file: "(expand-file-name \"${file}\" temporary-file-directory)";
    ## In general, Emacs understands `~` as the home directory. We use this rather
    ## than explicit `${config.home.homeDirectory}` because some things run on
    ## remote hosts (via TRAMP) and we want these paths to work regardless of what
    ## the expansion of `$HOME` is.
    emacs-cache-home = "~/${config.lib.local.xdg.cache.rel}/emacs";
    emacs-state-home = "~/${config.lib.local.xdg.state.rel}/emacs";

    ## NB: Bound so we can reference it in the the Emacs setup for `tex-mode`.
    texlive-combined = pkgs.texlive.combine {
      inherit (pkgs.texlive) braids dvipng pgf scheme-basic tikz-cd ulem xcolor;
    };
  in {
    enable = true;
    extraConfig = ''
      ;;; -*- lexical-binding: t; -*-

      (require 'custom-pseudo-theme)

      ;; Ideally, environment variables would be set more generally (outside
      ;; of Emacs), but setting things like ‘launchd.envVariables’,
      ;; ‘launchd.user.envVariables’, etc. doesn't seem to have an effect.
      ${lib.concatStringsSep "\n"
        (lib.mapAttrsToList
          (var: value: "(setenv \"${var}\" \"${value}\")")
          config.home.sessionVariables)}

      ;; TODO: Add these via a flake input … but need it to be in git or hg.
      (add-to-list 'load-path "${pkgs.emacs-color-theme-solarized}")

      ;;; This contains settings we want to customize with Nix-dependent values,
      ;;; organized by package.

      ;;; The setup for paths is split into two groups – the first is global
      ;;; settings, generally where we expect to always use the Emacs-side binary
      ;;; for things. The second is local settings, where we only want to use the
      ;;; Emacs-side binary for local buffers. However, there is another use case
      ;;; – we can also set values we want used for remote instances in the first
      ;;; group, then use the second group to override them for local instances.
      ;;; We should comment in both places when this is done.

      (custom-pseudo-theme-set-variables 'sellout-system-configurations-nix-path
        ;; Emacs packages

        ;; ispell
        '(ispell-program-name "${pkgs.ispell}/bin/ispell")

        ;; third-party packages

        ;; editorconfig
        '(editorconfig-exec-path "${pkgs.editorconfig-core-c}/bin/editorconfig")
        ;; flycheck
        '(flycheck-rust-binary-name "${pkgs.rustc}/bin/rustc")
        '(flycheck-rust-executable "${pkgs.rustc}/bin/rustc")
        '(flycheck-sh-bash-executable "${pkgs.bash}/bin/bash")
        '(flycheck-sh-posix-bash-executable "${pkgs.bash}/bin/bash")
        '(flycheck-sh-shellcheck-executable "${pkgs.shellcheck}/bin/shellcheck")
        '(flycheck-sh-zsh-executable "${pkgs.zsh}/bin/zsh")
        ;; flycheck-vale
        '(flycheck-vale-program "${pkgs.vale}/bin/vale")
        ;; wakatime-mode
        ;; wakatime/wakatime-mode#67
        '(wakatime-cli-path "${pkgs.wakatime}/bin/wakatime-cli"))

      ;; This should be moved to an upstream overlay containing settings for full
      ;; Nix-store paths.
      (custom-pseudo-theme-set-local-variables
          'sellout-system-configurations-nix-path
        ;; Emacs packages
        '(octave
          (inferior-octave-program "${pkgs.octave}/bin/octave"))
        '(tex-mode
          ;; TODO: These can’t go upstream like this – how to depend on the
          ;;       individual binaries correctly?
          (latex-run-command "${texlive-combined}/bin/latex")
          (slitex-run-command nil nil () "I can’t find this command anywhere")
          (tex-bibtex-command "${texlive-combined}/bin/bibtex")
          (tex-run-command "${texlive-combined}/bin/tex"))
        '(vc-darcs
          (vc-darcs-program-name "${pkgs.darcs}/bin/darcs"))

        ;; third-party packages
        '(agenix
          (agenix-age-program "${pkgs.age}/bin/age"))
        '(darcsum
          (darcsum-program "${pkgs.darcs}/bin/darcs"))
        '(detached
          (detached-dtach-program "${pkgs.dtach}/bin/dtach"))
        '(dhall-mode
          (dhall-command "${pkgs.dhall}/bin/dhall"))
        '(envrc
          (envrc-direnv-executable "${pkgs.direnv}/bin/direnv"))
        '(floobits
          (floobits-python-executable "${pkgs.python}/bin/python"))
        '(flycheck
          (flycheck-rust-cargo-executable "${pkgs.cargo}/bin/cargo"))
        '(ggtags
          (ggtags-executable-directory "${pkgs.global}/bin/"))
        '(graphviz-dot-mode
          (graphviz-dot-dot-program "${pkgs.graphviz}/bin/dot")
          (graphviz-dot-layout-programs
           '("${pkgs.graphviz}/bin/dot"
             "${pkgs.graphviz}/bin/neato"
             "${pkgs.graphviz}/bin/fdp"
             "${pkgs.graphviz}/bin/sfdp"
             "${pkgs.graphviz}/bin/twopi"
             "${pkgs.graphviz}/bin/circo"))
          (graphviz-dot-view-command "${pkgs.graphviz}/bin/dotty %s"))
        '(helm-rg
          (helm-rg-git-executable "${pkgs.git}/bin/git")
          (helm-rg-ripgrep-executable "${pkgs.ripgrep}/bin/ripgrep"))
        '(idris-mode
          (idris-interpreter-path "${pkgs.idris}/bin/idris"))
        '(lsp-nix
          (lsp-nix-nil-server-path "${pkgs.nil}/bin/nil"))
        '(lsp-pylsp
          (lsp-pylsp-server-command
           '("${pkgs.pythonPackages.python-lsp-server}/bin/pylsp")))
        '(lsp-rust
          (lsp-rust-analyzer-server-command
           '("${pkgs.rust-analyzer}/bin/rust-analyzer")))
        '(magit
          (magit-git-executable "${pkgs.git}/bin/git"))
        '(markdown-mode
          (markdown-command "${pkgs.pandoc}/bin/pandoc"))
        '(nix-mode
          (nix-build-executable "${pkgs.nix}/bin/nix-build")
          (nix-executable "${pkgs.nix}/bin/nix")
          (nix-instantiate-executable "${pkgs.nix}/bin/nix-instantiate")
          (nix-nixfmt-bin "${pkgs.nixfmt}/bin/nixfmt")
          (nix-shell-executable "${pkgs.nix}/bin/nix-shell")
          (nix-store-executable "${pkgs.nix}/bin/nix-store"))
        '(ormolu
          (ormolu-process-path "${pkgs.ormolu}/bin/ormolu"))
        '(projectile
          (projectile-darcs-command "${pkgs.darcs}/bin/darcs show files -0 ."))
        '(rustic
          (rustic-rustfmt-bin "${pkgs.rustfmt}/bin/rustfmt"))
        '(sbt-mode
          (sbt:program-name "${pkgs.sbt}/bin/sbt"))
        '(treemacs
          (treemacs-python-executable "${pkgs.python}/bin/python"))
        '(vc-pijul
          (vc-pijul-program-name "${pkgs.pijul}/bin/pijul")))

      ;; TODO: These variables don’t work if set via a theme. See
      ;;       jwiegley/use-package#1002. Unfortunately, this means they get
      ;;       written out to custom.el, and then that ends up with the wrong
      ;;       values over time.
      (custom-set-variables
       ;; easy-pg
       '(epg-gpg-program "${pkgs.gnupg}/bin/gpg2")
       '(epg-gpgconf-program "${pkgs.gnupg}/bin/gpgconf")
       '(epg-gpgsm-program "${pkgs.gnupg}/bin/gpgsm"))

      ;; These are personal settings that should remain after everything else is
      ;; upstreamed.
      (custom-pseudo-theme-set-variables 'sellout-system-configurations
        ;; Emacs packages

        ;; no package
        '(user-full-name
          "${config.lib.local.primaryEmailAccount.realName}")
        '(user-mail-address
          "${config.lib.local.primaryEmailAccount.address}")
        ;; org
        '(org-default-notes-file "${config.xdg.userDirs.documents}/org/notes.org")
        '(org-directory "${config.xdg.userDirs.documents}/org")
        ;; tramp
        ;; NB: This one should _not_ be upstreamed, because the default is nil.
        '(tramp-auto-save-directory "${emacs-state-home}/tramp/auto-save/")
        ;; NB: Set here instead of in init.el because it depends on home-manager.
        '(tramp-use-ssh-controlmaster-options
          nil
          nil
          ()
          "ControlMaster options are set by home-manager.")
        ;; url
        ;; TODO: Do I actually want to set this?
        ;;'(url-personal-mail-address
        ;;  "${config.lib.local.primaryEmailAccount.address}")

        ;; third-party packages

        ;; flim
        '(smtp-fqdn "${config.lib.local.primaryEmailAccount.smtp.host}")
        ;; magit
        '(magit-repository-directories
          ;; TODO: Add entries for rest of tailnet.
          '(("${config.lib.local.xdg.userDirs.projects.home}" . 3)))
        ;; projectile
        '(projectile-dirconfig-file
          "${config.lib.local.xdg.config.rel}/projectile")
        ;; wanderlust
        '(elmo-imap4-default-port
          ${toString config.lib.local.primaryEmailAccount.smtp.port})
        '(elmo-imap4-default-server
          "${config.lib.local.primaryEmailAccount.imap.host}")
        '(elmo-imap4-default-user
          "${config.lib.local.primaryEmailAccount.userName}")
        '(wl-smtp-posting-port
          ${toString config.lib.local.primaryEmailAccount.smtp.port})
        '(wl-smtp-posting-server
          "${config.lib.local.primaryEmailAccount.smtp.host}")
        '(wl-smtp-posting-user
          "${config.lib.local.primaryEmailAccount.userName}"))

      (custom-pseudo-theme-set-local-variables 'sellout-system-configurations
        ;; Emacs packages
        '(autorevert
          ;; TODO: This doesn’t depend on Nix, but it does require ‘c-p-t-s-l-v’.
          ;;       Those functions should be moved into their own module (package?)
          ;;       so they can easily be referenced from init.el as well.
          (auto-revert-check-vc-info
           t
           nil
           ()
           "This doesn’t behave well with TRAMP (see magit/magit#1205), so leave it disabled on remote machines.")))

      (custom-pseudo-theme-set-faces 'sellout-system-configurations
        '(default
          ((t (:family "${config.lib.local.defaultSansFont}"
               :height
               ${builtins.toString (builtins.floor (config.lib.local.defaultFontSize * 10))}))))
        '(fixed-pitch ((t (:family "${config.lib.local.defaultMonoFont}"))))
        '(font-lock ((t (:family "${config.lib.local.programmingFont}"))))
        '(variable-pitch ((t (:family "${config.lib.local.defaultSansFont}")))))
    '';
    extraPackages = epkgs: [
      epkgs.ace-window # better `other-window`
      # epkgs.agda2-mode # fails while linking Agda-2.6.2.2
      epkgs.agenix
      epkgs.applescript-mode
      epkgs.auto-dark
      epkgs.auto-dim-other-buffers
      epkgs.bats-mode
      epkgs.bradix
      epkgs.buttercup # Emacs-lisp unit testing
      epkgs.cascading-dir-locals
      epkgs.circe
      epkgs.company
      epkgs.company-box
      epkgs.company-nixos-options
      epkgs.company-posframe # uses a child frame for completions
      epkgs.dap-mode
      pkgs.llvmPackages.lldb
      epkgs.darcsum
      epkgs.default-text-scale # replaces zoom-frm
      epkgs.delight
      epkgs.detached
      epkgs.dhall-mode
      epkgs.diminish
      epkgs.direnv
      pkgs.direnv # needed by `epkgs.direnv` (but not by `epkgs.envrc`)
      epkgs.editorconfig
      # epkgs.emacs-elim
      epkgs.eldev
      epkgs.elfeed # RSS reader
      epkgs.elfeed-goodies
      epkgs.elfeed-org
      epkgs.envrc
      epkgs.epresent
      epkgs.extended-faces
      epkgs.floobits
      epkgs.flycheck
      epkgs.flycheck-eldev
      epkgs.flycheck-vale # linter for English prose
      # Needs git on exec-path
      epkgs.forge
      pkgs.git
      epkgs.ggtags
      epkgs.git-gutter
      epkgs.git-modes
      epkgs.gitter
      epkgs.graphviz-dot-mode
      epkgs.haskell-mode
      epkgs.helm
      epkgs.helm-company
      epkgs.helm-descbinds
      # epkgs.helm-ghc
      epkgs.helm-github-stars
      epkgs.helm-gitlab
      epkgs.helm-idris
      epkgs.helm-itunes
      epkgs.helm-ls-git
      epkgs.helm-lsp
      epkgs.helm-nixos-options
      epkgs.helm-org-rifle
      epkgs.helm-projectile
      epkgs.helm-rg
      epkgs.helm-xref
      epkgs.highlight-doxygen
      epkgs.idris-mode
      epkgs.json-mode
      epkgs.keychain-environment
      epkgs.ligature # enables use of Fira Code, etc. ligatures
      # the Emacs mode is contained in the program’s package.
      # FIXME: installs but doesn't run on darwin
      pkgs.lilypond
      epkgs.lsp-haskell
      epkgs.lsp-mode
      # Nix doesn’t recognize that python is a runtime dep of lsp-treemacs
      epkgs.lsp-treemacs
      pkgs.python
      epkgs.lsp-ui
      epkgs.magit
      epkgs.magit-popup
      epkgs.markdown-mode
      epkgs.multi-term
      epkgs.multiple-cursors
      epkgs.muse
      epkgs.nix-mode
      epkgs.nix-sandbox
      epkgs.nixos-options
      epkgs.ormolu
      epkgs.ox-gfm
      epkgs.ox-slack
      epkgs.page-break-lines
      epkgs.paredit
      epkgs.paredit-everywhere
      epkgs.pdf-tools
      epkgs.perspective
      epkgs.persp-projectile
      epkgs.pinentry
      epkgs.projectile
      epkgs.projectile-ripgrep
      epkgs.projectile-speedbar
      epkgs.proof-general
      epkgs.protobuf-mode
      epkgs.reveal-in-osx-finder # restrict to darwin?
      # Looks up `cargo` in `exec-path`
      epkgs.rustic
      pkgs.cargo
      epkgs.sbt-mode
      epkgs.scala-mode
      epkgs.slack
      epkgs.twittering-mode
      epkgs.undo-tree
      epkgs.unison-ts-mode
      epkgs.vc-darcs
      epkgs.vc-pijul
      epkgs.wakatime-mode
      epkgs.wanderlust
      epkgs.which-key
      epkgs.yaml-mode
      epkgs.yasnippet
    ];
  };
}
