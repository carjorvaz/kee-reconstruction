(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/worlds.lisp" *load-truename*))
(load (merge-pathnames "../src/rules.lisp" *load-truename*))
(load (merge-pathnames "../src/inspect.lisp" *load-truename*))
(load (merge-pathnames "../src/browser.lisp" *load-truename*))
(defparameter *run-hamburg-puzzle-demo* nil)
(load (merge-pathnames "hamburg-puzzle-mini.lisp" *load-truename*))

(in-package #:cl-user)

(defun browser-worlds (&optional (limit 8))
  (let ((worlds (sort (copy-list (kee:$worlds))
                      #'string<
                      :key (lambda (world)
                             (symbol-name (kee:get.world.name world))))))
    (subseq worlds 0 (min limit (length worlds)))))

(defun run-browser-demo ()
  (setup)
  (kee:create.world 'hypothesis-root)
  (kee:run.world.agenda '(constraint.rules hypothesis.rules) :max-iterations 20)
  (kee:print.browser
   :units '(people tom dick harriet constraint.rules hypothesis.rules)
   :worlds (browser-worlds)))

(run-browser-demo)
