;;
;; Add the buffer "%b - emacs 
;(setq frame-title-format "%b - emacs")
;(multiple-frames "%b" ("" invocation-name "@" system-name))
;
;(setq icon-title-format `(,"%b - (%f) 1emacs: ", (user-login-name) "@" ,(system-name)))
(add-hook 'after-init-hook (lambda ()
			     (setq frame-title-format `(,"%b - (%f) emacs: ", (user-login-name) "@" ,(system-name)))
))

;; Show line-number in the mode line
(line-number-mode 1)
;; Show column-number in the mode line
(column-number-mode 1)

;
; Customize shell mode
;
(setq sh-basic-offset 2)
(setq sh-indentation 2)

;
; Enable display of whitespace
;
(require 'whitespace)
;;(setq whitespace-line-column 80)
(setq whitespace-style '(face trailing lines-tail empty
			      space-before-tab indentation))
(add-hook 'after-change-major-mode-hook 'whitespace-mode)

;
; Backup options
;
(setq
 backup-by-copying t      ; don't clobber symlinks
 backup-directory-alist
 '(("." . "~/.emacs.d/saves"))    ; don't litter my fs tree
 delete-old-versions t
 kept-new-versions 6
 kept-old-versions 2
 version-control t)       ; use versioned backups
