(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/traces.lisp" *load-truename*))
(load (merge-pathnames "../src/worlds.lisp" *load-truename*))
(load (merge-pathnames "../src/rules.lisp" *load-truename*))
(load (merge-pathnames "../src/inspect.lisp" *load-truename*))

(in-package #:cl-user)

(defvar *run-hamburg-puzzle-demo* t)
(defparameter *people* '(tom dick harriet))

(defun define-rule (name form)
  (kee:create.unit name 'puzzle nil 'constraint.rules)
  (kee:put.value name 'kee:external.form form)
  (kee:parse name))

(defun define-hypothesis-rule (name form)
  (kee:create.unit name 'puzzle nil 'hypothesis.rules)
  (kee:put.value name 'kee:external.form form)
  (kee:parse name))

(defun setup ()
  (kee:reset-kee)
  (kee:create.kb 'puzzle)
  (kee:create.unit 'classes 'puzzle nil nil)
  (kee:create.unit 'entities 'puzzle nil nil)
  (kee:create.unit 'people 'puzzle 'entities 'classes)
  (kee:create.slot 'people 'sport 'member nil nil nil nil
                   '((kee:value.class (kee:one.of golf basketball sailing))
                     (kee:min.cardinality 1)
                     (kee:max.cardinality 1)))
  (kee:create.slot 'people 'phobia 'member nil nil nil nil
                   '((kee:value.class (kee:one.of cats heights close.spaces))
                     (kee:min.cardinality 1)
                     (kee:max.cardinality 1)))
  (dolist (person *people*)
    (kee:create.unit person 'puzzle nil 'people)
    (kee:add.value 'people 'members person))
  (kee:create.unit 'constraint.rules 'puzzle 'entities 'classes)
  (define-rule 'heights.golf
      '(while (the sport of ?person is golf)
              (the phobia of ?person is heights)
         believe false))
  (define-rule 'cats.sailing
      '(while (the sport of ?person is sailing)
              (the phobia of ?person is cats)
         believe false))
  (define-rule 'basketball.close.spaces
      '(while (the sport of ?person is basketball)
              (the phobia of ?person is close.spaces)
         believe false))
  (define-rule 'no.duplicate.sports
      '(while (the members of people is ?p1)
              (the members of people is ?p2)
              (lisp (not (eq ?p1 ?p2)))
              (the sport of ?p1 is ?sport)
              (the sport of ?p2 is ?sport)
         believe false))
  (define-rule 'no.duplicate.phobias
      '(while (the members of people is ?p1)
              (the members of people is ?p2)
              (lisp (not (eq ?p1 ?p2)))
              (the phobia of ?p1 is ?phobia)
              (the phobia of ?p2 is ?phobia)
         believe false))
  (kee:create.unit 'hypothesis.rules 'puzzle 'entities 'classes)
  (define-hypothesis-rule 'guess.sport
      '(if (the members of people is ?person)
           (lisp (cant.find ?person 'sport))
         then
           (in.new.world
            (the sport of ?person is values))))
  (define-hypothesis-rule 'guess.phobia
      '(if (the members of people is ?person)
           (lisp (cant.find ?person 'phobia))
         then
           (in.new.world
            (the phobia of ?person is values)))))

(defun try-world (name sport phobia)
  (let ((world (kee:create.world name)))
    (kee:with-world (world)
      (kee:put.value 'tom 'sport sport)
      (kee:put.value 'tom 'phobia phobia)
      (kee:forward.chain 'constraint.rules))
    world))

(defun complete-world-p (world)
  (and (not (kee:world.inconsistent.p world))
       (kee:with-world (world)
         (every (lambda (person)
                  (and (kee:find.any person 'sport)
                       (kee:find.any person 'phobia)))
                *people*))))

(defun assignment-summary (world)
  (kee:with-world (world)
    (mapcar (lambda (person)
              (list person
                    :sport (kee:get.value person 'sport)
                    :phobia (kee:get.value person 'phobia)))
            *people*)))

(defun complete-worlds ()
  (remove-if-not #'complete-world-p (kee:consistent.worlds)))

(defun show-contradiction-demo ()
  (let ((bad (try-world 'tom-golf-heights 'golf 'heights))
        (good (try-world 'tom-golf-cats 'golf 'cats)))
    (format t "~&~S inconsistent? ~S~%"
            (kee:get.world.name bad)
            (kee:world.inconsistent.p bad))
    (dolist (reason (kee:why.false bad))
      (format t "  because ~S matched ~S~%"
              (kee:justification.rule reason)
              (kee:justification.bindings reason)))
    (format t "~S inconsistent? ~S~%"
            (kee:get.world.name good)
            (kee:world.inconsistent.p good))))

(defun run-search-demo ()
  (kee:reset-kee)
  (setup)
  (kee:create.world 'hypothesis-root)
  (kee:run.world.agenda '(constraint.rules hypothesis.rules) :max-iterations 20)
  (let ((complete (complete-worlds)))
    (format t "~&Complete consistent worlds: ~D~%" (length complete))
    (dolist (world (subseq complete 0 (min 5 (length complete))))
      (format t "~&~S ~S~%"
              (kee:get.world.name world)
              (assignment-summary world)))))

(defun run ()
  (setup)
  (show-contradiction-demo)
  (run-search-demo))

(when *run-hamburg-puzzle-demo*
  (run))
