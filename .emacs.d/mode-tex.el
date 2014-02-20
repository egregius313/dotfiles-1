;;==============================================================================
;; TeX and LaTeX
;;==============================================================================
;; The default tex-mode and AucTeX may seem quite disappointing. Let's use
;; custom KISS functions for everything.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CUSTOM
(defcustom tex-compiler nil
  "This is the name of the executable called upon TeX compilations.
Examples: pdftex, pdflatex, xetex, xelatex, luatex, lualatex...

If value is nil, the compiler will be tex-default-compiler for
TeX mode, and latex-default-compiler for LaTeX mode."
  :safe 'stringp)

(defcustom masterfile nil
  "The file that should be compiled. Useful for modular documents."
  :safe 'stringp)

(defcustom tex-compiler-options "-file-line-error-style -interaction nonstopmode -synctex=1"
  "The options to the tex compiler. Options are set between the
compiler name and the file name.

Interesting options:

* -file-line-error-style: change the style of error report to
   display file name and line first.

* -halt-on-error: default.

* -interaction <mode>: like -halt-on-error, you can set the way
   the compilers behave on errors. Possible values for <mode> are
   'batchmode', 'errorstopmode', 'nonstopmode' and 'scrollmode'.

* -shell-escape: allow the use of \write18{<external command>}
   from within TeX documents. This is a potential security issue.

* -synctex=1: enable SyncTeX support.

You may use file local variable for convenience:

% -*- tex-compiler-options: \"-shell-escape\"

Note that -shell-escape can also be toggled with universal
argument."
  :safe 'stringp)

(defcustom tex-startcommands ""
  "You can call a TeX compiler upon a string instead of a file.
This is actually useful if you want to customize your
compilation.

If this variable is not an empty string, the mandatory \" is
prepended and \\input\" is appended, so that the target file gets
read; otherwise the TeX compiler would stop there.

You may use it to act on the process, like the default behaviour:
  \\nonstopmode
which will continue the process whenever an error is
encountered. There is an command-line argument for that on most
compilers, that is is rarely useful.

If you use a color theme, or any conditional variable inside your
document, you may define it here:
  \\def\\myvar{mycontent}"
  :safe 'stringp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VARIABLES
(defvar tex-viewer "zathura --fork -s -x \"emacsclient --eval '(progn (switch-to-buffer  (file-name-nondirectory \"'\"'\"%{input}\"'\"'\")) (goto-line %{line}))'\""
  "PDF Viewer for TeX documents. You may want to fork the viewer
so that it detects when the same document is launched twice, and
persists when Emacs gets closed.

Simple command:

  zathura --fork

We can use

  emacsclient --eval '(progn (switch-to-buffer  (file-name-nondirectory \"%{input}\")) (goto-line %{line}))'

to reverse-search a pdf using SyncTeX. Note that the quotes and
double-quotes matter and must be escaped appropriately.")

(defvar tex-default-compiler "pdftex"
  "Default compiler for TeX mode. Used if tex-compiler is
empty.")

(defvar latex-default-compiler "pdflatex"
  "Default compiler for LaTeX mode. Used if tex-compiler is
empty.")

(defvar tex-extension-list
  '("aux" "glg" "glo" "gls" "idx" "ilg" "ind" "lof" "log" "nav" "out" "snm" "synctex" "synctex.gz" "tns" "toc" "xdy")
  "List of known TeX exentsions. This list is used by 'tex-clean
  to purge all matching files.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTIONS
(defun tex-set-compiler ()
  "Use compile to process your TeX-based document. Use a prefix
argument to call the compiler along the '-shell-escape'
option. This will enable the use of '\write18{<external
command>}' from within TeX documents, which need to allow
external application to be called from TeX.

This may be useful for some features like GnuPlot support with TikZ.

WARNING: the -shell-escape option is a potential security issue."
  (interactive)
  (hack-local-variables)
  (let (
        ;; Set compiler to be tex-compiler if not empty, or a default
        ;; compiler otherwise.
        (local-compiler
         (if (not tex-compiler)
             (cond
              ((string= "latex-mode" major-mode) latex-default-compiler)
              ((string= "plain-tex-mode" major-mode) tex-default-compiler)
              (t (message "Warning: unknown major mode. Trying pdftex.") "pdftex"))
           tex-compiler))

        ;; Master file.
        (local-master
         (if (not masterfile) buffer-file-name masterfile))

        ;; If tex-startcommands has some content, we make sure it is a string
        ;; that loads the file.
        (local-start-cmd
         (if (not (string= "" tex-startcommands))
             (concat "\"" tex-startcommands "\\input\"")))

        ;; Support of prefix argument to toggle -shell-escape.
        (local-shell-escape
         (if (equal current-prefix-arg '(4)) "-shell-escape" "")))

    (set (make-local-variable 'compile-command)
         (concat local-compiler " "  local-shell-escape " " tex-compiler-options " " local-start-cmd " \"" local-master "\""))))


(defun tex-clean ()
  "Remove all TeX temporary files. This command should be safe,
but there is no warranty."
  (interactive)
  (hack-local-variables)
  (let (
        ;; Master file.
        (local-master
         (if (not masterfile) buffer-file-name masterfile)))

    (let (
          ;; File name without extension.
          (file
           (replace-regexp-in-string "tex" "" (file-name-nondirectory local-master))))

      ;; Concatate file name to list.
      (mapcar
       ;; Delete file if exist
       (lambda (argfile) (interactive)
         (when (and (file-exists-p argfile) (file-writable-p argfile))
           (delete-file argfile)
           (message "[%s] deleted." argfile)))
       (mapcar
        ;; Concat file name with extensions.
        (lambda (arg) (interactive) (concat file arg))
        tex-extension-list)))))

(defun tex-pdf-compress ()
  "Use `masterfile' variable as default value for `pdf-compress'."
  (interactive)
  (hack-local-variables)
  (let ((local-master (if (not masterfile) buffer-file-name masterfile)))
    (pdf-compress local-master)))

(defun tex-pdf-view ()
  "Call a PDF viewer for current buffer file. File name should be
properly escaped with double-quotes in case it has spaces."
  (interactive)
  (hack-local-variables)
  (let (
        ;; Master file.
        (local-master
         (if (not masterfile) buffer-file-name masterfile)))

    (shell-command
     (concat tex-viewer
             " \""
             (replace-regexp-in-string "\.tex$" "\.pdf" (file-name-nondirectory local-master))
             "\" &" ))
    (delete-windows-on "*Async Shell Command*")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MACROS

(defun latex-itemize ()
  "Prepend \\item to the beginning of the line if not already
  there, otherwise insert it on next line. On region, append
  \item to every line and surround the region by an `itemize'
  environment. If bound to M-RET, you can then easily apply this
  command on the paragraph at point with M-h M-RET."
  (interactive)
  (let (min max case-fold-search)
    (if (not (region-active-p))

        (if (string-match "\\item" (buffer-substring (line-beginning-position) (line-end-position)))
            (progn
              (goto-char (line-end-position))
              (newline)
              (insert "\\item "))
          (goto-char (line-beginning-position))
          (insert "\\item")
          (just-one-space))

      (replace-regexp "^ *\\([^
 ]\\)" "\\\\item \\1" nil (region-beginning) (region-end))
      (goto-char (region-end))
      (goto-char (line-end-position))
      (newline)
      (insert "\\end{itemize}")
      (goto-char (region-beginning))
      (goto-char (line-beginning-position))
      (insert "\\begin{itemize}")
      (newline))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TeX setup

(defun tex-setup ()
   (dolist (key '("\C-c\C-f" "\C-c\C-b"))
     (local-unset-key key))
   (set-face-attribute 'tex-verbatim nil :family "freemono")
   (set (make-local-variable 'compilation-scroll-output) t)
   (set (make-local-variable 'compilation-hide-window) t)
   (set (make-local-variable 'paragraph-start) "
")
   ;; (set (make-local-variable 'use-hard-newlines) t)
   (local-set-key (kbd "<f9>") 'tex-pdf-view)
   (tex-set-compiler))

;; TODO: why is tex-setup needed for tex-mode only?
(add-hook 'tex-mode-hook 'tex-setup t)
(tex-setup)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LaTeX setup

(defun latex-setup ()
 (local-set-key (kbd "M-RET") 'latex-itemize)
 (turn-on-orgtbl))

(add-hook 'latex-mode-hook 'latex-setup)
(latex-setup)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The magnificent latex-math-preview mode!
;; TODO: some symbols are not generated properly.
(autoload 'latex-math-preview-expression "latex-math-preview" nil t)
(autoload 'latex-math-preview-insert-symbol "latex-math-preview" nil t)
(autoload 'latex-math-preview-save-image-file "latex-math-preview" nil t)
(autoload 'latex-math-preview-beamer-frame "latex-math-preview" nil t)
(autoload 'latex-math-preview-text-symbol-datasets "latex-math-preview" nil t)

(setq latex-math-preview-cache-directory-for-insertion
      (concat emacs-cache-folder "latex-math-preview-cache"))

;; Extra for latex-math-preview-mode.
;; TODO: latex-math-preview-mode extra does not work.
(require 'latex-math-preview-extra-data nil t)
(add-hook
 'latex-mode-hook
 (lambda ()
   ;; (local-set-key (kbd "C-c p") 'latex-math-preview-expression)
   ;; (local-set-key (kbd "C-c C-p") 'latex-math-preview-save-image-file)
   (local-set-key (kbd "C-c j") 'latex-math-preview-insert-symbol)
   (local-set-key (kbd "C-c C-j") 'latex-math-preview-last-symbol-again)
   ;; (local-set-key (kbd "C-c C-b") 'latex-math-preview-beamer-frame)
   ;; (add-to-list 'latex-math-preview-text-symbol-datasets
   ;;              latex-math-preview-textcomp-symbol-data)
   ;; (add-to-list 'latex-math-preview-text-symbol-datasets
   ;;              latex-math-preview-pifont-zapf-dingbats-symbol-data)
   ;; (add-to-list 'latex-math-preview-text-symbol-datasets
   ;;              latex-math-preview-pifont-symbol-fonts-symbol-data)))
   ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Skeletons


(define-skeleton tex-article
  "Insert article template."
  nil
  > "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\\documentclass[10pt,a4paper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[T1]{fontenc}
\\usepackage{amsmath,amssymb,amsfonts}
\\usepackage{geometry}
\\usepackage{lmodern}
\\usepackage{marvosym}
\\usepackage{textcomp}
\\DeclareUnicodeCharacter{20AC}{\\EUR{}}
\\DeclareUnicodeCharacter{2260}{\\neq}
\\DeclareUnicodeCharacter{2264}{\\leq}
\\DeclareUnicodeCharacter{2265}{\\geq}
\\DeclareUnicodeCharacter{22C5}{\\cdot}
\\DeclareUnicodeCharacter{A0}{~}
\\DeclareUnicodeCharacter{B1}{\\pm}
\\DeclareUnicodeCharacter{D7}{\\times}
%%=============================================================================
%% Properties

\\title{Title}
\\author{P.~\\textsc{Neidhardt}}

\\makeatletter
\\let\\thetitle\\@title
\\let\\theauthor\\@author
\\let\\thedate\\@date
\\makeatother

%%=============================================================================
%% Aliases

\\usepackage{xspace}

\\let\\latexbak\\LaTeX
\\renewcommand{\\LaTeX}{\\textrm{\\latexbak}\\xspace}

\\let\\texbak\\TeX
\\renewcommand{\\TeX}{\\textrm{\\texbak}\\xspace}

\\def\\unix{\\textsc{Unix}\\xspace}
\\def\\ie{\\textsl{i.e.}\\xspace}
\\def\\eg{\\textsl{e.g.}\\xspace}

%%=============================================================================
%% Formatting

% \\usepackage{parskip}
% \\setlength{\\parindent}{15pt}

% \\renewcommand{\\thefigure}{\\arabic{section}.\\arabic{figure}}
\\renewcommand{\\arraystretch}{1.4}
% \\renewcommand{\\familydefault}{\\sfdefault}

%% Header
% \\usepackage{fancyhdr}
% \\setlength{\\headheight}{15.2pt}
% \\pagestyle{fancy}
% \\lhead{\\thetitle}
% \\rhead{\\theauthor}

%%==============================================================================
%% Tables

% \\usepackage{longtable}
% \\usepackage{tabu}

%%==============================================================================
%% Graphics

%% Load TikZ after xcolor.
\\usepackage[svgnames]{xcolor}
% \\usepackage{graphicx}
% \\usepackage{tikz}

% \\newcommand{\\fancybox}[1]{
%   \\begin{tikzpicture}
%     \\node[draw,rounded corners]{#1};
%   \\end{tikzpicture}
% }

%%==============================================================================
%% Misc.

\\usepackage{comment}
\\usepackage{needspace}

% \\usepackage{calc}
% \\usepackage{fp}
% \\usepackage{lipsum}


%%=============================================================================
%% Babel

%% Load last before 'hyperref'.
\\usepackage[french,ngerman,english]{babel}
\\iflanguage{french}{
}{
  %% Narrow items
  \\newlength{\\wideitemsep}
  \\setlength{\\wideitemsep}{.5\\itemsep}
  \\addtolength{\\wideitemsep}{-7pt}
  \\let\\olditem\\item
  \\renewcommand{\\item}{\\setlength{\\itemsep}{\\wideitemsep}\\olditem}
}

%%==============================================================================
%% Hyperref

%% Load last.
\\usepackage[]{hyperref}

\\hypersetup{
  colorlinks=true,
  linkcolor=DarkRed,
  linktoc=page,
  urlcolor=blue,
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\\begin{document}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\\maketitle
% \\vfill
% \\thispagestyle{empty}
% \\tableofcontents
" \n
> @ _ \n
> "
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\\end{document}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
" \n)

(define-skeleton latex-listing-setup
  "Insert listing setup template."
  nil
  > "%%=============================================================================
%% Listings

\\usepackage{listings}

%% Source code.
\\lstdefinestyle{custom}{
  % numbers=left,
  belowcaptionskip=1\\baselineskip,
  breaklines=true,
  frame=L,
  xleftmargin=\\parindent,
  % framexleftmargin=\\parindent,
  language=C,
  showstringspaces=false,
  basicstyle=\\footnotesize\\ttfamily,
  keywordstyle=\\bfseries\\color{green!40!black},
  commentstyle=\\itshape\\color{purple!40!black},
  identifierstyle=\\color{blue},
  stringstyle=\\color{orange},
  numberstyle=\\ttfamily,
}

\\lstset{escapechar=,style=custom,
  literate=
  {á}{{\\'a}}1 {é}{{\\'e}}1 {í}{{\\'i}}1 {ó}{{\\'o}}1 {ú}{{\\'u}}1
  {Á}{{\\'A}}1 {É}{{\\'E}}1 {Í}{{\\'I}}1 {Ó}{{\\'O}}1 {Ú}{{\\'U}}1
  {à}{{\\`a}}1 {è}{{\\'e}}1 {ì}{{\\`i}}1 {ò}{{\\`o}}1 {ù}{{\\`u}}1
  {À}{{\\`A}}1 {È}{{\\'E}}1 {Ì}{{\\`I}}1 {Ò}{{\\`O}}1 {Ù}{{\\`U}}1
  {ä}{{\\\"a}}1 {ë}{{\\\"e}}1 {ï}{{\\\"i}}1 {ö}{{\\\"o}}1 {ü}{{\\\"u}}1
  {Ä}{{\\\"A}}1 {Ë}{{\\\"E}}1 {Ï}{{\\\"I}}1 {Ö}{{\\\"O}}1 {Ü}{{\\\"U}}1
  {â}{{\\^a}}1 {ê}{{\\^e}}1 {î}{{\\^i}}1 {ô}{{\\^o}}1 {û}{{\\^u}}1
  {Â}{{\\^A}}1 {Ê}{{\\^E}}1 {Î}{{\\^I}}1 {Ô}{{\\^O}}1 {Û}{{\\^U}}1
  {œ}{{\\oe}}1 {Œ}{{\\OE}}1 {æ}{{\\ae}}1 {Æ}{{\\AE}}1 {ß}{{\\ss}}1
  {ç}{{\\c c}}1 {Ç}{{\\c C}}1 {ø}{{\\o}}1 {å}{{\\r a}}1 {Å}{{\\r A}}1
  {€}{{\\EUR}}1 {£}{{\\pounds}}1
}

\\newcommand{\\includecode}[2][custom]{
  \\lstinputlisting[caption=#2, escapechar=, style=#1]{#2}}" \n)


(provide 'mode-tex)
