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

(defun rule-head-p (item name)
  (and (consp item) (rule-symbol-p (first item) name)))

(defun find-rule-form (form)
  (cond ((and (consp form)
              (or (rule-symbol-p (first form) "IF")
                  (rule-symbol-p (first form) "WHILE")))
         form)
        ((and (consp form) (rule-symbol-p (first form) "RULE"))
         (find-if #'(lambda (item)
                      (and (consp item)
                           (or (rule-symbol-p (first item) "IF")
                               (rule-symbol-p (first item) "WHILE"))))
                  form))
        (t nil)))

(defun split-while-form (items)
  (let ((position (position-if
                   (lambda (item)
                     (or (rule-symbol-p item "BELIEVE")
                         (rule-head-p item "BELIEVE")
                         (rule-symbol-p item "IN.NEW.WORLD")
                         (rule-head-p item "IN.NEW.WORLD")))
                   items)))
    (unless position
      (error "Expected an action in WHILE rule: ~S." items))
    (let ((conditions (subseq items 0 position))
          (action-tail (subseq items position)))
      (values conditions
              (if (consp (first action-tail))
                  action-tail
                  (list action-tail))))))

(defun parse-rule-form (form)
  (let ((rule-form (find-rule-form (read-rule-form form))))
    (unless rule-form
      (error "Rule form does not contain an IF or WHILE form: ~S." form))
    (cond ((rule-symbol-p (first rule-form) "IF")
           (multiple-value-bind (conditions actions)
               (split-at-keyword (rest rule-form) "THEN")
             (when (null actions)
               (error "Rule has no THEN actions: ~S." form))
             (list :kind :if
                   :source rule-form
                   :conditions conditions
                   :actions actions)))
          ((rule-symbol-p (first rule-form) "WHILE")
           (multiple-value-bind (conditions actions)
               (split-while-form (rest rule-form))
             (list :kind :while
                   :source rule-form
                   :conditions conditions
                   :actions actions))))))

