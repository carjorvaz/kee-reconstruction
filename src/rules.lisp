(in-package #:kee)

(defun rule-symbol-p (value name)
  (and (symbolp value) (string= (symbol-name value) name)))

(defun variable-symbol-p (value)
  (and (symbolp value)
       (plusp (length (symbol-name value)))
       (char= (char (symbol-name value) 0) #\?)))

(defun variable-key (variable)
  (string-upcase (symbol-name variable)))

(defun bound-variable-p (variable bindings)
  (assoc (variable-key variable) bindings :test #'string=))

(defun variable-value (variable bindings)
  (cdr (bound-variable-p variable bindings)))

(defun bind-variable (variable value bindings)
  (acons (variable-key variable) value bindings))

(defun split-at-keyword (items keyword-name)
  (let ((position (position-if (lambda (item)
                                 (rule-symbol-p item keyword-name))
                               items)))
    (unless position
      (error "Expected ~A in ~S." keyword-name items))
    (values (subseq items 0 position)
            (subseq items (1+ position)))))

(defun read-rule-form (external-form)
  (cond ((stringp external-form)
         (with-input-from-string (stream external-form)
           (read stream nil nil)))
        (t external-form)))

(defun find-if-form (form)
  (cond ((and (consp form) (rule-symbol-p (first form) "IF"))
         form)
        ((and (consp form) (rule-symbol-p (first form) "RULE"))
         (find-if #'(lambda (item)
                      (and (consp item) (rule-symbol-p (first item) "IF")))
                  form))
        (t nil)))

(defun parse-if-form (form)
  (let ((if-form (find-if-form (read-rule-form form))))
    (unless if-form
      (error "Rule form does not contain an IF form: ~S." form))
    (multiple-value-bind (conditions actions) (split-at-keyword (rest if-form) "THEN")
      (when (null actions)
        (error "Rule has no THEN actions: ~S." form))
      (list :source if-form
            :conditions conditions
            :actions actions))))

(defun parse (rule-unit-designator)
  "Parse a rule unit's EXTERNAL.FORM into INTERNAL.FORM.

This is a deliberately small TellAndAsk/RuleSystem subset. It supports IF,
THEN, THE/OF/IS patterns, and LISP conditions/actions."
  (let ((rule-unit (unit rule-unit-designator)))
    (handler-case
        (let ((parsed (parse-if-form (get.value rule-unit 'external.form))))
          (put.value rule-unit 'internal.form parsed)
          (remove.all.values rule-unit 'parse.errors)
          parsed)
      (error (condition)
        (put.values rule-unit 'parse.errors (list (princ-to-string condition)))
        nil))))

(defun same-rule-value-p (left right)
  (cond ((and (typep left 'kee-unit) (symbolp right))
         (string= (symbol-name (unit.name left)) (symbol-name right)))
        ((and (symbolp left) (typep right 'kee-unit))
         (string= (symbol-name left) (symbol-name (unit.name right))))
        (t (equal left right))))

(defun resolve-rule-term (term bindings)
  (if (and (variable-symbol-p term) (bound-variable-p term bindings))
      (variable-value term bindings)
      term))

(defun match-rule-value (pattern value bindings)
  (cond ((variable-symbol-p pattern)
         (let ((bound (bound-variable-p pattern bindings)))
           (cond ((null bound)
                  (list (bind-variable pattern value bindings)))
                 ((same-rule-value-p (cdr bound) value)
                  (list bindings))
                 (t nil))))
        ((same-rule-value-p pattern value)
         (list bindings))
        (t nil)))

(defun parse-the-condition (condition)
  (unless (and (consp condition) (rule-symbol-p (first condition) "THE"))
    (error "Not a THE condition: ~S." condition))
  (multiple-value-bind (slot-and-unit value-part)
      (split-at-keyword (rest condition) "IS")
    (multiple-value-bind (slot-part unit-part)
        (split-at-keyword slot-and-unit "OF")
      (unless (and (= (length slot-part) 1) (= (length unit-part) 1)
                   (= (length value-part) 1))
        (error "Malformed THE condition: ~S." condition))
      (values (first slot-part) (first unit-part) (first value-part)))))

(defun evaluate-the-condition (condition bindings)
  (multiple-value-bind (slot-name unit-term value-pattern)
      (parse-the-condition condition)
    (let ((target-unit (resolve-rule-term unit-term bindings)))
      (when (variable-symbol-p target-unit)
        (error "Unbound unit variable in THE condition: ~S." condition))
      (loop for value in (get.values target-unit slot-name)
            append (match-rule-value value-pattern value bindings)))))

(defun canonical-function-symbol (symbol)
  (multiple-value-bind (kee-symbol status) (find-symbol (symbol-name symbol) '#:kee)
    (if (and status (fboundp kee-symbol)) kee-symbol symbol)))

(defun substitute-rule-bindings (form bindings)
  (cond ((variable-symbol-p form)
         (resolve-rule-term form bindings))
        ((atom form) form)
        ((rule-symbol-p (first form) "QUOTE") form)
        (t (cons (if (symbolp (first form))
                     (canonical-function-symbol (first form))
                     (substitute-rule-bindings (first form) bindings))
                 (mapcar (lambda (item)
                           (substitute-rule-bindings item bindings))
                         (rest form))))))

(defun lisp-clause-body (clause)
  (cond ((null (rest clause)) nil)
        ((null (cddr clause)) (second clause))
        (t `(progn ,@(rest clause)))))

(defun evaluate-lisp-clause (clause bindings)
  (eval (substitute-rule-bindings (lisp-clause-body clause) bindings)))

(defun evaluate-condition (condition bindings)
  (cond ((and (consp condition) (rule-symbol-p (first condition) "THE"))
         (evaluate-the-condition condition bindings))
        ((and (consp condition) (rule-symbol-p (first condition) "LISP"))
         (and (evaluate-lisp-clause condition bindings)
              (list bindings)))
        (t (error "Unsupported rule condition: ~S." condition))))

(defun evaluate-conditions (conditions)
  (let ((bindings-list (list nil)))
    (dolist (condition conditions bindings-list)
      (setf bindings-list
            (loop for bindings in bindings-list
                  append (evaluate-condition condition bindings))))))

(defun execute-action (action bindings)
  (cond ((and (consp action) (rule-symbol-p (first action) "LISP"))
         (evaluate-lisp-clause action bindings))
        (t (error "Unsupported rule action: ~S." action))))

(defun parsed-rule (rule-unit)
  (or (get.value rule-unit 'internal.form)
      (parse rule-unit)))

(defun execute-rule (rule-unit)
  (let ((parsed (parsed-rule rule-unit)))
    (when parsed
      (let ((bindings-list (evaluate-conditions (getf parsed :conditions))))
        (dolist (bindings bindings-list)
          (dolist (action (getf parsed :actions))
            (execute-action action bindings)))
        (and bindings-list t)))))

(defun forward.chain (rule-class-designator &key (max-passes 100))
  "Run member rules of RULE-CLASS-DESIGNATOR until no slot values change."
  (let ((fired nil))
    (loop repeat max-passes
          for before = *change-count*
          do (dolist (rule-unit (unit.children rule-class-designator 'member))
               (when (execute-rule rule-unit)
                 (pushnew rule-unit fired)))
          until (= before *change-count*)
          finally (return (nreverse fired)))))
