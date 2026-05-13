(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/worlds.lisp" *load-truename*))
(load (merge-pathnames "../src/rules.lisp" *load-truename*))

(in-package #:cl-user)

(defun setup ()
  (kee:reset-kee)
  (kee:create.kb 'puzzle)
  (kee:create.unit 'classes 'puzzle nil nil)
  (kee:create.unit 'entities 'puzzle nil nil)
  (kee:create.unit 'people 'puzzle 'entities 'classes)
  (kee:create.unit 'tom 'puzzle nil 'people)
  (kee:create.unit 'constraint.rules 'puzzle 'entities 'classes)
  (kee:create.unit 'heights.golf 'puzzle nil 'constraint.rules)
  (kee:put.value 'heights.golf 'kee:external.form
                 '(while (the sport of tom is golf)
                         (the phobia of tom is heights)
                    believe false))
  (kee:parse 'heights.golf))

(defun try-world (name sport phobia)
  (let ((world (kee:create.world name)))
    (kee:with-world (world)
      (kee:put.value 'tom 'sport sport)
      (kee:put.value 'tom 'phobia phobia)
      (kee:forward.chain 'constraint.rules))
    world))

(defun run ()
  (setup)
  (let ((bad (try-world 'tom-golf-heights 'golf 'heights))
        (good (try-world 'tom-golf-cats 'golf 'cats)))
    (format t "~&~S inconsistent? ~S~%"
            (kee:get.world.name bad)
            (kee:world.inconsistent.p bad))
    (format t "~S inconsistent? ~S~%"
            (kee:get.world.name good)
            (kee:world.inconsistent.p good))))

(run)
