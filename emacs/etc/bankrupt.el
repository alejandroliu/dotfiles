;; take a look at http://xenon.stanford.edu/~manku/emacs.html
(setq load-path (cons "~/.dotfiles/emacs-lib" load-path))
(setq inhibit-startup-message t)


;;(require 'fill-column-indicator)
;;(setq-default fci-handle-line-move-visual nil)
;;(setq-default fci-rule-column 80)
;;(setq fci-rule-width 3)
;;(setq fci-handle-truncate-lines nil)
;;(add-hook 'after-change-major-mode-hook 'auto-fci-mode)
;;(add-hook 'window-size-change-functions 'auto-fci-mode)

;;(defun auto-fci-mode (&optional unused)
;;  (if (> (frame-width) 80)
;;      (fci-mode 1)
;;    (fci-mode 0))
;;)


;----------------------------------------------------------------------
; DEFT stuff
(require 'deft)
(setq deft-extension "txt")
(setq deft-directory "~/notes/")
(setq deft-text-mode 'markdown-mode)
