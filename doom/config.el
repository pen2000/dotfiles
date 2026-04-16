;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; ノーマルモード移行時に IME を自動オフ
(after! evil
  (add-hook 'evil-normal-state-entry-hook
            (lambda () (mac-select-input-source "com.apple.keylayout.ABC"))))

(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; --- Org 基本設定 ---
(setq org-agenda-files '("~/org/"))

;; org-capture テンプレート
(after! org
  (setq org-capture-templates
        '(("i" "Inbox（後で整理）" entry
           (file "~/org/roam/inbox.org")
           "* %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:\n\n"))))

;; --- Org-roam 設定 ---
(setq org-roam-directory (expand-file-name "roam" org-directory))

(after! org-roam
  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "${slug}.org"
                              "#+TITLE: ${title}\n#+DATE: %<%Y-%m-%d>\n#+FILETAGS: \n\n")
           :unnarrowed t)
          ("t" "tip" plain "%?"
           :target (file+head "${slug}.org"
                              "#+TITLE: ${title}\n#+DATE: %<%Y-%m-%d>\n#+FILETAGS: :tip:\n\n")
           :unnarrowed t)
          ("a" "account" plain "%?"
           :target (file+head "${slug}.org"
                              "#+TITLE: ${title}\n#+DATE: %<%Y-%m-%d>\n#+FILETAGS: :account:\n\n")
           :unnarrowed t)
          ("i" "idea" plain "* 内容\n%?"
           :target (file+head "${slug}.org"
                              "#+TITLE: ${title}\n#+DATE: %<%Y-%m-%d>\n#+FILETAGS: :idea:\n\n")
           :unnarrowed t)
          ("e" "trouble" plain "* 現象\n%?\n\n* 環境\n\n* 原因\n\n* 解決策\n\n* 参考URL\n"
           :target (file+head "${slug}.org"
                              "#+TITLE: ${title}\n#+DATE: %<%Y-%m-%d>\n#+FILETAGS: :trouble:\n\n")
           :unnarrowed t)
          ("p" "project" plain "* 目的・概要\n%?\n\n* リポジトリURL\n\n* 関係者\n\n* メモ\n"
           :target (file+head "${slug}.org"
                              "#+TITLE: ${title}\n#+DATE: %<%Y-%m-%d>\n#+FILETAGS: :project:\n\n")
           :unnarrowed t))))

;; --- consult-org-roam 設定 ---
(after! consult-org-roam
  (setq consult-org-roam-grep-func #'consult-ripgrep)
  (consult-org-roam-mode 1))

;; --- org-roam タグ絞り込み検索 ---
(defun my/org-roam--all-tags ()
  "org-roam DBから全タグリストを返す。"
  (mapcar #'car
          (org-roam-db-query [:select :distinct [tag]
                              :from tags
                              :order-by (asc tag)])))

(defun my/org-roam--select-tags ()
  "completing-read-multipleでタグを選択し、リストで返す。"
  (completing-read-multiple "タグ選択 (カンマ区切りで複数可): "
                            (my/org-roam--all-tags)
                            nil t))

(defun my/org-roam--nodes-with-tags (selected-tags)
  "SELECTED-TAGS を全て持つノードのリストを返す。"
  (cl-remove-if-not
   (lambda (node)
     (let ((node-tags (org-roam-node-tags node)))
       (cl-every (lambda (tag) (member tag node-tags))
                 selected-tags)))
   (org-roam-node-list)))

(defun my/org-roam-find-by-tags ()
  "タグで絞り込んでorg-roamノードを検索・ジャンプする。"
  (interactive)
  (let ((selected-tags (my/org-roam--select-tags)))
    (if (null selected-tags)
        (message "タグが選択されませんでした")
      (org-roam-node-find
       nil nil
       (lambda (node)
         (let ((node-tags (org-roam-node-tags node)))
           (cl-every (lambda (tag) (member tag node-tags))
                     selected-tags)))))))

(defun my/org-roam-grep-by-tags ()
  "タグで絞り込んだファイルに対してripgrepを実行する。"
  (interactive)
  (let ((selected-tags (my/org-roam--select-tags)))
    (if (null selected-tags)
        (message "タグが選択されませんでした")
      (let* ((nodes (my/org-roam--nodes-with-tags selected-tags))
             (files (delete-dups (mapcar #'org-roam-node-file nodes))))
        (if (null files)
            (message "該当するファイルがありませんでした")
          (consult-ripgrep files))))))

(map! :leader
      :prefix ("n r" . "org-roam")
      :desc "ノート全文検索"          "/" #'consult-org-roam-search
      :desc "ノートファイル検索"       "o" #'consult-org-roam-file-find
      :desc "タグ絞り込みノード検索"   "t" #'my/org-roam-find-by-tags
      :desc "タグ絞り込みgrep"         "T" #'my/org-roam-grep-by-tags)

;; --- org-roam-ui 設定 ---
(after! org-roam-ui
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-open-on-start nil))

;; --- timetrack ---
(add-load-path! "lisp")
(require 'timetrack)
(evil-set-initial-state 'timetrack-task-list-mode 'emacs)

(map! :leader
      (:prefix ("o t" . "timetrack")
       :desc "今日のファイルを開く"     "t" #'timetrack-open-today
       :desc "工数追加"                 "a" #'timetrack-add-entry
       :desc "タスク追加"               "n" #'timetrack-add-task
       :desc "clock-in（作業開始）"     "i" #'timetrack-clock-in
       :desc "clock-out（作業終了）"    "o" #'timetrack-clock-out
       :desc "clock状態確認"            "c" #'timetrack-clock-status
       :desc "今日のタスク一覧"         "l" #'timetrack-list-tasks
       :desc "全タスク一覧（未完了）"   "L" #'timetrack-list-all-tasks
       :desc "当日サマリー"             "s" #'timetrack-show-summary
       :desc "日付指定サマリー"         "S" #'timetrack-show-summary-for-date
       :desc "プロジェクト定義を開く"   "m" #'timetrack-open-master))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
