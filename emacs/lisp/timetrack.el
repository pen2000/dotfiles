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
;;   C-c t i  clock-in (作業開始)
;;   C-c t o  clock-out (作業終了・テーブル追記)
;;   C-c t c  clock 状態確認
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

;;;; 補完ヘルパー

(defun timetrack--completing-read (prompt collection)
  "部分一致補完を使って PROMPT で COLLECTION から選択する。"
  (let ((completion-styles '(basic substring partial-completion)))
    (completing-read prompt collection nil nil)))

;;;; 定義ファイル

(defun timetrack--create-master ()
  "定義ファイルのテンプレートを作成する。"
  (with-temp-file (timetrack--master-path)
    (insert "#+TITLE: プロジェクト・フェーズ定義\n\n")
    (insert "* プロジェクト一覧\n\n")
    (insert "プロジェクト名とフェーズを追加してください。\n")
    (insert "フェーズが不要な場合は空欄にしてください。\n\n")
    (insert "| プロジェクト名 | フェーズ | PJコード |\n")
    (insert "|--------------|----------|----------|\n")
    (insert "| サンプルPJ | 設計 | PJ001 |\n")
    (insert "| サンプルPJ | 実装 | PJ001 |\n")
    (insert "| サンプルPJ | テスト | PJ001 |\n")
    (insert "| デイリーミーティング | | |\n")))

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

;;;; エントリ追加 (共通)

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

(defun timetrack--insert-entry (project phase task hours-str)
  "PROJECT/PHASE/TASK/HOURS-STR を今日の日次ファイルに追記する。"
  (let* ((path  (timetrack--daily-path))
         (today (format-time-string "%Y-%m-%d")))
    (unless (file-exists-p path)
      (timetrack--create-daily path today))
    (let* ((buf       (find-file-noselect path))
           (table-end (timetrack--find-table-end buf)))
      (with-current-buffer buf
        (if table-end
            (progn
              (goto-char table-end)
              (end-of-line)
              (insert (format "\n| %s | %s | %s | %s |"
                              project phase task hours-str)))
          (goto-char (point-max))
          (insert "\n* 作業記録\n\n| プロジェクト | フェーズ | タスク名 | 工数 |\n")
          (insert "|-------------|---------|---------|------|\n")
          (insert (format "| %s | %s | %s | %s |" project phase task hours-str)))
        (save-buffer)))))

;;;###autoload
(defun timetrack-add-entry ()
  "工数エントリを今日の勤怠ファイルに追加する。"
  (interactive)
  (timetrack--ensure-dir)
  (let* ((master   (timetrack--read-master))
         (projects (mapcar #'car master))
         (project  (timetrack--completing-read "プロジェクト: " projects))
         (phases   (cdr (assoc project master)))
         (phase    (cond
                    (phases
                     (timetrack--completing-read "フェーズ: "
                                                (append phases (list ""))))
                    (t (read-string "フェーズ (空でOK): "))))
         (task     (read-string "タスク名: "))
         (hours    (read-string "工数 (例: 1.5): ")))
    (unless (string-match-p "^[0-9]+\\.?[0-9]*$" hours)
      (user-error "工数は数値で入力してください: %s" hours))
    (timetrack--insert-entry project phase task hours)
    (message "追加: %s | %s | %s | %s 時間" project phase task hours)))

;;;; Clock-in / Clock-out

(defvar timetrack--current-clock nil
  "実行中のクロック: (project phase task start-time) または nil。")

(defvar timetrack--update-timer nil
  "モードライン更新用タイマー。")

(defun timetrack--format-elapsed (seconds)
  "SECONDS を H:MM 形式の文字列に変換する。"
  (let* ((total-mins (floor (/ seconds 60)))
         (hours      (floor (/ total-mins 60)))
         (mins       (mod total-mins 60)))
    (format "%d:%02d" hours mins)))

(defun timetrack--mode-line-indicator ()
  "モードライン表示用の文字列を返す。clock-in 中のみ値を返す。"
  (when timetrack--current-clock
    (let* ((elapsed (float-time (time-subtract (current-time)
                                               (nth 3 timetrack--current-clock))))
           (task    (nth 2 timetrack--current-clock)))
      (format " [⏱%s %s]"
              (timetrack--format-elapsed elapsed)
              task))))

(defun timetrack--start-mode-line-timer ()
  "アイドル時のモードライン強制更新タイマーを開始する。"
  (unless timetrack--update-timer
    (setq timetrack--update-timer
          (run-with-timer 0 60 #'force-mode-line-update t))))

(defun timetrack--stop-mode-line-timer ()
  "モードライン更新タイマーを停止する。"
  (when timetrack--update-timer
    (cancel-timer timetrack--update-timer)
    (setq timetrack--update-timer nil)
    (force-mode-line-update t)))

(defun timetrack--select-project-phase ()
  "プロジェクト・フェーズをインタラクティブに選択し (project phase) を返す。"
  (let* ((master   (timetrack--read-master))
         (projects (mapcar #'car master))
         (project  (timetrack--completing-read "プロジェクト: " projects))
         (phases   (cdr (assoc project master)))
         (phase    (cond
                    (phases
                     (timetrack--completing-read "フェーズ: "
                                                (append phases (list ""))))
                    (t (read-string "フェーズ (空でOK): ")))))
    (list project phase)))

;;;###autoload
(defun timetrack-clock-in ()
  "作業の開始時刻を記録する (clock-in)。"
  (interactive)
  (timetrack--ensure-dir)
  (when timetrack--current-clock
    (unless (y-or-n-p
             (format "現在「%s」が進行中です。切り替えますか? "
                     (nth 2 timetrack--current-clock)))
      (user-error "clock-in をキャンセルしました")))
  (let* ((proj-phase (timetrack--select-project-phase))
         (project    (nth 0 proj-phase))
         (phase      (nth 1 proj-phase))
         (task       (read-string "タスク名: ")))
    (setq timetrack--current-clock (list project phase task (current-time)))
    (timetrack--start-mode-line-timer)
    (message "clock-in: %s / %s / %s [%s]"
             project phase task (format-time-string "%H:%M"))))

;;;###autoload
(defun timetrack-clock-out ()
  "作業の終了時刻を記録し、工数エントリをテーブルに追加する (clock-out)。"
  (interactive)
  (unless timetrack--current-clock
    (user-error "現在 clock-in されていません"))
  (let* ((project (nth 0 timetrack--current-clock))
         (phase   (nth 1 timetrack--current-clock))
         (task    (nth 2 timetrack--current-clock))
         (start   (nth 3 timetrack--current-clock))
         (elapsed (float-time (time-subtract (current-time) start)))
         (hours   (/ elapsed 3600.0))
         (hours-str (format "%.2f" hours)))
    (setq timetrack--current-clock nil)
    (timetrack--stop-mode-line-timer)
    (timetrack--insert-entry project phase task hours-str)
    (message "clock-out: %s / %s / %s → %.2f h" project phase task hours)))

;;;###autoload
(defun timetrack-clock-status ()
  "現在のクロック状態を表示する。"
  (interactive)
  (if timetrack--current-clock
      (let* ((project (nth 0 timetrack--current-clock))
             (phase   (nth 1 timetrack--current-clock))
             (task    (nth 2 timetrack--current-clock))
             (start   (nth 3 timetrack--current-clock))
             (elapsed (float-time (time-subtract (current-time) start))))
        (message "進行中: %s / %s / %s (経過 %s)"
                 project phase task
                 (timetrack--format-elapsed elapsed)))
    (message "現在 clock-in されていません")))

;;;; モードライン登録

(unless (member '(:eval (timetrack--mode-line-indicator)) global-mode-string)
  (add-to-list 'global-mode-string '(:eval (timetrack--mode-line-indicator)) t))

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
    (define-key m (kbd "i") #'timetrack-clock-in)
    (define-key m (kbd "o") #'timetrack-clock-out)
    (define-key m (kbd "c") #'timetrack-clock-status)
    (define-key m (kbd "s") #'timetrack-show-summary)
    (define-key m (kbd "S") #'timetrack-show-summary-for-date)
    (define-key m (kbd "m") #'timetrack-open-master)
    m)
  "Timetrack コマンドのキーマップ。
C-c t がプレフィックスとして設定される。")

;; which-key の説明テキスト設定
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements "C-c t" "勤怠トラッキング")
  (which-key-add-keymap-based-replacements timetrack-map
    "t" "今日のファイルを開く"
    "a" "工数エントリを追加"
    "i" "clock-in (作業開始)"
    "o" "clock-out (作業終了)"
    "c" "clock 状態確認"
    "s" "今日のサマリー"
    "S" "日付指定でサマリー"
    "m" "プロジェクト定義を開く"))

(provide 'timetrack)
;;; timetrack.el ends here
