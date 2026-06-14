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
(require 'treesit)

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

;;; Completion

(setq completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)
(setq read-file-name-completion-ignore-case t)

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1))

(use-package vertico
  :init
  (vertico-mode 1)
  :custom
  (vertico-count 20)
  (vertico-cycle t))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles basic partial-completion orderless)))))

(use-package marginalia
  :init
  (marginalia-mode 1))

(use-package consult
  :custom
  (consult-preview-key '(:debounce 0.2 any)))

(use-package corfu
  :hook (eglot-managed-mode . corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-cycle t))

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
      '((astro "https://github.com/virchau13/tree-sitter-astro")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript")
        (css "https://github.com/tree-sitter/tree-sitter-css")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (lua "https://github.com/tree-sitter-grammars/tree-sitter-lua")
        (nix "https://github.com/nix-community/tree-sitter-nix")))

(defun my/install-treesit-grammars ()
  "Install the tree-sitter grammars used by this Emacs configuration."
  (interactive)
  (dolist (language '(astro typescript tsx javascript css json python lua nix))
    (unless (treesit-language-available-p language)
      (treesit-install-language-grammar language))))

(use-package lua-mode
  :mode "\\.lua\\'")

(use-package nix-ts-mode
  :mode "\\.nix\\'")

(use-package astro-ts-mode
  :mode "\\.astro\\'")

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

(defun my/format-buffer ()
  "Format the current buffer with the configured formatter."
  (interactive)
  (cond
   ((fboundp 'apheleia-format-buffer)
    (apheleia-format-buffer))
   ((and (fboundp 'eglot-managed-p) (eglot-managed-p))
    (eglot-format))
   (t
    (indent-region (point-min) (point-max)))))

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
         (python-mode . eglot-ensure)
         (python-ts-mode . eglot-ensure)
         (lua-mode . eglot-ensure)
         (lua-ts-mode . eglot-ensure)
         (astro-ts-mode . eglot-ensure)
         (js-ts-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode . eglot-ensure)
         (eglot-managed-mode . my/eglot-enable-hover)
         (eglot-managed-mode . my/eglot-enable-inlay-hints))
  :config
  (add-to-list 'eglot-server-programs '(nix-ts-mode . ("nixd")))
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((lua-mode lua-ts-mode)
                 . ("lua-language-server")))
  (add-to-list 'eglot-server-programs
               '(astro-ts-mode . ("astro-ls" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((js-ts-mode typescript-ts-mode tsx-ts-mode)
                 . ("typescript-language-server" "--stdio"))))

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-no-changes-timeout 0.5)
  (flymake-start-on-save-buffer t))

