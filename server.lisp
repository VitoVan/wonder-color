(setf sb-impl::*default-external-format* :UTF-8)
;;(declaim (optimize (debug 3)))
(ql:quickload '(hunchentoot drakma cl-spider))

(defpackage wonder-color
  (:use :cl :hunchentoot))
(in-package :wonder-color)

; Start Hunchentoot
(setf *show-lisp-errors-p* t)
(setf *acceptor* (make-instance 'hunchentoot:easy-acceptor
                                :port 5001
                                :access-log-destination "log/access.log"
                                :message-log-destination "log/message.log"
                                :error-template-directory  "www/errors/"
                                :document-root "www/"))

(defun start-server ()
  (start *acceptor*)
  (format t "Server started at 5001"))

(defun search-pic(text)
  (cdaar (cl-spider:get-data "http://cn.bing.com/images/search" :selector "img[height]" :attrs '("src") :params `(("q" . ,text)))))

(defun controller-wonder-pic ()
  (let* ((pic-name (cl-ppcre:regex-replace-all " " (parameter "text") "-"))
         (pic-url (search-pic (parameter "text"))))
    (let ((file (open (concatenate 'string "pics/" pic-name)
                      :direction :output
                      :if-exists :rename-and-delete
                      :element-type '(unsigned-byte 8)
                      :if-does-not-exist :create))
          (input (drakma:http-request pic-url
                                      :want-stream t
                                      :user-agent "Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0")))
      (when input
        (loop for byte = (read-byte input nil nil)
           while byte do (write-byte byte file))
        (progn (close input) (close file))))
    pic-name))

(setf *dispatch-table*
      (list
       (create-regex-dispatcher "^/wonder$" 'controller-wonder-pic)))

(start-server)
