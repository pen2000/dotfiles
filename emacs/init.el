;; macOS: Homebrewのパスをemacsに認識させる
(add-to-list 'exec-path "/opt/homebrew/bin")

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

;; スペース区切りの柔軟な補完スタイル
(use-package orderless
  :config
  (setq completion-styles '(orderless basic)))

;; 補完候補に説明を表示
(use-package marginalia
  :config (marginalia-mode))

;; 強化された検索・バッファ切り替え
(use-package consult
  :custom
  (consult-async-min-input 2) ;; 2文字から検索開始（日本語対応）
  :bind (("C-x b"   . consult-buffer)    ;; バッファ+最近のファイル一覧
         ("C-c f"   . consult-fd)        ;; ファイル名検索
         ("C-c g"   . consult-ripgrep))) ;; 内容検索

;; Org-roam: ノートグラフ管理
(use-package org-roam
  :custom
  (org-roam-directory (expand-file-name "roam" org-directory))
  (org-roam-capture-templates
   '(("d" "default" plain "%?"
      :target (file+head "${slug}.org"
                         "#+TITLE: ${title}\n#+DATE: %<%Y-%m-%d>\n#+FILETAGS: \n\n")
      :unnarrowed t)
     ("t" "tip" plain "%?"
      :target (file+head "${slug}.org"
                         "#+TITLE: ${title}\n#+DATE: %<%Y-%m-%d>\n#+FILETAGS: :tip:\n\n")
      :unnarrowed t)))
  :bind
  (("C-c n f" . org-roam-node-find)
   ("C-c n i" . org-roam-node-insert)
   ("C-c n c" . org-roam-capture)
   ("C-c n b" . org-roam-buffer-toggle)
   :map org-mode-map
   ("C-c n t" . org-roam-tag-add))
  :config
  (org-roam-db-autosync-mode)
  (with-eval-after-load 'which-key
    (which-key-add-key-based-replacements "C-c n" "ノート管理")
    (which-key-add-key-based-replacements
      "C-c n f" "ノード検索・新規作成"
      "C-c n i" "リンク挿入"
      "C-c n c" "キャプチャ"
      "C-c n b" "バックリンクサイドバー"
      "C-c n t" "タグ追加"
      "C-c n s" "全文検索"
      "C-c n B" "バックリンク一覧"
      "C-c n u" "グラフUIを開く")))

;; consult + org-roam 統合
(use-package consult-org-roam
  :after (consult org-roam)
  :custom
  (consult-org-roam-grep-func #'consult-ripgrep)
  :bind
  (("C-c n B" . consult-org-roam-backlinks))
  :config
  (consult-org-roam-mode 1))

(defun my/org-roam-search ()
  "org-roamディレクトリ内をripgrepで全文検索する。"
  (interactive)
  (let ((default-directory org-roam-directory))
    (consult-ripgrep)))
(global-set-key (kbd "C-c n s") #'my/org-roam-search)

;; ブラウザ上でのグラフ可視化
(use-package org-roam-ui
  :after org-roam
  :custom
  (org-roam-ui-sync-theme t)
  (org-roam-ui-follow t)
  (org-roam-ui-open-on-start nil)
  :bind
  ("C-c n u" . org-roam-ui-open))

;; timetrack: 日次勤怠トラッキング
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(require 'timetrack)
(global-set-key (kbd "C-c t") timetrack-map)

;; Org-modeの基本設定
(setq org-directory "~/org/")
(setq org-agenda-files '("~/org/"))

;; org-capture テンプレート
(setq org-capture-templates
      '(("i" "Inbox（後で整理）" entry
         (file "~/org/roam/inbox.org")
         "* %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:\n\n")))
(global-set-key (kbd "C-c c") #'org-capture)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(consult marginalia orderless vertico which-key org-modern)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
