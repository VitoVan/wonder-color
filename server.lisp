(setf sb-impl::*default-external-format* :UTF-8)
;;(declaim (optimize (debug 3)))
(ql:quickload '(hunchentoot drakma cl-spider cl-cron cl-json))

(defpackage wonder-color
  (:use :cl :hunchentoot))
(in-package :wonder-color)

(defvar *pic-dir* "www/pics/")

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

(setf cl-spider:*cl-spider-user-agent* "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36")
;;GOOGLE: https://www.google.com/search?safe=off&tbs=isz:i&tbm=isch&q=doraemon&gbv=1
;;BING: http://bing.com/images/search?q=doraemon&qft=filterui:imagesize-medium
(defun search-pic(text)
  (cdaar (cl-spider:get-data "https://www.google.com/search" :selector "img[height]" :attrs '("src") :params `(("q" . ,text) ("safe" . "off") ("tbs" . "isz:i") ("tbm" . "isch") ("gbv" . "1")))))

(defun download-pic (text)
  (let* ((pic-url (search-pic text))
         (pic-name (cl-ppcre:regex-replace-all " " text "-"))
         (pic-file-path (concatenate 'string *pic-dir* pic-name)))
    (or
     (fad:file-exists-p pic-file-path)
     (let ((file (open pic-file-path
                       :direction :output
                       :if-exists :rename-and-delete
                       :element-type '(unsigned-byte 8)
                       :if-does-not-exist :create))
           (input (drakma:http-request pic-url
                                       :want-stream t
                                       :user-agent cl-spider:*cl-spider-user-agent*)))
       (when input
         (loop for byte = (read-byte input nil nil)
            while byte do (write-byte byte file))
         (progn (close input) (close file)))))
    pic-name))

(defun controller-wonder ()
  (let* ((text (parameter "text")))
    (download-pic text)))

(defun controller-wonder-api-html ()
  "Generate a HTML page with Vibrant.js for PhantomJS to execute"
  (let* ((text (parameter "text"))
         (pic-url (concatenate 'string "/pics/" (download-pic text)))
         (html-str (concatenate 'string "<html><head><script type=\"text/javascript\" src=\"vibrant.js\"></script><script type=\"text/javascript\" src=\"api.js\"></script></head><body><img  onload=\"doVibrant()\" src=\"" pic-url "\"/></body></html>")))
    html-str))

;; TODO:  ADD Condition
(defun phantom-query(text)
  "Execute PhantomJS, fetch wonder-api-html and get the results of Vibrant.js"
  (handler-case
      (read-from-string (cl-ppcre:regex-replace-all "|
"  (with-output-to-string (s)
     (sb-ext:run-program "phantom/wonder-api.js" `(,text) :pty s)) ""))
    (error
        (condition)
      (progn
        (log-message* *log-lisp-errors-p* (format nil "~A" condition))
        (format nil "Sorry, something goes wrong, try again please.")))))

(defun controller-wonder-api ()
  (let* ((callback (parameter "callback"))
         (json-str (json:encode-json-to-string (phantom-query (parameter "text")))))
    (if callback
        (progn
          (setf (hunchentoot:content-type*) "application/javascript")
          (concatenate 'string callback "(" json-str ")" ))
        (progn
          (setf (hunchentoot:content-type*) "application/json")
          json-str))))

(setf *dispatch-table*
      (list
       (create-regex-dispatcher "^/wonder$" 'controller-wonder)
       (create-regex-dispatcher "^/wonder-api-html$" 'controller-wonder-api-html)
       (create-regex-dispatcher "^/wonder-api$" 'controller-wonder-api)))

(start-server)

(defun clear-pics()
  (dolist (file (fad:list-directory *pic-dir*))
    (if (> (- (get-universal-time) (file-write-date file)) (* 60 60 12))
        (progn
          (delete-file file)
          (format t "Deleted: ~A~%" file)))))

;;Cron Job
(cl-cron:make-cron-job #'clear-pics)
(cl-cron:start-cron)
