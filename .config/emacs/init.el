;; バックアップファイルの自動作成などを無効化
(setq make-backup-files nil)
(setq auto-save-default nil)

;; 行番号を表示する
(global-display-line-numbers-mode 1)

;; Use separate fonts for Latin text, Japanese text, and emoji.  WSLg uses the
;; Linux fontconfig database, so these fonts are installed by Home Manager.
(set-face-attribute 'default nil
                    :family "JetBrainsMono Nerd Font Mono"
                    :height 130)
(set-fontset-font t 'japanese-jisx0208
                  (font-spec :family "Noto Sans CJK JP"))
(set-fontset-font t 'katakana-jisx0201
                  (font-spec :family "Noto Sans CJK JP"))
(set-fontset-font t 'han
                  (font-spec :family "Noto Sans CJK JP"))
(set-fontset-font t 'emoji
                  (font-spec :family "Noto Color Emoji"))

;; Keep WSLg frames compact and let the theme provide the visual hierarchy.
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))
(setq-default line-spacing 0.1)
(add-to-list 'default-frame-alist '(internal-border-width . 12))
(add-to-list 'default-frame-alist '(width . 120))
(add-to-list 'default-frame-alist '(height . 40))

;; モダンなpackage-manager の leaf を 入れる
;; ref: https://github.com/conao3/leaf.el

(eval-and-compile
  (customize-set-variable
   'package-archives '(("org" . "https://orgmode.org/elpa/")
                       ("melpa" . "https://melpa.org/packages/")
                       ("gnu" . "https://elpa.gnu.org/packages/")))
  (package-initialize)
  (use-package leaf :ensure t)
  (leaf leaf-keywords
    :ensure t
    :init
    (leaf blackout :ensure t)
    :config
    (leaf-keywords-init)))

(leaf leaf-convert
  :doc "Convert many format to leaf format"
  :ensure t)