(defun parse (rule-unit-designator)
  "Parse a rule unit's EXTERNAL.FORM into INTERNAL.FORM.

This is a deliberately small TellAndAsk/RuleSystem subset. It supports IF,
WHILE, THEN, THE/OF/IS patterns, BELIEVE FALSE, and LISP conditions/actions."
  (let ((rule-unit (unit rule-unit-designator)))
    (handler-case
        (let ((parsed (parse-rule-form (get.value rule-unit 'external.form))))
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
      (cond ((and (variable-symbol-p unit-term)
                  (not (bound-variable-p unit-term bindings)))
             (loop for candidate being the hash-values of
                     (knowledge-base-units (kb))
                   append
                   (let ((candidate-bindings
                           (bind-variable unit-term candidate bindings)))
                     (loop for value in (get.values candidate slot-name)
                           append (match-rule-value value-pattern value
                                                    candidate-bindings)))))
            ((variable-symbol-p target-unit)
             (error "Unbound unit variable in THE condition: ~S." condition))
            (t
             (loop for value in (get.values target-unit slot-name)
                   append (match-rule-value value-pattern value bindings)))))))

(defun canonical-function-symbol (symbol)
  (multiple-value-bind (kee-symbol status) (find-symbol (symbol-name symbol) '#:kee)
    (if (and status (fboundp kee-symbol)) kee-symbol symbol)))

(defun lisp-literal (value)
  (if (or (symbolp value) (consp value))
      `',value
      value))

(defun substitute-rule-bindings (form bindings)
  (cond ((variable-symbol-p form)
         (lisp-literal (resolve-rule-term form bindings)))
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

(defun cant.find (unit-designator slot-name)
  (null (get.values unit-designator slot-name)))

(defun find.any (unit-designator slot-name)
  (get.value unit-designator slot-name))

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

(defun quoted-rule-form-p (form)
  (and (consp form)
       (rule-symbol-p (first form) "QUOTE")
       (null (cddr form))))

(defun proper-rule-list-p (value)
  (or (null value)
      (and (consp value)
           (proper-rule-list-p (cdr value)))))

(defun rule-reference-term (term)
  (cond ((quoted-rule-form-p term) (second term))
        ((typep term 'kee-unit) (unit.name term))
        ((and (consp term) (proper-rule-list-p term))
         (mapcar #'rule-reference-term term))
        (t term)))

(defun rule-reference-operation (symbol)
  (intern (symbol-name symbol) '#:keyword))

(defun make-rule-slot-reference
    (&key kind context operation unit slot value source)
  (list :kind kind
        :context context
        :operation operation
        :unit (rule-reference-term unit)
        :slot (rule-reference-term slot)
        :value (rule-reference-term value)
        :source source))

(defun make-rule-assertion-reference (&key context operation proposition source)
  (list :kind :assert
        :context context
        :operation operation
        :proposition (rule-reference-term proposition)
        :source source))

(defun rule-the-reference (form context kind operation)
  (handler-case
      (multiple-value-bind (slot-name unit-term value-term)
          (parse-the-condition form)
        (list (make-rule-slot-reference
               :kind kind
               :context context
               :operation operation
               :unit unit-term
               :slot slot-name
               :value value-term
               :source form)))
    (error () nil)))

(defun rule-read-call-p (symbol)
  (and (symbolp symbol)
       (member (symbol-name symbol)
               '("GET.VALUE" "GET.VALUES" "FIND.ANY" "CANT.FIND")
               :test #'string=)))

(defun rule-write-call-p (symbol)
  (and (symbolp symbol)
       (member (symbol-name symbol)
               '("PUT.VALUE" "PUT.VALUES" "ADD.VALUE" "ADD.VALUES"
                 "REMOVE.ALL.VALUES" "REMOVE.ALL.FACET.VALUES"
                 "PUT.FACET.VALUE")
               :test #'string=)))

(defun rule-lisp-call-reference (form context)
  (let ((operator (first form))
        (arguments (rest form)))
    (cond ((and (rule-read-call-p operator)
                (>= (length arguments) 2))
           (list (make-rule-slot-reference
                  :kind :read
                  :context context
                  :operation (rule-reference-operation operator)
                  :unit (first arguments)
                  :slot (second arguments)
                  :source form)))
          ((and (rule-write-call-p operator)
                (>= (length arguments) 2))
           (list (make-rule-slot-reference
                  :kind :write
                  :context context
                  :operation (rule-reference-operation operator)
                  :unit (first arguments)
                  :slot (second arguments)
                  :value (third arguments)
                  :source form)))
          (t nil))))

(defun collect-lisp-rule-references (form context)
  (cond ((atom form) nil)
        ((quoted-rule-form-p form) nil)
        (t (append (rule-lisp-call-reference form context)
                   (loop for item in (rest form)
                         append (collect-lisp-rule-references
                                 item context))))))

(defun rule-condition-references (condition)
  (cond ((rule-head-p condition "THE")
         (rule-the-reference condition :condition :read :the))
        ((rule-head-p condition "LISP")
         (loop for form in (rest condition)
               append (collect-lisp-rule-references form :condition)))
        (t nil)))

(defun rule-action-references (action)
  (cond ((rule-head-p action "LISP")
         (loop for form in (rest action)
               append (collect-lisp-rule-references form :action)))
        ((rule-head-p action "IN.NEW.WORLD")
         (loop for form in (rest action)
               when (rule-head-p form "THE")
                 append (rule-the-reference form :action :write
                                            :in.new.world)
               else append (when (rule-head-p form "LISP")
                             (loop for lisp-form in (rest form)
                                   append (collect-lisp-rule-references
                                           lisp-form :action)))))
        ((rule-head-p action "BELIEVE")
         (list (make-rule-assertion-reference
                :context :action
                :operation :believe
                :proposition (second action)
                :source action)))
        (t nil)))

(defun rule-reference-source-present-p (rule-unit)
  (or (get.value rule-unit 'internal.form)
      (get.value rule-unit 'external.form)))

(defun parsed-rule (rule-unit)
  (or (get.value rule-unit 'internal.form)
      (parse rule-unit)))

(defun rule.references (rule-unit-designator)
  "Return a reconstructed static cross-reference report for a rule unit."
  (let ((rule-unit (unit rule-unit-designator)))
    (when (rule-reference-source-present-p rule-unit)
      (let ((parsed (parsed-rule rule-unit)))
        (when parsed
          (let* ((condition-refs
                   (loop for condition in (getf parsed :conditions)
                         append (rule-condition-references condition)))
                 (action-refs
                   (loop for action in (getf parsed :actions)
                         append (rule-action-references action)))
                 (references (remove-duplicates
                              (append condition-refs action-refs)
                              :test #'equal)))
            (list :rule (unit.name rule-unit)
                  :kb (kb.name (unit.kb rule-unit))
                  :kind (getf parsed :kind)
                  :rule-classes (mapcar #'unit.name
                                         (unit.parents rule-unit 'member))
                  :reads (remove-if-not
                          (lambda (reference)
                            (eq (getf reference :kind) :read))
                          references)
                  :writes (remove-if-not
                           (lambda (reference)
                             (eq (getf reference :kind) :write))
                           references)
                  :asserts (remove-if-not
                            (lambda (reference)
                              (eq (getf reference :kind) :assert))
                            references))))))))

(defun rule-reference-candidates (&key kb rule-class)
  (cond (rule-class
         (unit.children rule-class 'member))
        (t (sort
            (loop for rule-unit being the hash-values of
                    (knowledge-base-units (or (and kb (kb kb)) (kb)))
                  collect rule-unit)
            #'string<
            :key #'unit.name))))

(defun rule.reference.index (&key kb rule-class)
  "Return reconstructed static cross-reference reports for known rule units."
  (remove nil
          (mapcar #'rule.references
                  (rule-reference-candidates
                   :kb kb
                   :rule-class rule-class))))

(defun current-trace-world-name ()
  (and (current.world) (get.world.name (current.world))))

(defun execute-action (action bindings)
  (cond ((and (consp action) (rule-symbol-p (first action) "LISP"))
         (evaluate-lisp-clause action bindings))
        ((and (consp action) (rule-symbol-p (first action) "BELIEVE"))
         (believe (substitute-rule-bindings (second action) bindings)))
        ((and (consp action) (rule-symbol-p (first action) "IN.NEW.WORLD"))
         (execute-in-new-world-action action bindings))
        (t (error "Unsupported rule action: ~S." action))))

(defun resolved-fact (fact bindings)
  (multiple-value-bind (slot-name unit-term value-term)
      (parse-the-condition fact)
    (let ((target-unit (resolve-rule-term unit-term bindings))
          (target-value (resolve-rule-term value-term bindings)))
      (when (variable-symbol-p target-unit)
        (error "Unbound unit variable in IN.NEW.WORLD fact: ~S." fact))
      (values (unit target-unit) slot-name target-value))))

(defun fact-value-alternatives (unit slot-name value-term)
  (cond ((and (consp value-term) (constraint-symbol-p (first value-term) "ONE.OF"))
         (rest value-term))
        ((and (symbolp value-term)
              (or (constraint-symbol-p value-term "$VALUES")
                  (constraint-symbol-p value-term "VALUES")))
         (or (slot.allowed.values unit slot-name)
             (error "No value.class facet is available for ~S of ~S."
                    slot-name (unit.name unit))))
        (t (list value-term))))

(defun assert-the-fact (fact bindings)
  (multiple-value-bind (target-unit slot-name value-term)
      (resolved-fact fact bindings)
    (when (variable-symbol-p value-term)
      (error "Unbound value variable in IN.NEW.WORLD fact: ~S." fact))
    (dolist (target-value (fact-value-alternatives target-unit slot-name value-term))
      (put.value target-unit slot-name target-value))))

(defun execute-in-new-world-action (action bindings)
  (labels ((branch (world remaining)
             (if (null remaining)
                 world
                 (let ((item (first remaining)))
                   (cond ((rule-head-p item "THE")
                          (multiple-value-bind (target-unit slot-name value-term)
                              (resolved-fact item bindings)
                            (let ((result-worlds nil))
                              (dolist (target-value
                                        (fact-value-alternatives target-unit
                                                                 slot-name
                                                                 value-term))
                                (let* ((fact-signature
                                         (list (kb.name (unit.kb target-unit))
                                               (unit.name target-unit)
                                               slot-name
                                               (list target-value)))
                                       (child-world
                                         (ensure.fact.branch.world world
                                                                   fact-signature)))
                                  (with-world (child-world)
                                    (put.value target-unit slot-name target-value)
                                    (push (branch child-world (rest remaining))
                                          result-worlds))))
                              (nreverse result-worlds))))
                         ((rule-head-p item "LISP")
                          (with-world (world)
                            (evaluate-lisp-clause item bindings))
                          (branch world (rest remaining)))
                         (t (error "Unsupported IN.NEW.WORLD fact/action: ~S."
                                   item)))))))
    (branch *current-world* (rest action))))

(defun execute-rule (rule-unit)
  (let ((parsed (parsed-rule rule-unit)))
    (when parsed
      (let ((bindings-list (evaluate-conditions (getf parsed :conditions))))
        (dolist (bindings bindings-list)
          (record.trace.event :rule-match
                              :world (current-trace-world-name)
                              :rule (unit.name rule-unit)
                              :bindings bindings
                              :conditions (getf parsed :conditions))
          (dolist (action (getf parsed :actions))
            (let ((*current-rule-unit* rule-unit)
                  (*current-rule-bindings* bindings)
                  (*current-rule-conditions* (getf parsed :conditions))
                  (*current-rule-action* action))
              (record.trace.event :rule-fire
                                  :world (current-trace-world-name)
                                  :rule (unit.name rule-unit)
                                  :bindings bindings
                                  :conditions (getf parsed :conditions)
                                  :action action)
              (execute-action action bindings))))
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

(defun normalize-rule-class-list (rule-classes)
  (cond ((null rule-classes) nil)
        ((listp rule-classes) rule-classes)
        (t (list rule-classes))))

(defun run.world.agenda (rule-classes &key (max-iterations 20))
  "Run RULE-CLASSES across consistent worlds until worlds and values stabilize."
  (let ((classes (normalize-rule-class-list rule-classes)))
    (when (null ($worlds))
      (create.world 'base.world))
    (loop repeat max-iterations
          for before = (list (length ($worlds)) *change-count*)
          do (dolist (world (copy-list (consistent.worlds)))
               (with-world (world)
                 (dolist (rule-class classes)
                   (unless (world.inconsistent.p world)
                     (record.trace.event :agenda
                                         :world (get.world.name world)
                                         :rule-class (unit.name (unit rule-class))
                                         :message "forward-chain")
                     (forward.chain rule-class)))))
          until (equal before (list (length ($worlds)) *change-count*)))
    (consistent.worlds)))
