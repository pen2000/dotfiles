;; パッケージ管理の設定
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; use-packageの設定
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; 見た目改善
(use-package org-modern
  :hook (org-mode . org-modern-mode))

;; キー候補表示
(use-package which-key
  :config (which-key-mode))

;; 補完UI
(use-package vertico
  :config (vertico-mode))

;; timetrack: 日次勤怠トラッキング
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(require 'timetrack)
(global-set-key (kbd "C-c t") timetrack-map)

;; Org-modeの基本設定
(setq org-directory "~/org/")
(setq org-agenda-files '("~/org/"))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(vertico which-key org-modern)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
