;;; advance-words-count.el --- A Package Provides Extended `count-words'
;;
;; Filename: advance-words-count.el
;; Description: Provides Extended `count-words' function.
;; Author: LdBeth
;; Maintainer: LdBeth
;; Created: Wed Mar 29 14:42:25 2017 (+0800)
;; Version: 0.8.1
;; Package-Requires: (pos-tip)
;; Last-Updated:
;;           By:
;;     Update #: 0
;; URL:
;; Doc URL:
;; Keywords:
;; Compatibility:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:
(defgroup andvance-words-count nil
  "Extended `count-words' function."
  :prefix "words-count"
  :group 'text)

(defcustom words-count-rule-chinese "\\cc"
  "A regexp string to match Chinese characters."
  :group 'advance-words-count
  :type 'string)

(defcustom words-count-rule-nonespace "[^[:space:]]"
  "A regexp string to match none space characters."
  :group 'advance-words-count
  :type 'string)

(defcustom words-count-rule-ansci "[A-Za-z0-9][A-Za-z0-9[:punct:]]*"
  "A regexp string to match ANSCII characters."
  :group 'advance-words-count
  :type 'string)

(defcustom words-count-regexp-list
  (list words-count-rule-chinese
        words-count-rule-nonespace
        words-count-rule-ansci)
  "A list for the regexp used in `advance-words-count'."
  :group 'advance-words-count
  :type '(repeat regexp))

(defcustom words-count-message-func 'format-message--words-count
  "The function used to format message in `advance-words-count'."
  :group 'advance-words-count
  :type '(function))

(defcustom words-count-message-display 'minibuffer
  "The way how `message--words-count' display messages."
  :group 'advance-words-count
  :type '(choice (const minibuffer)
                 (const pos-tip)))

(defun special--words-count (start end regexp)
  "Count the word from START to END with REGEXP."
  (let ((count 0))
    (save-excursion
      (save-restriction
        (goto-char start)
        (while (and (< (point) end) (re-search-forward regexp end t))
          (setq count (1+ count)))))
    count))

(defun format-message--words-count (list start end &optional arg)
  "Format a string to be shown for `message--words-count'.
Using the LIST passed form `advance-words-count'. START & END are
required to call extra functions, see `count-lines' &
`count-words'. When ARG is specified, display verbosely."
  (format
   (if arg
       "
-----------~*~ Words Count ~*~----------

 Characters (without Space) .... %d
 Characters (all) .............. %d
 Number of Lines ............... %d
 ANSCII Words .................. %d
%s
========================================
"
     "Ns:%d, Al:%d, Ln:%d, An:%d, %s")
   (cadr list)
   (- end start)
   (count-lines start end)
   (car (last list))
   (if (= 0 (car list))
       (format (if arg
                   " Latin Words ................... %d\n"
                 "La:%d")
               (count-words start end))
     (format (if arg
                 " CJK Chars ..................... %d
 Word Count .................... %d\n"
               "Ha:%d, Wc:%d")
             (car list)
             (+ (car list) (car (last list)))))))

(defmacro words-count-define-func (name message rules &optional bind)
  "foo"
  `(progn
     (defun ,name (list start end &optional arg)
       "Format a string to be shown for `message--words-count'.
Using the LIST passed form `advance-words-count'. START & END are
required to call extra functions, see `count-lines' &
`count-words'. When ARG is specified, display verbosely."
       (format ,message ,rules))
     (if ,bind
         (setq words-count-message-func ,name))))

;; (defmacro words-count-define-func (name message rules &optional bind verbo opt end)
;;   "foo"
;;   (let* ((string (if verbo
;;                      `(if arg
;;                           ,message
;;                         ,verbo)
;;                    message))
;;          body)
;;     (if opt
;;         (setq body `(concat
;;                      (format
;;                       ,string ,rules)
;;                      ,(words-count--build-cond opt)
;;                      end)
;;               (setq body `(format ,message ,rules)))
;;       `(progn
;;          (defun ,name (list start end &optional arg)
;;            "Format a string to be shown for `message--words-count'.
;; Using the LIST passed form `advance-words-count'. START & END are
;; required to call extra functions, see `count-lines' &
;; `count-words'. When ARG is specified, display verbosely."
;;            body)
;;          (if ,bind
;;              (setq words-count-message-func ,name))))))

;; (defun words-count--build-cond (opt)
;;   "zz"
;;   (let ((cache opt)
;;         arg
;;         op)
;;     (when cache
;;       (progn
;;         (setq arg (pop cache))
;;         (list 'if (car arg) 'arg (cadr arg))))))

(require 'pos-tip)

(defun message--words-count (list &optional arg)
  "Display the word count message.
Using tool specified in `words-count-message-display'. The LIST
will be passed to `format-message--words-count'. See
`words-count-message-func'. If ARG is not ture, display in the
minibuffer."
  (let ((opt words-count-message-display)
        (string (apply words-count-message-func list))
        (time nil))
    (if (null arg)
        (message string)
      (cond
       ((eq opt 'pos-tip)
        ;; Use `run-at-time' to avoid the problem caued by `flycheck-pos-tip'.
        (run-at-time 0.1 nil #'pos-tip-show string nil nil nil -1))
       ((eq 'minibuffer opt)
        (message string))))))

;;;###autoload
(defun advance-words-count (beg end &optional arg)
  "Chinese user preferred word count.
If BEG = END, count the whole buffer. If called initeractively,
use minibuffer to display the messages. The optional ARG will be
passed to `format-message--words-count' to decide the style of
display.

See also `special-words-count'."
  (interactive (if (use-region-p)
                   (list (region-beginning)
                         (region-end)
                         (or current-prefix-arg nil))
                 (list nil nil (or current-prefix-arg nil))))
  (if (called-interactively-p 'any)
      (message--words-count (advance-words-count beg end arg)
                            (if arg t))
    (let ((min (or beg (point-min)))
          (max (or end (point-max))))
      (mapcar
       (lambda (r) (special--words-count min max r))
       words-count-regexp-list))))

(provide 'advance-words-count)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; advance-words-count.el ends here
