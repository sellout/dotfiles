;;; default.el --- Sellout’s Emacs configuration  -*- lexical-binding: t -*-

;;; Commentary:

;; This package is part of a larger Nix-based configuration. It can _probably_
;; be used in isolation, but has not been, so be aware.

;; # mode line lighter guidelines
;; - global lighters should be diminished completely
;; - non-global lighters should be symbolized to be compact
;; - if lighters display state, there are a few options
;;   - up to five states (error/warn/info/success/shadow) can be represented by
;;     simply propertizing the symbol itself (see ‘envrc’)
;;   - if there are more states (or the states don’t reasonably map to the
;;     categories above), use a lighter like ‘<mode symbol>[<state symbol>]’,
;;     propertizing the state symbol as appropriate (see ‘flycheck’ … sort of)
;;   - if there are multiple states (e.g., independent counts of errors and
;;     warnings), use a lighter like
;;    ‘<mode symbol>[<state1 symbol> <state2 symbol> <…>]’, where each state
;;     symbol can be propertized individually. For something like error counts,
;;     non-zero counts should use the face ‘error’ and zero counts should use
;;     face ‘shadow’ (see ‘compilation’).
;;   - if the state changes often, try to maintain the same width for each
;;     state, even if the indicators are different lengths, in order to reduce
;;     mode-line flicker (see ‘flycheck’)
;;   - some states are not fixed-width (e.g., ‘projectile’), but generally these
;;     also don’t change very frequently, so it’s not an issue.

;;; Code:

