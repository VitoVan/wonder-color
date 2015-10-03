(setf sb-impl::*default-external-format* :UTF-8)
;;(declaim (optimize (debug 3)))
(ql:quickload '(hunchentoot drakma cl-spider cl-cron cl-json cl-mongo))

(defpackage wonder-color
  (:use :cl :hunchentoot :cl-mongo))
(in-package :wonder-color)

;;pic dir
(defvar *pic-dir* "www/pics/")

;;init db
(db.use "wonder-color")
;;Cache time in seconds, default 30 days
(defvar *cache-delay* (* 60 60 24 30))

(defun cache-color(text color)
  (and (listp color)
       (db.update
        "cache"
        ($ "text" text)
        (kv ($set "time" (get-universal-time)) ($set "color" color))
        :upsert t :multi t))
  color)

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

(defun get-color-cache(text)
  (and text (> (length text) 0)
       (let* ((cache-doc (car (docs
                               (db.find "cache"
                                        (kv "text" text)))))
              (cache-time (get-element "time" cache-doc)))
         (if cache-doc
             (progn
               (if (<= cache-time (- (get-universal-time) *cache-delay*))
                   (bordeaux-threads:make-thread #'(lambda () (cache-color text (phantom-query text)))))
               (get-element "color" cache-doc))
             (cache-color text (phantom-query text))))))

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
  (log-message* *log-lisp-warnings-p* (format nil "Searching: ~A~%" text))
  (cdaar (cl-spider:get-data "https://www.google.com/search" :selector "img[height]" :attrs '("src") :params `(("q" . ,text) ("safe" . "off") ("tbs" . "isz:i") ("tbm" . "isch") ("gbv" . "1")))))

(defun download-pic (text)
  (and text (> (length text) 0) (let* ((pic-url (search-pic text))
         (pic-name (cl-ppcre:regex-replace-all " " text "-"))
         (pic-file-path (concatenate 'string *pic-dir* pic-name)))
    (or
     (fad:file-exists-p pic-file-path)
     (progn
       (log-message* *log-lisp-warnings-p* (format nil "Downloading: ~A~%" pic-url))
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
           (progn (close input) (close file))))))
    pic-name)))

(defun controller-wonder-api-html ()
  "Generate a HTML page with Vibrant.js for PhantomJS to execute"
  (log-message* *log-lisp-warnings-p* (format nil "Wonder API HTML Called: ~A~%" (parameter "text")))
  (let* ((text (parameter "text"))
         (pic-url (concatenate 'string "/pics/" (download-pic text)))
         (html-str (concatenate 'string "<html><head><meta charset=\"utf-8\"/><script type=\"text/javascript\" src=\"vibrant.js\"></script><script type=\"text/javascript\" src=\"api.js\"></script></head><body><img  onload=\"doVibrant()\" src=\"" pic-url "\"/></body></html>")))
    html-str))

(defun controller-wonder-api ()
  (let* ((callback (parameter "callback"))
         (json-str (json:encode-json-to-string (get-color-cache (parameter "text")))))
    (if callback
        (progn
          (setf (hunchentoot:content-type*) "application/javascript")
          (concatenate 'string callback "(" json-str ")" ))
        (progn
          (setf (hunchentoot:content-type*) "application/json")
          json-str))))

(setf *dispatch-table*
      (list
       (create-regex-dispatcher "^/wonder-api-html$" 'controller-wonder-api-html)
       (create-regex-dispatcher "^/wonder-api$" 'controller-wonder-api)))

(start-server)

(defun clear-pics()
  (dolist (file (fad:list-directory *pic-dir*))
    (if (> (- (get-universal-time) (file-write-date file)) *cache-delay*)
        (progn
          (delete-file file)
          (log-message* *log-lisp-warnings-p* (format nil "Deleted: ~A~%" file))))))

;;Cron Job
(cl-cron:make-cron-job #'clear-pics)
(cl-cron:start-cron)
