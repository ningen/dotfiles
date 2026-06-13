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

(unless package-archive-contents
  (package-refresh-contents))

;;; Environment

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :custom
  (exec-path-from-shell-variables '("PATH" "MANPATH" "NIX_PROFILES" "NIX_SSL_CERT_FILE"))
  :config
  (exec-path-from-shell-initialize))

;;; Discoverability

(use-package which-key
  :ensure nil
  :init
  (which-key-mode 1)
  :custom
  (which-key-idle-delay 0.4)
  (which-key-idle-secondary-delay 0.05))

;;; Theme

(use-package doom-themes
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italic t)
  :config
  (load-theme 'doom-tokyo-night t))

;;; Syntax Highlighting

(setq treesit-font-lock-level 4)

(setq treesit-language-source-alist
      '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (nix "https://github.com/nix-community/tree-sitter-nix")))

(defun my/install-treesit-grammars ()
  "Install the tree-sitter grammars used by this Emacs configuration."
  (interactive)
  (dolist (language '(typescript tsx javascript json nix))
    (unless (treesit-language-available-p language)
      (treesit-install-language-grammar language))))

(use-package nix-ts-mode
  :mode "\\.nix\\'")

(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-ts-mode))

;;; LSP

(setq eldoc-idle-delay 0.2)
(setq eldoc-echo-area-use-multiline-p 3)

(use-package eldoc-box
  :commands (eldoc-box-help-at-point))

(defun my/eldoc-help-at-point ()
  "Show hover documentation at point."
  (interactive)
  (if (display-graphic-p)
      (eldoc-box-help-at-point)
    (eldoc-doc-buffer)))

(defun my/eglot-enable-hover ()
  "Enable hover documentation for graphical Eglot buffers."
  (when (and (display-graphic-p)
             (fboundp 'eldoc-box-hover-at-point-mode))
    (eldoc-box-hover-at-point-mode 1)))

(defun my/eglot-enable-inlay-hints ()
  "Enable LSP inlay hints for TypeScript buffers."
  (when (and (eglot-managed-p)
             (fboundp 'eglot-inlay-hints-mode)
             (memq major-mode '(typescript-ts-mode tsx-ts-mode)))
    (eglot-inlay-hints-mode 1)))

(defun my/eglot-toggle-inlay-hints ()
  "Toggle LSP inlay hints in the current Eglot buffer."
  (interactive)
  (require 'eglot)
  (unless (eglot-current-server)
    (user-error "Eglot is not connected in this buffer"))
  (call-interactively #'eglot-inlay-hints-mode))

(setq-default eglot-workspace-configuration
              '(:typescript
                (:inlayHints
                 (:includeInlayParameterNameHints "all"
                  :includeInlayParameterNameHintsWhenArgumentMatchesName t
                  :includeInlayFunctionParameterTypeHints t
                  :includeInlayVariableTypeHints t
                  :includeInlayVariableTypeHintsWhenTypeMatchesName t
                  :includeInlayPropertyDeclarationTypeHints t
                  :includeInlayFunctionLikeReturnTypeHints t
                  :includeInlayEnumMemberValueHints t))
                :javascript
                (:inlayHints
                 (:includeInlayParameterNameHints "all"
                  :includeInlayParameterNameHintsWhenArgumentMatchesName t
                  :includeInlayFunctionParameterTypeHints t
                  :includeInlayVariableTypeHints t
                  :includeInlayVariableTypeHintsWhenTypeMatchesName t
                  :includeInlayPropertyDeclarationTypeHints t
                  :includeInlayFunctionLikeReturnTypeHints t
                  :includeInlayEnumMemberValueHints t))))

(use-package eglot
  :ensure nil
  :hook ((nix-ts-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode . eglot-ensure)
         (eglot-managed-mode . my/eglot-enable-hover)
         (eglot-managed-mode . my/eglot-enable-inlay-hints))
  :config
  (add-to-list 'eglot-server-programs '(nix-ts-mode . ("nixd")))
  (add-to-list 'eglot-server-programs
               '((typescript-ts-mode tsx-ts-mode)
                 . ("typescript-language-server" "--stdio"))))

(defvar-keymap my/lsp-map
  :doc "LSP commands."
  "r" #'eglot-rename
  "a" #'eglot-code-actions
  "f" #'eglot-format
  "h" #'my/eldoc-help-at-point
  "i" #'my/eglot-toggle-inlay-hints
  "d" #'flymake-show-buffer-diagnostics
  "n" #'flymake-goto-next-error
  "p" #'flymake-goto-prev-error)

(keymap-global-set "C-c l" my/lsp-map)

;;; Projects

(defun my/project-root ()
  "Return the current project root, or `default-directory' if outside a project."
  (if-let* ((project (project-current nil)))
      (project-root project)
    default-directory))

(use-package project
  :ensure nil
  :custom
  (project-switch-commands
   '((project-find-file "Find file")
     (project-find-regexp "Find regexp")
     (project-dired "Dired")
     (my/project-vterm "Terminal")
     (project-eshell "Eshell")
     (magit-project-status "Magit")
     (project-any-command "Other"))))

(defun my/ghq-repositories ()
  "Return repositories managed by ghq as full paths."
  (unless (executable-find "ghq")
    (user-error "ghq executable was not found"))
  (let ((output
         (with-temp-buffer
           (unless (zerop (call-process "ghq" nil t nil "list" "--full-path"))
             (user-error "ghq list --full-path failed"))
           (buffer-string))))
    (sort (seq-filter #'file-directory-p
                      (delete-dups (split-string output "\n" t)))
          #'string<)))

(defun my/ghq-read-repository ()
  "Read a ghq repository path with completion."
  (let* ((repositories (my/ghq-repositories))
         (current-project (my/project-root))
         (default (and (member current-project repositories)
                       current-project)))
    (unless repositories
      (user-error "No ghq repositories found"))
    (completing-read "ghq repo: " repositories nil t nil nil default)))

(defun my/ghq-switch-project (directory)
  "Switch to a ghq repository DIRECTORY using `project.el'."
  (interactive (list (my/ghq-read-repository)))
  (project-switch-project (file-name-as-directory directory)))

(defvar-keymap my/project-map
  :doc "Project commands."
  "p" #'project-switch-project
  "g" #'my/ghq-switch-project
  "f" #'project-find-file
  "s" #'project-find-regexp
  "e" #'my/project-vterm
  "t" #'my/project-vterm
  "E" #'project-eshell
  "d" #'project-dired
  "b" #'project-switch-to-buffer
  "k" #'project-kill-buffers)

(keymap-global-set "C-c p" my/project-map)

;;; Terminal

(defvar vterm-always-compile-module)
(defvar vterm-module-cmake-args)
(defvar vterm-shell)

(defun my/vterm-libvterm-prefix ()
  "Return an installed libvterm prefix, if one is available."
  (catch 'prefix
    (dolist (prefix '("/opt/homebrew/opt/libvterm"
                      "/usr/local/opt/libvterm"
                      "~/.nix-profile"))
      (let ((expanded-prefix (expand-file-name prefix)))
        (when (file-exists-p (expand-file-name "include/vterm.h" expanded-prefix))
          (throw 'prefix expanded-prefix))))
    nil))

(defun my/vterm-cmake-args ()
  "Return CMake arguments for compiling the vterm module."
  (if-let* ((prefix (my/vterm-libvterm-prefix)))
      (format "-DCMAKE_PREFIX_PATH=%s" (shell-quote-argument prefix))
    ""))

(use-package vterm
  :commands (vterm)
  :init
  (setq vterm-always-compile-module t)
  (setq vterm-module-cmake-args (my/vterm-cmake-args))
  :custom
  (vterm-kill-buffer-on-exit t)
  (vterm-max-scrollback 20000)
  :config
  (setq vterm-shell (or (getenv "SHELL") shell-file-name)))

(defun my/vterm--buffer-name (prefix root)
  "Return a vterm buffer name with PREFIX for ROOT."
  (format "*%s:%s*"
          prefix
          (file-name-nondirectory
           (directory-file-name root))))

(defun my/vterm--command (program args)
  "Return a shell command string for PROGRAM with ARGS."
  (mapconcat #'shell-quote-argument (cons program args) " "))

(defun my/vterm--start (buffer-name &optional command)
  "Open vterm BUFFER-NAME, optionally starting COMMAND."
  (if (get-buffer buffer-name)
      (pop-to-buffer buffer-name)
    (require 'vterm)
    (let ((vterm-shell (or command vterm-shell)))
      (vterm buffer-name))))

(defun my/project-vterm ()
  "Open a vterm buffer at the current project root."
  (interactive)
  (let* ((root (my/project-root))
         (default-directory root)
         (buffer-name (my/vterm--buffer-name "vterm" root)))
    (my/vterm--start buffer-name)))

(keymap-global-set "C-c t" #'my/project-vterm)

;;; Git

(use-package magit
  :bind ("C-c g" . magit-status))

;;; Codex

(defun my/codex--start (name &rest args)
  "Start Codex in a terminal buffer named NAME with ARGS."
  (let* ((root (my/project-root))
         (default-directory root)
         (codex-program (or (executable-find "codex") "codex"))
         (buffer-name (my/vterm--buffer-name name root))
         (command (my/vterm--command codex-program
                                     (append (list "--cd" root) args))))
    (my/vterm--start buffer-name command)))

(defun my/codex ()
  "Open Codex CLI at the current project root."
  (interactive)
  (my/codex--start "codex"))

(defun my/codex-resume ()
  "Resume a Codex CLI session at the current project root."
  (interactive)
  (my/codex--start "codex-resume" "resume"))

(defvar-keymap my/codex-map
  :doc "Codex commands."
  "c" #'my/codex
  "r" #'my/codex-resume)

(keymap-global-set "C-c c" my/codex-map)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(save-place-mode 1)
(recentf-mode 1)

;;; init.el ends here