(defgroup sellout nil
  "My personal configuration."
  :group 'local)

(defcustom sellout-describe-key-package 'helm-descbinds
  "‘helm-descbinds’ and ‘which-key’ are mutually incompatible.
‘helm-descbinds’ seems better for a few reasons, but I’m having trouble getting
 it to work. If this is nil, no package will be used."
  :type '(choice (const helm-descbinds) (const which-key)))

(defcustom sellout-lsp-package 'eglot
  "‘eglot’ and ‘lsp-mode’ both offer LSP integration.
‘lsp-mode’ is much richer, but also much more complicated and flaky."
  :type '(choice (const eglot) (const lsp-mode)))

(defun require-config (feature &optional filename noerror)
  "Like ‘require’, but first look for FEATURE in ‘user-emacs-directory’.
FILENAME and NOERROR behave the same as for ‘require‘."
  (let ((load-path (cons user-emacs-directory load-path)))
    (require feature filename noerror)))

(require-config 'xdg-locations)

(xdg-locations-custom-paths)

;; This needs to be loaded like _right here_:
;;
;; • ‘xdg-locations-custom-paths’ above sets the correct ‘custom-file’ and
;;
;; • any variables in ‘custom-file’ should be initialized before we start
;;   loading any other packages (in particular, we need to set
;;  ‘custom-safe-themes’ from the local value before ‘custom-enabled-themes’ is
;;   set below).
(load custom-file)

(eval-when-compile
  (require 'use-package))

(use-package use-package
  :custom (use-package-always-defer t))

;; NB: Need these ones first, because use-package uses them in other clauses.
(use-package bind-key)
(use-package delight)

(use-package inheritance-theme
  ;; FIXME: Not sure why the ‘autoload’ in this file isn’t working. Maybe have
  ;;        to move it to the primary package file? In any case, this ensures
  ;;        that our theme is available. Once I get the ‘autoload’ working,
  ;;        remove this.
  :demand t)

(use-package interim-faces
  :demand t)

(use-package solarized-theme
  ;; FIXME: Not sure why the ‘autoload’ in this file isn’t working. Maybe have
  ;;        to move it to the primary package file? In any case, this ensures
  ;;        that our theme is available. Once I get the ‘autoload’ working,
  ;;        remove this.
  :demand t)

;; This package is assumed to be loaded already, so do the rest of the setup
;; immediately.
(use-package custom
  ;; NB: Themes need to be loaded before we set up ‘custom’, since that then
  ;;     enables them.
  :after (inheritance-theme solarized-theme)
  :config
  ;; Stolen from https://www.emacswiki.org/emacs/DisabledCommands
  (defadvice en/disable-command (around put-in-custom-file activate)
    "Put declarations in `custom-file'."
    (let ((user-init-file custom-file))
      ad-do-it))
  :custom
  (custom-enabled-themes '(bringhurst solarized inheritance))
  (custom-unlispify-remove-prefixes t))

;; This is a escape hatch for loading non-Nix-managed configuration local to the
;; user account. See the contents of ‘user-init-file’ for more information.
(require-config 'local nil nil)

(use-package abbrev
  :delight "…")

(use-package ace-window
  :bind ("C-c a" . ace-window)
  :custom
  (ace-window-display-mode t)
  (aw-char-position 'left)
  (aw-display-mode-overlay nil))

(use-package agenix)

(use-package ansi-color
  :hook (compilation-filter . ansi-color-compilation-filter))

(use-package auto-dark
  :after custom
  :defer nil
  :delight (auto-dark-mode)
  :init (auto-dark-mode))

(use-package autorevert
  :custom (auto-revert-mode-text "↩"))

(use-package bradix
  :preface
  ;; TODO: Move these into a separate repo for my dozenal work.
  (defconst 𝜏 (* 2 float-pi)
    "Tau or “turn” is the correct way to calculate rotation.
1𝜏 is a single full rotation.")

  ;; See https://physics.nist.gov/cuu/Units/binary.html for more about these
  ;; prefixes.
  (defconst base-binary-multiple (expt 2 10))
  (defconst Ki (expt base-binary-multiple 1))
  (defconst Mi (expt base-binary-multiple 2))
  (defconst Gi (expt base-binary-multiple 3))
  (defconst Ti (expt base-binary-multiple 4))
  (defconst Pi (expt base-binary-multiple 5))
  (defconst Ei (expt base-binary-multiple 6))
  :config
  (defconst seconds-in-day (bradix-parse "86 399⠊999 85")
    "Mean seconds per day.
This is needed since Emacs generally wants time values in seconds.")

  (defun days-to-seconds (days)
    "Convert a floating-point number of DAYS to the number of seconds."
    (* (/ days 𝜏) seconds-in-day))

  (defconst dozenal-blink-rate
    (days-to-seconds (* (bradix-parse "0⠌000 02") 𝜏))
    "Blink at a rate of 0⠌000 02𝜏.")
  :functions bradix-parse days-to-seconds)

(use-package bug-reference
  :hook
  (prog-mode . bug-reference-prog-mode)
  (text-mode . bug-reference-mode))

(use-package calendar
  :custom
  (calendar-date-style 'iso)
  (calendar-time-display-form
   '(24-hours ":" minutes (if time-zone " ") time-zone))
  (calendar-week-start-day 1))

(use-package cascading-dir-locals
  :custom (cascading-dir-locals-mode t))

(use-package cc-mode
  ;; Semi-standard C++ template implementation file extension
  :init (add-to-list 'auto-mode-alist '("\\.tcc\\'" . c++-mode)))

(use-package comint
  :custom (comint-input-ignoredups t))

(use-package company
  :custom
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 2)
  (company-posframe-lighter "")
  (company-posframe-mode t nil (company-posframe))
  (company-posframe-show-metadata t)
  :delight "👔")

(use-package compile
  :custom
  (compilation-save-buffers-predicate
   'projectile-current-project-buffer-p
   "This only asks to save buffers in the project being compiled ... unless we're not in a project, then it asks for all files."))

(use-package dap-mode
  :commands dap-debug
  :functions dap-hydra
  :hook
  (dap-stopped . (lambda (arg) (call-interactively #'dap-hydra))))

(use-package dap-python
  :config
  (defun dap-python--pyenv-executable-find (command)
    (with-venv (executable-find "python")))
  :custom (dap-python-debugger 'debugpy)
  :functions with-venv)

;; TODO: The fringe and margin widths don’t appear to be correct
(cl-defun fix-frame-width
    (&optional (face 'default) (columns 2) (frame (selected-frame)))
  "Set the FRAME width so that it fits the desired layout.
The layout is COLUMNS of windows, with each window fitting ‘fill-column’
characters of FACE plus any specified ‘fringe’."
  (interactive)
  (let ((font-width (window-font-width nil face)))
    (set-frame-width frame
                     (* columns
                        (+ (* left-margin-width font-width)
                           (or left-fringe-width 8) ; “8” so they’re not nil
                           (* fill-column font-width)
                           (or right-fringe-width 8) ; “8” so they’re not nil
                           (* right-margin-width font-width)))
                     nil
                     t)))

(defun fix-frame-width-fixed ()
  "Just a wrapper around ‘fix-frame-width’ to make it bindable."
  (interactive)
  (fix-frame-width 'fixed-pitch))

(use-package default-text-scale
  ;; WARN: This isn’t a user-reserved key, but it matches the default bindings
  ;;       for ‘default-text-scale-mode’, so we’ll use it until we notice it’s
  ;;       trampling something.
  :bind ("C-M-;" . fix-frame-width-fixed)
  :custom (default-text-scale-mode t))

(use-package delsel
  :custom (delete-selection-mode t))

(defun sellout--detached--db-update-sessions (orig-fn)
  "Ensure ORIG-FN doesn’t truncate data written to the sessions DB."
  (let ((print-level nil)
        (print-length nil))
    (funcall orig-fn)))

;; TODO: Currently `detached-notification-function` is customized. This should
;;       be undone once I figure out dbus on Mac & Nix.
(use-package detached
  :bind
  ("C-c d" . detached-action-map)
  ([remap async-shell-command] . detached-shell-command)
  ([remap compile] . detached-compile)
  ([remap detached-open-session] . detached-consult-session)
  ([remap recompile] . detached-compile-recompile)
  :config
  ;; See
  ;; https://lists.sr.ht/~niklaseklund/detached.el/%3C43845199-6AAD-4651-9D13-4F02F0D887D6%40technomadic.org%3E
  (advice-add 'detached--db-update-sessions
              :around
              #'sellout--detached--db-update-sessions)
  (connection-local-set-profile-variables
   'remote-detached
   '((detached-shell-program . "bash")
     ;; usually connecting to a Linux box
     (detached-terminal-data-command . gnu/linux)))
  (connection-local-set-profiles '() 'remote-detached)
  :custom
  (detached-notification-function 'detached-state-transitionion-echo-message)
  :delight
  (detached-eshell-mode "🔗")
  (detached-shell-mode "🔗")
  (detached-vterm-mode "🔗")
  :init (detached-init))

(use-package dired
  :custom (dired-listing-switches "-Alh"))

;; TODO: Make it possible to select which modes
;;      ‘global-display-line-numbers-mode’ controls, like
;;      ‘whitespace-global-modes’.
(use-package display-line-numbers
  :after bradix
  :custom
  (display-line-numbers-current-absolute t)
  (display-line-numbers-major-tick (bradix-parse "10⠌"))
  (display-line-numbers-minor-tick 4)
  (display-line-numbers-type 'relative)
  :custom-face
  (line-number-current-line ((t (:inherit (line-number) :inverse-video t))))
  (line-number-major-tick ((t (:inherit (line-number) :strike-through t :weight bold))))
  (line-number-minor-tick ((t (:inherit (line-number) :weight bold))))
  ;; TODO: This should be managed differently so it can be toggled via
  ;;      ‘over-the-shoulder’.
  :hook (prog-mode . display-line-numbers-mode))

(use-package editorconfig
  :delight "⚙️"
  :init (editorconfig-mode))

(use-package eldoc
  :delight "🖹")

(use-package elfeed
  ;; Binding mnemonic: “Read Rss” (should use similar for “Read Mail” and “Read
  ;; News”)
  :bind ("C-c C-r r" . elfeed))

(use-package elfeed-goodies
  :after elfeed
  :init (elfeed-goodies/setup))

(use-package elfeed-org
  :after elfeed
  :init (elfeed-org))

(use-package elisp-mode
  :bind (:map emacs-lisp-mode-map ("C-M-l" . emacs-lisp-byte-compile-and-load)))

(use-package em-term ; eshell
  :bind
  (:map eshell-cmpl-mode
        ([remap completion-at-point] . helm-esh-pcomplete))
  (:map eshell-hist-mode
        ([remap eshell-list-history] . helm-eshell-history)
        ([remap eshell-previous-matching-input] . helm-eshell-history)
        ([remap eshell-previous-matching-input-from-input]
         . helm-eshell-history))
  :config
  (add-to-list 'eshell-visual-commands "rmux")
  (require-config 'eshell-init)
  :custom
  (eshell-cmpl-autolist t)
  (eshell-cmpl-cycle-completions nil)
  (eshell-cmpl-ignore-case t)
  (eshell-hist-ignoredups 'erase)
  (eshell-ls-exclude-hidden nil)
  (eshell-ls-initial-args '("-A" "-h"))
  :hook
  (eshell-alias-load . eshell-load-bash-aliases)
  (eshell-mode . (lambda () (setenv "TERM" "emacs"))))

(use-package emacs
  :after bradix
  :config
  (put 'downcase-region 'disabled nil)
  (put 'upcase-region 'disabled nil)
  :custom
  (debug-on-error t)
  (default-frame-alist '((height . 82) (width . 196)))
  (enable-recursive-minibuffers t)
  (fill-column 80)
  (gc-cons-threshold (* 100 Mi) "Bumped to 100 MiB based on C++ LSP tutorial")
  (history-delete-duplicates t)
  (indent-tabs-mode nil)
  (indicate-buffer-boundaries 'right)
  (load-prefer-newer t)
  (mode-line-format
   '("%e" mode-line-front-space mode-line-mule-info mode-line-client mode-line-modified mode-line-remote mode-line-frame-identification mode-line-buffer-identification
     " " mode-line-position
     (vc-mode vc-mode)
     " " mode-line-modes mode-line-misc-info mode-line-end-spaces))
  (ns-alternate-modifier 'none)
  (ns-function-modifier 'meta)
  (scroll-bar-mode nil)
  (tool-bar-mode nil)
  (visible-bell t))

(use-package ensime
  :bind (:map scala-mode ("C-c b s" . sbt-start)) ; For when Ensime isn’t loaded.
  :hook (scala-mode . ensime-scala-mode-hook))

(use-package face-remap
  :delight (buffer-face-mode "🦬"))

(use-package files
  :custom
  (confirm-kill-emacs 'y-or-n-p)
  (enable-remote-dir-locals t)
  (list-directory-brief-switches "-ACF")
  (list-directory-verbose-switches "-Alh")
  (make-backup-files nil))

(defun sellout--mode-line-status-indicator (prefix status)
  (list prefix `(:propertize ,status face mode-line-state)))

(use-package flycheck
  :custom
  (flycheck-mode-line '(:eval (sellout--flycheck-mode-line-status-text)))
  (flycheck-mode-line-prefix "✓")
  :defines
  flycheck-current-errors
  flycheck-last-status-change
  flycheck-mode-line-prefix
  :functions global-flycheck-mode
  :init (global-flycheck-mode)
  :preface
  ;; Overridden to match my general format for this stuff
  ;; > prefix[err warn info]
  ;; with faces to match.
  ;; TODO: Generalize this
  (defun sellout--flycheck-mode-line-status-text (&optional status)
    "Get a text describing STATUS for use in the mode line.
STATUS defaults to `flycheck-last-status-change' if omitted or nil."
    (let ((text (pcase (or status flycheck-last-status-change)
                  ('not-checked '("   "))
                  ('no-checker '((:propertize " - " face warning)))
                  ('running '(" * "))
                  ('errored '((:propertize " ! " face error)))
                  ('finished
                   (let-alist (flycheck-count-errors flycheck-current-errors)
                     (if (or .error .warning)
                         (list (if .error
                                   `(:propertize ,(number-to-string .error)
                                                 face error)
                                 "0")
                               " "
                               (if .warning
                                   `(:propertize ,(number-to-string .warning)
                                                 face warning)
                                 "0"))
                       '((:propertize " ✓ " face success)))))
                  ('interrupted '((:propertize " . " face warning)))
                  ('suspicious '((:propertize " ? " face warning))))))
      (sellout--mode-line-status-indicator flycheck-mode-line-prefix text))))

(use-package flycheck-eldev
  :custom (flycheck-eldev-unknown-projects 'trust))

(use-package flycheck-vale
  :functions flycheck-vale-setup
  :init (flycheck-vale-setup))

(use-package flyspell
  :custom
  (flyspell-issue-message-flag nil)
  (flyspell-mode-line-string "¶")
  ;; remap to the right mouse button, stolen from
  ;; https://stackoverflow.com/a/10997845/5090651
  :bind
  (:map flyspell-mouse-map
        ([down-mouse-3] . flyspell-correct-word)
        ([mouse-3] . undefined))
  :delight
  (flyspell-mode
   (flyspell-mode-line-string
    ((:propertize flyspell-mode-line-string)
     (:propertize
      (-2 (:eval (or ispell-local-dictionary ispell-dictionary "--")))
      face mode-line-state
      help-echo "mouse-1: Change dictionary"
      local-map (keymap
                 (mode-line keymap
                            (mouse-1 . ispell-change-dictionary)))))))
  :hook
  (prog-mode . flyspell-prog-mode)
  (text-mode . flyspell-mode))

(use-package forge
  :after magit
  :preface
  (defun forge--fake-alpha (rgb alpha &optional underlying-face)
    (let ((underlying-face (or underlying-face 'default)))
      (cl-mapcar (lambda (color background)
                   (+ (* color alpha) (* background (- 1 alpha))))
                 rgb
                 (color-name-to-rgb (face-background underlying-face nil t)))))

  (defun forge--label-face (background-mode label &optional underlying-face)
    "Produce an anonymous face from the provided LABEL."
    (cl-destructuring-bind (label-r label-g label-b) (color-name-to-rgb label)
      (cl-destructuring-bind (label-h label-s label-l)
          (color-rgb-to-hsl label-r label-g label-b)
        (let* ((light-mode (eq background-mode 'light))
               (lightness-threshold (if light-mode 0.453 0.6))
               (perceived-lightness (+ (* label-r 0.2126)
                                       (* label-g 0.7152)
                                       (* label-b 0.0722)))
               (border-threshold 0.96)
               (border-alpha (if light-mode (if (< border-threshold perceived-lightness) 1 0) 0.3))
               (lightness-switch (if (< perceived-lightness lightness-threshold) 1 0))
               ;; TODO: Redefine this in terms of ‘lightness-switch’ once we’re in dark mode again.
               (lighten-by (max 0 (- lightness-threshold perceived-lightness))))
          (list
           :foreground
           (apply #'color-rgb-to-hex
                  (color-hsl-to-rgb label-h
                                    label-s
                                    (if light-mode
                                        lightness-switch
                                      (+ label-l lighten-by))))
           :background
           (if light-mode
               label
             (apply #'color-rgb-to-hex
                    (forge--fake-alpha (list label-r label-g label-b) 0.18 underlying-face)))
           :box
           (list
            :line-width (if (>= emacs-major-version 28) (cons -1 -1) -1)
            :color
            (apply #'color-rgb-to-hex
                   (forge--fake-alpha (color-hsl-to-rgb label-h
                                                        label-s
                                                        (if light-mode
                                                            (- label-l 0.25)
                                                          (+ label-l lighten-by)))
                                      border-alpha
                                      underlying-face))))))))

  (defun forge--insert-topic-labels (topic &optional skip-separator labels)
    (pcase-dolist (`(,name ,color ,description)
                   (or labels (closql--iref topic 'labels)))
      (if skip-separator
          (setq skip-separator nil)
        (insert " "))
      (let ((name (concat " " name " ")))
        (insert name)
        (let ((o (make-overlay (- (point) (length name)) (point))))
          (overlay-put o 'priority 2)
          (overlay-put o 'evaporate t)
          (overlay-put o 'font-lock-face
                       `(forge-topic-label
                         ',(forge--label-face frame-background-mode
                                              (forge--sanitize-color color))))
          (when description
            (overlay-put o 'help-echo description))))))

  :bind
  (:map magit-mode-map ("C-c v" . forge-copy-url-at-point-as-kill)))

(use-package frame
  :after bradix
  :custom
  (blink-cursor-blinks 0)
  (blink-cursor-delay dozenal-blink-rate)
  (blink-cursor-interval dozenal-blink-rate))

(use-package flymake
  :custom (flymake-mode-line-lighter "🛠️"))

(use-package git-commit
  :custom
  (git-commit-major-mode 'markdown-mode)
  (git-commit-summary-max-length 50)
  :hook
  (git-commit-setup . git-commit-save-message)
  (git-commit-setup . git-commit-setup-changelog-support)
  (git-commit-setup . git-commit-turn-on-auto-fill)
  (git-commit-setup . git-commit-turn-on-flyspell)
  (git-commit-setup . git-commit-propertize-diff)
  (git-commit-setup . bug-reference-mode)
  (git-commit-setup . with-editor-usage-message))

(use-package gravatar
  :custom (gravatar-rating "x"))

(use-package haskell-mode
  :after paredit
  :config
  ;; Remove once haskell/haskell-mode#1880 is merged.
  (add-hook 'haskell-cabal-mode-hook
            (lambda ()
              (font-lock-add-keywords nil
                                      '(("^[ \t]*\\(--\\)\\(.*\\)"
                                         (1 font-lock-comment-delimiter-face)
                                         (2 font-lock-comment-face))))))
  :delight
  '(:eval
    (concat
     (propertize "λ" 'face '(:inverse-video nil :foreground "#5f5189"))
     (propertize "=" 'face '(:inverse-video nil :foreground "#8f4e8b"))))
  :hook
  ;; (haskell-mode . autocomplete-mode)
  (haskell-mode . flymake-mode)
  (haskell-mode . flyspell-prog-mode)
  ;; (haskell-mode . ghc-init)
  (haskell-mode . haskell-indent-mode)
  (haskell-mode . imenu-add-menubar-index)
  (haskell-mode . interactive-haskell-mode)
  (haskell-mode . paredit-mode)
  ;; (haskell-mode . structured-haskell-mode)
  (haskell-mode . subword-mode)
  (haskell-mode . turn-on-eldoc-mode)
  (haskell-mode . turn-on-haskell-indent))

(use-package helm
  :bind
  ([remap execute-extended-command] . helm-M-x)
  ([remap find-file]                . helm-find-files)
  ([remap occur]                    . helm-occur)
  ([remap switch-to-buffer]         . helm-mini)
  :custom
  (helm-completion-style 'emacs)
  (helm-grep-file-path-style 'relative)
  (helm-top-poll-mode t)
  :delight "⎈"
  :init (helm-mode))

(use-package helm-descbinds
  :disabled (not (eq sellout-describe-key-package 'helm-descbinds))
  :init (helm-descbinds-mode))

(use-package helm-ls-git
  :after magit
  ;; TODO: Check that this works. It’s inserting itself into the magit-mode-map,
  ;;       and trampling something.
  :bind ("C-c h b" . helm-browse-project)
  :custom (helm-ls-git-status-command 'magit-status-setup-buffer))

(use-package helm-projectile
  :custom (helm-projectile-truncate-lines t)
  :delight "🚀"
  :init (helm-projectile-on))

(use-package helm-xref
  :demand t)

(use-package help
  :bind ("C-h A" . describe-face))

(use-package highlight-doxygen
  :custom (highlight-doxygen-global-mode t))

(use-package icloud
  :delight "☁️"
  ;; TODO: Would be nice to switch this to check if iCloud is a running service
  ;;       or something like that.
  :disabled (not (eq system-type 'darwin))
  :init (icloud-navigation-mode))

(use-package idris-mode
  :delight
  '(:eval (propertize "🐲" 'face '(:inverse-video nil :foreground "#aa0100"))))

(use-package isearch
  :delight "🔎")

(use-package ispell
  :custom
  (ispell-personal-dictionary
   (xdg-locations-emacs-config-home "ispell/personal.dict")
   "Not set in xdg-locations because the default is nil, not a relative path."))

(use-package keychain-environment
  :init (keychain-refresh-environment))

(use-package ligature
  :config
  ;; Stolen from https://github.com/mickeynp/ligature.el/wiki
  (ligature-set-ligatures t '("ff" "fi" "ffi" "www"))
  (ligature-set-ligatures 'prog-mode
                          '(;; == === ==== => =| =>>=>=|=>==>> ==< =/=//=// =~
                            ;; =:= =!=
                            ("=" (rx (+ (or ">" "<" "|" "/" "~" ":" "!" "="))))
                            ;; ;; ;;;
                            (";" (rx (+ ";")))
                            ;; && &&&
                            ("&" (rx (+ "&")))
                            ;; !! !!! !. !: !!. != !== !~
                            ("!" (rx (+ (or "=" "!" "\." ":" "~"))))
                            ;; ?? ??? ?:  ?=  ?.
                            ("?" (rx (or ":" "=" "\." (+ "?"))))
                            ;; %% %%%
                            ("%" (rx (+ "%")))
                            ;; |> ||> |||> ||||> |] |} || ||| |-> ||-||
                            ;; |->>-||-<<-| |- |== ||=||
                            ;; |==>>==<<==<=>==//==/=!==:===>
                            ("|" (rx (+ (or ">" "<" "|" "/" ":" "!" "}" "\]"
                                            "-" "=" ))))
                            ;; \\ \\\ \/
                            ("\\" (rx (or "/" (+ "\\"))))
                            ;; ++ +++ ++++ +>
                            ("+" (rx (or ">" (+ "+"))))
                            ;; :: ::: :::: :> :< := :// ::=
                            (":" (rx (or ">" "<" "=" "//" ":=" (+ ":"))))
                            ;; // /// //// /\ /* /> /===:===!=//===>>==>==/
                            ("/" (rx (+ (or ">"  "<" "|" "/" "\\" "\*" ":" "!"
                                            "="))))
                            ;; .. ... .... .= .- .? ..= ..<
                            ("\." (rx (or "=" "-" "\?" "\.=" "\.<" (+ "\."))))
                            ;; -- --- ---- -~ -> ->> -| -|->-->>->--<<-|
                            ("-" (rx (+ (or ">" "<" "|" "~" "-"))))
                            ;; *> */ *)  ** *** ****
                            ("*" (rx (or ">" "/" ")" (+ "*"))))
                            ;; www wwww
                            ("w" (rx (+ "w")))
                            ;; <> <!-- <|> <: <~ <~> <~~ <+ <* <$ </  <+> <*>
                            ;; <$> </> <|  <||  <||| <|||| <- <-| <-<<-|-> <->>
                            ;; <<-> <= <=> <<==<<==>=|=>==/==//=!==:=>
                            ;; << <<< <<<<
                            ("<" (rx (+ (or "\+" "\*" "\$" "<" ">" ":" "~"  "!"
                                            "-"  "/" "|" "="))))
                            ;; >: >- >>- >--|-> >>-|-> >= >== >>== >=|=:=>>
                            ;; >> >>> >>>>
                            (">" (rx (+ (or ">" "<" "|" "/" ":" "=" "-"))))
                            ;; #: #= #! #( #? #[ #{ #_ #_( ## ### #####
                            ("#" (rx (or ":" "=" "!" "(" "\?" "\[" "{" "_(" "_"
                                         (+ "#"))))
                            ;; ~~ ~~~ ~=  ~-  ~@ ~> ~~>
                            ("~" (rx (or ">" "=" "-" "@" "~>" (+ "~"))))
                            ;; __ ___ ____ _|_ __|____|_
                            ("_" (rx (+ (or "_" "|"))))
                            ;; Fira code: 0xFF 0x12
                            ("0" (rx (and "x" (+ (in "A-F" "a-f" "0-9")))))
                            ;; Fira code:
                            "Fl"  "Tl"  "fi"  "fj"  "fl"  "ft"
                            ;; The few not covered by the regexps.
                            "{|"  "[|"  "]#"  "(*"  "}#"  "$>"  "^="))
  :custom (global-ligature-mode t))

(use-package LilyPond-mode
  :hook (LilyPond-mode . turn-on-font-lock)
  :mode "\\.ly$")

(use-package lisp-mode
  :custom (emacs-lisp-docstring-fill-column nil))

(use-package locate
  :custom (locate-header-face 'level-1))

;; TODO: This currently requires `project-manager` to be installed. Would be
;;       good to conditionalize this to use `nix fmt --` if `project-manager`
;;       isn’t found.
(defvar project-manager-format-command
  ["project-manager"
   "fmt"
   ;; NB: These arguments are specific to `treefmt`.
   "virtual.nix"
   "--stdin"]
  "The command to run to format specific files with Project Manager. This
intentionally uses a bare command name so that it picks up the Project Manager
in the project environment it’s being run from.")

(use-package eglot
  :config
  ;; Stolen from
  ;; https://jeffkreeftmeijer.com/emacs-configuration/#outline-container-automatically-format-files-on-save-in-eglot-enabled-buffers
  (defun maybe-eglot-format-buffer ()
    (when (bound-and-true-p eglot-managed-p)
      (eglot-format-buffer)))

  (mapc (lambda (server) (add-to-list 'eglot-server-programs server))
        '((nix-mode "nil"
                    :initializationOptions
                    (:formatting (:command ,project-manager-format-command)))
          (rust-mode "rust-analyzer"
                     :initializationOptions ( :cargo (:buildScripts (:enable t))
                                              :procMacro (:enable t)))
          ((unison-ts-mode unisonlang-mode) "127.0.0.1" 5757)))
  :custom
  (eglot-autoshutdown t)
  (eglot-menu-string "↹")
  :disabled (not (eq sellout-lsp-package 'eglot))
  :hook
  (after-save . maybe-eglot-format-buffer)
  ((nix-mode haskell-mode rust-mode rustic-mode unison-ts-mode unisonlang-mode)
   . eglot-ensure))

(use-package lsp-bash
  :config
  (add-to-list 'lsp-language-id-configuration '(bats-mode . "shellscript"))
  (add-to-list 'lsp-language-id-configuration
               '(envrc-file-mode . "shellscript"))
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection #'lsp-bash--bash-ls-server-command)
    :priority -1
    :major-modes '(bats-mode direnv-envrc-mode envrc-file-mode)
    :environment-fn
    (lambda ()
      '(("EXPLAINSHELL_ENDPOINT" . lsp-bash-explainshell-endpoint)
        ("HIGHLIGHT_PARSING_ERRORS" . lsp-bash-highlight-parsing-errors)
        ("GLOB_PATTERN" . lsp-bash-glob-pattern)))
    :server-id 'bash-like-ls
    :download-server-fn
    (lambda (_client callback error-callback _update?)
      (lsp-package-ensure 'bash-language-server callback error-callback))))
  :custom (lsp-bash-highlight-parsing-errors t)
  :disabled (not (eq sellout-lsp-package 'lsp-mode)))

(use-package lsp-haskell
  :config
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-tramp-connection #'lsp-haskell--server-command)
    :remote? t
    :major-modes '(haskell-mode haskell-literate-mode)
    :ignore-messages nil
    :server-id 'hls-remote))
  :disabled (not (eq sellout-lsp-package 'lsp-mode)))

(use-package lsp-mode
  :config
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-tramp-connection "clangd")
    :remote? t
    :major-modes '(c-mode c++-mode)
    :ignore-messages nil
    :server-id 'clangd-remote))
  :custom
  (lsp-eldoc-render-all t)
  (lsp-headerline-breadcrumb-enable t)
  (lsp-headerline-breadcrumb-segments '(project symbols))
  (lsp-keymap-prefix "s-g")
  :hook
  ((c-mode c++-mode haskell-mode haskell-literate-mode python-mode sh-mode)
   . lsp-deferred)
  (lsp-mode . lsp-enable-which-key-integration)
  :disabled (not (eq sellout-lsp-package 'lsp-mode)))

(use-package lsp-nix
  :after nix-mode
  :config
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-tramp-connection (lambda () lsp-nix-nil-server-path))
    :remote? t
    :major-modes '(nix-mode)
    :ignore-messages nil
    :server-id 'nil-remote))
  :custom
  (lsp-nix-nil-formatter project-manager-format-command)
  :disabled (not (eq sellout-lsp-package 'lsp-mode))
  :hook (nix-mode . lsp-deferred))

(use-package lsp-rust
  :config
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-tramp-connection "rust-analyzer")
    :remote? t
    :major-modes '(rust-mode rustic-mode)
    :initialization-options 'lsp-rust-analyzer--make-init-options
    :notification-handlers (ht<-alist lsp-rust-notification-handlers)
    :action-handlers (ht ("rust-analyzer.runSingle" #'lsp-rust--analyzer-run-single))
    :library-folders-fn (lambda (_workspace) lsp-rust-analyzer-library-directories)
    :after-open-fn (lambda ()
                     (when lsp-rust-analyzer-server-display-inlay-hints
                       (lsp-rust-analyzer-inlay-hints-mode)))
    :ignore-messages nil
    :server-id 'rust-analyzer-remote))
  ;; recommended setting for lsp-rust, 4k by default, this is 1M.
  (setq read-process-output-max (* 1024 1024))
  :custom
  (lsp-rust-analyzer-cargo-watch-command
   "clippy"
   "TODO: Determine if this is meant to be a subcommand (in which case, update this comment and send doc patch upstream), or if it’s meant to be a path to a command (in which case, move to emacs.nix).")
  (lsp-rust-analyzer-display-chaining-hints t)
  (lsp-rust-analyzer-display-closure-return-type-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names t)
  (lsp-rust-analyzer-display-parameter-hints t)
  (lsp-rust-analyzer-display-reborrow-hints t)
  (lsp-rust-analyzer-server-display-inlay-hints t)
  :disabled (not (eq sellout-lsp-package 'lsp-mode)))

(use-package lsp-ui
  :after lsp-mode
  :custom
  (lsp-ui-doc-delay 1)
  (lsp-ui-doc-enable t)
  (lsp-ui-doc-use-webkit nil)
  (lsp-ui-peek-always-show t)
  (lsp-ui-sideline-enable nil)
  (lsp-ui-sideline-show-hover t)
  ;; TODO: I think this is getting in the way of a lot of stuff, but I don’t
  ;;       have a specific failure. Just disable it until I can spend some time.
  :disabled t ; (not (eq sellout-lsp-package 'lsp-mode))
  :hook (lsp-mode . lsp-ui-mode))

;; TODO: Replace this with a ‘vc-magit’ package to have ‘vc’ pass calls through
;;       to ‘magit’ instead of ‘vc-git’.
(defun vc-or-magit-annotate (vc-annotate file &rest args)
  "Replace VC-ANNOTATE with ‘magit-blame’ when FILE is managed by Git.
FIXME: ARGS is currently ignored when ‘magit-blame’ is used."
  (if (eq (vc-responsible-backend file) 'Git)
      (magit-blame)
    (apply orig-fn file args)))

(use-package magit
  :bind-keymap ("C-c g" . magit-mode-map)
  :config
  (advice-add 'vc-or-magit-annotate :around #'vc-annotate)
  (transient-append-suffix
    'magit-commit
    "-C"
    '("-c"
      "Reedit commit message"
      "--reedit-message="
      magit-read-reuse-message))
  (transient-append-suffix
    'magit-rebase
    "-A"
    '("-x" "Exec command" "--exec=" read-shell-command))
  (transient-insert-suffix
    'magit-stash-push
    "-u"
    '("-S" "Only save staged changes" "--staged"))
  ;; TODO: Have Magit ask for a message regardless of this option.
  (transient-append-suffix
    'magit-stash-push
    "-K"
    '("-m" "Edit the message" "--message="))
  ;; TODO: Remove once there’s some resolution to magit/magit#4861
  (defun magit-insert-revision-gravatar (beg rev email regexp)
    (save-excursion
      (goto-char beg)
      (when (re-search-forward regexp nil t)
        (goto-char (or (match-end 1) (match-end 0)))
        (when-let ((window (get-buffer-window)))
          (let* ((column   (length (or (match-string 1) (match-string 0))))
                 (font-obj (query-font (font-at (point) window)))
                 (size     (* 2 (+ (aref font-obj 4)
                                   (aref font-obj 5))))
                 (align-to (+ column
                              (ceiling (/ size (aref font-obj 7) 1.0))
                              1))
                 (gravatar-size (- size 2)))
            (ignore-errors              ; service may be unreachable
              (gravatar-retrieve email #'magit-insert-revision-gravatar-cb
                                 (list gravatar-size rev
                                       (point-marker)
                                       align-to column))))))))
  :custom
  (magit-blame-mode-lighter "🫵")
  (magit-delete-by-moving-to-trash
   nil
   nil
   nil
   "This causes large files to really slow things down.")
  (magit-diff-refine-hunk 'all)
  (magit-log-margin '(t age-abbreviated magit-log-margin-width t 18))
  (magit-revision-headers-format
   "Author: %aN <%aE>
              %ai (%ar)
Committer: %cN <%cE>
                     %ci (%cr)
"
   nil
   nil
   "The padding here is specific to my ‘default’ face, Lexica Ultralegible. If that changes, this should as well. Ideally I could use text properties to align all this, but can’t get that to work (presumably because it’s passed to `git`.")
  (magit-revision-show-gravatars
   '("^\\(\\)Author: " . "^\\(\\)Committer: ")
   nil
   nil
   "This relies on my custom changes for Gravatar placement. Update once magit/magit#4861 is resolved.")
  (magit-wip-mode t)
  (magit-wip-mode-lighter "🚧")
  :delight (magit-status-mode "✨"))

(use-package markdown-mode
  :custom
  (markdown-fontify-code-blocks-natively t)
  (markdown-fontify-whole-heading-line t)
  (markdown-italic-underscore t)
  :hook (markdown-mode . visual-line-mode))

(use-package minibuffer
  :custom (completion-styles '(flex basic partial-completion emacs22)))

(use-package multiple-cursors
  :bind
  ("C-c m c" . mc/edit-lines)
  ("C-c m >" . mc/mark-next-like-this)
  ("C-c m <" . mc/mark-previous-like-this)
  ("C-c m *" . mc/mark-all-like-this))

(use-package muse-wiki ; muse
  :config
  (add-to-list 'muse-wiki-interwiki-alist
               '("WardsWiki" . "http://c2.com/cgi/wiki?")))

(use-package org
  :custom
  (org-babel-load-languages '((C . t)
                              (emacs-lisp . t)
                              (haskell . t)
                              (mermaid . t) ; via ob-mermaid
                              (python . t)))
  (org-link-abbrev-alist '(("github" . "https://github.com/"))))

(use-package org-brain
  :after extended-faces
  :config
  ;; This mode draws lines and arrows, so it expects characters to be a common
  ;; width.
  (extended-faces-default-mode-face 'pseudo-column '(org-brain-visualize-mode))
  :custom
  ;; NB: This path is ostensibly local, but I’m consistent enough with where
  ;;     repos live, that it should be accurate.
  (org-brain-path "~/Projects/personal/brain")
  :custom-face
  ;; FIXME: Upstream has a bug in these faces, where there is an extra quote in
  ;;        the inheritance field, which at least confuses the Customize
  ;;        interface.
  (org-brain-title ((t (:inherit org-level-1))))
  ;; NB: I also added `pseudo-column' to this face’s inheritance, to make it
  ;;     render better, but I probably have to use `buffer-face-set' for that.
  (org-brain-wires ((t ( :inherit (pseudo-column font-lock-comment-face)
                         :slant normal)))))

(use-package org-clock
  :custom
  (org-clock-clocked-in-display 'frame-title)
  (org-clock-persist t)
  (org-clock-persist-query-save t)
  :init (org-clock-persistence-insinuate))

(use-package org-duration
  :custom (org-duration-format 'h:mm))

(use-package org-mode
  :bind
  ;; mnemonic: Org
  ("C-c o a" . org-agenda)
  ("C-c o c" . org-capture)
  ("C-c o l" . org-store-link)
  ;; mnemonic: Org Task
  ("C-c o t i" . (lambda () (interactive) (org-clock-in-last 1)))
  ("C-c o t o" . org-clock-out)
  :config (add-to-list 'org-export-backends 'md)
  :custom (org-preview-latex-default-process 'imagemagick))

(use-package ormolu
  :after haskell-mode
  :bind (:map haskell-mode-map ("C-c r" . ormolu-format-buffer))
  :defines haskell-mode-map
  :hook (haskell-mode . ormolu-format-on-save-mode))

(use-package ox-latex
  ;; Much richer than `pdflatex`.
  :custom (org-latex-compiler "xelatex"))

;; In general, prefer installation via Nix. However, we can manually install
;; temporarily in order to test things out before deciding to commit. The cycle
;; is much faster this way.
(use-package package
  :config
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/")))

(use-package paredit
  :bind
  (:map paredit-mode-map
        ([remap backward-kill-word] . paredit-backward-kill-word)
        ([remap newline] . paredit-newline))
  :hook
  ((emacs-lisp-mode ielm-mode lisp-data-mode lisp-interaction-mode lisp-mode)
   . paredit-mode)
  :delight "()")

(use-package paredit-everywhere
  :bind
  (:map paredit-everywhere-mode-map
        ([remap kill-line] . paredit-kill))
  :delight "{}")

(use-package paren
  ;; Don’t want to highlight parens that I can’t edit, so ‘special-mode-hook’
  ;; should hopefully cover most of those cases. If it gets too complicated, try
  ;; disabling it globally then enabling for ‘prog-mode’, etc.
  :hook (special-mode . (lambda () (show-paren-local-mode -1))))

(use-package perspective
  :config
  ;; See nex3/perspective-el#192
  (defun sellout-persp-frame-title ()
    (let ((open (nth 0 persp-modestring-dividers))
          (close (nth 1 persp-modestring-dividers)))
      (concat open (persp-current-name) close)))
  (setq frame-title-format '((:eval (sellout-persp-frame-title)) " %b"))
  :custom
  (persp-mode-prefix-key "C-c x")
  (persp-modestring-short t)
  ;; NB: Make this non-nil if we get “No such live buffer” errors. See
  ;;     nex3/perspective-el#179. If we do run into it again, try loading
  ;;     this package _after_ helm.
  :disabled nil
  :init (persp-mode))

(use-package persp-projectile
  :bind ([remap projectile-switch-project] . projectile-persp-switch-project))

;; GunPG pinentry support
(use-package pinentry
  :init (pinentry-start))

(use-package push-pop-done
  :bind-keymap ("C-c P" . ppd-mode-map))

(use-package projectile
  :bind-keymap ("C-c p" . projectile-command-map)
  :config
  (require-config 'sellout-projectile)
  (add-to-list 'projectile-project-root-files-bottom-up ".floo") ; for floobits
  :custom
  (projectile-ignored-project-function
   '(lambda (path) (string-prefix-p "/nix/store" path)))
  (projectile-mode t nil (projectile))
  (projectile-mode-line-prefix "🚀")
  (projectile-per-project-compilation-buffer t)
  (projectile-project-name-function
   (lambda (project-root)
     (intercalate (-take-last 2 (file-name-split (directory-file-name project-root)))  "/")))
  ;; Open Magit or ‘vc-dir’ by default when switching projects.
  (projectile-switch-project-action 'projectile-vc)
  (projectile-use-git-grep t)
  ;; TODO: This should be set by ‘projectile-mode-line-prefix’, but sometimes
  ;; it’s not, so this handles that case. However, this might trample
  ;; ‘projectile-mode-line-function’, which is not good.
  ;; :delight "🚀"
  :init (projectile-mode +1))

(use-package python-mode
  :delight "🐍"
  :hook
  (python-mode . dap-mode)
  (python-mode . dap-ui-mode))

(use-package reveal-in-osx-finder
  :bind ("C-c z" . reveal-in-osx-finder))

(use-package rustic
  ;; TODO: Rework these bindings to follow the conventions.
  :bind
  (:map rustic-mode-map
        ("M-j" . lsp-ui-imenu)
        ("M-?" . lsp-find-references)
        ("C-c C-c l" . flycheck-list-errors)
        ("C-c C-c a" . lsp-execute-code-action)
        ("C-c C-c r" . lsp-rename)
        ("C-c C-c q" . lsp-workspace-restart)
        ("C-c C-c Q" . lsp-workspace-shutdown)
        ("C-c C-c s" . lsp-rust-analyzer-status))
  :custom
  (rustic-format-trigger 'on-save)
  (rustic-lsp-client sellout-lsp-package)
  :defines rustic-mode-map
  :delight "🦀")

(use-package scala-mode2
  ;; TODO: Why explicitly defer? Does it take too long to load? Should it
  ;;       actually be Ensime that’s deferred?
  :defer t
  :delight
  '(:eval (propertize "≋" 'face '(:inverse-video nil :foreground "#bd1902"))))

(use-package simple
  :custom
  (column-number-mode t)
  (mail-user-agent 'wl-user-agent))

(use-package slime
  :after paredit
  :bind
  (:map slime-repl-mode-map
        ;; Make sure we can still send forms even though they're always balanced
        ("C-RET" . slime-repl-return))
  :config
  ;; Stop SLIME's REPL from grabbing DEL,
  ;; which is annoying when backspacing over a '('
  (define-key slime-repl-mode-map
              (read-kbd-macro paredit-backward-delete-key) nil)
  :hook (slime-repl-mode . paredit-mode))

(use-package theme-kit
  :bind-keymap ("C-c t" . theme-kit-keymap))

(use-package text-mode
  :hook (text-mode . visual-line-mode))

(use-package tramp
  :config
  ;; Use a login shell on remote machines to pull in correct environment.
  ;; See Info node ‘(tramp)Remote programs’
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

(use-package transient
  :custom
  (transient-mode-line-format
   '("%e" mode-line-front-space mode-line-buffer-identification)))

(use-package treemacs
  :custom (treemacs-space-between-root-nodes nil))

(use-package treesit-fold
  :custom (global-treesit-fold-mode t))

(use-package uniquify
  :custom
  (uniquify-buffer-name-style 'post-forward)
  (uniquify-separator "→"))

(use-package unison-ts-mode
  :after markdown-mode
  :config (add-to-list 'markdown-code-lang-modes '("unison" . unison-ts-mode))
  :hook (unison-ts-mode . eglot-ensure))

(use-package vc-pijul
  :init (add-to-list 'vc-handled-backends 'Pijul))

(use-package wakatime-mode
  :delight "⏱"
  :init (wakatime-global-mode))

(use-package which-key
  :custom
  (which-key-lighter "🔑")
  (which-key-preserve-window-configuration t)
  (which-key-unicode-correction 5)
  :disabled (not (eq sellout-describe-key-package 'which-key))
  :init (which-key-mode))

(use-package whitespace
  :custom
  (global-whitespace-mode t)
  (whitespace-action '(auto-cleanup))
  (whitespace-global-modes
   '(not
     diff-mode
     magit-log-mode
     magit-process-mode
     magit-revision-mode
     magit-status-mode
     markdown-mode
     org-mode))
  (whitespace-line-column nil)
  (whitespace-style
   '(face
     trailing
     tabs
     lines-tail
     missing-newline-at-eof
     empty
     indentation::space
     space-after-tab
     space-before-tab
     tab-mark))
  :delight
  (global-whitespace-mode)
  (whitespace-mode "␠"))

(use-package wl
  ;; Binding mnemonic: “Read Mail”
  :bind ("C-c C-r m" . wl)
  :custom
  (elmo-imap4-default-stream-type 'ssl)
  (wl-smtp-authenticate-type "login")
  (wl-smtp-connection-type 'ssl)
  :init
  (define-mail-user-agent
    'wl-user-agent
    'wl-user-agent-compose
    'wl-draft-send
    'wl-draft-kill
    'mail-send-hook))

(use-package yasnippet
  :delight (yas-minor-mode "✂️")
  :init (yas-global-mode))

;; Stolen from (https://oleksandrmanzyuk.wordpress.com/2011/11/05/better-emacs-shell-part-i/)
(defun regexp-alternatives (regexps)
  "Return the alternation of a list of REGEXPS."
  (mapconcat (lambda (regexp)
               (concat "\\(?:" regexp "\\)"))
             regexps "\\|"))

(defvar non-sgr-control-sequence-regexp nil
  "Regexp that matches non-SGR control sequences.")

(setq non-sgr-control-sequence-regexp
      (regexp-alternatives
       '(;; icon name escape sequences
         "\033\\][0-2];.*?\007"
         ;; non-SGR CSI escape sequences
         "\033\\[\\??[0-9;]*[^0-9;m]"
         ;; noop
         "\012\033\\[2K\033\\[1F"
         )))

(defun filter-non-sgr-control-sequences-in-region (begin end)
  (save-excursion
    (goto-char begin)
    (while (re-search-forward
            non-sgr-control-sequence-regexp end t)
      (replace-match ""))))

(defun filter-non-sgr-control-sequences-in-output (ignored)
  (let ((start-marker
         (or comint-last-output-start
             (point-min-marker)))
        (end-marker
         (process-mark
          (get-buffer-process (current-buffer)))))
    (filter-non-sgr-control-sequences-in-region
     start-marker
     end-marker)))

(add-hook 'comint-output-filter-functions
          'filter-non-sgr-control-sequences-in-output)

(defun ediff-regions-in-current-buffer ()
  "Simplifies `ediff-regions-wordwise' a bit when trying to compare two things in the same buffer."
  (interactive)
  (ediff-regions-wordwise (current-buffer) (current-buffer)))

;;; OVER-THE-SHOULDER
;;; TODO: Make this its own repo

;;; Adds a quick toggle between regular editing and over-the-shoulder (pair)
;;; editing
;;; TODO: add a binding or two that only exist within OTS – eg, change keyboard
;;;       layout, disable paredit – stuff to switch when someone else wants to
;;;       use my keyboard

(deftheme over-the-shoulder
  "Theme to use when someone else is trying to understand your Emacs.
E.g., when pair programming, but you’re driving.")

(custom-theme-set-variables
 'over-the-shoulder
 '(debug-on-error nil)
 '(debug-on-quit nil)
 '(display-line-numbers-major-tick 10)
 '(display-line-numbers-minor-tick 5))
 '(global-display-line-numbers-mode t)

(defun toggle-theme (theme)
  (if (custom-theme-enabled-p theme)
      (disable-theme theme)
    (enable-theme theme)))

(defun toggle-ots-settings ()
  "Toggle over-the-shoulder, to make Emacs less jarring to observers."
  (interactive)
  (toggle-theme 'over-the-shoulder))

(defun toggle-partner-edit ()
  "Make it easier for someone else to sit a the keyboard."
  (interactive)
  (toggle-theme 'partner-edit))

;; Prefix mnemonic: “s” for “switch” or “share”
(global-set-key (kbd "C-c s o") 'toggle-ots-settings)
(global-set-key (kbd "C-c s p") 'toggle-partner-edit)

;;; TODO: ORGANIZE

(defun intersperse (list item)
  "Insert ITEM between each element of LIST."
  (if (or (null list) (null (cdr list)))
      list
    (cl-list* (car list) item (intersperse (cdr list) item))))

(defun intercalate (sequences inter-seq)
  "Insert INTER-SEQ between each element of SEQUENCES, then flatten."
  (apply #'concat (intersperse sequences inter-seq)))

(defun delete-file-and-buffer ()
  "Kill the current buffer and deletes the file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (when filename
      (if (vc-backend filename)
          (vc-delete-file filename)
        (progn
          (delete-file filename)
          (message "Deleted file %s" filename)
          (kill-buffer))))))

(defun rename-file-and-buffer ()
  "Rename the current buffer and file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (message "Buffer is not visiting a file!")
      (let ((new-name (read-file-name "New name: " filename)))
        (cond
         ((vc-backend filename) (vc-rename-file filename new-name))
         (t
          (rename-file filename new-name t)
          (set-visited-file-name new-name t t)))))))

(global-set-key (kbd "C-c D") 'delete-file-and-buffer)
(global-set-key (kbd "C-c r") 'rename-file-and-buffer)

;; https://emacs.wordpress.com/2007/01/17/eval-and-replace-anywhere/
(defun eval-and-replace ()
  "Replace the preceding sexp with its value."
  (interactive)
  (backward-kill-sexp)
  (condition-case nil
      (prin1 (eval (read (current-kill 0)))
             (current-buffer))
    (error (message "Invalid expression")
           (insert (current-kill 0)))))
(global-set-key (kbd "C-c e") 'eval-and-replace)

;;; From http://emacsredux.com/blog/2013/06/15/open-line-above/
(defun smart-open-line-above ()
  "Insert an empty line above the current line.
Position the cursor at it's beginning, according to the current mode."
  (interactive)
  (move-beginning-of-line nil)
  (newline-and-indent)
  (forward-line -1)
  (indent-according-to-mode))
(global-set-key [(control shift return)] 'smart-open-line-above)

(defvar copyright-block "Copyright (c) %s %s. All rights reserved.")

(defun insert-copyright-block ()
  "Drop a copyright entry for the current year and user at point."
  (interactive)
  (comment-dwim nil)
  (format copyright-block (format-time-string "%Y") (user-full-name)))

(defvar comment-guide
  "
;;;               1         2         3         4         5         6
;;; 123 .123456789012345678901234567890123456789012345678901234567890123456.
")

(defun insert-comment-guide ()
  "Drop a column counter into the buffer to help with formatting comments."
  (interactive)
  (comment-dwim nil)
  (format comment-guide))

(defun floatbg-hsv-to-rgb-string (h s v)
  "Convert color in H S V values to RGB string."
  (setq h (degrees-to-radians h))
  (let (r g b)
    (if (zerop s)
    (setq r v g v b v)
      (let* ((h (/ (if (>= h (* 2 pi)) 0.0 h)
           (/ pi 3)))
         (i (truncate h))
         (f (- h i)))
    (let ((p (* v (- 1.0 s)))
          (q (* v (- 1.0 (* s f))))
          (z (* v (- 1.0 (* s (- 1.0 f))))))
      (cond ((eq i 0) (setq r v g z b p))
        ((eq i 1) (setq r q g v b p))
        ((eq i 2) (setq r p g v b z))
        ((eq i 3) (setq r p g q b v))
        ((eq i 4) (setq r z g p b v))
        ((eq i 5) (setq r v g p b q))))))
    (format "#%.2X%.2X%.2X" (* r 255) (* g 255) (* b 255))))

(defun seconds-to-beats (seconds)
  (/ seconds 86.4))

(defun time-to-beats (time)
  (float-time time))

(defun beats-since-epoch ()
  (time-to-beats (current-time)))

;;; Swatch Beat time
;;; Internet Time
;; version 3
;; written by Mario Lang
(defun itime-internal (hour minute second offset)
  "Return Internet time as a float.
HOUR MINUTE and SECOND are local time. OFFSET is the offset in seconds."
  (let ((seconds (+ (* 3600 hour)
                    3600
                    (- offset)
                    (* 60 minute)
                    second)))
    (mod (/ seconds 86.4) 1000)))
(cl-assert (= (itime-internal 0 0 0 3600) 0))
(cl-assert (= (round (itime-internal 12 0 1 3600)) 500))
(cl-assert (= (round (itime-internal 23 0 0 3600))
              (round (itime-internal 0 0 0 7200))))

(defun itime-string (hour minute second &optional ticks)
  "Return Internet time formatted as a string.
HOUR MINUTE and SECOND are for `current-time-zone'. If TICKS is non-nil, also
include the decimal points."
  (let ((result (itime-internal (if (stringp hour)
                    (string-to-number hour)
                  hour)
                (if (stringp minute)
                    (string-to-number minute)
                  minute)
                (if (stringp second)
                    (string-to-number second)
                  second)
                (car (current-time-zone)))))
    (if ticks
    (format "@%03d.%02d"
        (floor result)
        (floor (* (- result (floor result)) 100)))
      (format "@%03d" (round result)))))

(defun emacs-uptime ()
  "Display a line containing uptime & allocation information."
  (interactive)
  (let* ((conses cons-cells-consed)
         (seconds (float-time (time-subtract (current-time) before-init-time)))
         (beats (seconds-to-beats seconds)))
    (message "%d conses / %s = %d conses/s (%.1f beats = %d conses/beat)"
             conses
             (format-seconds "%Y, %D, %z%h:%.2m:%.2s" seconds)
             (round (/ conses seconds))
             beats
             (round (/ conses beats)))))

;; From
;; http://emacsredux.com/blog/2013/04/29/start-command-or-switch-to-its-buffer/
(defun start-or-switch-to (function buffer-name)
  "Invoke FUNCTION if there is no buffer with BUFFER-NAME.
Otherwise switch to the buffer named BUFFER-NAME.  Don't clobber
the current buffer."
  (if (not (get-buffer buffer-name))
      (progn
        (split-window-sensibly (selected-window))
        (other-window 1)
        (funcall function))
    (switch-to-buffer-other-window buffer-name)))

;;; EXPERIMENTS

(defun unquify-dispatch-buffer-name-style (style base extra-string)
  (cond
   ((null extra-string) base)
   ((string-equal base "")    ; Happens for dired buffers on the root directory.
    (mapconcat #'identity extra-string "/"))
   ((eq style 'reverse)
    (mapconcat #'identity
               (cons base (nreverse extra-string))
               (or uniquify-separator "\\")))
   ((eq style 'forward)
    (mapconcat #'identity (nconc extra-string (list base)) "/"))
   ((eq style 'post-forward)
    (concat base (or uniquify-separator "|")
            (mapconcat #'identity extra-string "/")))
   ((eq style 'post-forward-angle-brackets)
    (concat base "<" (mapconcat #'identity extra-string "/") ">"))
   ((functionp style)
    (funcall style base extra-string))
   (t (error "Bad value for uniquify-buffer-name-style: %s" style))))

;; TODO: modify `uniquify' for a couple reasons:
;;     - support falling back to other styles (or inheriting parts of other
;;       styles)
;;     - provide both the list of extra strings to distinguish, but also the
;;       components that weren’t necessary to distinguish (for things like
;;       Projectile support)
;;
;; I think we want a signature like
;; `(fallback-style base common-prefix extra-string common-suffix)`
;;
;; The existing styles don’t fall back to anything else. New styles can choose
;; to if they can’t contribute anything. But this still doesn’t quite give us
;; ability to “inherit” some style. And the common parts can be used to
;; determine things like “are these in the same project?” We find the
;; project-root across the full path. If the root is a subset of the common
;; prefix, then everything is in the same project, so we fall-back. If the root
;; extends past that, we have at least some different projects. We need the
;; common-suffix just in case it’s part of the project path, and in that case, I
;; _think_ we might be the only file in that project, so we don’t need any of
;; `extra-string` … maybe?
;;
;; The possibilities:
;; 1. basic buffer name                  – foo.cpp
;; 2. files in same project              – foo.cpp<distingush/path>
;; 3. files in different projects        – foo.cpp[myproject]
;; 4. files in same & different projects - foo.cpp[myproject:distinguish/path]
;;
;; The brackets change because otherwise can’t tell difference between #2 & #3
;; in single-dir-component situations.
;;
;; Are projects guaranteed to have different names? I don’t think so. If they’re
;; in the same dir on different machines, they could probably be the same.
;;
;; This does mean that I tend to have the same info in my mode line like three
;; times:
;;
;; 1. vc
;; 2. projectile
;; 3. buffer name
;;
;; Wonder how to clean this up without losing info
(defun projectile-uniquify-buffer-name (fallback-style base extra-string)
  "Include the project name when duplicate buffers are in distinct projects.
This unfortunately requires `uniquify-strip-common-suffix' to be nil for this to
be very useful."
  (let* ((path (message (mapconcat #'identity extra-string "/")))
         (root (projectile-project-root path)))
    (if root
        (let ((name (projectile-project-name root)))
          (concat base
                  "["
                  name
                  ":"
                  (string-remove-prefix root
                                        (mapconcat #'identity extra-string "/"))
                  "]"))
      (unquify-dispatch-buffer-name-style fallback-style base extra-string))))

;; FIXME: This shouldn’t need to be a separate function – should be able to pass
;;        an expression that evaluates to a function to
;;        `uniquify-buffer-name-style'.
(defun projectile-post-forward-uniquify (base extra-string)
  (projectile-uniquify-buffer-name 'post-forward base extra-string))

;;; END EXPERIMENTS

;; NB: Keep this at the end of the file, per
;;     https://github.com/purcell/envrc/blob/master/README.md#usage
(use-package envrc
  :custom
  (envrc-lighter-function #'sellout--envrc-lighter)
  (envrc-remote t)
  :hook (after-init . envrc-global-mode)
  :preface
  ;; TODO: Customize ‘envrc-lighter-function’ with this once purcell/envrc#86 is
  ;;       merged.
  (defun sellout--envrc-lighter (status)
    "Return a lighter for the provided envrc STATUS."
    `(:propertize "🗁"
                  face
                  ,(pcase status
                     ('error 'envrc-mode-line-error-face)
                     ('on 'envrc-mode-line-on-face)
                     (_ 'envrc-mode-line-none-face)))))

;;; default.el ends here
