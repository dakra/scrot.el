;;; scrot.el --- Take screenshots with scrot         -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2023  Daniel Kraus

;; Author: Daniel Kraus <daniel@kraus.my>
;; Keywords: tools, multimedia, convenience
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Take screenshots with scrot (or tool specified in `scrot-command'),
;; upload them to imgbb and copy the url to the kill-ring


;;; Code:

(require 'request)

(defgroup scrot nil
  "Screenshot utility using scrot"
  :prefix "scrot-"
  :group 'tools)

(defcustom scrot-command "scrot"
  "Scrot executable."
  :type 'file)

(defcustom scrot-args "-s"
  "Default arguments."
  :type 'string)

(defcustom scrot-file-ext "png"
  "File name extension."
  :type 'string)

(defcustom scrot-local-path "~/Screenshots"
  "Path where the screenshots should be stored locally."
  :type 'directory)


;; From https://github.com/ecraven/imgbb.el
;;;###autoload
(defun scrot-upload (filename)
  "Upload FILENAME to imgbb.com, show the image url and put it into the kill ring."
  (interactive "fImage file: ")
  (request "https://imgbb.com/json"
    :params '((type . "file")
              (action . "upload"))
    :files `(("source" . (,(file-name-nondirectory filename) :file ,filename)))
    :parser 'json-read
    :error (cl-function
            (lambda (&rest args &key _error-thrown &allow-other-keys)
              (message "Error uploading image.")))
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (let ((url (assoc-default 'url (assoc-default 'image (assoc-default 'image data)))))
                  (message "Image uploaded to %s" url)
                  (browse-url url)
                  (kill-new url))))))

(defun scrot-default-filenames ()
  "Return list of filename suggestions for new screenshots."
  (let ((project-name (if (project-current)
                          (file-name-nondirectory (directory-file-name (cdr (project-current))))
                        (buffer-name))))
    (list
     (concat project-name (format-time-string "-%Y-%m-%d"))
     (concat project-name (format-time-string "-%Y-%m-%d--%H-%M-%S"))
     (format-time-string "%Y-%m-%d-")
     (concat project-name "-"))))

;;;###autoload
(defun scrot (name)
  "Take screenshot with filename NAME."
  (interactive
   (list (read-string "Image name: " (car (scrot-default-filenames)) nil (cdr (scrot-default-filenames)))))
  (let ((use-org-format current-prefix-arg)
        (buf (current-buffer))
        (filename (format "%s%s.%s" (file-name-as-directory (expand-file-name scrot-local-path))
                          (shell-quote-argument name) scrot-file-ext)))
    (make-process
     :name "scrot"
     :command (list scrot-command scrot-args filename)
     :sentinel (lambda (p _e)
                 (when (= 0 (process-exit-status p))
                   (if use-org-format
                       (with-current-buffer buf
                         (insert (concat "[[" filename "]]")))
                     (scrot-upload filename)))))))

(provide 'scrot)
;;; scrot.el ends here
