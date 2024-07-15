;;; sellout-projectile --- Projectile customizations  -*- lexical-binding: t; -*-

;;; Commentary:

;; This tries to fix a couple issues I have with Projectile.
;; 1. some Projectile commands are really for a file type within a project, not
;;    for a whole project. `sellout-projectile-with-project-type-from-mode`
;;    addresses that and then some keys are rebound for these versions.

;;; Code:

(require 'projectile)

(defmacro sellout-projectile-with-project-type (type thunk)
  "Replace ‘projectile-project-type’ with TYPE around THUNK."
  (declare (indent 1))
  `(let ((projectile-project-type ,type))
     ,thunk))

(defconst sellout-projectile-mode-type
  '((clojure-mode . clojure-cli)
    (emacs-lisp-mode . emacs-cask)
    (go-mode . go)
    (haskell-mode . haskell-cabal)
    (java-mode . maven)
    (python-mode . python-pkg)
    (scala-mode . sbt))
  "A mapping between major modes and Projectile project types.")

(defmacro sellout-projectile-with-project-type-from-mode (thunk)
  "Replace ‘projectile-project-type’ around THUNK.
Uses the project type associated with the current buffer’s mode, as defined in
‘sellout-projectile-mode-type’."
  (declare (indent 0))
  `(sellout-projectile-with-project-type
       (if-let (mode-type (assoc major-mode sellout-projectile-mode-type))
           (cdr mode-type)
         (projectile-project-type))
     ,thunk))

(defun sellout-projectile-find-test-file (&optional invalidate-cache)
  "Like ‘projectile-find-test-file’.
Finds file based on major mode. INVALIDATE-CACHE is same as wrapped function."
  (interactive "P")
  (sellout-projectile-with-project-type-from-mode
    (projectile-find-test-file invalidate-cache)))

(define-key projectile-mode-map
  [remap projectile-find-test-file] 'sellout-projectile-find-test-file)

(defun sellout-projectile-toggle-between-implementation-and-test ()
  "Like ‘projectile-toggle-between-implementation-and-test’.
Finds file based on major mode."
  (interactive)
  (sellout-projectile-with-project-type-from-mode
    (projectile-toggle-between-implementation-and-test)))

(define-key projectile-mode-map
  [remap projectile-toggle-between-implementation-and-test]
  'sellout-projectile-toggle-between-implementation-and-test)

(provide 'sellout-projectile)
;;; sellout-projectile.el ends here
