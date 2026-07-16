;; バックアップファイルの自動作成などを無効化
(setq make-backup-files nil)
(setq auto-save-default nil)

;; 行番号を表示する
(global-display-line-numbers-mode 1)

;; nerd font
(set-face-font 'default "JetBrains Mono-14")

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

(leaf doom-themes
  :ensure t
  :custom ((doom-themes-enable-bold . t)
           (doom-themes-enable-italic . t)
           (doom-themes-treemacs-theme . "doom-atom"))
  :config
  (load-theme 'doom-one t)
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
   (org-log-done . 'time))
  :config
  ;; ディレクトリ作成
  (unless (file-exists-p org-directory)
    (make-directory org-directory t))

  ;; ファイル作成（初回時）
  (unless (file-exists-p org-default-notes-file)
    (write-region "* Inbox\n" nil org-default-notes-file)))

(leaf org-modern
  :doc "modern .org file visualize"
  :ensure t
  :custom
  ((org-auto-align-tags . nil)
   (org-tags-column . 0)
   (org-catch-invisible-edits . 'show-and-error)
   (org-special-ctrl-a/e . t)
   (org-insert-heading-respect-content . t)
   ;; org styling
   (org-hide-emphasis-markers . t)
   (org-pretty-entities . t)
   (org-agenda-tags-column . 0)
   (org-ellipsis . "…")
   (org-modern-hide-stars . t))
  :config
  ;; 見出しのサイズを大きくする
  (custom-set-faces
   '(org-level-1 ((t (:height 1.4))))
   '(org-level-2 ((t (:height 1.3))))
   '(org-level-3 ((t (:height 1.2))))
   '(org-level-4 ((t (:height 1.1))))
   '(org-level-5 ((t (:height 1.0)))))
  :hook
  (org-mode-hook . org-modern-mode))

;; lsp client である eglot の設定
(leaf eglot
  :doc "LSP client"
  :ensure t
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

(leaf eglot-keybinds
  :config
  (defun my-eglot-keybinds ()
    "eglot 用キーバインド"
    (local-set-key (kbd "M-.") 'xref-find-definitions)
    (local-set-key (kbd "M-?") 'xref-find-references)
    (local-set-key (kbd "C-c l r") 'eglot-rename)
    (local-set-key (kbd "C-c l f") 'eglot-format-buffer)
    (local-set-key (kbd "C-c l a") 'eglot-code-actions)
    (local-set-key (kbd "C-c l d") 'eldoc))
  :hook
  (eglot-managed-mode-hook . my-eglot-keybinds))