(defun dotfiles-wsl-p ()
  (and (eq system-type 'gnu/linux)
       (or (getenv "WSL_INTEROP")
           (and (file-readable-p "/proc/sys/kernel/osrelease")
                (with-temp-buffer
                  (insert-file-contents "/proc/sys/kernel/osrelease")
                  (let ((case-fold-search t))
                    (re-search-forward "microsoft\\|wsl" nil t)))))))

;; WSLg does not reliably forward Windows IME composition to Emacs.  Mozc runs
;; as an Emacs input method, so it works independently of the GUI backend.
(when (dotfiles-wsl-p)
  (require 'mozc)
  (setq default-input-method "japanese-mozc")
  (global-set-key (kbd "C-SPC") #'toggle-input-method)
  (global-set-key (kbd "C-c SPC") #'set-mark-command))

(leaf which-key
  :doc "which emacs keybinds"
  :ensure t
  :global-minor-mode t)

(leaf magit
  :doc "emacs git handler"
  :ensure t)

(leaf doom-themes
  :ensure t
  :custom ((doom-themes-enable-bold . t)
           (doom-themes-enable-italic . t)
           (doom-themes-treemacs-theme . "doom-atom"))
  :config
  (load-theme 'doom-solarized-light t)
  ;; 各種設定
  (doom-themes-visual-bell-config)
  (doom-themes-neotree-config)
  (doom-themes-treemacs-config)
  (doom-themes-org-config))

(setq org-capture-templates
      '(("m" "Memo" entry
         (file+headline "~/org/capture.org" "Inbox")
         "* Memo %? \n")))

(leaf org
  :ensure t
  :custom
  ((org-directory . "~/org")
   (org-default-notes-file . "~/org/capture.org")
   (org-agenda-files . '("~/org/"))
   (org-startup-with-inline-images . t)
   (org-todo-keywords . '((sequence "TODO(t)" "IN-PROGRESS(i)" "|" "DONE(d)" "CANCELLED(c)")))
   (org-log-done . 'time)
   (org-startup-indented . t)
   (org-fontify-todo-headline . t)
   (org-fontify-done-headline . t)
   (org-hide-leading-stars . t))
  :config
  ;; ディレクトリ作成
  (unless (file-exists-p org-directory)
    (make-directory org-directory t))

  ;; ファイル作成（初回時）
  (unless (file-exists-p org-default-notes-file)
    (write-region "* Inbox\n" nil org-default-notes-file))
  :hook
  (org-mode-hook . org-indent-mode))

(leaf org-download
  :doc "drag and drop image .org support"
  :ensure t
  :after org
  :preface
  (defun dotfiles/org-download-wsl-clipboard (&optional basename)
    "Insert a Windows clipboard image into the current Org buffer."
    (interactive)
    (unless (executable-find "win-paste-image")
      (user-error "win-paste-image is not available; apply the WSL Home Manager configuration"))
    (let ((org-download-screenshot-method "win-paste-image %s"))
      (org-id-get-create)
      (org-download-screenshot basename)))

  (defun dotfiles/org-download-clipboard (&optional basename)
    "Insert a clipboard image using the platform-appropriate backend."
    (interactive)
    (if (dotfiles-wsl-p)
        (dotfiles/org-download-wsl-clipboard basename)
      (org-download-clipboard basename)))
  :bind
  (:org-mode-map
   ("C-M-y" . dotfiles/org-download-clipboard))
  :custom
  ((org-download-screenshot-method . "screencapture -i %s")
   (org-download-timestamp . "%Y%m%d_%H%M%S_"))
  :hook
  (org-mode-hook
   . (lambda ()
       (when buffer-file-name
         (setq-local org-download-image-dir
                     (expand-file-name "images/"
                                       (file-name-directory buffer-file-name)))))))

(leaf org-preview-html
  :doc ".org file preview plugin"
  :ensure t)

(leaf org-modern
  :doc "modern .org file visualize"
  :ensure t
  :custom
  ((org-modern-star . '("◉" "○" "✦" "✧" "◆" "◇"))
   (org-modern-list . '((?- . "•") (?+ . "◦")))
   (org-modern-table . t)
   (org-modern-tag . t)
   (org-auto-align-tags . nil)
   (org-tags-column . 0)
   (org-catch-invisible-edits . 'show-and-error)
   (org-special-ctrl-a/e . t)
   (org-insert-heading-respect-content . t)
   ;; org styling
   (org-hide-emphasis-markers . t)
   (org-pretty-entities . t)
   (org-agenda-tags-column . 0)
   (org-ellipsis . "…")
   (org-modern-hide-stars . nil))
  :custom-face
  (org-level-1 . '((t (:height 1.35 :weight bold))))
  (org-level-2 . '((t (:height 1.20 :weight bold))))
  (org-level-3 . '((t (:height 1.10 :weight bold))))
  (org-level-4 . '((t (:height 1.05 :weight bold))))
  (org-level-5 . '((t (:height 1.00 :weight bold))))
  :hook
  (org-mode-hook . org-modern-mode))

;; Tree-sitter grammars used for syntax highlighting and language tooling.
(setq treesit-language-source-alist
      '((org "https://github.com/milisims/tree-sitter-org")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (nix "https://github.com/nix-community/tree-sitter-nix")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (markdown "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown/src")
        (markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown-inline/src")
        (yaml "https://github.com/tree-sitter-grammars/tree-sitter-yaml")
        (json "https://github.com/tree-sitter/tree-sitter-json")))

(defun my/treesit-install-all-grammars ()
  "Install every Tree-sitter grammar in `treesit-language-source-alist'."
  (interactive)
  (dolist (source treesit-language-source-alist)
    (let ((lang (car source)))
      (unless (treesit-language-available-p lang)
        (treesit-install-language-grammar lang)))))

;; lsp client である eglot の設定
(leaf eglot
  :doc "LSP client"
  :ensure t
  :bind
  (("M-." . xref-find-definitions)
   ("M-?" . xref-find-references)
   ("C-c l r" . eglot-rename)
   ("C-c l f" . eglot-format-buffer)
   ("C-c l a" . eglot-code-actions)
   ("C-c l d" . eldoc))
  :custom
  ((eglot-autoshutdown . t)
   (eglot-sync-connect . 0)
   (eglot-connect-timeout . 10)
   (eglot-managed-mode-line-prefix . ""))
  :hook
  (emacs-lisp-mode-hook . eglot-ensure)
  :config
  (add-to-list
   'eglot-server-programs
   '(emacs-lisp-mode
     . ("emacs-lsp-booster" "--json-rpc" "emacs-lisp-language-server" "--stdio"))))

;; vertico（候補選択UI）
(leaf vertico
  :doc "補完選択 UI"
  :ensure t
  :init
  (vertico-mode))

;; orderless（曖昧検索）
(leaf orderless
  :doc "あいまい検索"
  :ensure t
  :custom
  ((completion-styles . '(orderless basic))
   (completion-category-defaults . nil)))

;; company（補完エンジン）
(leaf company
  :doc "補完エンジン"
  :ensure t
  :custom
  ((company-minimum-prefix-length . 1)
   (company-idle-delay . 0.1)
   (company-tooltip-align-annotations . t))
  :hook
  (eglot-managed-mode-hook . company-mode))
