;;; timetrack.el --- 日次勤怠時間トラッキング -*- lexical-binding: t -*-

;;; Commentary:
;; プロジェクト・フェーズごとの工数を org-mode テーブルで管理する。
;;
;; ファイル構成:
;;   ~/works/timetrack/projects.org        ... プロジェクト/フェーズ定義
;;   ~/works/timetrack/timetrack_YYYYMMDD.org ... 日次記録
;;
;; キーバインド (C-c t がプレフィックス):
;;   C-c t t  今日のファイルを開く
;;   C-c t a  工数エントリを追加
;;   C-c t s  当日サマリーを表示
;;   C-c t S  日付指定でサマリーを表示
;;   C-c t m  プロジェクト定義ファイルを開く

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(declare-function which-key-add-key-based-replacements "which-key")
(declare-function which-key-add-keymap-based-replacements "which-key")

;;;; カスタマイズ変数

(defgroup timetrack nil
  "日次勤怠トラッキング。"
  :prefix "timetrack-"
  :group 'tools)

(defcustom timetrack-directory (expand-file-name "~/works/notes/timetrack")
  "勤怠ファイルを格納するディレクトリ。"
  :type 'directory
  :group 'timetrack)

(defcustom timetrack-master-file "projects.org"
  "プロジェクト/フェーズ定義ファイルの名前。"
  :type 'string
  :group 'timetrack)

;;;; パス計算

(defun timetrack--master-path ()
  "定義ファイルのフルパスを返す。"
  (expand-file-name timetrack-master-file timetrack-directory))

(defun timetrack--daily-path (&optional date)
  "DATE (YYYYMMDD, 省略時は今日) の日次ファイルパスを返す。"
  (expand-file-name
   (format "timetrack_%s.org" (or date (format-time-string "%Y%m%d")))
   timetrack-directory))

(defun timetrack--ensure-dir ()
  "勤怠ディレクトリを作成する。"
  (make-directory timetrack-directory t))

;;;; 定義ファイル

(defun timetrack--create-master ()
  "定義ファイルのテンプレートを作成する。"
  (with-temp-file (timetrack--master-path)
    (insert "#+TITLE: プロジェクト・フェーズ定義\n\n")
    (insert "* プロジェクト一覧\n\n")
    (insert "プロジェクト名とフェーズを追加してください。\n")
    (insert "フェーズが不要な場合は空欄にしてください。\n\n")
    (insert "| プロジェクト名 | フェーズ |\n")
    (insert "|--------------|----------|\n")
    (insert "| サンプルPJ | 設計 |\n")
    (insert "| サンプルPJ | 実装 |\n")
    (insert "| サンプルPJ | テスト |\n")
    (insert "| デイリーミーティング | |\n")))

(defun timetrack--read-master ()
  "定義ファイルを読み込み、(プロジェクト . (フェーズ...)) のalistを返す。"
  (let ((path (timetrack--master-path))
        result)
    (when (file-exists-p path)
      (with-temp-buffer
        (insert-file-contents path)
        (goto-char (point-min))
        (while (re-search-forward
                "^| *\\([^|\n]+?\\) *| *\\([^|\n]*?\\) *|" nil t)
          (let ((proj  (string-trim (match-string 1)))
                (phase (string-trim (match-string 2))))
            ;; セパレータ行と見出し行を除外
            (unless (or (string-prefix-p "-" proj)
                        (string= proj "プロジェクト名"))
              (let ((cell (assoc proj result)))
                (if cell
                    (unless (string-empty-p phase)
                      (setcdr cell (nconc (cdr cell) (list phase))))
                  (push (cons proj
                               (if (string-empty-p phase) nil (list phase)))
                        result))))))))
    (nreverse result)))

;;;###autoload
(defun timetrack-open-master ()
  "プロジェクト/フェーズ定義ファイルを開く。"
  (interactive)
  (timetrack--ensure-dir)
  (let ((path (timetrack--master-path)))
    (unless (file-exists-p path)
      (timetrack--create-master)
      (message "定義ファイルを作成しました: %s" path))
    (find-file path)))

;;;; 日次ファイル

(defun timetrack--create-daily (path date-display)
  "PATH に日付 DATE-DISPLAY の日次ファイルを作成する。"
  (with-temp-file path
    (insert (format "#+TITLE: 勤怠記録 %s\n" date-display))
    (insert (format "#+DATE: %s\n\n" date-display))
    (insert "* 作業記録\n\n")
    (insert "| プロジェクト | フェーズ | タスク名 | 工数 |\n")
    (insert "|-------------|---------|---------|------|\n\n")
    (insert "-----\n\n")
    (insert "* タスク\n\n")
    (insert "-----\n\n")
    (insert "* メモ\n\n")))

;;;###autoload
(defun timetrack-open-today ()
  "今日の勤怠ファイルを開く (存在しない場合は作成)。"
  (interactive)
  (timetrack--ensure-dir)
  (let* ((path  (timetrack--daily-path))
         (today (format-time-string "%Y-%m-%d")))
    (unless (file-exists-p path)
      (timetrack--create-daily path today)
      (message "本日のファイルを作成しました: %s" path))
    (find-file path)))

;;;; エントリ追加

(defun timetrack--find-table-end (buf)
  "BUF 内の「作業記録」セクションにあるテーブルの最終行位置を返す。
見つからない場合は nil。"
  (with-current-buffer buf
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^\\* 作業記録" nil t)
        (let (last-pos)
          (while (re-search-forward "^|" nil t)
            (setq last-pos (line-end-position)))
          last-pos)))))

;;;###autoload
(defun timetrack-add-entry ()
  "工数エントリを今日の勤怠ファイルに追加する。"
  (interactive)
  (timetrack--ensure-dir)
  (let* ((master   (timetrack--read-master))
         (projects (mapcar #'car master))
         (project  (completing-read "プロジェクト: " projects nil nil))
         (phases   (cdr (assoc project master)))
         (phase    (cond
                    (phases
                     (completing-read "フェーズ: "
                                      (append phases (list ""))
                                      nil nil))
                    (t (read-string "フェーズ (空でOK): "))))
         (task     (read-string "タスク名: "))
         (hours    (read-string "工数 (例: 1.5): "))
         (path     (timetrack--daily-path))
         (today    (format-time-string "%Y-%m-%d")))
    ;; 入力検証
    (unless (string-match-p "^[0-9]+\\.?[0-9]*$" hours)
      (user-error "工数は数値で入力してください: %s" hours))
    (unless (file-exists-p path)
      (timetrack--create-daily path today))
    (let* ((buf      (find-file-noselect path))
           (table-end (timetrack--find-table-end buf)))
      (with-current-buffer buf
        (if table-end
            (progn
              (goto-char table-end)
              (end-of-line)
              (insert (format "\n| %s | %s | %s | %s |"
                              project phase task hours)))
          ;; テーブルが見つからない場合はファイル末尾に追記
          (goto-char (point-max))
          (insert (format "\n* 作業記録\n\n| プロジェクト | フェーズ | タスク名 | 工数 |\n"))
          (insert "|-------------|---------|---------|------|\n")
          (insert (format "| %s | %s | %s | %s |" project phase task hours)))
        (save-buffer)))
    (message "追加: %s | %s | %s | %s 時間" project phase task hours)))

;;;; サマリー

(defun timetrack--parse-entries (path)
  "PATH の日次ファイルからエントリ一覧を返す。
各要素は (project phase task hours) のリスト。"
  (let (entries)
    (when (file-exists-p path)
      (with-temp-buffer
        (insert-file-contents path)
        (goto-char (point-min))
        (while (re-search-forward
                (concat "^| *\\([^|\n]+?\\) *"  ; project
                        "| *\\([^|\n]*?\\) *"    ; phase
                        "| *\\([^|\n]+?\\) *"    ; task
                        "| *\\([0-9]+\\.?[0-9]*\\) *|") ; hours
                nil t)
          (let ((proj  (string-trim (match-string 1)))
                (phase (string-trim (match-string 2)))
                (task  (string-trim (match-string 3)))
                (hours (string-to-number (match-string 4))))
            ;; ヘッダー行を除外
            (unless (string= proj "プロジェクト")
              (push (list proj phase task hours) entries))))))
    (nreverse entries)))

(defun timetrack--build-summary (entries)
  "ENTRIES から集計ハッシュ (project -> (phase -> hours)) を返す。"
  (let ((tbl (make-hash-table :test 'equal)))
    (dolist (e entries)
      (let* ((proj  (nth 0 e))
             (phase (nth 1 e))
             (hours (nth 3 e))
             (ptbl  (or (gethash proj tbl)
                        (let ((h (make-hash-table :test 'equal)))
                          (puthash proj h tbl)
                          h))))
        (puthash phase (+ (gethash phase ptbl 0) hours) ptbl)))
    tbl))

(defun timetrack--render-summary (date tbl entries)
  "サマリーバッファにレンダリングする。"
  (let ((buf (get-buffer-create "*Timetrack Summary*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "勤怠サマリー  %s\n" date))
        (insert (make-string 60 ?═))
        (insert "\n")
        (if (null entries)
            (insert "\n  (エントリなし)\n")
          (let* ((proj-list (sort (hash-table-keys tbl) #'string<))
                 (grand-total 0))
            (dolist (proj proj-list)
              (let* ((ptbl       (gethash proj tbl))
                     (phases     (sort (hash-table-keys ptbl) #'string<))
                     (proj-total (let ((s 0))
                                   (maphash (lambda (_ h) (setq s (+ s h))) ptbl)
                                   s)))
                (insert (format "\n  ▌ %s\n" proj))
                (dolist (phase phases)
                  (let ((h (gethash phase ptbl))
                        (label (if (string-empty-p phase) "(フェーズなし)" phase)))
                    (insert (format "    %-22s %6.2f h\n" label h))))
                (when (> (length phases) 1)
                  (insert (format "    %s\n" (make-string 30 ?─)))
                  (insert (format "    %-22s %6.2f h\n" "小計" proj-total)))
                (setq grand-total (+ grand-total proj-total))))
            (insert "\n")
            (insert (make-string 60 ?═))
            (insert "\n")
            (insert (format "  合計                     %6.2f h\n" grand-total))))
        (insert "\n[q] で閉じる\n"))
      (special-mode)
      (local-set-key (kbd "q") #'quit-window)
      (goto-char (point-min)))
    (pop-to-buffer buf)))

;;;###autoload
(defun timetrack-show-summary ()
  "今日の勤怠サマリーをプロジェクト/フェーズ別に表示する。"
  (interactive)
  (let* ((date    (format-time-string "%Y%m%d"))
         (path    (timetrack--daily-path date))
         (entries (timetrack--parse-entries path))
         (tbl     (timetrack--build-summary entries)))
    (timetrack--render-summary (format-time-string "%Y-%m-%d") tbl entries)))

;;;###autoload
(defun timetrack-show-summary-for-date (date)
  "指定日 DATE (YYYYMMDD) の勤怠サマリーを表示する。"
  (interactive (list (read-string "日付 (YYYYMMDD): "
                                  (format-time-string "%Y%m%d"))))
  (unless (string-match-p "^[0-9]\\{8\\}$" date)
    (user-error "日付は YYYYMMDD 形式で入力してください"))
  (let* ((display (format "%s-%s-%s"
                           (substring date 0 4)
                           (substring date 4 6)
                           (substring date 6 8)))
         (path    (timetrack--daily-path date))
         (entries (timetrack--parse-entries path))
         (tbl     (timetrack--build-summary entries)))
    (timetrack--render-summary display tbl entries)))

;;;; キーマップ

;;;###autoload
(defvar timetrack-map
  (let ((m (make-sparse-keymap "Timetrack")))
    (define-key m (kbd "t") #'timetrack-open-today)
    (define-key m (kbd "a") #'timetrack-add-entry)
    (define-key m (kbd "s") #'timetrack-show-summary)
    (define-key m (kbd "S") #'timetrack-show-summary-for-date)
    (define-key m (kbd "m") #'timetrack-open-master)
    m)
  "Timetrack コマンドのキーマップ。
C-c t がプレフィックスとして設定される。")

;; which-key の説明テキスト設定
(with-eval-after-load 'which-key
  ;; C-c t 自体の説明
  (which-key-add-key-based-replacements "C-c t" "勤怠トラッキング")
  ;; 各サブキーの説明
  (which-key-add-keymap-based-replacements timetrack-map
    "t" "今日のファイルを開く"
    "a" "工数エントリを追加"
    "s" "今日のサマリー"
    "S" "日付指定でサマリー"
    "m" "プロジェクト定義を開く"))

(provide 'timetrack)
;;; timetrack.el ends here
