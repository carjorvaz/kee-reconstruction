(in-package #:kee)

(defstruct (kee-world (:constructor %make-world (name parent)))
  name
  parent
  (values (make-hash-table :test #'equal))
  inconsistent-p
  assumptions
  justifications
  nogoods)

(defstruct (kee-justification
            (:constructor make-justification
                (&key rule bindings conditions action proposition))
            (:conc-name justification.))
  rule
  bindings
  conditions
  action
  proposition)

(defstruct (kee-nogood
            (:constructor make-nogood (&key world justification environment))
            (:conc-name nogood.))
  world
  justification
  environment)

(defstruct (kee-assumption
            (:constructor make-assumption
                (&key world parent fact rule bindings conditions action
                      agenda-id activation-id fire-id))
            (:conc-name assumption.))
  world
  parent
  fact
  rule
  bindings
  conditions
  action
  agenda-id
  activation-id
  fire-id)

(defvar *worlds* (make-hash-table :test #'eq))
(defvar *world-branches* (make-hash-table :test #'equal))
(defvar *world-fact-index* (make-hash-table :test #'equal))
(defvar *current-world* nil)
(defvar *world-counter* 0)
(defvar *current-rule-unit* nil)
(defvar *current-rule-bindings* nil)
(defvar *current-rule-conditions* nil)
(defvar *current-rule-action* nil)

(defun reset-worlds ()
  (setf *worlds* (make-hash-table :test #'eq)
        *world-branches* (make-hash-table :test #'equal)
        *world-fact-index* (make-hash-table :test #'equal)
        *current-world* nil
        *world-counter* 0))

(pushnew #'reset-worlds *reset-hooks*)

(defun world (world-designator)
  (cond ((null world-designator) nil)
        ((typep world-designator 'kee-world) world-designator)
        ((symbolp world-designator)
         (or (gethash world-designator *worlds*)
             (error "No world named ~S exists." world-designator)))
        (t (error "Cannot use ~S as a world designator." world-designator))))

(defun create.world (&optional name parent-designator)
  (let* ((world-name (or name (intern (format nil "WORLD-~D" (incf *world-counter*))
                                      '#:kee)))
         (parent (if parent-designator
                     (world parent-designator)
                     *current-world*))
         (new (%make-world world-name parent)))
    (setf (gethash world-name *worlds*) new)
    (record.trace.event :world-create
                        :world world-name
                        :parent (and parent (kee-world-name parent)))
    new))

(defun goto.world (world-designator)
  (setf *current-world* (world world-designator)))

(defun current.world ()
  *current-world*)

(defun world.parent (world-designator)
  (kee-world-parent (world world-designator)))

(defun get.world.name (world-designator)
  (kee-world-name (world world-designator)))

(defun world.inconsistent.p (world-designator)
  (kee-world-inconsistent-p (world world-designator)))

(defun world.justifications (world-designator)
  (copy-list (kee-world-justifications (world world-designator))))

(defun world.nogoods (world-designator)
  (copy-list (kee-world-nogoods (world world-designator))))

(defun world.assumptions (world-designator)
  (reverse (copy-list (kee-world-assumptions (world world-designator)))))

(defun world.environment (world-designator)
  (loop for ancestor in (world-ancestor-chain (world world-designator))
        append (world.assumptions ancestor)))

(defun world.facts (world-designator)
  (let ((world (world world-designator)))
    (loop for key being the hash-keys of (kee-world-values world)
            using (hash-value values)
          collect (destructuring-bind (kb-name unit-name slot-name) key
                    (list :kb kb-name
                          :unit unit-name
                          :slot slot-name
                          :values (copy-list values))))))

(defun $worlds ()
  (loop for world being the hash-values of *worlds*
        collect world))

(defun consistent.worlds ()
  (remove-if #'world.inconsistent.p ($worlds)))

(defmacro with-world ((world-designator) &body body)
  `(let ((*current-world* (world ,world-designator)))
     ,@body))

(defun world-key (unit slot-name)
  (list (kb.name (unit.kb unit)) (unit.name unit) slot-name))

(defun base-slot-values (unit slot-name)
  (let ((slot (gethash slot-name (kee-unit-slots unit))))
    (when slot
      (copy-list (kee-slot-combined-values slot)))))

(defun world-local-values (world key)
  (multiple-value-bind (values presentp) (gethash key (kee-world-values world))
    (values (copy-list values) presentp)))

(defun world-effective-values (world unit slot-name)
  (let ((key (world-key unit slot-name)))
    (labels ((walk (candidate)
               (if candidate
                   (multiple-value-bind (values presentp)
                       (world-local-values candidate key)
                     (if presentp
                         values
                         (walk (kee-world-parent candidate))))
                   (base-slot-values unit slot-name))))
      (walk world))))

(defun world-ancestor-chain (world)
  (let ((result nil))
    (loop for cursor = world then (kee-world-parent cursor)
          while cursor
          do (push cursor result))
    result))

(defun world-effective-fact-signature (world &optional extra-fact)
  (let ((facts (make-hash-table :test #'equal)))
    (dolist (ancestor (world-ancestor-chain world))
      (loop for key being the hash-keys of (kee-world-values ancestor)
              using (hash-value values)
            do (setf (gethash key facts) (copy-list values))))
    (when extra-fact
      (destructuring-bind (kb-name unit-name slot-name values) extra-fact
        (setf (gethash (list kb-name unit-name slot-name) facts)
              (copy-list values))))
    (sort
     (loop for key being the hash-keys of facts
             using (hash-value values)
           collect (append key (list values)))
     #'string<
     :key #'prin1-to-string)))

(defun world-active-p ()
  (not (null *current-world*)))

(defun world-get-values (unit slot-name)
  (world-effective-values *current-world* unit slot-name))

(defun set-world-values (unit slot-name values)
  (let ((old-values (world-effective-values *current-world* unit slot-name)))
    (validate-slot-values unit slot-name values)
    (setf (gethash (world-key unit slot-name)
                   (kee-world-values *current-world*))
          (copy-list values))
    (note-change old-values values)
    (unless (equal old-values values)
      (record.trace.event :world-slot-write
                          :world (kee-world-name *current-world*)
                          :unit (unit.name unit)
                          :slot slot-name
                          :old-values old-values
                          :new-values values))
    values))

(defun world-put-values (unit slot-name values)
  (set-world-values unit slot-name values))

(defun world-add-values (unit slot-name values)
  (let ((new-values (world-effective-values *current-world* unit slot-name)))
    (dolist (value values)
      (unless (member value new-values :test #'equal)
        (setf new-values (append new-values (list value)))))
    (set-world-values unit slot-name new-values)
    values))

(defun world-remove-all-values (unit slot-name)
  (set-world-values unit slot-name nil)
  nil)

(defun in.new.world (&optional name)
  (let ((new (create.world name *current-world*)))
    (goto.world new)))

(defun ensure.branch.world (key)
  (or (gethash key *world-branches*)
      (setf (gethash key *world-branches*)
            (create.world nil *current-world*))))

(defun ensure.fact.branch.world (parent fact)
  (let ((signature (world-effective-fact-signature parent fact)))
    (or (gethash signature *world-fact-index*)
        (let ((new (create.world nil parent)))
          (setf (gethash signature *world-fact-index*) new)
          (record-world-assumption new parent fact)
          (record.trace.event :world-branch
                              :world (kee-world-name new)
                              :parent (kee-world-name parent)
                              :fact fact)
          new))))

(defun true.in.world (world-designator unit-designator slot-name value)
  (let ((target-world (world world-designator))
        (target-unit (unit unit-designator)))
    (with-world (target-world)
      (member value (get.values target-unit slot-name) :test #'equal))))

(defun justification-value (value)
  (cond ((typep value 'kee-unit) (unit.name value))
        ((consp value) (mapcar #'justification-value value))
        (t value)))

(defun current-bindings-for-justification ()
  (mapcar (lambda (binding)
            (cons (car binding) (justification-value (cdr binding))))
          *current-rule-bindings*))

(defun make-current-justification (proposition)
  (make-justification
   :rule (and *current-rule-unit* (unit.name *current-rule-unit*))
   :bindings (current-bindings-for-justification)
   :conditions *current-rule-conditions*
   :action *current-rule-action*
   :proposition proposition))

(defun make-current-assumption (world parent fact)
  (make-assumption
   :world (kee-world-name world)
   :parent (and parent (kee-world-name parent))
   :fact (copy-tree fact)
   :rule (and *current-rule-unit* (unit.name *current-rule-unit*))
   :bindings (current-bindings-for-justification)
   :conditions (copy-tree *current-rule-conditions*)
   :action (copy-tree *current-rule-action*)
   :agenda-id *current-trace-agenda-id*
   :activation-id *current-trace-activation-id*
   :fire-id *current-trace-fire-id*))

(defun same-assumption-p (left right)
  (and (equal (assumption.world left) (assumption.world right))
       (equal (assumption.parent left) (assumption.parent right))
       (equal (assumption.fact left) (assumption.fact right))
       (equal (assumption.rule left) (assumption.rule right))
       (equal (assumption.bindings left) (assumption.bindings right))))

(defun record-world-assumption (world parent fact)
  (let ((assumption (make-current-assumption world parent fact)))
    (unless (some (lambda (existing)
                    (same-assumption-p existing assumption))
                  (kee-world-assumptions world))
      (push assumption (kee-world-assumptions world)))
    assumption))

(defun same-justification-p (left right)
  (and (equal (justification.rule left) (justification.rule right))
       (equal (justification.bindings left) (justification.bindings right))
       (equal (justification.conditions left) (justification.conditions right))
       (equal (justification.action left) (justification.action right))
       (equal (justification.proposition left) (justification.proposition right))))

(defun record-world-justification (world justification)
  (unless (some (lambda (existing)
                  (same-justification-p existing justification))
                (kee-world-justifications world))
    (push justification (kee-world-justifications world))
    (push (make-nogood :world (kee-world-name world)
                       :justification justification
                       :environment (world.environment world))
          (kee-world-nogoods world))
    (record.trace.event :nogood
                        :world (kee-world-name world)
                        :rule (justification.rule justification)
                        :bindings (justification.bindings justification)
                        :conditions (justification.conditions justification)
                        :action (justification.action justification)
                        :proposition (justification.proposition justification))
    (incf *change-count*)
    t))

(defun why.false (&optional world-designator)
  (mapcar #'nogood.justification
          (world.nogoods (or world-designator *current-world*))))

(defun believe (proposition)
  (cond ((and (symbolp proposition)
              (string= (symbol-name proposition) "FALSE"))
         (let ((world (or *current-world*
                          (setf *current-world* (create.world 'base.world))))
               (justification (make-current-justification proposition)))
           (record-world-justification world justification)
           (unless (kee-world-inconsistent-p world)
             (setf (kee-world-inconsistent-p world) t)
             (record.trace.event :contradiction
                                 :world (kee-world-name world)
                                 :rule (justification.rule justification)
                                 :bindings (justification.bindings justification)
                                 :proposition proposition)
             (incf *change-count*))
           nil))
        (t (error "Unsupported BELIEVE proposition: ~S." proposition))))

(setf *world-active-p-hook* #'world-active-p
      *world-get-values-hook* #'world-get-values
      *world-put-values-hook* #'world-put-values
      *world-add-values-hook* #'world-add-values
      *world-remove-all-values-hook* #'world-remove-all-values)
