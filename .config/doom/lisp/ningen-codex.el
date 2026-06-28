;;; ningen-codex.el -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'project nil t)

(defgroup ningen-codex nil
  "Personal Codex CLI integration."
  :group 'tools)

(defcustom ningen-codex-command "codex"
  "Codex CLI executable."
  :type 'string
  :group 'ningen-codex)

(defcustom ningen-codex-sandbox "workspace-write"
  "Default sandbox mode for interactive Codex sessions."
  :type '(choice (const "read-only")
                 (const "workspace-write")
                 (const "danger-full-access"))
  :group 'ningen-codex)

(defcustom ningen-codex-approval "on-request"
  "Default approval policy for interactive Codex sessions."
  :type '(choice (const "untrusted")
                 (const "on-request")
                 (const "never"))
  :group 'ningen-codex)

(defcustom ningen-codex-exec-sandbox "read-only"
  "Default sandbox mode for non-interactive Codex exec runs."
  :type '(choice (const "read-only")
                 (const "workspace-write")
                 (const "danger-full-access"))
  :group 'ningen-codex)

(defun ningen-codex--project-root ()
  "Return the current project root, falling back to `default-directory'."
  (file-truename
   (or (when (fboundp 'projectile-project-root)
         (ignore-errors (projectile-project-root)))
       (when-let ((project (and (fboundp 'project-current)
                                (project-current nil))))
         (if (fboundp 'project-root)
             (project-root project)
           (cdr project)))
       default-directory)))

(defun ningen-codex--project-name (root)
  "Return a display name for ROOT."
  (file-name-nondirectory (directory-file-name root)))

(defun ningen-codex--ensure-command ()
  "Raise an error when `ningen-codex-command' is not available."
  (unless (executable-find ningen-codex-command)
    (user-error "Cannot find %s in exec-path" ningen-codex-command)))

(defun ningen-codex--shell-command (args)
  "Return a shell command for Codex ARGS."
  (mapconcat #'shell-quote-argument
             (cons ningen-codex-command args)
             " "))

(defun ningen-codex--vterm-run (args buffer-suffix)
  "Run Codex with ARGS in a project-local vterm BUFFER-SUFFIX."
  (ningen-codex--ensure-command)
  (unless (require 'vterm nil t)
    (user-error "vterm is not available"))
  (let* ((root (ningen-codex--project-root))
         (default-directory root)
         (buffer-name (format "*codex:%s:%s*"
                              (ningen-codex--project-name root)
                              buffer-suffix))
         (buffer (get-buffer buffer-name)))
    (when (and buffer (not (get-buffer-process buffer)))
      (kill-buffer buffer)
      (setq buffer nil))
    (if buffer
        (pop-to-buffer buffer)
      (vterm buffer-name)
      (vterm-send-string (ningen-codex--shell-command args))
      (vterm-send-return))))

(defun ningen-codex-open ()
  "Open Codex TUI for the current project."
  (interactive)
  (let ((root (ningen-codex--project-root)))
    (ningen-codex--vterm-run
     (list "--cd" root
           "--sandbox" ningen-codex-sandbox
           "--ask-for-approval" ningen-codex-approval)
     "tui")))

(defun ningen-codex-resume-last ()
  "Resume the latest Codex session for the current project."
  (interactive)
  (let ((root (ningen-codex--project-root)))
    (ningen-codex--vterm-run
     (list "resume"
           "--last"
           "--cd" root
           "--sandbox" ningen-codex-sandbox
           "--ask-for-approval" ningen-codex-approval)
     "resume")))

(defun ningen-codex-doctor ()
  "Run `codex doctor' in vterm."
  (interactive)
  (ningen-codex--vterm-run (list "doctor") "doctor"))

(defun ningen-codex--exec-buffer ()
  "Return the buffer used for Codex exec output."
  (get-buffer-create "*codex-exec*"))

(defun ningen-codex-exec (prompt &optional input)
  "Run `codex exec' with PROMPT and optional INPUT via stdin."
  (interactive "sCodex prompt: ")
  (ningen-codex--ensure-command)
  (let* ((root (ningen-codex--project-root))
         (buffer (ningen-codex--exec-buffer))
         (command (list ningen-codex-command
                        "exec"
                        "--cd" root
                        "--sandbox" ningen-codex-exec-sandbox
                        "--color" "never"
                        prompt)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "$ %s\n\n" (mapconcat #'shell-quote-argument command " ")))))
    (pop-to-buffer buffer)
    (let ((process
           (make-process
            :name "codex-exec"
            :buffer buffer
            :stderr buffer
            :command command
            :connection-type 'pipe
            :sentinel
            (lambda (process _event)
              (when (memq (process-status process) '(exit signal))
                (with-current-buffer (process-buffer process)
                  (goto-char (point-max))
                  (insert (format "\n[codex exited with status %s]\n"
                                  (process-exit-status process)))))))))
      (when input
        (process-send-string process input))
      (process-send-eof process))))

(defun ningen-codex-exec-region-or-buffer (prompt)
  "Run `codex exec' with PROMPT and the active region or current buffer."
  (interactive "sCodex prompt: ")
  (let ((input (if (use-region-p)
                   (buffer-substring-no-properties (region-beginning) (region-end))
                 (buffer-substring-no-properties (point-min) (point-max)))))
    (ningen-codex-exec prompt input)))

(map! :leader
      (:prefix ("o c" . "codex")
       :desc "Open Codex" "c" #'ningen-codex-open
       :desc "Resume Codex" "r" #'ningen-codex-resume-last
       :desc "Codex exec" "e" #'ningen-codex-exec
       :desc "Codex exec region/buffer" "b" #'ningen-codex-exec-region-or-buffer
       :desc "Codex doctor" "d" #'ningen-codex-doctor))

(provide 'ningen-codex)
