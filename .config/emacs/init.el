(eval-and-compile
(customize-set-variable
'package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
("melpa" . "https://melpa.org/packages/")))
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


;; 選択モードに入るのを変更する
(global-unset-key (kbd "C-SPC"))
(global-set-key (kbd "M-SPC") 'set-mark-command)


;; 補完スタイル
(leaf orderless
:ensure t
:custom
(completion-styles . '(orderless basic))
(completion-category-overrides . '((file (styles basic partial-completion)))))

;; 縦リスト補完UI
(leaf vertico
:ensure t
:config
(vertico-mode 1))

;; 候補に説明を表示
(leaf marginalia
:ensure t
:config
(marginalia-mode 1))

;; 強力な検索・移動コマンド
(leaf consult
:ensure t
:bind
("C-s" . consult-line) ;; バッファ内検索
("C-x b" . consult-buffer) ;; バッファ切り替え
("C-x C-r" . consult-recent-file) ;; 最近のファイル
("M-y" . consult-yank-pop) ;; kill-ring
("C-c s" . consult-ripgrep) ;; ripgrep で検索
("C-c f" . consult-find)) ;; ファイル検索


;; color schema
(leaf doom-themes
:ensure t
:custom
(doom-themes-enable-bold . t)
(doom-themes-enable-italic . t)
:config
(load-theme 'doom-one t) ;; テーマを適用
(doom-themes-visual-bell-config)
(doom-themes-org-config)) ;; org-mode も綺麗に


;; モードライン
(leaf doom-modeline
:ensure t
:custom
(doom-modeline-height . 25)
(doom-modeline-icon . t)
:config
(doom-modeline-mode 1))

;; shell の環境変数を引き継ぐ
(leaf exec-path-from-shell
:ensure t
:config
(exec-path-from-shell-initialize))

;; アイコン
(leaf nerd-icons
:ensure t)

;; フォント
(leaf emacs
:config
(set-face-attribute 'default nil
:family "JetBrains Mono"
:height 140))

;; ghq と連携したemacs の project 管理
(leaf projectile
:ensure t
:config
(projectile-mode +1)
(when (executable-find "ghq")
(setq projectile-known-projects
;; ✅ 空文字列を削除
(delete "" (split-string
(shell-command-to-string "ghq list --full-path")
"\n"))))
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))


;; which-key
(leaf which-key
:ensure nil
:config
(which-key-mode 1))

;; org-mode
(leaf org
:ensure t
:init
(setq org-directory (expand-file-name "~/org"))

:custom
(org-todo-keywords . '((sequence "TODO" "DOING" "|" "DONE" "CANCELLED")))
(org-export-backends . '(md html))
(org-startup-indented . t)
(org-hide-leading-stars . t)

:config
;; ✅ 複雑なリスト構造は :config で setq を使う
(setq org-agenda-files (list org-directory))
(setq org-default-notes-file (concat org-directory "/tasks.org"))

(setq org-capture-templates
'(("t" "Task" entry
(file+headline org-default-notes-file "Inbox")
"* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n**調査内容\n\n** メモ\n")))

(defun org-export-markdown-to-clipborad ()
"現在のorg ファイルをMarkdown に変換してコピー"
(interactive)
(let ((markdown (org-export-as 'md)))
(kill-new markdown)
(message "Markdown をクリップボードにコピーしました"))))

;; 見た目を整える
(leaf org-modern
:ensure t
:after org
:config
(global-org-modern-mode))


(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-level-1 ((t (:height 1.3))))
 '(org-level-2 ((t (:height 1.2))))
 '(org-level-3 ((t (:height 1.1))))
 '(org-level-4 ((t (:height 1.0)))))

;; git 連携
(leaf magit
:ensure t
:bind (("C-c g" . magit-status)))


;; tree-sitter 構文を入れる
(leaf treesit
:custom
(treesit-language-source-alist
. '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
(tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
(javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src"))))

(leaf typescript-ts-mode
:ensure t
:mode (("\\.ts\\'" . typescript-ts-mode)
("\\.tsx\\'" . typescript-ts-mode)))

;; LSP
(leaf eglot
:ensure t
:hook (typescript-ts-mode . eglot-ensure)
:custom
(eglot-autoshutdown . t)
(eglot-sync-connect . 0)
:config
(add-to-list 'eglot-server-programs
'(typescript-ts-mode . ("typescript-language-server" "--stdio"))))

;; prettier
(leaf prettier
:ensure t
:hook (typescript-ts-mode . prettier-mode))

;; company(補完)
(leaf company
:ensure t
:hook (after-init . global-company-mode)
:custom
(company-idle-delay . 0.2)
(company-minimum-length . 1))





;; tool bar 非表示
(tool-bar-mode -1)

;; 行番号を表示する
(global-display-line-numbers-mode 1)

;; 末尾のスペースやタブを可視化
(setq-default show-trailing-whitespace t)

;; 現在行を強調表示
(leaf hl-line
:init
(global-hl-line-mode +1))

;; markdown を org 形式に変換
(defun markdown-to-org ()
"Convert markdown buffer to org format"
(interactive)
(shell-command-on-region (point-min) (point-max)
"pandoc -f markdown -t org"
(current-buffer) t))





(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))

