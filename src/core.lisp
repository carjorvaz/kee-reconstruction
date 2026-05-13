(in-package #:kee)

(defstruct (knowledge-base (:constructor make-knowledge-base (name)))
  name
  (units (make-hash-table :test #'eq)))

(defstruct (kee-slot (:constructor make-kee-slot (name kind)))
  name
  kind
  local-values
  inherited-values
  combined-values
  inheritance
  value-type
  default
  (facets (make-hash-table :test #'eq)))

(defstruct (kee-unit (:constructor %make-unit (name kb)))
  name
  kb
  comment
  class-parents
  member-parents
  class-children
  member-children
  (slots (make-hash-table :test #'eq)))

(defvar *knowledge-bases* (make-hash-table :test #'eq))
(defvar *current-kb* nil)
(defvar *active-value-depth* 0)
(defvar *change-count* 0)

(defun reset-kee ()
  "Clear all reconstructed KEE state."
  (setf *knowledge-bases* (make-hash-table :test #'eq)
        *current-kb* nil
        *change-count* 0)
  t)

(defun create.kb (name)
  (let ((new (make-knowledge-base name)))
    (setf (gethash name *knowledge-bases*) new
          *current-kb* new)
    new))

(defun kb.exists.p (name)
  (gethash name *knowledge-bases*))

(defun goto.kb (name)
  (let ((found (kb.exists.p name)))
    (unless found
      (error "No knowledge base named ~S exists." name))
    (setf *current-kb* found)))

(defun kb (&optional name)
  (cond (name
         (or (kb.exists.p name)
             (error "No knowledge base named ~S exists." name)))
        (*current-kb*)
        (t (error "No current knowledge base."))))

(defun kb.name (kb)
  (knowledge-base-name (if (typep kb 'knowledge-base) kb (kb kb))))

(defun unit-key (thing)
  (cond ((typep thing 'kee-unit) (values (kee-unit-name thing)
                                         (knowledge-base-name
                                          (kee-unit-kb thing))))
        ((and (consp thing) (symbolp (first thing)))
         (values (first thing) (second thing)))
        ((symbolp thing)
         (values thing (and *current-kb* (knowledge-base-name *current-kb*))))
        (t (error "Cannot use ~S as a unit designator." thing))))

(defun unit.exists.p (thing &optional kb-name)
  (cond ((typep thing 'kee-unit) thing)
        (t
         (multiple-value-bind (name embedded-kb) (unit-key thing)
           (let ((target-kb (or kb-name embedded-kb)))
             (when target-kb
               (let ((kb (kb.exists.p target-kb)))
                 (and kb (gethash name (knowledge-base-units kb))))))))))

(defun unit (thing &optional kb-name)
  (or (unit.exists.p thing kb-name)
      (error "No unit named ~S exists." thing)))

(defun unit.name (unit)
  (kee-unit-name (unit unit)))

(defun unit.kb (unit)
  (kee-unit-kb (unit unit)))

(defun normalize-unit-list (items)
  (cond ((null items) nil)
        ((typep items 'kee-unit) (list items))
        ((symbolp items) (list (unit items)))
        ((and (consp items)
              (symbolp (first items))
              (symbolp (second items))
              (null (cddr items))
              (kb.exists.p (second items)))
         (list (unit items)))
        ((and (consp items) (not (consp (first items))))
         (mapcar #'unit items))
        (t (mapcar #'unit items))))

(defun add-child-link (parent child relation)
  (ecase relation
    (subclass (pushnew child (kee-unit-class-children parent)))
    (member (pushnew child (kee-unit-member-children parent)))))

(defun remove-child-link (parent child relation)
  (ecase relation
    (subclass
     (setf (kee-unit-class-children parent)
           (remove child (kee-unit-class-children parent))))
    (member
     (setf (kee-unit-member-children parent)
           (remove child (kee-unit-member-children parent))))))

(defun all-parents (unit)
  (append (kee-unit-class-parents unit)
          (kee-unit-member-parents unit)))

(defun all-children (unit)
  (append (kee-unit-class-children unit)
          (kee-unit-member-children unit)))

(defun ensure-slot (unit name &key (kind 'own))
  (or (gethash name (kee-unit-slots unit))
      (setf (gethash name (kee-unit-slots unit))
            (make-kee-slot name kind))))

(defun inherited-values-for (unit slot-name)
  (loop for parent in (all-parents unit)
        for parent-slot = (gethash slot-name (kee-unit-slots parent))
        when parent-slot
          append (kee-slot-combined-values parent-slot)))

(defun method-contribution-kind (value)
  (cond ((and (consp value) (member (first value) '(before after wrapper)))
         (first value))
        (t 'primary)))

(defun method-slot-p (slot)
  (or (eq (kee-slot-inheritance slot) 'method)
      (eq (kee-slot-value-type slot) 'method)
      (some (lambda (value)
              (member (method-contribution-kind value) '(before after wrapper)))
            (append (kee-slot-local-values slot)
                    (kee-slot-inherited-values slot)))))

(defun method-contributions-of-kind (kind values)
  (remove-if-not (lambda (value)
                   (eq (method-contribution-kind value) kind))
                 values))

(defun combine-method-values (local inherited)
  (let ((local-primary (method-contributions-of-kind 'primary local))
        (inherited-primary (method-contributions-of-kind 'primary inherited)))
    (append
     (method-contributions-of-kind 'before local)
     (method-contributions-of-kind 'before inherited)
     (method-contributions-of-kind 'wrapper local)
     (method-contributions-of-kind 'wrapper inherited)
     (if local-primary local-primary inherited-primary)
     (method-contributions-of-kind 'after local)
     (method-contributions-of-kind 'after inherited))))

(defun recompute-slot (unit slot-name)
  (let* ((slot (ensure-slot unit slot-name))
         (inherited (inherited-values-for unit slot-name))
         (local (kee-slot-local-values slot)))
    (setf (kee-slot-inherited-values slot) inherited
          (kee-slot-combined-values slot)
          (cond ((method-slot-p slot)
                 (combine-method-values local inherited))
                (local local)
                (t inherited)))
    slot))

(defun propagate-slot (unit slot-name)
  (dolist (child (all-children unit))
    (recompute-slot child slot-name)
    (propagate-slot child slot-name)))

(defun all-parent-slot-names (unit)
  (remove-duplicates
   (loop for parent in (all-parents unit)
         append (loop for name being the hash-keys of (kee-unit-slots parent)
                      collect name))
   :test #'eq))

(defun initialize-inherited-slots (unit)
  (dolist (slot-name (all-parent-slot-names unit))
    (recompute-slot unit slot-name)))

(defun normalize-slot-values (values)
  (cond ((null values) nil)
        ((listp values) values)
        (t (list values))))

(defun install-slot-spec (unit kind spec)
  (destructuring-bind (name &optional initial-values inheritance value-type default facets)
      spec
    (let ((slot (ensure-slot unit name :kind kind)))
      (setf (kee-slot-kind slot) kind
            (kee-slot-local-values slot) (normalize-slot-values initial-values)
            (kee-slot-inheritance slot) inheritance
            (kee-slot-value-type slot) value-type
            (kee-slot-default slot) default)
      (dolist (facet facets)
        (when (consp facet)
          (setf (gethash (first facet) (kee-slot-facets slot))
                (rest facet))))
      (recompute-slot unit name)
      (propagate-slot unit name)
      slot)))

(defun create.unit (name kb-designator class-parents member-parents
                    &optional comment member-slots own-slots)
  (let* ((target-kb (if (typep kb-designator 'knowledge-base)
                        kb-designator
                        (kb kb-designator)))
         (new (%make-unit name target-kb)))
    (when (gethash name (knowledge-base-units target-kb))
      (error "Unit ~S already exists in KB ~S." name (knowledge-base-name target-kb)))
    (setf (kee-unit-comment new) comment
          (kee-unit-class-parents new) (normalize-unit-list class-parents)
          (kee-unit-member-parents new) (normalize-unit-list member-parents)
          (gethash name (knowledge-base-units target-kb)) new)
    (dolist (parent (kee-unit-class-parents new))
      (add-child-link parent new 'subclass))
    (dolist (parent (kee-unit-member-parents new))
      (add-child-link parent new 'member))
    (initialize-inherited-slots new)
    (dolist (slot-spec member-slots)
      (install-slot-spec new 'member slot-spec))
    (dolist (slot-spec own-slots)
      (install-slot-spec new 'own slot-spec))
    new))

(defun rename.unit (unit-designator new-name)
  (let* ((unit (unit unit-designator))
         (kb (kee-unit-kb unit))
         (old-name (kee-unit-name unit)))
    (remhash old-name (knowledge-base-units kb))
    (setf (kee-unit-name unit) new-name
          (gethash new-name (knowledge-base-units kb)) unit)
    unit))

(defun delete.unit (unit-designator &rest ignored)
  (declare (ignore ignored))
  (let* ((unit (unit unit-designator))
         (kb (kee-unit-kb unit)))
    (dolist (parent (kee-unit-class-parents unit))
      (remove-child-link parent unit 'subclass))
    (dolist (parent (kee-unit-member-parents unit))
      (remove-child-link parent unit 'member))
    (remhash (kee-unit-name unit) (knowledge-base-units kb))
    t))

(defun relation-parents (unit relation)
  (ecase relation
    (subclass (kee-unit-class-parents unit))
    (member (kee-unit-member-parents unit))))

(defun relation-children (unit relation)
  (ecase relation
    (subclass (kee-unit-class-children unit))
    (member (kee-unit-member-children unit))))

(defun unit.parents (unit-designator &optional relation)
  (let ((unit (unit unit-designator)))
    (if relation
        (relation-parents unit relation)
        (all-parents unit))))

(defun unit.children (unit-designator &optional relation)
  (let ((unit (unit unit-designator)))
    (if relation
        (relation-children unit relation)
        (all-children unit))))

(defun unit.ancestors (unit-designator &optional relation)
  (labels ((walk (unit seen)
             (loop for parent in (unit.parents unit relation)
                   unless (member parent seen)
                     append (cons parent (walk parent (cons parent seen))))))
    (walk (unit unit-designator) nil)))

(defun unit.descendant.p (possible-descendant possible-ancestor &optional relation)
  (let ((descendant (unit possible-descendant))
        (ancestor (unit possible-ancestor)))
    (and (member ancestor (unit.ancestors descendant relation)) descendant)))

(defun unit.slot.names (unit-designator)
  (loop for name being the hash-keys of (kee-unit-slots (unit unit-designator))
        collect name))

(defun create.slot (unit-designator name kind &optional values inheritance
                    value-type default facets &rest ignored)
  (declare (ignore ignored))
  (let ((unit (unit unit-designator)))
    (install-slot-spec unit kind
                       (list name values inheritance value-type default facets))))

(defun slot.exists.p (&rest args)
  (destructuring-bind (first second &optional third) args
    (cond (third
           (let ((unit (unit.exists.p second third)))
             (and unit (gethash first (kee-unit-slots unit)))))
          (t
           (let ((unit (unit.exists.p first)))
             (and unit (gethash second (kee-unit-slots unit))))))))

(defun delete.slot (unit-designator name &rest ignored)
  (declare (ignore ignored))
  (let ((unit (unit unit-designator)))
    (remhash name (kee-unit-slots unit))
    (propagate-slot unit name)
    t))

(defun slot-values-for-facet (slot facet)
  (ecase facet
    (own (kee-slot-local-values slot))
    (local (kee-slot-local-values slot))
    (inherited (kee-slot-inherited-values slot))
    (combined (kee-slot-combined-values slot))))

(defun note-change (old-values new-values)
  (unless (equal old-values new-values)
    (incf *change-count*)))

(defun facet-values (slot facet)
  (copy-list (gethash facet (kee-slot-facets slot))))

(defun active-value-units (slot)
  (when slot
    (remove nil
            (mapcar #'unit.exists.p
                    (append (facet-values slot 'active.values)
                            (facet-values slot 'active-values))))))

(defun invoke-active-values (unit slot-name operation old-values new-values)
  (when (zerop *active-value-depth*)
    (let ((slot (gethash slot-name (kee-unit-slots unit))))
      (dolist (active-value (active-value-units slot))
        (when (slot.exists.p active-value operation)
          (let ((*active-value-depth* (1+ *active-value-depth*)))
            (unitmsg active-value operation
                     unit slot-name old-values new-values)))))))

(defun get.values (unit-designator slot-name &optional facet)
  (let* ((unit (unit unit-designator))
         (slot (gethash slot-name (kee-unit-slots unit))))
    (cond ((null slot) nil)
          (facet (copy-list (slot-values-for-facet slot facet)))
          (t (let ((values (copy-list (kee-slot-combined-values slot))))
               (invoke-active-values unit slot-name 'value-read values values)
               values)))))

(defun get.value (unit-designator slot-name &optional facet)
  (first (get.values unit-designator slot-name facet)))

(defun put.values (unit-designator slot-name values &optional facet)
  (declare (ignore facet))
  (let* ((unit (unit unit-designator))
         (slot (ensure-slot unit slot-name))
         (old-values (copy-list (kee-slot-combined-values slot))))
    (setf (kee-slot-local-values slot) (copy-list values))
    (recompute-slot unit slot-name)
    (propagate-slot unit slot-name)
    (note-change old-values (kee-slot-combined-values slot))
    (invoke-active-values unit slot-name 'value-written
                          old-values (copy-list (kee-slot-combined-values slot)))
    values))

(defun put.value (unit-designator slot-name value &optional facet)
  (put.values unit-designator slot-name (list value) facet)
  value)

(defun add.values (unit-designator slot-name values &optional facet)
  (declare (ignore facet))
  (let* ((unit (unit unit-designator))
         (slot (ensure-slot unit slot-name))
         (old-values (copy-list (kee-slot-combined-values slot)))
         (new-local-values (copy-list (kee-slot-local-values slot))))
    (dolist (value values)
      (unless (member value new-local-values :test #'equal)
        (setf new-local-values (append new-local-values (list value)))))
    (setf (kee-slot-local-values slot)
          new-local-values)
    (recompute-slot unit slot-name)
    (propagate-slot unit slot-name)
    (note-change old-values (kee-slot-combined-values slot))
    (invoke-active-values unit slot-name 'value-added
                          old-values (copy-list (kee-slot-combined-values slot)))
    values))

(defun add.value (unit-designator slot-name value &optional facet)
  (add.values unit-designator slot-name (list value) facet)
  value)

(defun remove.all.values (unit-designator slot-name &optional facet)
  (declare (ignore facet))
  (let* ((unit (unit unit-designator))
         (slot (ensure-slot unit slot-name))
         (old-values (copy-list (kee-slot-combined-values slot))))
    (setf (kee-slot-local-values slot) nil)
    (recompute-slot unit slot-name)
    (propagate-slot unit slot-name)
    (note-change old-values (kee-slot-combined-values slot))
    (invoke-active-values unit slot-name 'values-removed
                          old-values (copy-list (kee-slot-combined-values slot)))
    nil))

(defun put.facet.value (unit-designator slot-name facet value &rest ignored)
  (declare (ignore ignored))
  (let* ((slot (ensure-slot (unit unit-designator) slot-name)))
    (setf (gethash facet (kee-slot-facets slot)) (list value))
    value))

(defun remove.all.facet.values (unit-designator slot-name facet &rest ignored)
  (declare (ignore ignored))
  (let ((slot (slot.exists.p unit-designator slot-name)))
    (when slot
      (remhash facet (kee-slot-facets slot))))
  nil)

(defun add.method (unit-designator slot-name kind function-designator)
  "Add a method contribution to a method slot.

KIND is one of :primary, :before, or :after. Around methods are represented
internally, but this first public helper does not expose them yet."
  (let ((unit (unit unit-designator)))
    (unless (slot.exists.p unit slot-name)
      (create.slot unit slot-name 'member nil 'method 'method))
    (ecase kind
      (:primary (add.value unit slot-name function-designator))
      (:before (add.value unit slot-name `(before ,function-designator)))
      (:after (add.value unit slot-name `(after ,function-designator))))))

(defun callable-method (method-value)
  (cond ((functionp method-value) method-value)
        ((and (symbolp method-value) (fboundp method-value))
         (symbol-function method-value))
        ((and (consp method-value) (eq (first method-value) 'lambda))
         (coerce method-value 'function))
        (t nil)))

(defun method-callable (contribution)
  (case (method-contribution-kind contribution)
    ((before after)
     (callable-method (second contribution)))
    (wrapper
     nil)
    (otherwise
     (callable-method contribution))))

(defun call-method-contribution (contribution target args)
  (let ((fn (method-callable contribution)))
    (unless fn
      (error "Method contribution ~S is not callable." contribution))
    (apply fn target args)))

(defun unitmsg (unit-designator message &rest args)
  (let* ((target (unit unit-designator))
         (methods (get.values target message)))
    (unless methods
      (error "Unit ~S has no method slot ~S." (unit.name target) message))
    (let ((result nil))
      (dolist (method (method-contributions-of-kind 'before methods))
        (call-method-contribution method target args))
      (dolist (method (method-contributions-of-kind 'primary methods))
        (setf result (call-method-contribution method target args)))
      (dolist (method (method-contributions-of-kind 'after methods))
        (setf result (call-method-contribution method target args)))
      result)))

(defun unitmsg* (unit-designator message args)
  (apply #'unitmsg unit-designator message args))