(defun my/flymake-eslint-enable-maybe ()
  "Enable ESLint diagnostics in JavaScript and TypeScript buffers."
  (when (memq major-mode '(astro-ts-mode js-ts-mode typescript-ts-mode tsx-ts-mode))
    (flymake-eslint-enable)))

(use-package flymake-eslint
  :commands (flymake-eslint-enable)
  :hook ((astro-ts-mode js-ts-mode typescript-ts-mode tsx-ts-mode eglot-managed-mode)
         . my/flymake-eslint-enable-maybe)
  :custom
  (flymake-eslint-executable-name "eslint_d"))

(use-package flymake-ruff
  :commands (flymake-ruff-load)
  :hook ((python-mode python-ts-mode eglot-managed-mode) . flymake-ruff-load))

(use-package apheleia
  :commands (apheleia-format-buffer apheleia-mode)
  :hook (prog-mode . apheleia-mode)
  :config
  (setf (alist-get 'prettier apheleia-formatters)
        '("prettier" "--stdin-filepath" filepath))
  (setf (alist-get 'black apheleia-formatters)
        '("black" "--quiet" "--stdin-filename" filepath "-"))
  (setf (alist-get 'stylua apheleia-formatters)
        '("stylua" "-"))
  (setf (alist-get 'nixfmt apheleia-formatters)
        '("nixfmt" "-"))
  (dolist (formatter '((js-ts-mode . prettier)
                       (astro-ts-mode . prettier)
                       (typescript-ts-mode . prettier)
                       (tsx-ts-mode . prettier)
                       (json-ts-mode . prettier)
                       (python-mode . black)
                       (python-ts-mode . black)
                       (lua-mode . stylua)
                       (lua-ts-mode . stylua)
                       (nix-ts-mode . nixfmt)))
    (setf (alist-get (car formatter) apheleia-mode-alist)
          (cdr formatter))))

(defvar-keymap my/lsp-map
  :doc "LSP commands."
  "r" #'eglot-rename
  "a" #'eglot-code-actions
  "f" #'my/format-buffer
  "F" #'apheleia-mode
  "h" #'my/eldoc-help-at-point
  "i" #'my/eglot-toggle-inlay-hints
  "d" #'flymake-show-buffer-diagnostics
  "l" #'consult-flymake
  "n" #'flymake-goto-next-error
  "p" #'flymake-goto-prev-error)

(keymap-global-set "C-c l" my/lsp-map)

;;; Projects

(require 'cl-lib)

(defun my/project-root ()
  "Return the current project root, or `default-directory' if outside a project."
  (if-let* ((project (project-current nil)))
      (project-root project)
    default-directory))

(use-package project
  :ensure nil
  :custom
  (project-switch-commands
   '((my/project-find-file "Find file" ?f)
     (project-find-regexp "Find regexp" ?s)
     (project-dired "Dired" ?d)
     (my/project-vterm "Terminal" ?t)
     (project-eshell "Eshell" ?e)
     (my/project-magit-status "Magit" ?m)
     (project-any-command "Other" ?o))))

(defun my/project-find-file ()
  "Find a file in the current project with a preview-friendly completion UI."
  (interactive)
  (let ((default-directory (my/project-root)))
    (cond
     ((and (require 'consult nil t)
           (executable-find "fd"))
      (consult-fd default-directory))
     ((require 'consult nil t)
      (consult-find default-directory))
     (t
      (project-find-file)))))

(defvar my/ghq-history nil
  "Minibuffer history for ghq repository selection.")

(defun my/ghq--command-lines (&rest args)
  "Return non-empty output lines from ghq called with ARGS."
  (unless (executable-find "ghq")
    (user-error "ghq executable was not found"))
  (let ((output
         (with-temp-buffer
           (unless (zerop (apply #'call-process "ghq" nil t nil args))
             (user-error "ghq %s failed" (mapconcat #'identity args " ")))
           (buffer-string))))
    (split-string output "\n" t)))

(defun my/ghq-repositories ()
  "Return repositories managed by ghq as (NAME . PATH) pairs."
  (let ((names (my/ghq--command-lines "list"))
        (paths (my/ghq--command-lines "list" "--full-path")))
    (unless (= (length names) (length paths))
      (user-error "ghq list output was inconsistent"))
    (sort (cl-remove-if-not (lambda (repository)
                              (file-directory-p (cdr repository)))
                            (delete-dups (cl-mapcar #'cons names paths)))
          (lambda (a b)
            (string< (car a) (car b))))))

(defun my/ghq-read-repository ()
  "Read a ghq repository path with completion."
  (let* ((repositories (my/ghq-repositories))
         (names (mapcar #'car repositories))
         (current-project (directory-file-name
                           (expand-file-name (my/project-root))))
         (default (car (rassoc current-project repositories)))
         (annotate
          (lambda (candidate)
            (when-let* ((path (cdr (assoc candidate repositories))))
              (concat " " (abbreviate-file-name path)))))
         (collection
          (lambda (string pred action)
            (if (eq action 'metadata)
                `(metadata
                  (category . my/ghq-repository)
                  (annotation-function . ,annotate))
              (complete-with-action action names string pred)))))
    (unless repositories
      (user-error "No ghq repositories found"))
    (cdr (assoc (completing-read "ghq repo: "
                                  collection nil t nil 'my/ghq-history default)
                repositories))))

(defun my/ghq-switch-project (directory)
  "Switch to a ghq repository DIRECTORY using `project.el'."
  (interactive (list (my/ghq-read-repository)))
  (project-switch-project (file-name-as-directory directory)))

(defvar-keymap my/project-map
  :doc "Project commands."
  "p" #'project-switch-project
  "g" #'my/ghq-switch-project
  "f" #'my/project-find-file
  "s" #'project-find-regexp
  "m" #'my/project-magit-status
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

(defun my/project-magit-status ()
  "Open Magit status for the current project root."
  (interactive)
  (require 'magit)
  (let ((default-directory (my/project-root)))
    (magit-status default-directory)))

(use-package magit
  :bind ("C-c g" . my/project-magit-status)
  :init
  (setq magit-save-repository-buffers 'dontask)
  (setq magit-diff-refine-hunk t)
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1)
  (setq magit-bury-buffer-function #'magit-restore-window-configuration)
  (setq magit-repository-directories `((,(expand-file-name "~/ghq") . 3))))

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
