(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/active-images.lisp" *load-truename*))
(load (merge-pathnames "../src/traces.lisp" *load-truename*))
(load (merge-pathnames "../src/pictures.lisp" *load-truename*))
(load (merge-pathnames "../src/dump.lisp" *load-truename*))
(load (merge-pathnames "../src/inspect.lisp" *load-truename*))

(in-package #:cl-user)

(defun dump-output-path ()
  #+sbcl
  (sb-ext:posix-getenv "KEE_KB_DUMP_OUT")
  #-sbcl
  nil)

(defun setup-dump-mini ()
  (kee:reset-kee)
  (kee:create.kb 'delivery)
  (kee:create.unit 'classes 'delivery nil nil)
  (kee:create.unit 'entities 'delivery nil nil)
  (kee:create.unit 'targets 'delivery 'entities 'classes)
  (kee:create.slot 'targets 'status 'member '(pending)
                   nil nil nil '((kee:value.class
                                  (kee:one.of pending ready done))))
  (kee:create.unit 'target.a 'delivery nil 'targets)
  (kee:put.value 'target.a 'status 'ready)
  (kee:create.active.image 'target.status.image 'target.a 'status
                           :widget :value
                           :label "Target status"
                           :choices '(pending ready done)
                           :writable-p t)
  (kee:create.kee.picture 'delivery.panel
                          :kb 'delivery
                          :label "Delivery Panel"
                          :width 220
                          :height 100)
  (kee:create.picture.item 'delivery.panel 'delivery.title :text
                           :x 12
                           :y 24
                           :text "Delivery KB")
  (kee:create.picture.item 'delivery.panel 'delivery.status :active-image
                           :active-image 'target.status.image
                           :x 12
                           :y 38
                           :width 140
                           :height 42))

(defun run ()
  (setup-dump-mini)
  (let ((output-path (dump-output-path)))
    (if output-path
        (progn
          (kee:write.kb.dump.file output-path 'delivery)
          (format t "~&Wrote ~A~%" output-path))
        (let ((dump-text (with-output-to-string (stream)
                           (kee:write.kb.dump stream 'delivery))))
          (format t "~&Dump bytes: ~D~%" (length dump-text))
          (kee:load.kb.dump (read-from-string dump-text) :replace t)
          (format t "Restored KBs: ~S~%" (kee:list.kbs))
          (format t "Restored status: ~S~%"
                  (kee:get.value 'target.a 'status))
          (format t "Restored picture items: ~S~%"
                  (mapcar #'kee:unit.name
                          (kee:picture.items 'delivery.panel)))))))

(run)
