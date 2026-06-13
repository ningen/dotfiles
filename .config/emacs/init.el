;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;;; macOS modifiers

(when (eq system-type 'darwin)
  ;; Try the Emacs-native keybinding style first: Command sends Meta.
  (setq mac-command-modifier 'meta)
  (setq mac-option-modifier 'none)
  (setq mac-control-modifier 'control)
  (setq ns-function-modifier 'hyper))

;;; Defaults

(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)
(setq ring-bell-function 'ignore)
(setq use-short-answers t)
(setq make-backup-files nil)
(setq auto-save-default nil)

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; Package Management

(require 'package)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

(package-initialize)

(require 'use-package)
(setq use-package-always-ensure t)

;;; Discoverability

(use-package which-key
  :ensure nil
  :init
  (which-key-mode 1)
  :custom
  (which-key-idle-delay 0.4)
  (which-key-idle-secondary-delay 0.05))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(save-place-mode 1)
(recentf-mode 1)

;;; init.el ends here
