;;; init.el -*- lexical-binding: t; -*-

(doom!
 :input

 :completion
 company
 vertico

 :ui
 doom
 doom-dashboard
 hl-todo
 modeline
 nav-flash
 ophints
 (popup +defaults)
 treemacs
 vc-gutter
 vi-tilde-fringe
 workspaces

 :editor
 (evil +everywhere)
 file-templates
 fold
 snippets

 :emacs
 dired
 electric
 ibuffer
 undo
 vc

 :term
 vterm

 :checkers
 syntax

 :tools
 direnv
 docker
 editorconfig
 (eval +overlay)
 lookup
 lsp
 magit
 make
 pdf
 tmux
 tree-sitter

 :os
 (:if IS-MAC macos)
 tty

 :lang
 emacs-lisp
 json
 javascript
 markdown
 (org +pretty)
 python
 sh
 web
 yaml
 nix

 :config
 (default +bindings +smartparens))
