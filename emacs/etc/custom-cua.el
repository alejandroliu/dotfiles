; See: http://www.gnu.org/software/emacs/manual/html_node/emacs/CUA-Bindings.html
(cua-mode t)
(setq cua-auto-tabify-rectangles nil) ;; Don't tabify after rectangle commands
(transient-mark-mode 1) ;; No region when it is not highlighted
(setq cua-keep-region-after-copy t) ;; Standard Windows behaviour

;
; These are my additional CUA like bindings...
;
(global-set-key (kbd "M-<left>") 'beginning-of-line)
(global-set-key (kbd "M-<right>") 'end-of-line)
(global-set-key (kbd "C-<prior>") 'beginning-of-line)
(global-set-key (kbd "C-<next>") 'end-of-line)
(global-set-key (kbd "C-o") 'find-file) ; was C-x C-f
(global-set-key (kbd "C-r") 'recenter-top-bottom) ; was C-l
(global-set-key (kbd "<f5>") 'recenter-top-bottom) ; was C-l
(global-set-key (kbd "C-s") 'save-buffer) ; was C-x C-s
(global-set-key (kbd "S-C-s") 'save-some-buffers) ; was C-x s
(global-set-key (kbd "M-s") 'write-file) ; C-x C-w
(global-set-key (kbd "C-f") 'isearch-forward) ; was C-s
(global-set-key (kbd "S-C-f") 'isearch-backward) ; was C-r
(global-set-key (kbd "C-q") 'save-buffers-kill-emacs) ; was C-x C-c
(global-set-key (kbd "M-<f4>") 'save-buffers-kill-terminal) ; was C-x C-c
(global-set-key (kbd "C-<delete>") 'kill-line) ; was C-k
(global-set-key (kbd "S-C-<delete>") 'kill-word) ; was M-d

; should be kill beginning of line
(defun backward-kill-line (arg)
  "Kill ARG lines backward."
  (interactive "p")
  (kill-line (- 1 arg)))
(global-set-key (kbd "C-<backspace>") 'backward-kill-line)
(global-set-key (kbd "S-C-<backspace>") 'backward-kill-word)
(global-set-key (kbd "M-o") 'open-line) ; was Ctrl-o
(global-set-key (kbd "C-a") 'mark-whole-buffer) ; C-x h

(global-set-key (kbd "C-<insert>") 'quoted-insert) ; was Ctrl-q
(global-set-key (kbd "C--") 'suspend-frame) ; was Ctrl-z
(global-set-key (kbd "C-<") 'kmacro-start-macro) ; C-x (
(global-set-key (kbd "C->") 'kmacro-end-macro) ; C-x )
(global-set-key (kbd "C-?") 'kmacro-end-and-call-macro) ; C-x e
(global-set-key (kbd "S-C-r") 'kmacro-start-macro) ; C-x (
(global-set-key (kbd "S-C-e") 'kmacro-end-or-call-macro) ; C-x ) or C-x e

(global-set-key (kbd "M-g") 'goto-line)

(global-set-key (kbd "C-/") 'cua-exchange-point-and-mark) ; C-x C-x

; Semi Evil mode
(global-set-key (kbd "C-h") 'backward-char)
(global-set-key (kbd "C-j") 'next-line)
(global-set-key (kbd "C-k") 'previous-line)
(global-set-key (kbd "C-l") 'forward-char)

(global-set-key (kbd "C-<tab>") 'other-window) ; was C-x o
; This only seems to work on Windows
(global-set-key (kbd "S-C-<tab>") 'other-window); was C-x o
(global-set-key (kbd "S-C-<insert>") 'insert-file) ; C-x i
(global-set-key (kbd "C-w") 'kill-buffer) ; was C-x k
(global-set-key (kbd "C-`") 'list-buffers) ; C-x C-b
(global-set-key (kbd "S-C-g") 'switch-to-buffer) ; C-x b

(global-set-key (kbd "C-<kp-0>") 'delete-window) ; C-x 0
(global-set-key (kbd "C-<kp-1>") 'delete-other-windows) ; C-x 1
(global-set-key (kbd "C-<kp-2>") 'split-window-below) ; C-x 2
(global-set-key (kbd "C-<kp-3>") 'split-window-right) ; C-x 3


;  Don't know how to implement these...
; should be new file
(global-set-key (kbd "C-n") 'find-file) ; was C-x C-f
;global-set-key (kbd "C-y") 'repeat) ; redo

; standard Emacs bindings
; pgup : scroll-down-command
; pgdn : scroll-up-command
; M-pgup : scroll-other-window-down
; M-pgdn : scroll-other-window-up
; home : move-beginning-of-line
; end : move-end-of-line
; C-home : beginning-of-buffer
; C-end : end-of-buffer
; C-left : left-word
; C-right : right-word
; C-backspace : backward-kill-word
; C-delete : kill-word
; f3 : start-macro
; f4 : stop-macro-or-execute-macro

; CUA bindings
; ctrl+x : cut (if mark set, otherwise, prefix ctrl-x)
; ctrl+c : copy (if mark set, otherwise, prefix ctrl-c)
; ctrl+z : undo
; ctrl+v : paste

;
; Selective display
;
(defun jao-toggle-selective-display ()
  (interactive)
  (set-selective-display (if selective-display nil 1)))
(global-set-key (kbd "<f9>") 'jao-toggle-selective-display) ; folds current code block

;----------------------------------------------------------------------
;;; CUA http://zzyxx.wikidot.com/key-bindings

; f1|ctrl-h k : describe key
; f1|ctrl-h b : describe all key bindings
; f1|chrl-h m : describe bindings by mode

;; http://ergoemacs.org/emacs/keyboard_shortcuts_examples.html
