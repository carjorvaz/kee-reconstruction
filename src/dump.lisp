(in-package #:kee)

(defparameter *kb-dump-format* :reconstructed-kee-kb)
(defparameter *kb-dump-version* 1)

(defun dump-readable-atom (value)
  (handler-case
      (let ((*print-readably* t))
        (prin1-to-string value)
        value)
    (print-not-readable ()
      (error "Cannot dump unreadable value ~S. This first dumper supports ~
readable Lisp data and reconstructed KEE unit references, not live functions."
             value))))

(defun dump-value (value)
  (cond ((typep value 'kee-unit)
         (list :kee-dump-unit-ref
               (unit.name value)
               (kb.name (unit.kb value))))
        ((typep value 'knowledge-base)
         (list :kee-dump-kb-ref (kb.name value)))
        ((consp value)
         (cons (dump-value (car value))
               (dump-value (cdr value))))
        (t (dump-readable-atom value))))

(defun restore-dump-value (value)
  (cond ((and (consp value)
              (eq (first value) :kee-dump-unit-ref))
         (unit (second value) (third value)))
        ((and (consp value)
              (eq (first value) :kee-dump-kb-ref))
         (kb (second value)))
        ((consp value)
         (cons (restore-dump-value (car value))
               (restore-dump-value (cdr value))))
        (t value)))

(defun dump-values (values)
  (mapcar #'dump-value values))

(defun restore-dump-values (values)
  (mapcar #'restore-dump-value values))

(defun dump-slot-facets (slot)
  (sort
   (loop for facet being the hash-keys of (kee-slot-facets slot)
           using (hash-value values)
         collect (cons facet (dump-values values)))
   #'string<
   :key (lambda (entry) (symbol-name (car entry)))))

(defun dump-slot (slot)
  (list :name (kee-slot-name slot)
        :kind (kee-slot-kind slot)
        :local-values (dump-values (kee-slot-local-values slot))
        :inheritance (dump-value (kee-slot-inheritance slot))
        :value-type (dump-value (kee-slot-value-type slot))
        :default (dump-value (kee-slot-default slot))
        :facets (dump-slot-facets slot)))

(defun dump-unit-slot-list (unit)
  (sort
   (loop for slot being the hash-values of (kee-unit-slots unit)
         collect (dump-slot slot))
   #'string<
   :key (lambda (slot) (symbol-name (getf slot :name)))))

(defun dump-unit (unit)
  (list :name (unit.name unit)
        :comment (dump-value (kee-unit-comment unit))
        :class-parents (mapcar #'unit.name (unit.parents unit 'subclass))
        :member-parents (mapcar #'unit.name (unit.parents unit 'member))
        :slots (dump-unit-slot-list unit)))

(defun dump.kb (&optional kb-designator)
  "Return a readable s-expression dump of KB-DESIGNATOR.

This is a clean-room reconstruction aid inspired by public KEE delivery and
KATYDID evidence. It preserves units, parent links, local slots, slot facets,
and reconstructed unit references. Live functions are intentionally rejected:
the first dumper records portable KB data, not executable Lisp images."
  (let* ((target-kb (if kb-designator (kb kb-designator) (kb)))
         (units (sort (loop for unit being the hash-values of
                              (knowledge-base-units target-kb)
                            collect unit)
                      #'string<
                      :key #'unit.name)))
    (list :format *kb-dump-format*
          :version *kb-dump-version*
          :kb (kb.name target-kb)
          :units (mapcar #'dump-unit units))))

(defun dump-unit-entry-name (entry)
  (or (getf entry :name)
      (error "KB dump unit entry has no :NAME: ~S." entry)))

(defun restore-parent-list (names kb-name)
  (mapcar (lambda (name) (unit name kb-name)) names))

(defun restore-unit-parents (entry kb-name)
  (let ((unit (unit (dump-unit-entry-name entry) kb-name)))
    (setf (kee-unit-class-parents unit)
          (restore-parent-list (getf entry :class-parents) kb-name)
          (kee-unit-member-parents unit)
          (restore-parent-list (getf entry :member-parents) kb-name))
    (dolist (parent (kee-unit-class-parents unit))
      (add-child-link parent unit 'subclass))
    (dolist (parent (kee-unit-member-parents unit))
      (add-child-link parent unit 'member))
    unit))

(defun restore-slot-facets (facets)
  (mapcar (lambda (facet)
            (cons (car facet)
                  (restore-dump-values (cdr facet))))
          facets))

(defun restore-unit-slots (entry kb-name)
  (let ((unit (unit (dump-unit-entry-name entry) kb-name)))
    (dolist (slot (getf entry :slots))
      (install-slot-spec
       unit
       (or (getf slot :kind) 'own)
       (list (getf slot :name)
             (restore-dump-values (getf slot :local-values))
             (restore-dump-value (getf slot :inheritance))
             (restore-dump-value (getf slot :value-type))
             (restore-dump-value (getf slot :default))
             (restore-slot-facets (getf slot :facets))))))
  t)

(defun validate-kb-dump (dump)
  (unless (and (listp dump)
               (eq (getf dump :format) *kb-dump-format*)
               (= (or (getf dump :version) 0) *kb-dump-version*)
               (getf dump :kb)
               (listp (getf dump :units)))
    (error "Not a supported reconstructed KEE KB dump: ~S." dump))
  dump)

(defun load.kb.dump (dump &key replace)
  "Load a KB from DUMP and return the reconstructed knowledge base.

When REPLACE is true, an existing KB with the same name is removed first."
  (let* ((validated (validate-kb-dump dump))
         (kb-name (getf validated :kb))
         (entries (getf validated :units)))
    (when (kb.exists.p kb-name)
      (unless replace
        (error "KB ~S already exists. Use :REPLACE T to overwrite it." kb-name))
      (remhash kb-name *knowledge-bases*))
    (let ((target-kb (create.kb kb-name)))
      (dolist (entry entries)
        (create.unit (dump-unit-entry-name entry)
                     target-kb
                     nil
                     nil
                     (restore-dump-value (getf entry :comment))))
      (dolist (entry entries)
        (restore-unit-parents entry kb-name))
      (dolist (entry entries)
        (restore-unit-slots entry kb-name))
      target-kb)))

(defun write.kb.dump (stream &optional kb-designator)
  "Write a readable KB dump to STREAM."
  (let ((*print-readably* t)
        (*print-circle* t)
        (*package* (find-package :cl-user)))
    (pprint (dump.kb kb-designator) stream))
  (values))

(defun read.kb.dump (stream)
  "Read one KB dump from STREAM."
  (read stream))
