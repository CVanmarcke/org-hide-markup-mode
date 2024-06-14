
;;; org-hide-markup-mode.el --- Hide org markup      -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Free Software Foundation, Inc.
;;
;; Author: CVanmarcke
;; URL: https://github.com/cvanmarcke/org-hide-markup-mode
;; Version: 1.1
;; Keywords: org, text, markup
;; Package-Requires: ((emacs "29.1"))

;;; Commentary:
;;
;; This is a minor mode to reduce clutter and improve the viewing experience in emacs' org-mode.
;; This package hides keywords and property drawers, and shortens org-cite citations.
;;
;; 4 variables can be toggled to control which elements will be hidden:
;;
;;    org-hide-markup-shorten-citations
;;    org-hide-markup-hide-keywords
;;    org-hide-markup-hide-property-drawers
;;    org-hide-markup-toggle-links


;;; Code:

(require 'org)

(defgroup org-hide-markup-mode nil
  "Hide markup text for org mode."
  :group 'org
  :prefix "org-hide-markup-")


; "\\(\n\\#\\+\\(STARTUP\\:.+\\|filetags\\:\\|ATTR_\\(ORG\\|HTML\\)\\:.+\\)\\|\\#\\+title\\: *\\)"
(defcustom org-hide-markup-keywords-re "\\(\n\\#\\+\\(STARTUP\\:.+\\|filetags\\:\\|ATTR_\\(ORG\\|HTML\\)\\:.+\\)\\|\\#\\+\\(title\\:[ \t]*\\)\\)"
  "Matches to the regex sequence will be hidden"
  :type 'regexp
  :group 'org-hide-markup-mode)

(defconst org-hide-markup-property-drawer-re
  (concat "^[ \t]*:PROPERTIES:[ \t]*\n"
          "\\(?:[ \t]*:\\S-+:\\(?:[ \t].*\\)?[ \t]*\n\\)*?"
          "[ \t]*:END:[ \t]*\n")
  "Matches an entire property drawer. Basically `org-property-drawer-re' with a newline instead of $ at the end.")

(defcustom org-shorten-citations-re "\\[\\(cite:\\)@[a-z-]+\\([A-Z0-9]\\w\\{15,\\}\\)\\(\\]\\|;@\\)"
  "Regular expression that matches strings where the invisible-property is set.
   This regular expression matches [cite:@authorTitleInCamelCase2024], and hides select parts as defined in `org-hide-markup-mode-font-lock-keyword-list'.
   The result is [@author]"
  :type 'regexp
  :group 'org-hide-markup-mode)

(defcustom org-shorten-long-citations-re ";@[a-z-]+\\([A-Z0-9]\\w\\{15,\\}\\)"
  "Regular expression that matches strings where the invisible-property is set.
   This regular expression matches [cite:@authorTitleInCamelCase2024;@otherauthorTitleInCamelCase2023;@anotherauthorTitleInCamelCase2023], and hides select parts as defined in `org-hide-markup-mode-font-lock-keyword-list'.
   The result alone is [cite:@authorTitleInCamelCase2024;@otherauthor;@anotherauthor]. In combination with `org-shorten-citations-re' it becomes [@author;@otherauthor;@anotherauthor]."
  :type 'regexp
  :group 'org-hide-markup-mode)

(defcustom org-hide-markup-hide-keywords t
  "If non-nil, hide keywords as defined by `org-hide-markup-keywords-re'."
  :type 'boolean
  :group 'org-hide-markup-mode)

(defcustom org-hide-markup-hide-property-drawers t
  "If non-nil, also hide property drawers."
  :type 'boolean
  :group 'org-hide-markup-mode)

(defcustom org-hide-markup-toggle-links t
  "If non-nil, also toggle `org-toggle-link-display' on toggling `org-hide-markup-mode'"
  :type 'boolean
  :group 'org-hide-markup-mode)

(defcustom org-hide-markup-shorten-citations t
  "If non-nil, shortens org-cite references according to `org-shorten-citations-re', `org-shorten-long-citations-re' and `org-hide-markup-mode-font-lock-keyword-list'"
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
  "Make all matches in buffer for regex `org-hide-markup-keywords-re' invisible."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward org-hide-markup-keywords-re nil t)
      (overlay-put (make-overlay (match-beginning 0)
                                 (match-end 0))
                   'invisible
                   '(invisible-markup)))))

(defun org-hide-markup--hide-properties ()
  "Make all matches in buffer for regex `org-hide-markup-property-drawer-re' invisible."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward org-hide-markup-property-drawer-re nil t)
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
    (when org-hide-markup-hide-keywords
      (org-hide-markup--hide-keywords))
    (when org-hide-markup-hide-property-drawers
      (org-hide-markup--hide-properties))
    (when org-hide-markup-shorten-citations
      (add-hook 'org-font-lock-set-keywords-hook
		#'org-hide-markup-mode--add-keywords-to-font-lock))
    (when (and (not org-link-descriptive)
	       org-hide-markup-toggle-links) ;;enable if it is disabled
      (org-toggle-link-display)))
   (t
    (remove-from-invisibility-spec '(invisible-markup))
    (when (and org-link-descriptive org-hide-markup-toggle-links) ;;disable if it is enabled
      (org-toggle-link-display)))))

(provide 'org-hide-markup-mode)
;;; org-hide-markup-mode.el ends here
