;; (org-babel-load-file
;;  (expand-file-name "config.org" user-emacs-directory))
(defvar my-config-dir user-emacs-directory)

(defun my/tangle-config ()
  "config.org を config.el に変換する"
  (interactive)
  (let ((org-file (expand-file-name "config.org" my-config-dir))
        (el-file (expand-file-name "config.el" my-config-dir)))
    (require 'org)
    (org-babel-tangle-file org-file el-file "emacs-lisp")
    (message "Tangled: %s" el-file)))

(defun my/tangle-config-on-save ()
  "config.org 保存時に自動で tangle"
  (when (string-equal (buffer-file-name)
                      (expand-file-name "config.org" my-config-dir))
    (my/tangle-config)))

(add-hook 'after-save-hook #'my/tangle-config-on-save)


(let ((config-el (expand-file-name "config.el" my-config-dir)))
  (if (file-exists-p config-el)
      (load config-el)
    (message "config.el not found. Run M-x my/tangle-config")))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil)
 '(package-vc-selected-packages
   '((claude-code-ide :url
		      "https://github.com/manzaltu/claude-code-ide.el"
		      :rev :newest))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
