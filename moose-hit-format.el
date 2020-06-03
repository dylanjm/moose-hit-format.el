;;; moose-hit-format -- HIT Formatter for MOOSE input files -*- lexical-binding: t;-*-
;;; Commentary:
;;; Code:

(require 'cl-lib)

(eval-when-compile
  (defconst mhf--system-type
    (cl-case system-type
      (windows-nt 'windows)
      (cygwin 'windows)
      (darwin 'macos)
      (gnu/linux 'linux))))

(eval-when-compile
  (defconst mhf--default-executable
    (cond
      ((eq mhf--system-type 'windows)
        (expand-file-name "lib/hit.exe"))
      ((eq mhf--system-type 'macos)
        (expand-file-name "lib/hit.darwin.x64"))
      (t
        (expand-file-name "lib/hit.linux.x64")))))

(eval-when-compile
  (defconst mhf--default-style (expand-file-name "default.style")))

(defgroup moose-hit-format nil
  "An input file formating tool."
  :group 'tools)

(defcustom mhf-hit-executable mhf--default-executable
  "The hit executable used by moose-hit-format.
This wil be looked up through the variable `exec-path'
if it isn't an absolute path to the binary."
  :type 'string
  :group 'moose-hit-format)

(defcustom mhf-hit-default-style mhf--default-style
  "The default style file to use for hit formatting."
  :type 'string
  :group 'moose-hit-format)

(defun moose-hit-format ()
  "Use hit format executable on the current buffer."
  (interactive)
  (if (executable-find mhf-hit-executable)
    (let ((tmp-buffer (generate-new-buffer " *moose-hit-format*"))
           (tmp-file (make-temp-file "moose-hit-stderr" nil ".el")))
      (condition-case err
        (unwind-protect
          (let ((status
                  (apply #'call-process-region nil nil mhf-hit-executable
                    nil `(,tmp-buffer ,tmp-file) nil
                    `("format" "-style" ,mhf-hit-default-style "-")))
                 (stderr
                   (with-temp-buffer
                     (unless (zerop (cadr (insert-file-contents tmp-file)))
                       (insert ": "))
                     (buffer-substring-no-properties (point-min) (point-max)))))
            (unless (zerop status)
              (error "Hit Formatting Error %s%s" status stderr))
            (with-current-buffer (current-buffer)
              (replace-buffer-contents tmp-buffer))))
        (error (message "%s" (error-message-string err))))
      (delete-file tmp-file)
      (when (buffer-name tmp-buffer)
        (kill-buffer tmp-buffer)))
    (error "%s" (concat mhf-hit-executable " not found."))))

(provide 'moose-hit-format)
;;; moose-hit-format.el ends here
