;;; config.el -*- lexical-binding: t; -*-


(setq user-full-name "ningen"
      doom-theme 'doom-one
      doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 14)
      org-directory (expand-file-name "~/org"))

(global-unset-key (kbd "C-SPC"))
(global-set-key (kbd "M-SPC") #'set-mark-command)

(setq display-line-numbers-type t)
(setq-default show-trailing-whitespace t)

(defun ningen/add-exec-path (path)
  "Add PATH to both `exec-path' and the process PATH when it exists."
  (when (file-directory-p path)
    (add-to-list 'exec-path path)
    (setenv "PATH" (concat path path-separator (getenv "PATH")))))

(dolist (path (list (expand-file-name "~/.nix-profile/bin")
                    (expand-file-name "~/.local/state/nix/profiles/profile/bin")
                    (format "/etc/profiles/per-user/%s/bin" user-login-name)
                    "/run/current-system/sw/bin"
                    "/nix/var/nix/profiles/default/bin"))
  (ningen/add-exec-path path))

(defun ningen/add-treesit-extra-load-path (profile)
  "Add PROFILE's lib directory to `treesit-extra-load-path' when it exists."
  (let ((lib (expand-file-name "lib" profile)))
    (when (file-directory-p lib)
      (add-to-list 'treesit-extra-load-path lib))))

(after! treesit
  (dolist (profile (list (expand-file-name "~/.nix-profile")
                         (expand-file-name "~/.local/state/nix/profiles/profile")
                         (format "/etc/profiles/per-user/%s" user-login-name)
                         "/run/current-system/sw"
                         "/nix/var/nix/profiles/default"))
    (ningen/add-treesit-extra-load-path profile)))

(require 'server)
(require 'org-protocol)
(unless (advice-member-p #'org--protocol-detect-protocol-server #'server-visit-files)
  (advice-add #'server-visit-files :around #'org--protocol-detect-protocol-server))
(unless (server-running-p)
  (server-start))

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
           "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n%a\n")
          ("n" "Note" entry
           (file+headline ,(expand-file-name "notes.org" org-directory) "Inbox")
           "* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n%i\n%a\n")
          ("l" "Link" entry
           (file+headline ,(expand-file-name "links.org" org-directory) "Inbox")
           "* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n%a\n%i\n")
          ("w" "Web capture" entry
           (file+headline ,(expand-file-name "links.org" org-directory) "Inbox")
           "* %:description\n:PROPERTIES:\n:CREATED: %U\n:URL: %:link\n:END:\n\n%i\n")
          ("r" "Research" entry
           (file+headline ,(expand-file-name "research.org" org-directory) "Inbox")
           "* %^{Topic}\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n** Question\n%?\n\n** Sources\n- %a\n\n** Notes\n%i\n\n** Next\n- TODO \n"))))

(after! org-modern
  (global-org-modern-mode 1))

(custom-set-faces!
  '(org-level-1 :height 1.3)
  '(org-level-2 :height 1.2)
  '(org-level-3 :height 1.1)
  '(org-level-4 :height 1.0))

(defun ningen/projectile-sync-ghq-projects (&optional quiet)
  "Add projects from `ghq list --full-path' to Projectile."
  (interactive)
  (if-let ((ghq (executable-find "ghq")))
      (let ((added 0))
        (dolist (project (condition-case nil
                             (process-lines ghq "list" "--full-path")
                           (error nil)))
          (when (file-directory-p project)
            (projectile-add-known-project project)
            (setq added (1+ added))))
        (unless quiet
          (message "Added %d ghq projects to Projectile" added)))
    (unless quiet
      (message "ghq not found"))))

(after! projectile
  (ningen/projectile-sync-ghq-projects t))

(require 'web-mode)

(define-derived-mode astro-mode web-mode "Astro"
  "Major mode for Astro files.")

(add-to-list 'auto-mode-alist '("\\.astro\\'" . astro-mode))

(defun ningen/typescript-sdk-path-from-tsserver ()
  "Return the TypeScript SDK path that belongs to `tsserver'."
  (when-let ((tsserver (executable-find "tsserver")))
    (let* ((package-root (file-name-directory
                          (directory-file-name
                           (file-name-directory (file-truename tsserver)))))
           (tsdk (expand-file-name "lib/node_modules/typescript/lib" package-root)))
      (when (file-directory-p tsdk)
        tsdk))))

(after! lsp-mode
  (require 'lsp-astro nil t)
  (add-to-list 'lsp-language-id-configuration '(astro-mode . "astro"))
  (add-hook 'astro-mode-local-vars-hook #'lsp!))

(after! lsp-astro
  (defun lsp-astro--get-initialization-options ()
    "Return TypeScript SDK initialization options for astro-ls."
    (when-let ((tsdk (or (let ((project-tsdk
                                (expand-file-name "node_modules/typescript/lib"
                                                  (lsp-workspace-root))))
                           (when (file-directory-p project-tsdk)
                             project-tsdk))
                         (ningen/typescript-sdk-path-from-tsserver))))
      `(:typescript (:tsdk ,tsdk)))))

(defun ningen/go-format-buffer ()
  "Format Go buffers and organize imports."
  (when (derived-mode-p 'go-mode 'go-ts-mode)
    (if (bound-and-true-p lsp-mode)
        (progn
          (lsp-organize-imports)
          (lsp-format-buffer))
      (when (fboundp 'gofmt)
        (gofmt)))))

(defun ningen/go-mode-setup ()
  "Apply local Go editing defaults."
  (setq tab-width 4
        indent-tabs-mode t)
  (when (boundp 'go-ts-mode-indent-offset)
    (setq-local go-ts-mode-indent-offset 4))
  (add-hook 'before-save-hook #'ningen/go-format-buffer nil t))

(setq gofmt-command "gofumpt")
(dolist (hook '(go-mode-hook go-ts-mode-hook))
  (add-hook hook #'subword-mode)
  (add-hook hook #'ningen/go-mode-setup)
  (add-hook hook #'lsp-deferred))

(after! lsp-mode
  (setq lsp-go-use-gofumpt t
        lsp-go-staticcheck t
        lsp-go-analyses '((fieldalignment . t)
                          (nilness . t)
                          (shadow . t)
                          (unusedparams . t)
                          (unusedwrite . t)
                          (useany . t))))

(custom-set-faces!
  '(go-package-name :foreground "LightGoldenrod" :weight bold)
  '(go-func-name :foreground "DeepSkyBlue" :weight bold)
  '(go-builtins :foreground "LightSkyBlue")
  '(go-keyword :foreground "Violet" :weight bold))

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

(defun ningen/xwidget-available-p ()
  "Return non-nil when this Emacs can render xwidget WebKit buffers."
  (and (display-graphic-p)
       (featurep 'xwidget-internal)
       (fboundp 'xwidget-webkit-browse-url)))

(defun ningen/browse-url-in-emacs (url &optional new-window)
  "Open URL inside Emacs, preferring xwidget WebKit when available."
  (interactive (browse-url-interactive-arg "URL: "))
  (if (ningen/xwidget-available-p)
      (if (and (require 'xwidgets-reuse nil t)
               (fboundp 'xwidgets-reuse-xwidget-reuse-browse-url))
          (xwidgets-reuse-xwidget-reuse-browse-url url)
        (xwidget-webkit-browse-url url new-window))
    (eww-browse-url url new-window)))

(setq browse-url-browser-function #'ningen/browse-url-in-emacs)

(load! "lisp/ningen-codex")

(map! :leader
      :desc "Browse URL in Emacs" "o w" #'ningen/browse-url-in-emacs)

(after! xwidget
  (map! :map xwidget-webkit-mode-map
        :n "H" #'xwidget-webkit-back
        :n "L" #'xwidget-webkit-forward
        :n "r" #'xwidget-webkit-reload
        :n "q" #'quit-window))

(after! flycheck
  (add-to-list 'flycheck-checkers 'python-ruff)
  (after! lsp-mode
    (flycheck-add-next-checker 'lsp '(warning . python-ruff))))
