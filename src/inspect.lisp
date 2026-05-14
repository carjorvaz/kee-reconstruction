(in-package #:kee)

(defun list.kbs ()
  (sort (loop for name being the hash-keys of *knowledge-bases*
              collect name)
        #'string<
        :key #'symbol-name))

(defun list.units (&optional kb-designator)
  (let ((target-kb (or (and kb-designator (kb kb-designator)) (kb))))
    (sort (loop for unit being the hash-values of (knowledge-base-units target-kb)
                collect unit)
          #'string<
          :key #'unit.name)))

(defun values-for-display (values)
  (mapcar (lambda (value)
            (if (typep value 'kee-unit) (unit.name value) value))
          values))

(defun local-slot-facet-names (unit slot-name)
  (let ((slot (gethash slot-name (kee-unit-slots unit))))
    (when slot
      (loop for facet being the hash-keys of (kee-slot-facets slot)
            collect facet))))

(defun effective-slot-facet-names (unit slot-name)
  (labels ((walk (candidate seen)
             (unless (member candidate seen)
               (append (local-slot-facet-names candidate slot-name)
                       (loop for parent in (all-parents candidate)
                             append (walk parent (cons candidate seen)))))))
    (remove-duplicates (walk unit nil) :test #'eq)))

(defun slot-facets-for-display (unit slot-name)
  (sort
   (loop for facet in (effective-slot-facet-names unit slot-name)
         collect (cons facet
                       (values-for-display
                        (slot.facet.values unit slot-name facet))))
   #'string<
   :key (lambda (entry) (symbol-name (car entry)))))

(defun inspect.slot (unit-designator slot-name)
  (let* ((target-unit (unit unit-designator))
         (slot (or (slot.exists.p target-unit slot-name)
                   (error "No slot ~S on unit ~S."
                          slot-name (unit.name target-unit)))))
    (list :name slot-name
          :kind (kee-slot-kind slot)
          :local-values (values-for-display (kee-slot-local-values slot))
          :inherited-values (values-for-display (kee-slot-inherited-values slot))
          :combined-values (values-for-display (get.values target-unit slot-name))
          :inheritance (kee-slot-inheritance slot)
          :value-type (kee-slot-value-type slot)
          :default (kee-slot-default slot)
          :facets (slot-facets-for-display target-unit slot-name))))

(defun inspect.unit (unit-designator)
  (let ((target-unit (unit unit-designator)))
    (list :name (unit.name target-unit)
          :kb (kb.name (unit.kb target-unit))
          :class-parents (mapcar #'unit.name (unit.parents target-unit 'subclass))
          :member-parents (mapcar #'unit.name (unit.parents target-unit 'member))
          :class-children (mapcar #'unit.name (unit.children target-unit 'subclass))
          :member-children (mapcar #'unit.name (unit.children target-unit 'member))
          :slots (mapcar (lambda (slot-name)
                           (inspect.slot target-unit slot-name))
                         (sort (unit.slot.names target-unit)
                               #'string<
                               :key #'symbol-name)))))

(defun inspect.assumption (assumption)
  (list :world (assumption.world assumption)
        :parent (assumption.parent assumption)
        :fact (assumption.fact assumption)
        :rule (assumption.rule assumption)
        :bindings (assumption.bindings assumption)
        :conditions (assumption.conditions assumption)
        :action (assumption.action assumption)
        :agenda-id (assumption.agenda-id assumption)
        :activation-id (assumption.activation-id assumption)
        :fire-id (assumption.fire-id assumption)))

(defun inspect.nogood (nogood)
  (let ((justification (nogood.justification nogood)))
    (list :world (nogood.world nogood)
          :rule (justification.rule justification)
          :bindings (justification.bindings justification)
          :conditions (justification.conditions justification)
          :action (justification.action justification)
          :proposition (justification.proposition justification)
          :environment (mapcar #'inspect.assumption
                               (nogood.environment nogood)))))

(defun inspect.world (world-designator)
  (let ((target-world (world world-designator)))
    (list :name (get.world.name target-world)
          :parent (and (world.parent target-world)
                       (get.world.name (world.parent target-world)))
          :inconsistent-p (world.inconsistent.p target-world)
          :facts (world.facts target-world)
          :environment (mapcar #'inspect.assumption
                               (world.environment target-world))
          :nogoods (mapcar #'inspect.nogood
                            (world.nogoods target-world)))))

(defun inspect.world.tree ()
  (sort
   (mapcar #'inspect.world ($worlds))
   #'string<
   :key (lambda (entry) (symbol-name (getf entry :name)))))

(defun inspected-world-report-p (value)
  (and (listp value)
       (member :name value)
       (member :inconsistent-p value)))

(defun world-for-display (world-designator-or-report)
  (if (inspected-world-report-p world-designator-or-report)
      world-designator-or-report
      (inspect.world world-designator-or-report)))

(defun print-list-line (stream label values &optional (indent 2))
  (format stream "~&~VT~A: ~{~S~^, ~}" indent label values))

(defun print-slot (stream slot &optional (indent 4))
  (format stream "~&~VT~S = ~S" indent
          (getf slot :name)
          (getf slot :combined-values))
  (when (getf slot :facets)
    (format stream " facets ~S" (getf slot :facets))))

(defun print-unit (stream unit)
  (format stream "~&~S [KB ~S]" (getf unit :name) (getf unit :kb))
  (print-list-line stream "subclass parents" (getf unit :class-parents))
  (print-list-line stream "member parents" (getf unit :member-parents))
  (print-list-line stream "subclass children" (getf unit :class-children))
  (print-list-line stream "member children" (getf unit :member-children))
  (dolist (slot (getf unit :slots))
    (print-slot stream slot)))

(defun print-world (stream world)
  (format stream "~&~S parent ~S inconsistent? ~S"
          (getf world :name)
          (getf world :parent)
          (getf world :inconsistent-p))
  (dolist (fact (getf world :facts))
    (format stream "~&  fact ~S/~S ~S => ~S"
            (getf fact :kb)
            (getf fact :unit)
            (getf fact :slot)
            (getf fact :values)))
  (dolist (nogood (getf world :nogoods))
    (format stream "~&  nogood rule ~S bindings ~S proposition ~S"
            (getf nogood :rule)
            (getf nogood :bindings)
            (getf nogood :proposition))))

(defun print.browser (&key (stream *standard-output*) units worlds)
  "Print a compact terminal browser for the current reconstructed KEE image."
  (format stream "~&Knowledge Bases: ~{~S~^, ~}~%" (list.kbs))
  (dolist (kb-name (list.kbs))
    (format stream "~&~%KB ~S" kb-name)
    (let ((unit-list (list.units kb-name)))
      (format stream "~&  Units: ~{~S~^, ~}" (mapcar #'unit.name unit-list))
      (dolist (unit-designator (or units (mapcar #'unit.name unit-list)))
        (when (unit.exists.p unit-designator kb-name)
          (format stream "~&")
          (print-unit stream (inspect.unit (list unit-designator kb-name)))))))
  (when (or worlds ($worlds))
    (format stream "~&~%Worlds")
    (dolist (world (if worlds
                       (mapcar #'world-for-display worlds)
                       (inspect.world.tree)))
      (print-world stream world)))
  (values))
