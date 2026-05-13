(in-package #:kee)

(defstruct (kee-world (:constructor %make-world (name parent)))
  name
  parent
  (values (make-hash-table :test #'equal))
  inconsistent-p)

(defvar *worlds* (make-hash-table :test #'eq))
(defvar *current-world* nil)
(defvar *world-counter* 0)

(defun reset-worlds ()
  (setf *worlds* (make-hash-table :test #'eq)
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

(defun $worlds ()
  (loop for world being the hash-values of *worlds*
        collect world))

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

(defun world-active-p ()
  (not (null *current-world*)))

(defun world-get-values (unit slot-name)
  (world-effective-values *current-world* unit slot-name))

(defun set-world-values (unit slot-name values)
  (let ((old-values (world-effective-values *current-world* unit slot-name)))
    (setf (gethash (world-key unit slot-name)
                   (kee-world-values *current-world*))
          (copy-list values))
    (note-change old-values values)
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

(defun true.in.world (world-designator unit-designator slot-name value)
  (let ((target-world (world world-designator))
        (target-unit (unit unit-designator)))
    (with-world (target-world)
      (member value (get.values target-unit slot-name) :test #'equal))))

(defun believe (proposition)
  (cond ((and (symbolp proposition)
              (string= (symbol-name proposition) "FALSE"))
         (let ((world (or *current-world*
                          (setf *current-world* (create.world 'base.world)))))
           (unless (kee-world-inconsistent-p world)
             (setf (kee-world-inconsistent-p world) t)
             (incf *change-count*))
           nil))
        (t (error "Unsupported BELIEVE proposition: ~S." proposition))))

(setf *world-active-p-hook* #'world-active-p
      *world-get-values-hook* #'world-get-values
      *world-put-values-hook* #'world-put-values
      *world-add-values-hook* #'world-add-values
      *world-remove-all-values-hook* #'world-remove-all-values)
