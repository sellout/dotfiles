;;; eshell-init.el --- Local Eshell config  -*- lexical-binding: t; -*-

(require 'em-alias) ; eshell
(require 'em-prompt) ; eshell

;; Stolen from https://www.emacswiki.org/emacs/EshellAlias#h5o-11
(defun eshell-load-bash-aliases ()
  "Read Bash aliases and add them to the list of eshell aliases."
  ;; Bash needs to be run - temporarily - interactively
  ;; in order to get the list of aliases.
  (with-temp-buffer
    (call-process "bash" nil '(t nil) nil "-ci" "alias")
    (goto-char (point-min))
    (while (re-search-forward "alias \\(.+\\)='\\(.+\\)'$" nil t)
      (eshell/alias (match-string 1) (match-string 2)))))

(defun jump-to-eshell-or-back (arg)
  "Jump to the Eshell buffer, if not already active.
If it doesn't exist, start it and jump to it. If it's already active, jump to
the buffer we were in when we jumped to Eshell last time."
  (interactive "P")
  (let ((sess (if arg (prefix-numeric-value arg))))
    (if (equal (buffer-name) "*eshell*")
        (if eshell-jump-other-buffer
            (set-window-buffer (selected-window)
                               eshell-jump-other-buffer)
          (message "No other buffer to jump to."))
      (setq eshell-jump-other-buffer (current-buffer))
      (eshell sess))))
(global-set-key (kbd "<f5>") 'jump-to-eshell-or-back)
; Start a new Eshell session
(global-set-key (kbd "C-<f5>") (lambda () (interactive) (eshell t)))

;;; a perhaps more general version of the above
;;; (defun switch-or-start (function buffer)
;;;   (if (get-buffer buffer)
;;;       (switch-to-buffer buffer)
;;;     (funcall function)))
;;; (global-set-key (kbd "C-c j")
;;;                 (lambda () (interactive) (switch-or-start 'jabber-connect "*-jabber-*")))
;;; (global-set-key (kbd "C-c g") (lambda () (interactive) (switch-or-start 'gnus "*Group*")))

(defun std-eshell-prompt ()
  "The default value for `eshell-prompt-function'."
  (concat (abbreviate-file-name (eshell/pwd))
          (if (= (user-uid) 0) " # " " $ ")))

;; TODO: This backend stuff should work for the modeline as well – make vc
;;       configurable
(defun vc-eshell-prompt ()
  "Include information about VC status in the Eshell prompt."
  (let* ((dir (eshell/pwd))
         (backend (ignore-errors (vc-responsible-backend dir))))
    (concat (when backend
              (concat (let ((vc-mode-line (vc-call-backend backend 'mode-line-string dir))
                            (state (vc-state dir backend)))
                        (propertize
                         (pcase backend
                           (`Git (concat "" (substring vc-mode-line 4)))
                           (`Pijul (concat "🦅" (substring vc-mode-line 6)))
                           (`SVN (concat "Ⓢ" (substring vc-mode-line 4)))
                           (_ vc-mode-line))
                         'face
                         (cond ((or (eq state 'up-to-date)
                                    (eq state 'needs-update))
                                '(:background "green"))
                               ((stringp state)
                                '(:background "green"))
                               ((eq state 'added)
                                '(:background "orange"))
                               ((eq state 'conflict)
                                '(:background "red"))
                               ((eq state 'removed)
                                '(:background "blue"))
                               ((eq state 'missing)
                                '(:background "purple"))
                               (t '(:background "yellow")))))
                      " "))
            (std-eshell-prompt))))

(defun tyler-eshell-view-file (file)
  "A version of `view-file' which properly respects the eshell prompt."
  (interactive "fView file: ")
  (unless (file-exists-p file) (error "%s does not exist" file))
  (let ((had-a-buf (get-file-buffer file))
        (buffer (find-file-noselect file)))
    (if (eq (with-current-buffer buffer (get major-mode 'mode-class))
            'special)
        (progn
          (switch-to-buffer buffer)
          (message "Not using View mode because the major mode is special"))
      (let ((undo-window (list (window-buffer) (window-start)
                               (+ (window-point)
                                  (length (funcall eshell-prompt-function))))))
        (switch-to-buffer buffer)
        (view-mode-enter (cons (selected-window) (cons nil undo-window))
                         'kill-buffer)))))

(defun eshell/less (&rest args)
  "Invoke `view-file' on a file.
“less +42 foo” will go to line 42 in the buffer for foo."
  (while args
    (if (string-match "\\`\\+\\([0-9]+\\)\\'" (car args))
        (let* ((line (string-to-number (match-string 1 (pop args))))
               (file (pop args)))
          (tyler-eshell-view-file file)
          (goto-line line))
      (tyler-eshell-view-file (pop args)))))

(defalias 'eshell/more 'eshell/less)

(provide 'eshell-init)
;;; eshell-init.el ends here
