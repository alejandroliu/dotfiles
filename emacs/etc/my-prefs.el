;;
;; Add the buffer "%b - emacs 
;(setq frame-title-format "%b - emacs")
(setq frame-title-format `(,"%b - (%f) emacs: ", (user-login-name) "@" ,(system-name)))

;
; Customize shell mode
;
(setq sh-basic-offset 2)
(setq sh-indentation 2)


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
