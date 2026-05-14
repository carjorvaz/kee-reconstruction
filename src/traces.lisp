(in-package #:kee)

(defvar *trace-events* nil)
(defvar *trace-counter* 0)
(defvar *trace-agenda-counter* 0)
(defvar *trace-activation-counter* 0)
(defvar *trace-fire-counter* 0)
(defvar *trace-enabled-p* t)
(defvar *current-trace-agenda-id* nil)
(defvar *current-trace-activation-id* nil)
(defvar *current-trace-fire-id* nil)

(defun clear.trace.events ()
  "Clear the reconstructed RuleSystem/KEEworlds trace log."
  (setf *trace-events* nil
        *trace-counter* 0
        *trace-agenda-counter* 0
        *trace-activation-counter* 0
        *trace-fire-counter* 0)
  nil)

(pushnew #'clear.trace.events *reset-hooks*)

(defun proper-trace-list-p (value)
  (or (null value)
      (and (consp value)
           (proper-trace-list-p (cdr value)))))

(defun trace-value (value)
  (cond ((typep value 'kee-unit) (unit.name value))
        ((and (consp value) (proper-trace-list-p value))
         (mapcar #'trace-value value))
        ((consp value)
         (cons (trace-value (car value))
               (trace-value (cdr value))))
        (t value)))

(defun trace-binding-value (binding)
  (cons (car binding) (trace-value (cdr binding))))

(defun normalize-trace-value (key value)
  (case key
    (:bindings (mapcar #'trace-binding-value value))
    (otherwise (trace-value value))))

(defun normalize-trace-plist (entries)
  (loop for (key value) on entries by #'cddr
        append (list key (normalize-trace-value key value))))

(defun next.trace.agenda.id ()
  (incf *trace-agenda-counter*))

(defun next.trace.activation.id ()
  (incf *trace-activation-counter*))

(defun next.trace.fire.id ()
  (incf *trace-fire-counter*))

(defun trace-entry-present-p (key entries)
  (loop for tail on entries by #'cddr
        thereis (eq (first tail) key)))

(defun trace-context-entries (entries)
  (append
   (when (and *current-trace-agenda-id*
              (not (trace-entry-present-p :agenda-id entries)))
     (list :agenda-id *current-trace-agenda-id*))
   (when (and *current-trace-activation-id*
              (not (trace-entry-present-p :activation-id entries)))
     (list :activation-id *current-trace-activation-id*))
   (when (and *current-trace-fire-id*
              (not (trace-entry-present-p :fire-id entries)))
     (list :fire-id *current-trace-fire-id*))))

(defun record.trace.event (kind &rest entries)
  "Append a structured trace event and return it.

KIND is a keyword such as `:rule-fire`, `:agenda`, `:world-create`, or
`:contradiction`. ENTRIES is a plist of event attributes."
  (when *trace-enabled-p*
    (let* ((raw-entries (append entries (trace-context-entries entries)))
           (event (append (list :id (incf *trace-counter*) :kind kind)
                          (normalize-trace-plist raw-entries))))
      (push event *trace-events*)
      event)))

(defun trace-event-match-p (event kind world rule)
  (and (or (null kind) (eq (getf event :kind) kind))
       (or (null world) (equal (getf event :world) world))
       (or (null rule) (equal (getf event :rule) rule))))

(defun trace.events (&key kind world rule limit)
  "Return trace events in chronological order, optionally filtered."
  (let ((events
          (remove-if-not
           (lambda (event)
             (trace-event-match-p event kind world rule))
           (reverse *trace-events*))))
    (if limit
        (last events (min limit (length events)))
        events)))
