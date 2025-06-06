;; Initialize package system
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Bootstrap use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Configure use-package
(eval-when-compile
  (require 'use-package))
(require 'bind-key)
(setq use-package-always-ensure t)

(load-theme 'dracula t)

;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("603a831e0f2e466480cdc633ba37a0b1ae3c3e9a4e90183833bc4def3421a961"
     default))
 '(package-selected-packages '(magit)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(use-package corfu
  ;; Optional customizations
  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  ;;
(corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
  ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches

  ;; Enable Corfu only for certain modes. See also `global-corfu-modes'.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))

  :init

  ;; Recommended: Enable Corfu globally.  Recommended since many modes provide
  ;; Capfs and Dabbrev can be used globally (M-/).  See also the customization
  ;; variable `global-corfu-modes' to exclude certain modes.
  (global-corfu-mode)

  ;; Enable optional extension modes:
  ;; (corfu-history-mode)
  ;; (corfu-popupinfo-mode)
  )
;; (setq corfu-auto        t
;;       corfu-auto-delay  0  ;; TOO SMALL - NOT RECOMMENDED!
;;       corfu-auto-prefix 0) ;; TOO SMALL - NOT RECOMMENDED!

;; (add-hook 'corfu-mode-hook
;;           (lambda ()
;;             ;; Settings only for Corfu
;;             (setq-local completion-styles '(basic)
;;                         completion-category-overrides nil
;;                         completion-category-defaults nil)))

;; Projectile configuration
(projectile-mode +1)
;; Recommended keymap prefix on Windows/Linux
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

;; Helm configuration
(helm-mode 1)

;; A few more useful configurations...
(use-package emacs
  :custom
  ;; TAB cycle if there are only few candidates
  ;; (completion-cycle-threshold 3)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (tab-always-indent 'complete)

  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil)

  ;; Hide commands in M-x which do not apply to the current mode.  Corfu
  ;; commands are hidden, since they are not used via M-x. This setting is
  ;; useful beyond Corfu.
  (read-extended-command-predicate #'command-completion-default-include-p))

;; Custom Functions
(defun xah-insert-bracket-pair (LBracket RBracket &optional WrapMethod)
  "Insert brackets around selection, word, at point, and maybe move cursor in between.

 LBracket and RBracket are strings. WrapMethod must be either `line' or `block'. `block' means between empty lines.

• If there is a active region, wrap around region.
Else
• If WrapMethod is `line', wrap around line.
• If WrapMethod is `block', wrap around block.
Else
• If cursor is at beginning of line and its not empty line and contain at least 1 space, wrap around the line.
• If cursor is at end of a word or buffer, one of the following will happen:
 xyz▮ → xyz(▮)
 xyz▮ → (xyz▮)       if in one of the lisp modes.
• wrap brackets around word if any. e.g. xy▮z → (xyz▮). Or just (▮)

URL `http://xahlee.info/emacs/emacs/elisp_insert_brackets_by_pair.html'
Created: 2017-01-17
Version: 2025-03-25"
  (if (region-active-p)
      (progn
        (let ((xbeg (region-beginning)) (xend (region-end)))
          (goto-char xend) (insert RBracket)
          (goto-char xbeg) (insert LBracket)
          (goto-char (+ xend 2))))
    (let (xbeg xend)
      (cond
       ((eq WrapMethod 'line)
        (setq xbeg (line-beginning-position) xend (line-end-position))
        (goto-char xend)
        (insert RBracket)
        (goto-char xbeg)
        (insert LBracket)
        (goto-char (+ xend (length LBracket))))
       ((eq WrapMethod 'block)
        (save-excursion
          (seq-setq (xbeg xend) (if (region-active-p) (list (region-beginning) (region-end)) (list (save-excursion (if (re-search-backward "\n[ \t]*\n" nil 1) (match-end 0) (point))) (save-excursion (if (re-search-forward "\n[ \t]*\n" nil 1) (match-beginning 0) (point))))))
          (goto-char xend)
          (insert RBracket)
          (goto-char xbeg)
          (insert LBracket)
          (goto-char (+ xend (length LBracket)))))
       ( ; do line. line must contain space
        (and
         (eq (point) (line-beginning-position))
         (not (eq (line-beginning-position) (line-end-position))))
        (insert LBracket)
        (end-of-line)
        (insert  RBracket))
       ((and
         (or ; cursor is at end of word or buffer. i.e. xyz▮
          (looking-at "[^-_[:alnum:]]")
          (eq (point) (point-max)))
         (not (or
               (eq major-mode 'xah-elisp-mode)
               (eq major-mode 'emacs-lisp-mode)
               (eq major-mode 'lisp-mode)
               (eq major-mode 'lisp-interaction-mode)
               (eq major-mode 'common-lisp-mode)
               (eq major-mode 'clojure-mode)
               (eq major-mode 'xah-clojure-mode)
               (eq major-mode 'scheme-mode))))
        (progn
          (setq xbeg (point) xend (point))
          (insert LBracket RBracket)
          (search-backward RBracket)))
       (t (progn
            ;; wrap around “word”. basically, want all alphanumeric, plus hyphen and underscore, but don't want space or punctuations. Also want chinese chars
            ;; 我有一帘幽梦，不知与谁能共。多少秘密在其中，欲诉无人能懂。
            (skip-chars-backward "-_[:alnum:]")
            (setq xbeg (point))
            (skip-chars-forward "-_[:alnum:]")
            (setq xend (point))
            (goto-char xend)
            (insert RBracket)
            (goto-char xbeg)
            (insert LBracket)
            (goto-char (+ xend (length LBracket)))))))))
(defun xah-insert-paren () (interactive) (xah-insert-bracket-pair "(" ")"))
(defun xah-insert-square-bracket () (interactive) (xah-insert-bracket-pair "[" "]"))
(defun xah-insert-brace () (interactive) (xah-insert-bracket-pair "{" "}"))

(defun xah-insert-ascii-double-quote () (interactive) (xah-insert-bracket-pair "\"" "\""))
(defun xah-insert-ascii-single-quote () (interactive) (xah-insert-bracket-pair "'" "'"))
(defun xah-insert-ascii-angle-bracket () (interactive) (xah-insert-bracket-pair "<" ">"))

(defun xah-insert-emacs-quote () (interactive) (xah-insert-bracket-pair "`" "'"))
(defun xah-insert-markdown-quote () (interactive) (xah-insert-bracket-pair "`" "`"))
(defun xah-insert-markdown-triple-quote () (interactive) (xah-insert-bracket-pair "```\n" "\n```"))

(defun xah-insert-double-curly-quote“” () (interactive) (xah-insert-bracket-pair "“" "”"))
(defun xah-insert-curly-single-quote‘’ () (interactive) (xah-insert-bracket-pair "‘" "’"))
(defun xah-insert-single-angle-quote‹› () (interactive) (xah-insert-bracket-pair "‹" "›"))
(defun xah-insert-double-angle-quote«» () (interactive) (xah-insert-bracket-pair "«" "»"))

(defun xah-insert-corner-bracket「」 () (interactive) (xah-insert-bracket-pair "「" "」"))
(defun xah-insert-white-corner-bracket『』 () (interactive) (xah-insert-bracket-pair "『" "』"))
(defun xah-insert-angle-bracket〈〉 () (interactive) (xah-insert-bracket-pair "〈" "〉"))
(defun xah-insert-double-angle-bracket《》 () (interactive) (xah-insert-bracket-pair "《" "》"))
(defun xah-insert-white-lenticular-bracket〖〗 () (interactive) (xah-insert-bracket-pair "〖" "〗"))
(defun xah-insert-black-lenticular-bracket【】 () (interactive) (xah-insert-bracket-pair "【" "】"))
(defun xah-insert-tortoise-shell-bracket〔〕 () (interactive) (xah-insert-bracket-pair "〔" "〕"))
(defun xah-insert-deco-angle-bracket❮❯ () (interactive) (xah-insert-bracket-pair "❮" "❯"))
(defun xah-insert-deco-angle-fat-bracket❰❱ () (interactive) (xah-insert-bracket-pair "❰" "❱"))

(defun xah-delete-forward-bracket-pairs (&optional DeleteInnerTextQ)
  "Delete the matching brackets to the right of cursor including the inner text.
e.g. ▮(a b c)

In lisp code, if DeleteInnerTextQ is true, also delete the inner text.

After the command, mark is set at the left matching bracket position, so you can `exchange-point-and-mark' to select it.

This command assumes the char to the right of point is a left bracket or quote, and have a matching one after.

What char is considered bracket or quote is determined by current syntax table.

URL `http://xahlee.info/emacs/emacs/emacs_delete_backward_char_or_bracket_text.html'
Version: 2017-07-02 2023-07-30"
  (interactive (list t))
  (if DeleteInnerTextQ
      (progn
        (mark-sexp)
        (kill-region (region-beginning) (region-end)))
    (let ((xpt (point)))
      (forward-sexp)
      (delete-char -1)
      (push-mark (point) t)
      (goto-char xpt)
      (delete-char 1))))

(defun xah-delete-backward-bracket-text ()
  "Delete the matching brackets to the left of cursor, including the inner text.
e.g. (a b c)▮

This command assumes the left of cursor is a right bracket, and there is a matching one before it.

What char is considered bracket or quote is determined by current syntax table.

URL `http://xahlee.info/emacs/emacs/emacs_delete_backward_char_or_bracket_text.html'
Version: 2017-09-21 2023-07-30"
  (interactive)
  (progn
    (forward-sexp -1)
    (mark-sexp)
    (kill-region (region-beginning) (region-end))))

(defun xah-delete-backward-bracket-pair ()
  "Delete the matching brackets/quotes to the left of cursor.
After call, mark is set at the matching bracket position, so you can `exchange-point-and-mark' to select it.

This command assumes the left of point is a right bracket, and there is a matching one before it.

What char is considered bracket or quote is determined by current syntax table.

URL `http://xahlee.info/emacs/emacs/emacs_delete_backward_char_or_bracket_text.html'
Version: 2017-07-02"
  (interactive)
  (let ((xp0 (point)) xp1)
    (forward-sexp -1)
    (setq xp1 (point))
    (goto-char xp0)
    (delete-char -1)
    (goto-char xp1)
    (delete-char 1)
    (push-mark (point) t)
    (goto-char (- xp0 2))))

(defun xah-delete-backward-char-or-bracket-text ()
  "Delete 1 character or delete quote/bracket pair and inner text.
If the char to the left of cursor is a matching pair, delete it along with inner text, push the deleted text to `kill-ring'.

What char is considered bracket or quote is determined by current syntax table.

If `universal-argument' is called first, do not delete inner text.

URL `http://xahlee.info/emacs/emacs/emacs_delete_backward_char_or_bracket_text.html'
Version: 2017-07-02 2023-07-22 2023-07-30"
  (interactive)
  (if (and delete-selection-mode (region-active-p))
      (delete-region (region-beginning) (region-end))
    (cond
     ((prog2 (backward-char) (looking-at "\\s)") (forward-char))
      (if current-prefix-arg
          (xah-delete-backward-bracket-pair)
        (xah-delete-backward-bracket-text))
      ;; (if (string-equal major-mode "xah-wolfram-mode")
      ;;           (let (xisComment (xp0 (point)))
      ;;             (backward-char)
      ;;             (setq xisComment (nth 4 (syntax-ppss)))
      ;;             (goto-char xp0)
      ;;             (if xisComment
      ;;                 (if (forward-comment -1)
      ;;                     (kill-region (point) xp0)
      ;;                   (message "error GSNN2:parsing comment failed."))
      ;;               (if current-prefix-arg
      ;;                   (xah-delete-backward-bracket-pair)
      ;;                 (xah-delete-backward-bracket-text))))
      ;;         (progn
      ;;           (if current-prefix-arg
      ;;               (xah-delete-backward-bracket-pair)
      ;;             (xah-delete-backward-bracket-text))))
      )
     ((prog2 (backward-char) (looking-at "\\s(") (forward-char))
      (message "left of cursor is opening bracket")
      (let (xpOpenBracketLeft
            (xpOpenBracketRight (point)) xisComment)
        (backward-char)
        (setq xpOpenBracketLeft (point))
        (goto-char xpOpenBracketRight)
        (forward-char)
        (setq xisComment (nth 4 (syntax-ppss)))
        (if xisComment
            (progn
              (message "cursor is in comment")
              (goto-char xpOpenBracketLeft)
              (if (forward-comment 1)
                  (kill-region (point) xpOpenBracketLeft)
                (message "error hSnRp: parsing comment failed.")))
          (progn
            (message "right 1 char of cursor is not in comment")
            (goto-char xpOpenBracketLeft)
            (forward-sexp)
            (if current-prefix-arg
                (xah-delete-backward-bracket-pair)
              (xah-delete-backward-bracket-text))))))
     ((prog2 (backward-char) (looking-at "\\s\"") (forward-char))
      (if (nth 3 (syntax-ppss))
          (progn
            (backward-char)
            (xah-delete-forward-bracket-pairs (not current-prefix-arg)))
        (if current-prefix-arg
            (xah-delete-backward-bracket-pair)
          (xah-delete-backward-bracket-text))))
     (t
      (delete-char -1)))))

(defvar xah-brackets '("“”" "()" "[]" "{}" "<>" "＜＞" "（）" "［］" "｛｝" "⦅⦆" "〚〛" "⦃⦄" "‹›" "«»" "「」" "〈〉" "《》" "【】" "〔〕" "⦗⦘" "『』" "〖〗" "〘〙" "｢｣" "⟦⟧" "⟨⟩" "⟪⟫" "⟮⟯" "⟬⟭" "⌈⌉" "⌊⌋" "⦇⦈" "⦉⦊" "❛❜" "❝❞" "❨❩" "❪❫" "❴❵" "❬❭" "❮❯" "❰❱" "❲❳" "〈〉" "⦑⦒" "⧼⧽" "﹙﹚" "﹛﹜" "﹝﹞" "⁽⁾" "₍₎" "⦋⦌" "⦍⦎" "⦏⦐" "⁅⁆" "⸢⸣" "⸤⸥" "⟅⟆" "⦓⦔" "⦕⦖" "⸦⸧" "⸨⸩" "｟｠")
 "A list of strings, each element is a string of 2 chars, the left bracket and a matching right bracket.
Used by `xah-select-text-in-quote' and others.")

(defconst xah-left-brackets
  (mapcar (lambda (x) (substring x 0 1)) xah-brackets)
  "List of left bracket chars. Each element is a string.")

(defconst xah-right-brackets
  (mapcar (lambda (x) (substring x 1 2)) xah-brackets)
  "List of right bracket chars. Each element is a string.")

(defun xah-backward-left-bracket ()
  "Move cursor to the previous occurrence of left bracket.
The list of brackets to jump to is defined by `xah-left-brackets'.

URL `http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html'
Version: 2015-10-01"
  (interactive)
  (re-search-backward (regexp-opt xah-left-brackets) nil t))

(defun xah-forward-right-bracket ()
  "Move cursor to the next occurrence of right bracket.
The list of brackets to jump to is defined by `xah-right-brackets'.

URL `http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html'
Version: 2015-10-01"
  (interactive)
  (re-search-forward (regexp-opt xah-right-brackets) nil t))

(defun xah-goto-matching-bracket ()
  "Move cursor to the matching bracket.
If cursor is not on a bracket, call `backward-up-list'.
The list of brackets to jump to is defined by `xah-left-brackets' and `xah-right-brackets'.

URL `http://xahlee.info/emacs/emacs/emacs_navigating_keys_for_brackets.html'
Version: 2016-11-22 2023-07-22"
  (interactive)
  (if (nth 3 (syntax-ppss))
      (backward-up-list 1 'ESCAPE-STRINGS 'NO-SYNTAX-CROSSING)
    (cond
     ((eq (char-after) ?\") (forward-sexp))
     ((eq (char-before) ?\") (backward-sexp))
     ((looking-at (regexp-opt xah-left-brackets))
      (forward-sexp))
     ((prog2 (backward-char) (looking-at (regexp-opt xah-right-brackets)) (forward-char))
      (backward-sexp))
     (t (backward-up-list 1 'ESCAPE-STRINGS 'NO-SYNTAX-CROSSING)))))

(defun xah-select-text-in-quote ()
  "Select text between the nearest left and right delimiters.
Delimiters here includes QUOTATION MARK, GRAVE ACCENT, and anything in variable `xah-brackets'.
This command ignores nesting. For example, if text is
「(a(b)c▮)」
the selected char is 「c」, not 「a(b)c」.

URL `http://xahlee.info/emacs/emacs/emacs_select_quote_text.html'
Created: 2020-11-24
Version: 2023-11-14"
  (interactive)
  (let ((xskipChars (concat "^\"`" (mapconcat #'identity xah-brackets ""))))
    (skip-chars-backward xskipChars)
    (push-mark (point) t t)
    (skip-chars-forward xskipChars)))

(defun xah-new-empty-buffer ()
  "Create a new empty buffer.
Returns the buffer object.
New buffer is named untitled, untitled<2>, etc.

Warning: new buffer is not prompted for save when killed, see `kill-buffer'.
Or manually `save-buffer'

URL `http://xahlee.info/emacs/emacs/emacs_new_empty_buffer.html'
Created: 2017-11-01
Version: 2022-04-05"
  (interactive)
  (let ((xbuf (generate-new-buffer "untitled")))
    (switch-to-buffer xbuf)
    (funcall initial-major-mode)
    xbuf
    ))

(defvar xah-fly-switch-buffer-map nil "repeat key map for `xah-next-user-buffer' etc.")
(setq xah-fly-switch-buffer-map
      (let ((xkmap (make-sparse-keymap)))
        (define-key xkmap (kbd "<up>") 'xah-previous-emacs-buffer)
        (define-key xkmap (kbd "<down>") 'xah-next-emacs-buffer)
        (define-key xkmap (kbd "<left>") 'xah-previous-user-buffer)
        (define-key xkmap (kbd "<right>") 'xah-next-user-buffer)
        xkmap))

(defun xah-user-buffer-p ()
  "Return t if current buffer is a user buffer, else nil.
A user buffer has buffer name NOT starts with * or space, and is not dired mode, help mode, etc.
This function is used by buffer switching command and close buffer command, so that next buffer shown is a user buffer.
You can override this function to get your idea of “user buffer”.
Created: 2016-06-18
Version: 2024-09-23"
  (interactive)
  (cond
   ((string-match "^\*" (buffer-name)) nil)
   ((eq major-mode 'dired-mode) nil)
   ((eq major-mode 'eww-mode) nil)
   ((eq major-mode 'help-mode) nil)
   (t t)))

(defun xah-next-user-buffer ()
  "Switch to the next user buffer.
User Buffer here is determined by `xah-user-buffer-p'.

Press left or right arrow key to switch to prev next user.
Press up or down arrow to switch to prev next emacs buffer.
Any other key to exit.

URL `http://xahlee.info/emacs/emacs/elisp_next_prev_user_buffer.html'
Created: 2016-06-19
Version: 2024-09-23"
  (interactive)
  (next-buffer)
  (let ((i 0))
    (while (< i 30)
      (if (not (xah-user-buffer-p))
          (progn (next-buffer)
                 (setq i (1+ i)))
        (progn (setq i 100)))))
  (set-transient-map xah-fly-switch-buffer-map))

(defun xah-previous-user-buffer ()
  "Switch to the previous user buffer.
User Buffer here is determined by `xah-user-buffer-p'.

Press left or right arrow key to switch to prev next user.
Press up or down arrow to switch to prev next emacs buffer.
Any other key to exit.

URL `http://xahlee.info/emacs/emacs/elisp_next_prev_user_buffer.html'
Created: 2016-06-19
Version: 2024-05-01"
  (interactive)
  (previous-buffer)
  (let ((i 0))
    (while (< i 29)
      (if (not (xah-user-buffer-p))
          (progn (previous-buffer)
                 (setq i (1+ i)))
        (progn (setq i 100)))))
  (set-transient-map xah-fly-switch-buffer-map))

(defun xah-next-emacs-buffer ()
  "Switch to the next emacs buffer.
Emacs buffer here means `xah-user-buffer-p' return nil.

Press left or right arrow key to switch to prev next user.
Press up or down arrow to switch to prev next emacs buffer.
Any other key to exit.

URL `http://xahlee.info/emacs/emacs/elisp_next_prev_user_buffer.html'
Created: 2013-05-22
Version: 2024-09-16"
  (interactive)
  (next-buffer)
  (let ((i 0))
    (while (and (xah-user-buffer-p) (< i 20))
      (setq i (1+ i)) (next-buffer)))
  (set-transient-map xah-fly-switch-buffer-map))

(defun xah-previous-emacs-buffer ()
  "Switch to the previous emacs buffer.
Emacs buffer here means `xah-user-buffer-p' return nil.

Press left or right arrow key to switch to prev next user.
Press up or down arrow to switch to prev next emacs buffer.
Any other key to exit.

URL `http://xahlee.info/emacs/emacs/elisp_next_prev_user_buffer.html'
Created: 2013-05-22
Version: 2024-09-16"
  (interactive)
  (previous-buffer)
  (let ((i 0))
    (while (and (xah-user-buffer-p) (< i 20))
      (setq i (1+ i)) (previous-buffer)))
  (set-transient-map xah-fly-switch-buffer-map))

(defcustom xah-recently-closed-buffers-max 40 "The maximum length for `xah-recently-closed-buffers'."
  :type 'integer)

(defvar xah-recently-closed-buffers nil "A Alist of recently closed buffers.
Each element is (bufferName . filePath).
The max number to track is controlled by the variable `xah-recently-closed-buffers-max'.")

(defun xah-add-to-recently-closed (&optional BufferName BufferFileName)
  "Add to `xah-recently-closed-buffers'.
Version: 2023-03-02"
  (let ((xbn (if BufferName BufferName (buffer-name)))
        (xbfn (if BufferFileName BufferFileName buffer-file-name)))
    (setq xah-recently-closed-buffers (cons (cons xbn xbfn) xah-recently-closed-buffers)))
  (when (> (length xah-recently-closed-buffers) xah-recently-closed-buffers-max)
    (setq xah-recently-closed-buffers (butlast xah-recently-closed-buffers 1))))

(defvar xah-create-buffer-backup nil "If true, `xah-close-current-buffer' creates a backup file when closing non-file buffer. Version: 2024-11-09")

(setq xah-create-buffer-backup t)

(defvar xah-temp-dir-path nil "Path to temp dir used by xah commands.
by default, the value is dir named temp at `user-emacs-directory'.
Version: 2023-03-21")

(setq xah-temp-dir-path (concat user-emacs-directory "temp/"))

(defun xah-open-last-closed ()
  "Open the last closed file.
URL `http://xahlee.info/emacs/emacs/elisp_close_buffer_open_last_closed.html'
Created: 2016-06-19
Version: 2022-03-22"
  (interactive)
  (if (> (length xah-recently-closed-buffers) 0)
      (find-file (cdr (pop xah-recently-closed-buffers)))
    (progn (message "No recently close buffer in this session."))))

(defun xah-open-recently-closed ()
  "Open recently closed file.
Prompt for a choice.

URL `http://xahlee.info/emacs/emacs/elisp_close_buffer_open_last_closed.html'
Created: 2016-06-19
Version: 2023-09-19"
  (interactive)
  (find-file
   (let ((completion-ignore-case t))
     (completing-read
      "Open:"
      (mapcar (lambda (f) (cdr f)) xah-recently-closed-buffers)
      nil t
      ))))

(defun xah-list-recently-closed ()
  "List recently closed file.

URL `http://xahlee.info/emacs/emacs/elisp_close_buffer_open_last_closed.html'
Version: 2016-06-19"
  (interactive)
  (let ((xbuf (generate-new-buffer "*recently closed*")))
    (switch-to-buffer xbuf)
    (mapc (lambda (xf) (insert (cdr xf) "\n"))
          xah-recently-closed-buffers)))

(defun xah-close-current-buffer ()
  "Close the current buffer with possible backup.

• If the buffer is a file and not modified, kill it. If is modified, do nothing. Print a message.
• If the buffer is not a file, and variable `xah-create-buffer-backup' is true, then save a backup to `xah-temp-dir-path' named untitled_‹datetime›_‹randomhex›.txt.

If `universal-argument' is called first, call `kill-buffer'. (this is useful to force kill.)

If the buffer is a file, add the path to the list `xah-recently-closed-buffers'.

URL `http://xahlee.info/emacs/emacs/elisp_close_buffer_open_last_closed.html'
Created: 2016-06-19
Version: 2025-04-13"
  (interactive)
  (widen)
  (cond
   (current-prefix-arg (kill-buffer))
   ;; ((eq major-mode 'minibuffer-inactive-mode) (minibuffer-keyboard-quit))
   ;; ((active-minibuffer-window) (minibuffer-keyboard-quit))
   ((minibufferp (current-buffer)) (minibuffer-keyboard-quit))

   ((eq major-mode 'dired-mode)
    (xah-add-to-recently-closed (buffer-name) default-directory)
    (kill-buffer))

   ((and buffer-file-name (not (buffer-modified-p)))
    (xah-add-to-recently-closed (buffer-name) buffer-file-name)
    (kill-buffer))

   ((and buffer-file-name (buffer-modified-p))
    (message "buffer file modified. Save it first.\n%s" buffer-file-name))
   ((and xah-create-buffer-backup (not buffer-file-name) (xah-user-buffer-p) (not (eq (point-max) 1)))
    (let ((xnewName (format "%suntitled_%s_%x.txt"
                            xah-temp-dir-path
                            (format-time-string "%Y-%m-%d_%H%M%S")
                            (random #xfffff))))
      (when (not (file-exists-p xah-temp-dir-path)) (make-directory xah-temp-dir-path))
      (write-region (point-min) (point-max) xnewName)
      (xah-add-to-recently-closed (buffer-name) xnewName)
      (kill-buffer)))
   (t (kill-buffer))))

(defun xah-copy-file-path (&optional DirPathOnlyQ)
  "Copy current buffer file path or dired path.
Result is full path.
If `universal-argument' is called first, copy only the dir path.

If in dired, copy the current or marked files.

If a buffer is not file and not dired, copy value of `default-directory'.

URL `http://xahlee.info/emacs/emacs/emacs_copy_file_path.html'
Created: 2018-06-18
Version: 2021-09-30"
  (interactive "P")
  (let ((xfpath
         (if (eq major-mode 'dired-mode)
             (progn
               (let ((xresult (mapconcat #'identity
                                         (dired-get-marked-files) "\n")))
                 (if (equal (length xresult) 0)
                     (progn default-directory )
                   (progn xresult))))
           (if buffer-file-name
               buffer-file-name
             (expand-file-name default-directory)))))
    (kill-new
     (if DirPathOnlyQ
         (progn
           (message "Directory copied: %s" (file-name-directory xfpath))
           (file-name-directory xfpath))
       (progn
         (message "File path copied: %s" xfpath)
         xfpath )))))

(defun xah-select-line ()
  "Select current line. If region is active, extend selection downward by line.
If `visual-line-mode' is on, consider line as visual line.

URL `http://xahlee.info/emacs/emacs/emacs_select_line.html'
Version: 2017-11-01 2023-07-16 2023-11-14"
  (interactive)
  (if (region-active-p)
      (if visual-line-mode
          (let ((xp1 (point)))
            (end-of-visual-line 1)
            (when (eq xp1 (point))
              (end-of-visual-line 2)))
        (progn
          (forward-line 1)
          (end-of-line)))
    (if visual-line-mode
        (progn (beginning-of-visual-line)
               (push-mark (point) t t)
               (end-of-visual-line))
      (progn
        (push-mark (line-beginning-position) t t)
        (end-of-line)))))

(defun xah-beginning-of-line-or-block ()
  "Move cursor to beginning of indent or line, end of previous block, in that order.

If `visual-line-mode' is on, beginning of line means visual line.

URL `http://xahlee.info/emacs/emacs/emacs_move_by_paragraph.html'
Created: 2018-06-04
Version: 2024-10-30"
  (interactive)
  (let ((xp (point)))
    (if (or (eq (point) (line-beginning-position))
            (eq last-command this-command))
        (when (re-search-backward "\n[\t\n ]*\n+" nil 1)
          (skip-chars-backward "\n\t ")
          ;; (forward-char)
          )
      (if visual-line-mode
          (beginning-of-visual-line)
        (if (eq major-mode 'eshell-mode)
            (beginning-of-line)
          (back-to-indentation)
          (when (eq xp (point))
            (beginning-of-line)))))))

(defun xah-end-of-line-or-block ()
  "Move cursor to end of line or next block.

• When called first time, move cursor to end of line.
• When called again, move cursor forward by jumping over any sequence of whitespaces containing 2 blank lines.
• if `visual-line-mode' is on, end of line means visual line.

URL `http://xahlee.info/emacs/emacs/emacs_move_by_paragraph.html'
Created: 2018-06-04
Version: 2024-10-30"
  (interactive)
  (if (or (eq (point) (line-end-position))
          (eq last-command this-command))
      (re-search-forward "\n[\t\n ]*\n+" nil 1)
    (if visual-line-mode
        (end-of-visual-line)
      (end-of-line))))

(defvar xah-punctuation-regex nil "A regex string for the purpose of moving cursor to a punctuation.")
(setq xah-punctuation-regex "[\"=+]")

(defun xah-forward-punct ()
  "Move cursor to the next occurrence of punctuation.
Punctuations is defined by `xah-punctuation-regex'

URL `http://xahlee.info/emacs/emacs/emacs_jump_to_punctuations.html'
Version 2017-06-26 2024-01-20"
  (interactive)
  (re-search-forward xah-punctuation-regex nil t))

(defun xah-backward-punct ()
  "Move cursor to the previous occurrence of punctuation.
See `xah-forward-punct'

URL `http://xahlee.info/emacs/emacs/emacs_jump_to_punctuations.html'
Version 2017-06-26 2024-01-20"
  (interactive)
  (re-search-backward xah-punctuation-regex nil t))

(defun xah-select-block ()
  "Select the current/next block plus 1 blankline.
If region is active, extend selection downward by block.

URL `http://xahlee.info/emacs/emacs/emacs_select_text_block.html'
Created: 2019-12-26
Version: 2023-11-14"
  (interactive)
  (if (region-active-p)
      (re-search-forward "\n[ \t]*\n[ \t]*\n*" nil 1)
    (progn
      (skip-chars-forward " \n\t")
      (when (re-search-backward "\n[ \t]*\n" nil 1)
        (goto-char (match-end 0)))
      (push-mark (point) t t)
      (re-search-forward "\n[ \t]*\n" nil 1))))

(defun xah-delete-current-text-block ()
  "Delete the current text block plus blank lines, or selection, and copy to `kill-ring'.

If cursor is between blank lines, delete following blank lines.

URL `http://xahlee.info/emacs/emacs/emacs_delete_block.html'
Created: 2017-07-09
Version: 2024-10-07"
  (interactive)
  (let (xbeg xend (xp (point)))
    (if (region-active-p)
        (setq xbeg (region-beginning) xend (region-end))
      (progn
        (setq xbeg
              (if (re-search-backward "\n[ \t]*\n+" nil 1)
                  (match-end 0)
                (point)))
        (goto-char xp)
        (setq xend (if (re-search-forward "\n[ \t]*\n+" nil 1)
                       (match-end 0)
                     (point-max)))))
    (kill-region xbeg xend)))

(defun xah-copy-line-or-region ()
  "Copy current line or selection.

Copy current line. When called repeatedly, append copy subsequent lines.
Except:

If `universal-argument' is called first, copy whole buffer (respects `narrow-to-region').
If `rectangle-mark-mode' is on, copy the rectangle.
If `region-active-p', copy the region.

URL `http://xahlee.info/emacs/emacs/emacs_copy_cut_current_line.html'
Created: 2010-05-21
Version: 2024-06-19"
  (interactive)
  (cond
   (current-prefix-arg (copy-region-as-kill (point-min) (point-max)))
   ((and (boundp 'rectangle-mark-mode) rectangle-mark-mode)
    (copy-region-as-kill (region-beginning) (region-end) t))
   ((region-active-p) (copy-region-as-kill (region-beginning) (region-end)))
   ((eq last-command this-command)
    (if (eobp)
        nil
      (progn
        (kill-append "\n" nil)
        (kill-append (buffer-substring (line-beginning-position) (line-end-position)) nil)
        (end-of-line)
        (forward-char))))
   ((eobp)
    (if (eq (char-before) 10)
        (progn)
      (progn
        (copy-region-as-kill (line-beginning-position) (line-end-position))
        (end-of-line))))
   (t
    (copy-region-as-kill (line-beginning-position) (line-end-position))
    (end-of-line)
    (forward-char))))

(defun xah-cut-line-or-region ()
  "Cut current line or selection.
When `universal-argument' is called first, cut whole buffer (respects `narrow-to-region').

URL `http://xahlee.info/emacs/emacs/emacs_copy_cut_current_line.html'
Version: 2010-05-21 2015-06-10"
  (interactive)
  (if current-prefix-arg
      (progn ; not using kill-region because we don't want to include previous kill
        (kill-new (buffer-string))
        (delete-region (point-min) (point-max)))
    (progn (if (region-active-p)
               (kill-region (region-beginning) (region-end) t)
             (kill-region (line-beginning-position) (line-beginning-position 2))))))

(defun xah-copy-all-or-region ()
  "Put the whole buffer content to `kill-ring', or text selection if there's one.
Respects `narrow-to-region'.
URL `http://xahlee.info/emacs/emacs/emacs_copy_cut_all_or_region.html'
Version 2015-08-22"
  (interactive)
  (if (use-region-p)
      (progn
        (kill-new (buffer-substring (region-beginning) (region-end)))
        (message "Text selection copied."))
    (progn
      (kill-new (buffer-string))
      (message "Buffer content copied."))))

(defun xah-cut-all-or-region ()
  "Cut the whole buffer content to `kill-ring', or text selection if there's one.
Respects `narrow-to-region'.
URL `http://xahlee.info/emacs/emacs/emacs_copy_cut_all_or_region.html'
Version 2015-08-22"
  (interactive)
  (if (use-region-p)
      (progn
        (kill-new (buffer-substring (region-beginning) (region-end)))
        (delete-region (region-beginning) (region-end)))
    (progn
      (kill-new (buffer-string))
      (delete-region (point-min) (point-max)))))

(defun xah-show-kill-ring ()
  "Insert all `kill-ring' content in a new buffer named *copy history*.

URL `http://xahlee.info/emacs/emacs/emacs_show_kill_ring.html'
Created: 2019-12-02
Version: 2024-05-07"
  (interactive)
  (let ((xbuf (generate-new-buffer "*copy history*"))
        (inhibit-read-only t))
    (progn
      (switch-to-buffer xbuf)
      (funcall 'fundamental-mode)
      (mapc
       (lambda (x)
         (insert x "\n\nsss97707------------------------------------------------\n\n" ))
       kill-ring))
    (goto-char (point-min))))

(defun xah-clean-whitespace ()
  "Delete trailing whitespace, and replace repeated blank lines to just 1.
Only space and tab is considered whitespace here.
Works on whole buffer or selection, respects `narrow-to-region'.

URL `http://xahlee.info/emacs/emacs/elisp_compact_empty_lines.html'
Created: 2017-09-22
Version: 2022-08-06"
  (interactive)
  (let (xbegin xend)
    (if (region-active-p)
        (setq xbegin (region-beginning) xend (region-end))
      (setq xbegin (point-min) xend (point-max)))
    (save-excursion
      (save-restriction
        (narrow-to-region xbegin xend)
        (goto-char (point-min))
        (while (re-search-forward "[ \t]+\n" nil 1) (replace-match "\n"))
        (goto-char (point-min))
        (while (re-search-forward "\n\n\n+" nil 1) (replace-match "\n\n"))
        (goto-char (point-max))
        (while (eq (char-before) 32) (delete-char -1)))))
  (message "%s done" real-this-command))

(defun xah-clean-empty-lines ()
  "Replace repeated blank lines to just 1, in whole buffer or selection.
Respects `narrow-to-region'.

URL `http://xahlee.info/emacs/emacs/elisp_compact_empty_lines.html'
Created: 2017-09-22
Version: 2020-09-08"
  (interactive)
  (let (xbegin xend)
    (if (region-active-p)
        (setq xbegin (region-beginning) xend (region-end))
      (setq xbegin (point-min) xend (point-max)))
    (save-excursion
      (save-restriction
        (narrow-to-region xbegin xend)
        (progn
          (goto-char (point-min))
          (while (re-search-forward "\n\n\n+" nil 1)
            (replace-match "\n\n")))))))

(defun xah-quote-lines (QuoteL QuoteR Sep)
  "Add quotes/brackets and separator (comma) to lines.
Act on current block or selection.

For example,

 cat
 dog
 cow

becomes

 \"cat\",
 \"dog\",
 \"cow\",

or

 (cat)
 (dog)
 (cow)

In lisp code, QuoteL QuoteR Sep are strings.

URL `http://xahlee.info/emacs/emacs/emacs_quote_lines.html'
Created: 2020-06-26
Version: 2025-03-25"
  (interactive
   (let ((xbrackets
          '(
            "\"QUOTATION MARK\""
            "'APOSTROPHE'"
            "(paren)"
            "{brace}"
            "[square]"
            "<greater>"
            "`emacs'"
            "`markdown`"
            "~tilde~"
            "=equal="
            "“curly double”"
            "‘curly single’"
            "‹french angle›"
            "«french double angle»"
            "「corner」"
            "none"
            "other"
            ))
         (xcomma '("comma ," "semicolon ;" "none" "other"))
         xbktChoice xsep xsepChoice xquoteL xquoteR)
     (let ((completion-ignore-case t))
       (setq xbktChoice (completing-read "Quote to use:" xbrackets nil t nil nil (car xbrackets)))
       (setq xsepChoice (completing-read "line separator:" xcomma nil t nil nil (car xcomma))))
     (cond
      ((string-equal xbktChoice "none")
       (setq xquoteL "" xquoteR ""))
      ((string-equal xbktChoice "other")
       (let ((xx (read-string "Enter 2 chars, for begin/end quote:")))
         (setq xquoteL (substring xx 0 1)
               xquoteR (substring xx 1 2))))
      (t (setq xquoteL (substring xbktChoice 0 1)
               xquoteR (substring xbktChoice -1))))
     (setq xsep
           (cond
            ((string-equal xsepChoice "comma ,") ",")
            ((string-equal xsepChoice "semicolon ;") ";")
            ((string-equal xsepChoice "none") "")
            ((string-equal xsepChoice "other") (read-string "Enter separator:"))
            (t xsepChoice)))
     (list xquoteL xquoteR xsep)))
  (let (xbeg xend (xquoteL QuoteL) (xquoteR QuoteR) (xsep Sep))
    (seq-setq (xbeg xend) (if (region-active-p) (list (region-beginning) (region-end)) (list (save-excursion (if (re-search-backward "\n[ \t]*\n" nil 1) (match-end 0) (point))) (save-excursion (if (re-search-forward "\n[ \t]*\n" nil 1) (match-beginning 0) (point))))))
    (save-excursion
      (save-restriction
        (narrow-to-region xbeg xend)
        (goto-char (point-min))
        (catch 'EndReached
          (while t
            (skip-chars-forward "\t ")
            (insert xquoteL)
            (end-of-line)
            (insert xquoteR xsep)
            (if (eq (point) (point-max))
                (throw 'EndReached t)
              (forward-char))))))))

;; newline below point without breaking current line
(defun newline-without-break-of-line ()
  "1. move to end of line
  2. insert new line with index"
  (interactive)
  (let ((oldpos (point)))
    (end-of-line)
    (newline-and-indent)))

;; eval buffer if file name is .emacs
(defun eval-buffer-when-emacs-config ()
  "1. check if buffer is emacs config (.emacs)
  2. eval-buffer"
  (interactive)
  (if (string= (buffer-name) ".emacs")
      (eval-buffer)))

;; Preferences
(setq mac-command-modifier 'meta)
(setq initial-buffer-choice 'xah-new-empty-buffer)

;; highlight matching paren
(show-paren-mode 1)

;; highlight brackets if visible, else entire expression
(setq show-paren-style 'mixed)

(setq-default indent-tabs-mode nil)
(setq tab-always-indent 'complete)

;; Make TAB smartly complete
(setq tab-always-indent 'complete)

;; Optional: fallback to default tab behavior if no completion
(setq corfu-auto-prefix 1)
(setq corfu-auto nil) ;; Only show menu when manually triggered

;; Keybindings
(global-set-key (kbd "M-7") 'xah-insert-brace) ; {}
(global-set-key (kbd "M-8") 'xah-insert-paren) ; ()
(global-set-key (kbd "M-9") 'xah-insert-square-bracket) ; []

(global-set-key (kbd "DEL") 'xah-delete-backward-char-or-bracket-text)

(global-set-key (kbd "C-7") 'xah-backward-left-bracket)
(global-set-key (kbd "C-8") 'xah-forward-right-bracket)

(global-set-key (kbd "C-9") 'xah-goto-matching-bracket)

(global-set-key (kbd "C-`") 'xah-select-text-in-quote)

(global-set-key (kbd "C-4") 'xah-previous-emacs-buffer)
(global-set-key (kbd "C-5") 'xah-next-emacs-buffer)

(global-set-key (kbd "C-M-w") 'xah-close-current-buffer)
(global-set-key (kbd "C-M-t") 'xah-open-last-closed)

(global-set-key (kbd "M-/") 'xah-copy-file-path)
(global-set-key (kbd "M-3") 'xah-cut-line-or-region)
(global-set-key (kbd "M-4") 'xah-copy-line-or-region)
(global-set-key (kbd "C-w") 'xah-cut-all-or-region)
(global-set-key (kbd "M-w") 'xah-copy-all-or-region)
(global-set-key (kbd "C-6") 'xah-show-kill-ring)

(global-set-key (kbd "C-M-l") 'xah-select-line)
(global-set-key (kbd "C-M-n") 'xah-select-block)
(global-set-key (kbd "C-q") 'xah-quote-lines)

(global-set-key (kbd "C-a") 'xah-beginning-of-line-or-block)
(global-set-key (kbd "C-e") 'xah-end-of-line-or-block)

(global-set-key (kbd "C-1") 'xah-backward-punct)
(global-set-key (kbd "C-2") 'xah-forward-punct)

;; Make one for C-DEL to kill line to end of backward

(global-set-key (kbd "C-M-DEL") 'xah-delete-current-text-block)

(global-set-key (kbd "C-c") 'xah-clean-empty-lines)

(global-set-key (kbd "C-3") 'ibuffer)

;; Use ibuffer instead of buffer list
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; Newline becomes newline and indent, without breaking current line
(global-set-key (kbd "C-o") 'newline-without-break-of-line)

;; Helm keybinding remaps
(global-set-key (kbd "M-x") #'helm-M-x)
(global-set-key (kbd "C-x r b") #'helm-filtered-bookmarks)
(global-set-key (kbd "C-x C-f") #'helm-find-files)

;; Hooks
(add-hook 'before-save-hook 'xah-clean-whitespace)

;; Eval config on save
(add-hook 'after-save-hook 'eval-buffer-when-emacs-config)

;; Display startup time
(message "emacs init time %s" (emacs-init-time))
