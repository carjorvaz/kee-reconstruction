(require :asdf)

(defun script-directory ()
  (make-pathname :name nil :type nil :defaults *load-truename*))

(asdf:load-asd (merge-pathnames "../kee-core.asd" (script-directory)))
(asdf:load-system "kee-core/test")
(uiop:quit (if (kee-test:run-tests) 0 1))
