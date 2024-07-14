;;; init.el --- Sellout’s Emacs init  -*- lexical-binding: t -*-

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

(defun require-config (feature)
  "Like ‘require’, but first look for FEATURE in ‘user-emacs-directory’."
  (let ((load-path (cons user-emacs-directory load-path)))
    (require feature)))

(require-config 'xdg-locations)

(custom-set-variables
 ;; NB: If this isn’t set in _this_ file, Emacs will ignore it by design.
 '(inhibit-startup-screen t nil () "Explicitly set in `user-init-file`."))

(xdg-locations-custom-paths)

;; FIXME: This is ridiculous. We shouldn’t have to set up the path, but
;;        otherwise it doesn’t have anything useful. We also can’t do it in
;;        default.el currently because something there is trampling it. Should
;;        try moving it up to see where it’s disappearing and fix that issue
;;        (and hopefully not have to explicitly set the PATH at all at some
;;        point …).
(setenv
 "PATH"
 (string-trim-right
  (shell-command-to-string
   "source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh && echo $PATH")))

(eval-when-compile
  ;; See jwiegley/use-package#880
  (autoload #'use-package-autoload-keymap "use-package")
  (require 'use-package))

;; NB: Need these ones first, because use-package uses them in other clauses.
(use-package bind-key)
(use-package delight)

(use-package abbrev
  :delight "…")

(use-package ace-window
  :bind ("C-c a" . ace-window)
  :custom
  (ace-window-display-mode t)
  (aw-char-position 'left)
  (aw-display-mode-overlay nil))

(use-package agenix)

(use-package auto-dark
  :after custom
  :defer nil
  :init (auto-dark-mode))

(use-package autorevert
  :custom (auto-revert-mode-text "↩"))

(use-package bradix
  :config
  ;; TODO: Move these into a separate repo for my dozenal work.
  (defconst 𝜏 (* 2 pi)
    "Tau or “turn” is the right way to calculate rotation.
1𝜏 is a single full rotation.")

  (defconst seconds-in-day (bradix-parse "86 399⠊999 85")
    "Mean seconds per day.
This is needed since Emacs generally wants time values in seconds.")

  (defun days-to-seconds (days)
    "Convert a floating-point number of DAYS to the number of seconds."
    (* (/ days 𝜏) seconds-in-day))

  (defconst dozenal-blink-rate
    (days-to-seconds (* (bradix-parse "0⠌000 02") 𝜏))
    "Blink at a rate of 0⠌000 02𝜏."))

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
  (load custom-file)
  :custom
  (custom-enabled-themes '(bringhurst solarized inheritance))
  (custom-unlispify-remove-prefixes t))

(custom-set-variables
 ;; NB: This can’t be set in a theme, see ‘custom-safe-themes’.
 '(custom-safe-themes t))

(use-package dap-mode
  :commands dap-debug
  :hook
  (dap-stopped . (lambda (arg) (call-interactively #'dap-hydra))))

(use-package dap-python
  :config
  (defun dap-python--pyenv-executable-find (command)
    (with-venv (executable-find "python")))
  :custom (dap-python-debugger 'debugpy))

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

(use-package floobits
  ;; TODO: Recommend a `floobits-prefix-key` ‘defcustom’ upstream.
  :init
  (let ((map (make-sparse-keymap)))
    (global-set-key (kbd "C-c f") map)
    (define-key map "k" 'floobits-clear-highlights)
    (define-key map "t" 'floobits-follow-mode-toggle)
    (define-key map "f" 'floobits-follow-user)
    (define-key map "j" 'floobits-join-workspace)
    (define-key map "l" 'floobits-leave-workspace)
    (define-key map "p" 'floobits-share-dir-public)
    (define-key map "s" 'floobits-summon)))

(defun sellout--mode-line-status-indicator (prefix status)
  (list prefix `(:propertize ,status face mode-line-state)))

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
                                 `(:propertize ,(number-to-string .error) face error)
                               "0")
                             " "
                             (if .warning
                                 `(:propertize ,(number-to-string .warning) face warning)
                               "0"))
                     '((:propertize " ✓ " face success)))))
                ('interrupted '((:propertize " . " face warning)))
                ('suspicious '((:propertize " ? " face warning))))))
    (sellout--mode-line-status-indicator flycheck-mode-line-prefix text)))

(use-package flycheck
  :custom
  (flycheck-mode-line '(:eval (sellout--flycheck-mode-line-status-text)))
  (flycheck-mode-line-prefix "✓")
  :init (global-flycheck-mode))

(use-package flycheck-eldev
  :custom (flycheck-eldev-unknown-projects 'trust))

(use-package flycheck-vale
  :init (flycheck-vale-setup))

(use-package flyspell
  :custom
  (flyspell-issue-message-flag nil)
  (flyspell-mode-line-string "¶")
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
  :bind
  (:map magit-mode-map ("C-c v" . forge-copy-url-at-point-as-kill)))

(use-package frame
  :after bradix
  :custom
  (blink-cursor-blinks 0)
  (blink-cursor-delay dozenal-blink-rate)
  (blink-cursor-interval dozenal-blink-rate))

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
  :custom (helm-descbinds-mode t))

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

(use-package idris-mode
  :delight
  '(:eval (propertize "🐲" 'face '(:inverse-video nil :foreground "#aa0100"))))

(use-package inheritance-theme
  ;; FIXME: Not sure why the ‘autoload’ in this file isn’t working. Maybe have
  ;;        to move it to the primary package file? In any case, this ensures
  ;;        that our theme is available. Once I get the ‘autoload’ working,
  ;;        remove this.
  :demand t)

(use-package interim-faces
  :demand t)

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

(let ((use-eglot t))
  (use-package eglot
    :config
    (add-to-list 'eglot-server-programs
                 '((unison-ts-mode unisonlang-mode) "127.0.0.1" 5757))
    :custom (eglot-menu-string "↹")
    :disabled (not use-eglot))

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
    :disabled use-eglot)

  (use-package lsp-haskell
    :config
    (lsp-register-client
     (make-lsp-client
      :new-connection (lsp-tramp-connection #'lsp-haskell--server-command)
      :remote? t
      :major-modes '(haskell-mode haskell-literate-mode)
      :ignore-messages nil
      :server-id 'hls-remote))
    :disabled use-eglot)

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
    (c-mode . lsp-deferred)
    (c++-mode . lsp-deferred)
    (haskell-mode . lsp-deferred)
    (haskell-literate-mode . lsp-deferred)
    (lsp-mode . lsp-enable-which-key-integration)
    (sh-mode . lsp-deferred)
    :disabled use-eglot)

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
    ;; TODO: This should be the default. See oxalica/nil#70 for why it’s not yet.
    ;;       If formatting is taking too long, switch this to ‘["alejandra"]’.
    (lsp-nix-nil-formatter ["nix" "fmt" "--" "--"])
    :disabled use-eglot
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
    :disabled use-eglot)

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
    :disabled t
    :hook (lsp-mode . lsp-ui-mode)
    :disabled use-eglot))

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
            (ignore-errors                ; service may be unreachable
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
   "The padding here is specific to my ‘default’ face, Atkinson Hyperlegible. If that changes, this should as well. Ideally I could use text properties to align all this, but can’t get that to work (presumably because it’s passed to `git`.")
  (magit-revision-show-gravatars
   '("^\\(\\)Author: " . "^\\(\\)Committer: ")
   nil
   nil
   "This relies on my custom changes for Gravatar placement. Update once magit/magit#4861 is resolved.")
  (magit-wip-mode t)
  (magit-wip-mode-lighter "🚧")
  :delight (magit-status-mode "✨"))

(use-package markdown-mode
  :custom (markdown-italic-underscore t)
  :hook (markdown-mode . visual-line-mode))

(use-package minibuffer
  :custom (completion-styles '(flex basic partial-completion emacs22)))

(use-package multiple-cursors
  :bind
  ("C-c m c" . mc/edit-lines)
  ("C-c m >" . mc/mark-next-like-this)
  ("C-c m <" . mc/mark-previous-like-this)
  ("C-c m *" . mc/mark-all-like-this))

(use-package muse-project ; muse
  :config
  (add-to-list 'muse-project-alist
               '("Society" ("~/Documents/personal/society" :default "index"))))

(use-package muse-wiki ; muse
  :config
  (add-to-list 'muse-wiki-interwiki-alist
               '("WardsWiki" . "http://c2.com/cgi/wiki?")))

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
  ;; See nex3/perspective-el#192
  :config (setq frame-title-format '((:eval (persp-mode-line)) " %b"))
  :custom
  (persp-mode-prefix-key "P")
  (persp-show-modestring t)
  ;; See nex3/perspective-el#179
  ;; :init (persp-mode)
  )

(use-package persp-projectile
  :bind ([remap projectile-swich-project] . projectile-persp-switch-project))

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
  (projectile-ignored-project-function '(lambda (path) (string-prefix-p "/nix/store" path)))
  (projectile-mode t nil (projectile))
  (projectile-mode-line-prefix "🚀")
  (projectile-per-project-compilation-buffer t)
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
  (python-mode . dap-ui-mode)
  (python-mode . lsp))

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

(use-package slack
  :config
  (slack-register-team
   :name "SlamData"
   :default t
   :client-id "7741787362.135511560273"
   :client-secret "741e4bde05f1c72e8abfa64efe07e955"
   :token "xoxp-7741787362-7950594261-136873000262-caf5641f39e0c0acc14a649d62474315"
   :subscribed-channels '(backend backend-team)))

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

(use-package solarized-theme
  ;; FIXME: Not sure why the ‘autoload’ in this file isn’t working. Maybe have
  ;;        to move it to the primary package file? In any case, this ensures
  ;;        that our theme is available. Once I get the ‘autoload’ working,
  ;;        remove this.
  :demand t)

(use-package theme-kit
  :bind-keymap ("C-c t" . theme-kit-keymap))

(use-package text-mode
  :hook (text-mode . visual-line-mode))

;; This is one of two features I need from Emacs 29 (not yet released). The
;; other is correct .dir-locals.el symlink refreshing on localhost. Funny how
;; they’re so similar.
(defun sellout-patch--tramp-handle-file-regular-p (orig-fn filename)
  "Returns true if either ORIG-FN or TRAMP currently doesn’t currently identify symlinks as regular files.
See https://debbugs.gnu.org/cgi/bugreport.cgi?bug=60943 for more information."
  (or (funcall orig-fn filename)
      (tramp-handle-file-symlink-p filename)))

(use-package tramp
  :config
  ;; Use a login shell on remote machines to pull in correct environment.
  ;; See Info node ‘(tramp)Remote programs’
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path)
  (advice-add #'tramp-handle-file-regular-p
              :around
              #'sellout-patch--tramp-handle-file-regular-p))

(use-package transient
  :custom
  (transient-mode-line-format
   '("%e" mode-line-front-space mode-line-buffer-identification)))

(use-package treemacs
  :custom (treemacs-space-between-root-nodes nil))

(use-package uniquify
  :custom
  (uniquify-buffer-name-style 'post-forward)
  (uniquify-separator "→"))

(use-package unison-ts-mode
  :hook (unison-ts-mode . eglot-ensure))

(use-package vc-pijul
  :init (add-to-list 'vc-handled-backends 'Pijul))

(use-package warnings
  :custom
  ;; TODO: There is some incompatibility between emacs-sqlite3 & emacs-forge in
  ;;       nixpkgs 23.05. This should go away either when that’s fixed or with
  ;;       Emacs 29.
  (warning-suppress-log-types '((emacsql)))
  (warning-suppress-types '((emacsql))))

(use-package wakatime-mode
  :delight "⏱"
  :init (wakatime-global-mode))

(use-package which-key
  :custom
  (which-key-lighter "🔑")
  (which-key-mode t)
  (which-key-preserve-window-configuration t)
  (which-key-unicode-correction 5))

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

;;; Stolen from
;;; https://emacs.stackexchange.com/questions/24698/ansi-escape-sequences-in-compilation-mode

;; Stolen from
;; http://endlessparentheses.com/ansi-colors-in-the-compilation-buffer-output.html
(require 'ansi-color)
(defun endless/colorize-compilation ()
  "Colorize from `compilation-filter-start' to `point'."
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region
     compilation-filter-start (point))))

(add-hook 'compilation-filter-hook
          #'endless/colorize-compilation)

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
    (list* (car list) item (intersperse (cdr list) item))))

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

;; NB: Keep these at the end of the file, per
;;     https://github.com/purcell/envrc/blob/master/README.md#usage

;; TODO: I like envrc better than direnv, but it currently doesn’t work over
;;       TRAMP (see purcell/envrc#29). However, direnv seems to cause a lot of
;;       trouble (at least on remote machines), so back to envrc for now.
(let ((use-envrc t))
  (use-package direnv
    :custom
    (direnv-mode t)
    (direnv-non-file-modes
     '(compilation-mode eshell-mode dired-mode magit-mode))
    :defer nil
    :delight "🗁"
    :disabled use-envrc)

  (use-package envrc
    :custom
    (envrc-error-lighter '(:propertize "🗁" face envrc-mode-line-error-face))
    (envrc-none-lighter '(:propertize "🗁" face envrc-mode-line-none-face))
    (envrc-on-lighter '(:propertize "🗁" face envrc-mode-line-on-face))
    (envrc-remote t)
    :defer nil
    :disabled (not use-envrc)
    :init (envrc-global-mode)))

;;; init.el ends here
