;;; config.el -*- lexical-binding: t; -*-

(setq user-full-name "ningen"
      doom-theme 'doom-one
      doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 14)
      org-directory (expand-file-name "~/org"))

(global-unset-key (kbd "C-SPC"))
(global-set-key (kbd "M-SPC") #'set-mark-command)

(setq display-line-numbers-type t)
(setq-default show-trailing-whitespace t)

(after! org
  (setq org-todo-keywords '((sequence "TODO" "DOING" "|" "DONE" "CANCELLED"))
        org-export-backends '(md html)
        org-startup-indented t
        org-hide-leading-stars t
        org-agenda-files (list org-directory)
        org-default-notes-file (expand-file-name "tasks.org" org-directory)
        org-capture-templates
        `(("t" "Task" entry
           (file+headline ,org-default-notes-file "Inbox")
           "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n**調査内容\n\n** メモ\n"))))

(after! org-modern
  (global-org-modern-mode 1))

(custom-set-faces!
  '(org-level-1 :height 1.3)
  '(org-level-2 :height 1.2)
  '(org-level-3 :height 1.1)
  '(org-level-4 :height 1.0))

(after! projectile
  (when (executable-find "ghq")
    (setq projectile-known-projects
          (delete "" (split-string
                      (shell-command-to-string "ghq list --full-path")
                      "\n")))))

(defun org-export-markdown-to-clipboard ()
  "Export the current Org buffer to Markdown and copy it."
  (interactive)
  (kill-new (org-export-as 'md))
  (message "Markdown copied to clipboard"))

(defun markdown-to-org ()
  "Convert the current Markdown buffer to Org using pandoc."
  (interactive)
  (shell-command-on-region (point-min) (point-max)
                           "pandoc -f markdown -t org"
                           (current-buffer) t))
