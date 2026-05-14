(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/traces.lisp" *load-truename*))
(load (merge-pathnames "../src/worlds.lisp" *load-truename*))
(load (merge-pathnames "../src/rules.lisp" *load-truename*))
(load (merge-pathnames "../src/inspect.lisp" *load-truename*))
(load (merge-pathnames "../src/graph.lisp" *load-truename*))
(load (merge-pathnames "../src/viewer.lisp" *load-truename*))
(defparameter *run-hamburg-puzzle-demo* nil)
(load (merge-pathnames "hamburg-puzzle-mini.lisp" *load-truename*))

(in-package #:cl-user)

(setup)
(kee:create.world 'hypothesis-root)
(kee:run.world.agenda '(constraint.rules hypothesis.rules) :max-iterations 20)

(defun demo-review-world ()
  (or (find-if (lambda (world)
                 (and (kee:world.inconsistent.p world)
                      (kee:world.nogoods world)
                      (kee:world.facts world)))
               (sort (copy-list (kee:$worlds))
                     #'string<
                     :key (lambda (world)
                            (symbol-name (kee:get.world.name world)))))
      (first (kee:$worlds))))

(let* ((review-world (demo-review-world))
       (review-world-id (format nil "world:~A"
                                (symbol-name
                                 (kee:get.world.name review-world)))))
  (kee:write.kee.viewer.html *standard-output*
                             :kb 'puzzle
                             :world-limit 80
                             :title "Hamburg Puzzle"
                             :initial-view "worlds"
                             :initial-selection review-world-id
                             :initial-trace-scope "selected"))
