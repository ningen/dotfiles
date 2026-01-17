;; straight.el を使用するため package.el を無効化
(setq package-enable-at-startup nil)

;; 画面最大化
(push '(fullscreen . maximized) default-frame-alist)

;; スクロール非表示
(push '(vertical-scroll-bars) default-frame-alist)

;; メニューバー非表示
(push '(menu-bar-lines . 0) default-frame-alist)

;; ツールバー非表示
(push '(tool-bar-lines . 0) default-frame-alist)

(provide 'early-init)
