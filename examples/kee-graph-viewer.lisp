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

(defun demo-review-rule (world)
  (let ((justification (first (kee:why.false world))))
    (and justification
         (kee:justification.rule justification))))

(defun demo-session (world)
  (let* ((world-name (symbol-name (kee:get.world.name world)))
         (rule (demo-review-rule world))
         (rule-name (if rule (symbol-name rule) "NIL"))
         (facts (length (kee:world.facts world)))
         (nogoods (length (kee:world.nogoods world))))
    (list :listener
          (list "CL-USER> (SETUP)"
                "PUZZLE"
                "CL-USER> (KEE:CREATE.WORLD 'HYPOTHESIS-ROOT)"
                "HYPOTHESIS-ROOT"
                "CL-USER> (KEE:RUN.WORLD.AGENDA '(CONSTRAINT.RULES HYPOTHESIS.RULES) :MAX-ITERATIONS 20)"
                "20")
          :typescript
          (list "Generated Hamburg puzzle viewer"
                "Complete consistent worlds: 12"
                (format nil "Review world: ~A" world-name)
                (format nil "~A facts ~D / nogoods ~D"
                        world-name facts nogoods))
          :prompt
          (list "Current KB: PUZZLE"
                "View: Worlds"
                (format nil "Selected: ~A" world-name)
                (format nil "First nogood rule: ~A" rule-name)))))

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
                             :initial-trace-scope "selected"
                             :session (demo-session review-world)))
