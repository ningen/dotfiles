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


(let ((config-el (expand-file-name "config.el" my-config-dir)))
  (if (file-exists-p config-el)
      (load config-el)
    (message "config.el not found. Run M-x my/tangle-config")))
