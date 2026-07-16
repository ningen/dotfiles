;;; init.el --- Minimal Emacs configuration -*- lexical-binding: t; -*-

(global-display-line-numbers-mode 1)

(use-package doom-themes
  :custom
  (doom-themes-enable-italic t)
  (doom-themes-enable-bold t)
  :custom-face
  (doom-modeline-bar ((t (:background "#6272a4"))))
  :config
  (load-theme 'doom-dracula t)
  (doom-themes-org-config))

;;; init.el ends here
