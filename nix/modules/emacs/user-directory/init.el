;;; init.el --- Marker for ‘user-emacs-directory’  -*- lexical-binding: t -*-

;;; Commentary:

;; This file needs to exist so that Emacs knows what directory to treat as
;; ‘user-emacs-directory’, but the bulk of the configuration is managed via a
;; Nix module.

;; Local (non-Nix-managed) configuration can be set in ./custom.el, using the
;; Customize system, or manually in ./local.el. ./local.el gets ‘require’d, so
;; make sure it ends with (publish 'local). This file doesn’t need to exist if
;; you have no local configuration. It also gets loaded early (but after
;; Nix-dependent setup and ‘use-package’) so that it can affect other things in
;; the Nix-managed config. It can delay various things by using ‘use-package’’s
;; :after.

;;; Code:

(custom-set-variables
 ;; NB: If this isn’t set in _this_ file, Emacs will ignore it by design.
 '(inhibit-startup-screen t nil () "Explicitly set in ‘user-init-file’."))

;;; init.el ends here
