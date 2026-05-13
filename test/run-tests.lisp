(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/worlds.lisp" *load-truename*))
(load (merge-pathnames "../src/rules.lisp" *load-truename*))

(in-package #:cl-user)

(defvar *failures* 0)

(defmacro check (form)
  `(unless ,form
     (incf *failures*)
     (format t "~&FAIL: ~S~%" ',form)))

(defun names (units)
  (mapcar #'kee:unit.name units))

(defun quit-with-status (status)
  #+sbcl (sb-ext:exit :code status)
  #-sbcl (error "Tests failed with status ~D." status))

(defun run ()
  (kee:reset-kee)
  (kee:create.kb 'veg)
  (kee:create.unit 'classes 'veg nil nil)
  (kee:create.unit 'entities 'veg nil nil)
  (kee:create.unit 'target.data 'veg 'entities 'classes)
  (kee:create.slot 'target.data 'source 'member '(manual))
  (kee:create.unit 'estimate.hemispherical.reflectance 'veg 'entities nil)
  (let ((sample (kee:create.unit 'sample.1 'veg nil '(target.data))))
    (check (eq (kee:get.value sample 'source) 'manual))
    (kee:put.value sample 'source 'manual)
    (kee:put.value sample 'complete.description "demo sample")
    (check (string= (kee:get.value sample 'complete.description)
                    "demo sample"))
    (kee:add.value 'estimate.hemispherical.reflectance 'new.samples sample)
    (check (equal (names (kee:get.values 'estimate.hemispherical.reflectance
                                        'new.samples))
                  '(sample.1)))
    (check (equal (names (kee:unit.parents sample 'member))
                  '(target.data)))
    (check (member 'sample.1 (names (kee:unit.children 'target.data 'member))))
    (kee:put.value 'target.data 'source 'file)
    (check (eq (kee:get.value sample 'source) 'manual))
    (kee:remove.all.values sample 'source)
    (check (eq (kee:get.value sample 'source) 'file)))
  (kee:create.unit 'worker 'veg 'entities nil)
  (kee:put.value 'worker 'initialize.system
                 (lambda (self)
                   (kee:put.value self 'state 'initialized)))
  (kee:unitmsg 'worker 'initialize.system)
  (check (eq (kee:get.value 'worker 'state) 'initialized))
  (let ((log nil))
    (kee:create.unit 'drawable 'veg 'entities 'classes)
    (kee:create.slot 'drawable 'draw 'member nil 'method 'method)
    (kee:add.method 'drawable 'draw :before
                    (lambda (self)
                      (declare (ignore self))
                      (push 'parent-before log)))
    (kee:add.method 'drawable 'draw :primary
                    (lambda (self)
                      (declare (ignore self))
                      (push 'parent-primary log)))
    (kee:add.method 'drawable 'draw :after
                    (lambda (self)
                      (declare (ignore self))
                      (push 'parent-after log)))
    (kee:create.unit 'highlighted.drawable 'veg 'drawable nil)
    (kee:add.method 'highlighted.drawable 'draw :before
                    (lambda (self)
                      (declare (ignore self))
                      (push 'child-before log)))
    (kee:add.method 'highlighted.drawable 'draw :after
                    (lambda (self)
                      (declare (ignore self))
                      (push 'child-after log)))
    (kee:unitmsg 'highlighted.drawable 'draw)
    (check (equal (reverse log)
                  '(child-before parent-before parent-primary
                    child-after parent-after)))
    (setf log nil)
    (kee:add.method 'highlighted.drawable 'draw :primary
                    (lambda (self)
                      (declare (ignore self))
                      (push 'child-primary log)))
    (kee:unitmsg 'highlighted.drawable 'draw)
    (check (equal (reverse log)
                  '(child-before parent-before child-primary
                    child-after parent-after))))
  (let ((events nil))
    (kee:create.unit 'audit.av 'veg 'entities nil)
    (kee:put.value 'audit.av 'kee:value-written
                   (lambda (self target slot old new)
                     (declare (ignore self))
                     (push (list 'written (kee:unit.name target) slot old new)
                           events)))
    (kee:put.value 'audit.av 'kee:value-read
                   (lambda (self target slot old new)
                     (declare (ignore self old))
                     (push (list 'read (kee:unit.name target) slot new)
                           events)))
    (kee:put.facet.value 'sample.1 'complete.description
                         'kee:active.values 'audit.av)
    (kee:put.value 'sample.1 'complete.description "changed")
    (kee:get.value 'sample.1 'complete.description)
    (check (equal (reverse events)
                  '((written sample.1 complete.description
                     ("demo sample") ("changed"))
                    (read sample.1 complete.description ("changed"))))))
  (kee:create.unit 'technique.selection.rules 'veg 'entities 'classes)
  (kee:put.value 'technique.selection.rules 'kee:parse #'kee:parse)
  (let ((wave (kee:create.unit 'wavelength.1 'veg nil nil)))
    (kee:add.value 'estimate.hemispherical.reflectance
                   'current.sample.wavelengths
                   wave)
    (kee:put.value wave 'reflectance.data '((0 0 0.31) (30 180 0.28)))
    (kee:create.unit 'pgcswr.10 'veg nil 'technique.selection.rules)
    (kee:put.value 'pgcswr.10 'kee:external.form
                   '(if (the current.sample.wavelengths
                         of estimate.hemispherical.reflectance
                         is ?x)
                        (lisp (consp (get.value ?x 'reflectance.data)))
                        then
                        (lisp (add.value ?x 'techniques
                                         'pgc.near.nadir))))
    (kee:create.unit 'pgc.followup 'veg nil 'technique.selection.rules)
    (kee:put.value 'pgc.followup 'kee:external.form
                   '(if (the current.sample.wavelengths
                         of estimate.hemispherical.reflectance
                         is ?x)
                        (the techniques of ?x is pgc.near.nadir)
                        then
                        (lisp (add.value ?x 'recommended.techniques
                                         'pgc.near.nadir))))
    (check (kee:unitmsg 'pgcswr.10 'kee:parse))
    (check (kee:unitmsg 'pgc.followup 'kee:parse))
    (check (null (kee:get.value 'pgcswr.10 'kee:parse.errors)))
    (check (equal (sort (names (kee:forward.chain 'technique.selection.rules))
                        #'string<
                        :key #'symbol-name)
                  '(pgc.followup pgcswr.10)))
    (check (equal (kee:get.values wave 'techniques)
                  '(pgc.near.nadir)))
    (check (equal (kee:get.values wave 'recommended.techniques)
                  '(pgc.near.nadir)))
    (kee:forward.chain 'technique.selection.rules)
    (check (equal (kee:get.values wave 'techniques)
                  '(pgc.near.nadir)))
    (check (equal (kee:get.values wave 'recommended.techniques)
                  '(pgc.near.nadir))))
  (kee:create.unit 'people 'veg 'entities 'classes)
  (kee:create.unit 'tom 'veg nil 'people)
  (kee:create.unit 'constraint.rules 'veg 'entities 'classes)
  (kee:create.unit 'heights.golf 'veg nil 'constraint.rules)
  (kee:put.value 'heights.golf 'kee:external.form
                 '(while (the sport of tom is golf)
                         (the phobia of tom is heights)
                    believe false))
  (check (kee:parse 'heights.golf))
  (let ((bad-world (kee:create.world 'tom-golf-heights))
        (good-world (kee:create.world 'tom-golf-cats)))
    (kee:with-world (bad-world)
      (kee:put.value 'tom 'sport 'golf)
      (kee:put.value 'tom 'phobia 'heights)
      (kee:forward.chain 'constraint.rules)
      (check (kee:world.inconsistent.p bad-world)))
    (kee:with-world (good-world)
      (kee:put.value 'tom 'sport 'golf)
      (kee:put.value 'tom 'phobia 'cats)
      (kee:forward.chain 'constraint.rules)
      (check (not (kee:world.inconsistent.p good-world))))
    (check (kee:true.in.world bad-world 'tom 'sport 'golf))
    (check (null (kee:get.value 'tom 'sport))))
  (format t "~&~A~%" (if (zerop *failures*) "All tests passed." "Tests failed."))
  (unless (zerop *failures*)
    (quit-with-status 1)))

(run)
