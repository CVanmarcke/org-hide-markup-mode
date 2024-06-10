;;; org-hide-markup-mode.el --- Hide org markup      -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Free Software Foundation, Inc.
;;
;; Author: CVanmarcke
;; URL: https://github.com/cvanmarcke/org-hide-markup-mode
;; Version: 1
;; Keywords: org, text, markup
;; Package-Requires: ((emacs "29.1"))

;;; Commentary:
;;
;; TODO

;;; Code:

(require 'org)

(defgroup org-hide-markup-mode nil
  "Hide markup text for org mode."
  :group 'org
  :prefix "org-hide-markup-")

(defcustom org-hide-markup-keywords-re "\\(\n\\#\\+\\(STARTUP\\:.+\\|filetags\\:\\|ATTR_\\(ORG\\|HTML\\)\\:.+\\)\\|\\#\\+title\\: *\\)"
  "Matches to the regex sequence will be hidden"
  :type 'regexp
  :group 'org-hide-markup-mode)

(defconst org-hide-markup-property-drawer-re
  (concat "^[ \t]*:PROPERTIES:[ \t]*\n"
          "\\(?:[ \t]*:\\S-+:\\(?:[ \t].*\\)?[ \t]*\n\\)*?"
          "[ \t]*:END:[ \t]*$")
  "Matches an entire property drawer. Basically `org-property-drawer-re' with a newline instead of $ at the end.")

(defcustom org-shorten-citations-re "\\[\\(cite:\\)@[a-z-]+\\([A-Z0-9]\\w\\{15,\\}\\)\\(\\]\\|;@\\)"
  "Regular expression that matches strings where the invisible-property is set."
  :type 'regexp
  :group 'org-hide-markup-mode)

(defcustom org-shorten-long-citations-re ";@[a-z-]+\\([A-Z0-9]\\w\\{15,\\}\\)"
  "Regular expression that matches strings where the invisible-property is set."
  :type 'regexp
  :group 'org-hide-markup-mode)

(defcustom org-hide-markup--also-toggle-links t
  "If non-nil, also toggle `org-toggle-link-display' on toggling `org-hide-markup-mode'"
  :type 'boolean
  :group 'org-hide-markup-mode)

(defcustom org-hide-markup-shorten-citations t
  "If non-nil, shortens org-cite references according to `org-shorten-citations-re', `org-shorten-long-citations-re' and `org-shorten-citations--hook-function'"
  :type 'boolean
  :group 'org-hide-markup-mode)

(defcustom org-hide-markup-mode-font-lock-keyword-list
  (list '(org-hide-markup--citation-regex-searcher
	  (1 '(face nil invisible invisible-markup))
	  (2 '(face nil invisible invisible-markup)))
	'(org-hide-markup--long-citation-regex-searcher
	  (1 '(face nil invisible invisible-markup))))
  "List of lists to be added to `org-font-lock-extra-keywords'")

(defun org-hide-markup--hide-keywords ()
  "Make all matches in buffer for regex `org-hide-markup-keywords-re' invisible.
          When UNFOLD is non-nil make them visible instead."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward org-hide-markup-keywords-re nil t)
      (overlay-put (make-overlay (match-beginning 0)
                                 (match-end 0))
                   'invisible
                   '(invisible-markup)))))

(defun org-hide-markup--citation-regex-searcher (limit)
  "Put invisible-property 'invisible-markup' on strings matching `org-shorten-citations-re'."
  (if org-shorten-citations-re
      (re-search-forward org-shorten-citations-re limit t)
    (goto-char limit)
    nil))

(defun org-hide-markup--long-citation-regex-searcher (limit)
  "Put invisible-property 'invisible-markup' on strings matching `org-shorten-long-citations-re'."
  (if org-shorten-long-citations-re
      (re-search-forward org-shorten-long-citations-re limit t)
    (goto-char limit)
    nil))

(defun org-hide-markup-mode--add-keywords-to-font-lock ()
  (dolist (keyword org-hide-markup-mode-font-lock-keyword-list)
    (add-to-list 'org-font-lock-extra-keywords keyword)))

(define-minor-mode org-hide-markup-mode
  "A minor mode that automatically hides elements in Org mode."
  :init-value nil
  :lighter nil
  :require 'org
  :keymap nil
  (cond
   ((and org-hide-markup-mode (eq major-mode #'org-mode))
    (add-to-invisibility-spec '(invisible-markup))
    (org-hide-markup--hide-keywords)
    (when org-hide-markup-shorten-citations
      (add-hook 'org-font-lock-set-keywords-hook
		#'org-hide-markup-mode--add-keywords-to-font-lock))
    (when (and (not org-link-descriptive)
	       org-hide-markup--also-toggle-links) ;;enable if it is disabled
      (org-toggle-link-display)))
   (t
    (remove-from-invisibility-spec '(invisible-markup))
    (when (and org-link-descriptive org-hide-markup--also-toggle-links) ;;disable if it is enabled
      (org-toggle-link-display)))))

(with-eval-after-load 'org
  (add-hook 'org-mode-hook 'org-hide-markup-mode))

(provide 'org-hide-markup-mode)
;;; org-hide-markup-mode.el ends here
