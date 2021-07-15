;;
;; Color scheme
;;
(load-theme 'tangotango t) ; A reasonable color scheme which lives in my .emacs.d.
;; Make the dividing line between window splits less bright. It's #EAEAEA in tangotango.
(set-face-attribute 'vertical-border nil :foreground "#888888")

;;
;; Package management
;;
(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
(add-to-list 'package-archives '("melpa-stable" . "http://melpa-stable.melpa.org/packages/"))

;; Cider from MELPA has been too unstable for me. Only use versions from MELPA Stable.
(add-to-list 'package-pinned-packages '(cider . "melpa-stable") t)
(add-to-list 'package-pinned-packages '(clojure-mode . "melpa-stable") t)

(package-initialize)
(when (not package-archive-contents)
  (package-refresh-contents))

(defvar my-packages '(browse-at-remote ; Jump to the Github page for a given line in a git-tracked file.
                      magit ; A mode for committing to git repositories and viewing Git history.
                      org ; For outlining. This is bundled with Emacs, but I'm using the latest version.
                      powerline ; Improve the appearance & density of the Emacs status bar.
                      rainbow-delimiters ; Highlight parentheses in rainbow colors.
                      flycheck ; On-the-fly syntax checker
                      clang-format+ ; Clang format on save for C++
                      auto-complete ; Auto-complete plugin for autocompletion prompts
                      ido ; Interactively DO things
                      recentf ; Find recently opened files
                      yasnippet)) ; Insert snippets using tab.

;; Ensure that every package above is installed. This is helpful when setting up Emacs on a new machine.
(dolist (p my-packages)
  (when (not (package-installed-p p))
    (package-install p)))

;; Enable autopair
(add-to-list 'load-path "~/.emacs.d/plugins/autopair")
(require 'autopair)
(autopair-global-mode) ;; enable autopair in all buffers


;;
;; General settings
;;
(setf gc-cons-threshold 100000000)
(add-to-list 'default-frame-alist '(fullscreen . maximized)) ; start full screen

;; Show line numbers always
(global-display-line-numbers-mode 1)

;; Based on my anecdotal observations, this reduces the amount of display flicker during Emacs startup.
(setq redisplay-dont-pause t)

;; This allows Emacs to occupy the full screen width and height, so that nothing below it (e.g. the desktop)
;; is visible. The default behavior in Emacs is to allow only resizing by whole character-columns and rows.
(setq frame-resize-pixelwise t)

;; set terminal background mode to `dark`
;; Emacs will choose appropriately colors for syntax highlighting based on this
;; Emacs incorrectly guesses the background mode as `light` for Windows Terminal
(setq frame-background-mode 'dark)

;; Turn off graphical toolbars.
(if (display-graphic-p) (menu-bar-mode 1) (menu-bar-mode -1))
(when (and (fboundp 'tool-bar-mode) tool-bar-mode) (tool-bar-mode -1))
(when (and (fboundp 'scroll-bar-mode) scroll-bar-mode) (scroll-bar-mode -1))

;; Reload an open file from disk if it is changed outside of Emacs.
(global-auto-revert-mode 1) 

;; Remove some of Emacs UI
(setq inhibit-startup-screen t) ; stop showing welcome screen
(setq initial-scratch-message "") ; When opening a new buffer, don't show the scratch message.
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message t)
(setq ring-bell-function 'ignore)

(setq mac-option-modifier 'alt)
(setq mac-command-modifier 'meta)

;; Increase the maximum stack depth (the default is 1000).
;; Without this, some of the iterative functions I've written (like
;; project-nav/project-nav/open-file-from-notes-folder) trigger a stack overflow exception.
(setq max-specpdl-size 2000)

;; Turn off backups and autosaves so we don't have ~ and # files strewn about the working directory. I've
;; tried storing backups in my home directory as suggested by http://stackoverflow.com/q/151945/46237, but
;; still I see the occasional backup file in the working directory for some reason.
(setq make-backup-files nil)
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))
(setq auto-save-default nil)

;; Disable Emacs' write-lock, which creates temporary .#files when saving. This crashes coffeescript --watch.
;; https://github.com/jashkenas/coffeescript/issues/985
(setq create-lockfiles nil)

(setq vc-follow-symlinks t) ; Don't ask confirmation to follow symlinks to edit files.

(savehist-mode t) ; Save your minibuffer history across Emacs sessions.

;; Include the path when displaying buffer names which have the same filename open (e.g. a/foo.txt b/foo.txt)
(setq uniquify-buffer-name-style 'forward)

;; Start scrolling the window when the cursor reaches its edge.
;; http://stackoverflow.com/questions/3631220/fix-to-get-smooth-scrolling-in-emacs
(setq scroll-margin 7
      scroll-step 1
      scroll-conservatively 10000
      scroll-preserve-screen-position 1
      ;; Make touchpad scrolling on OSX less jerky
      mouse-wheel-scroll-amount '(0.01))

;; The preference file for Emac's "Customize" system. `M-x customize` to access it.
(setq custom-file (expand-file-name "~/.emacs.d/custom.el"))
(load custom-file t)

(setq-default tab-width 2)

;; Visually wrap long lines on word boundaries. By default, Emacs will wrap mid-word. Note that Evil doesn't
;; have good support for moving between visual lines versus logical lines. Here's the start of a solution:
;; https://lists.ourproject.org/pipermail/implementations-list/2011-December/001430.html
(global-visual-line-mode t)

;; Highlight the line the cursor is on. This is mostly to make it easier to tell which split is active.
(global-hl-line-mode)
;; Don't blink the cursor. I can easily see it, because the line the cursor is on is already highlighted.
(blink-cursor-mode -1)

;; Indent with spaces instead of tabs by default. Modes that really need tabs should enable indent-tabs-mode
;; explicitly. Makefile-mode already does that, for example. If indent-tabs-mode is off, replace tabs with
;; spaces before saving the file.
(setq-default indent-tabs-mode nil)
(add-hook 'write-file-hooks
          (lambda ()
            (if (not indent-tabs-mode)
                (untabify (point-min) (point-max)))
            nil))

;; Save buffers whenever they lose focus.
;; This obviates the need to hit the Save key thousands of times a day. Inspired by http://goo.gl/2z0g5O.
(dolist (f '(windmove-up windmove-right windmove-down windmove-left))
  (advice-add f :before (lambda (&optional args) (util/save-buffer-if-dirty))))

;; When switching focus out of the Emacs app, save the buffer.
(add-hook 'focus-out-hook 'util/save-buffer-if-dirty)

;;
;; Incremental search (isearch)
;;
;; Make highlighting during incremental search feel snappier.
(setq case-fold-search t) ; Make Emac searches case insensitive.
(setq lazy-highlight-initial-delay 0)
(setq lazy-highlight-max-at-a-time nil)
;; Hitting esacpe aborts the search, restoring your cursor to the original position, as it does in Vim.
(define-key isearch-mode-map (kbd "<escape>") 'isearch-abort)


;;
;; Snippets - yassnippet
;;
(require 'yasnippet)
(yas-global-mode 1)
(define-key yas-keymap (kbd "M-v") 'clipboard-yank)
(define-key yas-keymap (kbd "<escape>") (lambda ()
                                          (interactive)
                                          (yas-abort-snippet)
                                          (switch-to-evil-normal-state)))
;; By default, you can't delete selected text using backspace when tabbing through a snippet.
;; Filed as a bug here: https://github.com/capitaomorte/yasnippet/issues/408
(define-key yas-keymap (kbd "C-h") 'yas-skip-and-clear-or-delete-backward-char)
;; (define-key yas-keymap (kbd "backspace") 'yas-skip-and-clear-or-delete-backward-char)

;; This function is based on yas-skip-and-clear-or-delete-char from yassnippet.el.
(defun yas-skip-and-clear-or-delete-backward-char (&optional field)
  "Clears unmodified field if at field start, skips to next tab. Otherwise deletes backward."
  (interactive)
  (let ((field (or field
                   (and yas--active-field-overlay
                        (overlay-buffer yas--active-field-overlay)
                        (overlay-get yas--active-field-overlay 'yas--field)))))
    (cond ((and field
                (not (yas--field-modified-p field))
                (eq (point) (marker-position (yas--field-start field))))
           (yas--skip-and-clear field)
           (yas-next-field 1))
          (t
           (call-interactively 'delete-backward-char)))))


;; Use clang-format+ for all C/C++ projects you edit
(add-hook 'c-mode-common-hook #'clang-format+-mode)

;; Auto-complete Configuration

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages (quote (magit flycheck clang-format+ auto-complete))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(ac-config-default)

;; Theme Configuration
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/") 

;; Enable flycheck syntax checking always
(add-hook 'after-init-hook #'global-flycheck-mode)

;; Change flycheck buffer appearance
(add-to-list 'display-buffer-alist
             `(,(rx bos "*Flycheck errors*" eos)
              (display-buffer-reuse-window
               display-buffer-in-side-window)
              (side            . bottom)
              (reusable-frames . visible)
              (window-height   . 0.33)))

;; Open flycheck buffer automatically when an error is detected
(add-hook 'flycheck-after-syntax-check-hook
          (lambda  ()
            (if flycheck-current-errors
                (flycheck-list-errors)
              (when (get-buffer "*Flycheck errors*")
                (switch-to-buffer "*Flycheck errors*")
                (kill-buffer (current-buffer))
                (delete-window)))))

(require 'recentf)

;; get rid of `find-file-read-only' and replace it with something
;; more useful.
(global-set-key (kbd "C-x C-r") 'ido-recentf-open)

;; enable recent files mode.
(recentf-mode t)

; 50 files ought to be enough.
(setq recentf-max-saved-items 50)

(defun ido-recentf-open ()
  "Use `ido-completing-read' to \\[find-file] a recent file"
  (interactive)
  (if (find-file (ido-completing-read "Find recent file: " recentf-list))
      (message "Opening file...")
    (message "Aborting")))
