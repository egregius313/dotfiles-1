;; Main options

;; Minimal UI. Load early to hide as soon as possible.
(setq inhibit-startup-screen t)
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(menu-bar-mode -1)
(when (fboundp 'set-scroll-bar-mode)
  (set-scroll-bar-mode 'left)
  (scroll-bar-mode -1)
  (define-key mickey-minor-mode-map (kbd "C-<f6>") 'toggle-scroll-bar))

;; Remember last cursor position.
(require 'saveplace)
(setq save-place-file (concat emacs-cache-folder "saveplace"))
(setq-default save-place-mode t)
;; When the daemon is killed abruptly, places are not saved. Adding this hook
;; allows to save places at a strategic moment.
(add-hook 'before-save-hook 'save-place-kill-emacs-hook)

;; url-cookie
(setq url-cookie-file (concat emacs-cache-folder "url.cookies"))

;; Bookmark file to cache folder.
(setq bookmark-default-file (concat emacs-cache-folder "emacs.bmk"))

;; Recent files.
(setq recentf-save-file (concat emacs-cache-folder "recentf"))

;; Disable autosave features.
(setq auto-save-default nil)
(setq auto-save-list-file-prefix nil)

;; Place backup files in specific directory.
(setq backup-directory-alist
      `((".*" . ,(concat emacs-cache-folder "backups/"))))

;; Other backup options.
; (setq backup-inhibited t) ;; Disable backup files.
; (setq make-backup-files t) ;; Enable backup files.
; (setq version-control t) ;; Enable numbered versioning.

;; Default mode
(setq default-major-mode 'text-mode)

;; Disable suspend key since it is useless on Emacs server.
(global-unset-key (kbd "C-z"))
(global-unset-key (kbd "C-x C-z"))

;; Make questions less annoying.
(defalias 'yes-or-no-p 'y-or-n-p)

;; Allow some protected functions.
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)

;; Print column number in mode line.
(column-number-mode 1)

;; Print buffer size in mode line.
(size-indication-mode 1)

;; Kill whole line including \n.
(setq kill-whole-line t)

;; Alternative scrolling
(define-key mickey-minor-mode-map [next]
  (lambda () (interactive)
    (if (string= major-mode "doc-view-mode")
        (doc-view-next-page)
      (condition-case nil (scroll-up)
        (end-of-buffer (goto-char (point-max)))))))

(define-key mickey-minor-mode-map [prior]
  (lambda () (interactive)
    (if (string= major-mode "doc-view-mode")
        (doc-view-previous-page)
      (condition-case nil (scroll-down)
        (beginning-of-buffer (goto-char (point-min)))))))

(define-key mickey-minor-mode-map (kbd "C-x M-n") (lambda () (interactive) (narrow-to-page 1)))
(define-key mickey-minor-mode-map (kbd "C-x M-p") (lambda () (interactive) (narrow-to-page -1)))

;; Line numbers
(add-hook 'find-file-hook (lambda () (linum-mode 1)))
(define-key mickey-minor-mode-map (kbd "C-<f5>") 'linum-mode)
(add-hook
 'linum-before-numbering-hook
 (lambda () (if (display-graphic-p) (setq linum-format "%d") (setq linum-format "%d "))))

;; Indentation
(setq-default tab-width 2)
(defvaralias 'standard-indent 'tab-width)
(setq-default indent-tabs-mode t)

;; Lisp should not use tabs.
(mapcar
 (lambda (hook)
   (add-hook
    hook
    (lambda ()
      (setq indent-tabs-mode nil))))
 '(lisp-mode-hook emacs-lisp-mode-hook))

(add-hook
 'emacs-lisp-mode-hook
 (lambda ()
   (local-set-key (kbd "M-.") 'find-symbol-at-point)))

(add-hook
 'change-log-mode-hook
 (lambda ()
   (setq tab-width 2)
   (setq left-margin 2)))

;; This needs to be set globally since they are defined as local variable and
;; Emacs does not know how to set an alias on a local variable.
(defvaralias 'c-basic-offset 'tab-width)
(defvaralias 'sh-basic-offset 'tab-width)

;; Line by line scrolling
(setq scroll-step 1)

;; Autofill tweak.
(setq sentence-end-double-space nil)

;; There is no prog-mode-hook on Emacs<24.
(require 'functions) ; for `page-number-mode'
(add-hook
 'prog-mode-hook
 (lambda ()
   (page-number-mode t)))

(define-key mickey-minor-mode-map (kbd "C-<f7>") 'whitespace-mode)
(setq
 whitespace-style
 '(face empty indentation space-after-tab space-before-tab tab-mark trailing))
;; `whitespace-report' will mistakenly always report empty lines at
;; beginning and end of buffer as long as there is at least one empty line.
;; `whitespace-cleanup' works properly however.
;; DONE: Reported at http://debbugs.gnu.org/cgi/bugreport.cgi?bug=23740.
; (setq whitespace-action '(report-on-bogus))

;; WARNING: this can break some configuration files needing whitespaces at the
;; end.
; (require 'functions) ; for `sanitize'
; (add-hook 'before-save-hook 'sanitize)
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Hippie expand.
;; (define-key mickey-minor-mode-map (kbd "M-/") 'hippie-expand)

;; Abbreviation support
(setq-default abbrev-mode t)

;; Set Fill Column
(setq-default fill-column 80)
(add-hook 'text-mode-hook 'turn-on-auto-fill)

;; Set man pages to display on a 80 character wide window.
(setenv "MANWIDTH" "80")

;; Enforce horizontal splitting. 140 means that the window is large enough to
;; hold 2 other windows of 70 columns.
(setq split-height-threshold nil)
(setq split-width-threshold 140)

;; Windmove mode: easy window switching with Shift+arrows.
(when (fboundp 'windmove-default-keybindings)
  (define-key mickey-minor-mode-map (kbd "M-s-h") 'windmove-left)
  (define-key mickey-minor-mode-map (kbd "M-s-j") 'windmove-down)
  (define-key mickey-minor-mode-map (kbd "M-s-k") 'windmove-up)
  (define-key mickey-minor-mode-map (kbd "M-s-l") 'windmove-right))

;; Make Emacs use environment browser, or w3m if BROWSER is not set.
(setq browse-url-generic-program
      (executable-find
       (let ((b (getenv "BROWSER")))
         (if b b "w3m" )))
      browse-url-browser-function 'browse-url-generic)

;; Default ispell dictionnay. If not set, Emacs uses the current locale.
(setq ispell-dictionary "english")
(define-key mickey-minor-mode-map
  (kbd "<f5>")
  (lambda () (interactive) (ispell-change-dictionary "english")))
(define-key mickey-minor-mode-map
  (kbd "<f6>")
  (lambda () (interactive) (ispell-change-dictionary "francais")))
(define-key mickey-minor-mode-map
  (kbd "<f7>")
  (lambda () (interactive) (ispell-change-dictionary "svenska")))

;; Long paragraphs. Useful for quick navigation with backward-paragraph and
;; forward-paragraph.
(setq paragraph-start "
")

;; Show matching parenthesis
(show-paren-mode 1)
;; By default, there’s a small delay before showing a matching parenthesis. Set
;; it to 0 to deactivate.
(setq show-paren-delay 0)
(setq show-paren-when-point-inside-paren t)

;; query-replace-regex fix on terminals.
(if (not (fboundp 'tool-bar-mode)) (define-key mickey-minor-mode-map (kbd "C-M-y") 'query-replace-regexp))

;; Electric Pairs to auto-complete () [] {} "" etc. You can use it on regions.
;; (if (>= emacs-major-version 24)
;;     (electric-pair-mode 1))

;; Run ranger asynchronously.
(define-key mickey-minor-mode-map (kbd "C-x D")
  (lambda () (interactive)
    (let ((term (getenv "TERMCMD")))
      (when (and (executable-find "ranger") (executable-find term))
        (start-process "dummy" nil term "-e" "ranger")))))

;; Run terminal asynchronously in current `default-directory'.
;; This requires SHELL_CD to be used in the shell config.
(define-key mickey-minor-mode-map (kbd "C-x M-RET")
  (lambda () (interactive)
    (let ((term (getenv "TERMCMD")))
      (when (executable-find term)
        (start-process "dummy" nil "env" (concat "SHELL_CD=" default-directory) term)))))

;; Calendar ISO display.
(setq calendar-week-start-day 1)
(setq calendar-date-style 'iso)

;; Quick buffer switching.
(define-key mickey-minor-mode-map (kbd "C-<prior>") 'previous-buffer)
(define-key mickey-minor-mode-map (kbd "C-<next>") 'next-buffer)

;; Remove auto-fill in web edits because wikis and forums do not like it.
;; This works for qutebrowser, but may need changes for other browsers.
(add-hook
 'find-file-hook
 (lambda ()
   (if (string-match (concat (getenv "BROWSER") "-editor-*") (buffer-name))
       (auto-fill-mode -1))))

;; Compilation bindings and conveniences.
(require 'functions) ; for `compile-custom'
(setq compilation-ask-about-save nil)
(autoload 'recompile "compile" nil t)
(define-key mickey-minor-mode-map (kbd "<f10>") 'compile-custom)
(define-key mickey-minor-mode-map (kbd "<f11>") 'previous-error)
(define-key mickey-minor-mode-map (kbd "<f12>") 'next-error)

;; Code browsing: make C-M-e jump to next function instead of the end of the current function.
(define-key mickey-minor-mode-map (kbd "C-M-e") (lambda () (interactive) (beginning-of-defun -1)))

;; Common LISP
(setq inferior-lisp-program "clisp")

(defadvice desktop-owner (after pry-from-cold-dead-hands activate)
  "Don't allow dead emacsen to own the desktop file."
  (when (not (emacs-process-p ad-return-value))
    (setq ad-return-value nil)))

;; Let Emacs auto-load/save sessions.
(when (getenv "EMACS_SERVER")
  (desktop-save-mode 1)
  (setq history-length 250)
  (setq desktop-dirname (concat emacs-cache-folder "desktop"))
  (unless (file-directory-p desktop-dirname)
    (make-directory desktop-dirname t))
  (setq desktop-path `(,desktop-dirname))
  (add-to-list 'desktop-locals-to-save 'compile-command))

;; GMP documentation
(eval-after-load "info-look"
  '(let ((mode-value (assoc 'c-mode (assoc 'symbol info-lookup-alist))))
     (setcar (nthcdr 3 mode-value)
             (cons '("(gmp)Function Index" nil "^ -.* " "\\>")
                   (nth 3 mode-value)))))

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

;; Skeleton settings
(require 'functions)
;; Do not expand abbrevs in skeletons.
(setq-default skeleton-further-elements '((abbrev-mode nil)))
(add-hook 'skeleton-end-hook 'skeleton-make-markers)
(define-key mickey-minor-mode-map (kbd "C->") 'skeleton-next-position)
(define-key mickey-minor-mode-map (kbd "C-<") (lambda () (interactive) (skeleton-next-position t)))

;; Alternate focus.
(add-hook 'occur-hook (lambda () (pop-to-buffer occur-buf)))
;; (add-hook 'help-mode-hook (lambda () (pop-to-buffer (get-buffer "*Help*"))))
(add-hook 'grep-mode-hook (lambda () (pop-to-buffer (get-buffer "*grep*"))))

;; Disable prompt (but leave warning) on git symlink.
(setq vc-follow-symlinks t)

;; Clipboard and primary selection.
(setq x-select-enable-clipboard t)
(setq x-select-enable-primary t)

;; Bibtex
(setq bibtex-entry-format '(opts-or-alts required-fields numerical-fields whitespace realign last-comma delimiters braces sort-fields))
(setq bibtex-field-delimiters 'double-quotes)
(add-hook
 'bibtex-mode-hook
 (lambda ()
   (setq indent-tabs-mode nil)))

;; Git commit meessages.
(add-to-list 'auto-mode-alist '("COMMIT_EDITMSG\\'" . conf-mode))

;; Mutt support.
(add-to-list 'auto-mode-alist '("/tmp/mutt.*" . mail-mode))

;; Arch Linux PKGBUILD.
(add-to-list 'auto-mode-alist '("PKGBUILD" . sh-mode))

;; Shell extensions. We do not put 'sh' only because it could get messy. Emacs
;; knows it anyway.
(add-to-list 'auto-mode-alist '("\\(bash\\'\\|zsh\\'\\|csh\\'\\|tcsh\\'\\|ksh\\'\\)" . sh-mode))
(add-to-list 'auto-mode-alist '("rc\\'" . sh-mode))

;; Subtitles support.
(add-to-list 'auto-mode-alist '("\\.srt\\'" . text-mode))

;; Read Matlab files in Octave mode.
(add-to-list 'auto-mode-alist '("\\.m\\'" . octave-mode))

;; Easy code folding toggle.
; (add-hook 'prog-mode-hook 'hs-minor-mode)
; (add-hook 'prog-mode-hook (lambda () (local-set-key (kbd "C-c h") 'hs-toggle-hiding)))

;; Move mouse away.
; (mouse-avoidance-mode 'banish)

;; Display defun in mode line.
(which-function-mode)

;; Replace maximized binding for fullscreen.
(define-key mickey-minor-mode-map (kbd "M-<f10>") 'toggle-frame-fullscreen)

;; Scroll zooming.
(define-key mickey-minor-mode-map (kbd "C-<wheel-down>") 'text-scale-decrease)
(define-key mickey-minor-mode-map (kbd "C-<mouse-5>") 'text-scale-decrease)
(define-key mickey-minor-mode-map (kbd "C-<wheel-up>") 'text-scale-increase)
(define-key mickey-minor-mode-map (kbd "C-<mouse-4>") 'text-scale-increase)
(setq text-scale-mode-step 1.1)

;; Sort
(setq sort-fold-case t)

;; Replace not-so-useful comment-dwim binding.
(define-key mickey-minor-mode-map "\M-;" 'comment-line)

; In case you find eldoc too distracting.
;; (global-eldoc-mode 0)

;; Replace `kill-buffer' binding by `kill-this-buffer'.
(define-key mickey-minor-mode-map (kbd "C-x k") 'kill-this-buffer)

(provide 'main)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Old code.

;; This may be needed for gud/pdb.
; (defadvice pop-to-buffer (before cancel-other-window first)
;   (ad-set-arg 1 nil))
; (ad-activate 'pop-to-buffer)

;; Use color escape sequences. Only use if needed.
; (add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

;; Flymake has a bug that prevents menu from spawning in a console. We redefine
;; the function to spawn the error message in the mini-buffer.
; (defun flymake-display-err-message-for-current-line ()
;   "Display a message with errors/warnings for current line if it
; has errors and/or warnings."
;   (interactive)
;   (let* ((line-no             (flymake-current-line-no))
;          (line-err-info-list  (nth 0 (flymake-find-err-info flymake-err-info line-no)))
;          (menu-data           (flymake-make-err-menu-data line-no line-err-info-list)))
;     (if menu-data
;         (let ((messages))
;           (push (concat (car menu-data) ":") messages)
;           (dolist (error-or-warning (cadr menu-data))
;             (push (car error-or-warning) messages))
;           (message "%s" (mapconcat #'identity (reverse messages) "\n"))))))
; (define-key mickey-minor-mode-map (kbd "C-<f10>")
;  'flymake-display-err-message-for-current-line)
