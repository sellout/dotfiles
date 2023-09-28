;;; xdg-locations.el --- Putting files in their place  -•- lexical-binding: t; -*-

;;; Commentary:

;; These should be moved upstream to an overlay for XDG compatibility.

;;; Code:

(require 'cl-lib)
(require 'custom-pseudo-theme)
(require 'xdg)

;; NB: This is defined in Emacs 29 and later, so remove once we upgrade.
(defun xdg-state-home ()
  "Return the base directory for user-specific state data.

According to the XDG Base Directory Specification version
0.8 (8th May 2021):

  \"The $XDG_STATE_HOME contains state data that should persist
  between (application) restarts, but that is not important or
  portable enough to the user that it should be stored in
  $XDG_DATA_HOME.  It may contain:

  * actions history (logs, history, recently used files, …)

  * current state of the application that can be reused on a
    restart (view, layout, open files, undo history, …)\""
  (xdg--dir-home "XDG_STATE_HOME" "~/.local/state"))

(defun xl--emacs-path (file xdg-directory)
  ;; NB: Don’t use ‘expand-file-name’. We need to keep “~”, otherwise things
  ;;     often break with TRAMP. This also removes $HOME if it sneaks in.
  (concat (string-replace (getenv "HOME") "~" xdg-directory) "/emacs/" file))

(defun xl-emacs-cache-home (file)
  (xl--emacs-path file (xdg-cache-home)))
(defun xl-emacs-config-home (file)
  (cl-assert (equal (expand-file-name user-emacs-directory)
                    (expand-file-name "emacs/" (xdg-config-home)))
             "‘user-emacs-directory’ (%s) does not agree with ‘xdg-config-home’ (%s)."
             user-emacs-directory
             (xdg-config-home))
  (xl--emacs-path file (xdg-config-home)))
(defun xl-emacs-data-home (file)
  (xl--emacs-path file (xdg-data-home)))
(defun xl-emacs-runtime-dir (file)
  (xl--emacs-path file (or (xdg-data-home) temporary-file-directory)))
(defun xl-emacs-state-home (file)
  (xl--emacs-path file (xdg-state-home)))

(defun xl-custom-paths ()
  "Customize paths across packages to use XDG locations."
  (custom-pseudo-theme-set-variables 'xdg-locations
    ;; Emacs packages

    ;; no package
    `(auto-save-list-file-prefix ,(xl-emacs-state-home "auto-save-list/.saves-"))
    ;; Not setting this, because Emacs has a more reasonable value than we
    ;; currently do. See ‘xl-emacs-runtime-dir’, where we do the inverse.
    ;; `(temporary-file-directory ,${xl-emacs-runtime-dir "."})
    ;; abbrev
    `(abbrev-file-name ,(xl-emacs-state-home "abbrev_defs"))
    ;; auth-source
    `(auth-sources '(,(xl-emacs-config-home "authinfo.gpg")))
    ;; bookmark
    `(bookmark-default-file ,(xl-emacs-state-home "bookmarks"))
    ;; custom
    `(custom-file ,(xl-emacs-config-home "custom.el"))
    `(custom-theme-directory ,(xl-emacs-config-home "custom-themes/"))
    ;; desktop
    `(desktop-path '(,(xl-emacs-state-home "")))
    ;; diary
    `(diary-file ,(xl-emacs-state-home "diary"))
    ;; eshell
    `(eshell-history-file-name ,(xl-emacs-state-home "eshell/history"))
    `(eshell-last-dir-ring-file-name ,(xl-emacs-state-home "eshell/lastdir"))
    ;; gnus
    `(gnus-directory ,(xl-emacs-state-home "gnus/"))
    `(gnus-home-directory ,(xl-emacs-config-home "gnus/"))
    ;; minibuffer
    `(savehist-file ,(xl-emacs-state-home "history"))
    ;; octave
    `(inferior-octave-startup-file ,(xl-emacs-config-home "octave/init.m"))
    ;; package
    ;; TODO: Is this state or data?
    `(package-user-dir ,(xl-emacs-state-home "elpa"))
    ;; recentf
    `(recentf-save-file ,(xl-emacs-state-home "recentf"))
    ;; tramp
    `(tramp-histfile-override ,(xl-emacs-state-home "tramp/history"))
    `(tramp-persistency-file-name ,(xl-emacs-state-home "tramp/persistency"))
    ;; url
    `(url-cookie-file ,(xl-emacs-state-home "url/cookies"))

    ;; third-party packages

    ;; dap-mode
    `(dap-breakpoints-file ,(xl-emacs-cache-home "dap/breakpoints"))
    ;; detached
    `(detached-db-directory ,(xl-emacs-state-home "detached"))
    `(detached-session-directory ,(xl-emacs-state-home "detached/sessions"))
    ;; forge
    `(forge-database-file ,(xl-emacs-state-home "forge/database.sqlite"))
    ;; lsp-mode
    `(lsp-clojure-workspace-cache-dir ,(xl-emacs-cache-home "lsp/clojure"))
    `(lsp-clojure-workspace-dir ,(xl-emacs-state-home "lsp/clojure"))
    `(lsp-rust-analyzer-store-path
      ,(xl-emacs-cache-home "lsp/rust/rust-analyzer"))
    `(lsp-server-install-dir ,(xl-emacs-cache-home "lsp/servers"))
    `(lsp-session-file ,(xl-emacs-state-home "lsp/session-v1"))
    `(lsp-toml-cache-path ,(xl-emacs-cache-home "lsp/toml"))
    ;; multiple-cursors
    `(mc/list-file ,(xl-emacs-state-home "mc-lists.el"))
    ;; org
    `(org-clock-persist-file ,(xl-emacs-state-home "org-clock-save.el"))
    ;; perspective
    `(persp-state-default-file ,(xl-emacs-state-home "perspective.el"))
    ;; projectile
    `(projectile-cache-file ,(xl-emacs-cache-home "projectile.cache"))
    `(projectile-known-projects-file
      ,(xl-emacs-state-home "projectile/bookmarks.eld"))
    ;; slime
    `(slime-repl-history-file ,(xl-emacs-state-home "slime/history.eld"))
    ;; transient
    `(transient-history-file ,(xl-emacs-state-home "transient/history.el"))
    `(transient-levels-file ,(xl-emacs-state-home "transient/levels.el"))
    `(transient-values-file ,(xl-emacs-state-home "transient/values.el"))
    ;; treemacs
    `(treemacs-last-error-persist-file
      ,(xl-emacs-cache-home "treemacs/persist-at-last-error"))
    `(treemacs-persist-file ,(xl-emacs-cache-home "treemacs/persist"))
    ;; wanderlust
    `(wl-folders-file ,(xl-emacs-config-home "wl/folders"))
    `(wl-init-file ,(xl-emacs-config-home "wl/init.el"))
    `(wl-temporary-file-directory ,(xl-emacs-runtime-dir "wl"))))

;; Local Variables:
;; read-symbol-shorthands: (("xl-" . "xdg-locations-"))
;; End:

(provide 'xdg-locations)
;;; xdg-locations.el ends here
