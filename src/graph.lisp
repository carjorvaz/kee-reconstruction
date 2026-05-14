(in-package #:kee)

(defun graph-symbol-label (value)
  (cond ((symbolp value) (symbol-name value))
        (t (princ-to-string value))))

(defun graph-unit-id (kb-name unit-name)
  (format nil "unit:~A/~A" (graph-symbol-label kb-name)
          (graph-symbol-label unit-name)))

(defun graph-world-id (world-name)
  (format nil "world:~A" (graph-symbol-label world-name)))

(defun graph-kb-name (&optional kb-designator)
  (kb.name (if kb-designator (kb kb-designator) (kb))))

(defun graph-unit-designator (unit-name kb-name)
  (list unit-name kb-name))

(defun graph-unit-report (unit-name kb-name)
  (inspect.unit (graph-unit-designator unit-name kb-name)))

(defun graph-unit-names (kb-name units)
  (let ((selected
          (if units
              (mapcar (lambda (unit-designator)
                        (unit.name (unit unit-designator kb-name)))
                      units)
              (mapcar #'unit.name (list.units kb-name)))))
    (sort
     (remove-duplicates
      (loop for name in selected
            for report = (graph-unit-report name kb-name)
            append (append (list name)
                           (getf report :class-parents)
                           (getf report :member-parents)))
      :test #'eq)
     #'string<
     :key #'symbol-name)))

(defun graph-unit-node (report)
  (list :id (graph-unit-id (getf report :kb) (getf report :name))
        :name (getf report :name)
        :kb (getf report :kb)
        :slots (mapcar (lambda (slot) (getf slot :name))
                       (getf report :slots))))

(defun graph-unit-edge (kb-name parent child relation)
  (list :from (graph-unit-id kb-name parent)
        :to (graph-unit-id kb-name child)
        :relation relation))

(defun graph-unit-edges (reports kb-name)
  (sort
   (loop for report in reports
         for child = (getf report :name)
         append (append
                 (loop for parent in (getf report :class-parents)
                       collect (graph-unit-edge kb-name parent child
                                                'subclass))
                 (loop for parent in (getf report :member-parents)
                       collect (graph-unit-edge kb-name parent child
                                                'member))))
   #'string<
   :key (lambda (edge)
          (format nil "~A/~A/~A"
                  (getf edge :from)
                  (getf edge :to)
                  (getf edge :relation)))))

(defun unit.graph (&key kb units)
  "Return a structured unit hierarchy graph for KB."
  (let* ((kb-name (graph-kb-name kb))
         (unit-names (graph-unit-names kb-name units))
         (reports (mapcar (lambda (unit-name)
                            (graph-unit-report unit-name kb-name))
                          unit-names)))
    (list :kind :unit-graph
          :kb kb-name
          :nodes (mapcar #'graph-unit-node reports)
          :edges (graph-unit-edges reports kb-name))))

(defun limited-world-reports (worlds limit)
  (let ((reports (if worlds
                     (mapcar #'world-for-display worlds)
                     (inspect.world.tree))))
    (if limit
        (subseq reports 0 (min limit (length reports)))
        reports)))

(defun graph-world-node (report)
  (list :id (graph-world-id (getf report :name))
        :name (getf report :name)
        :parent (getf report :parent)
        :inconsistent-p (getf report :inconsistent-p)
        :fact-count (length (getf report :facts))
        :nogood-count (length (getf report :nogoods))))

(defun graph-world-edge (report)
  (when (getf report :parent)
    (list :from (graph-world-id (getf report :parent))
          :to (graph-world-id (getf report :name))
          :relation 'parent)))

(defun missing-parent-world-reports (reports)
  (let ((names (mapcar (lambda (report) (getf report :name)) reports)))
    (remove nil
            (mapcar (lambda (report)
                      (let ((parent (getf report :parent)))
                        (when (and parent (not (member parent names)))
                          (inspect.world parent))))
                    reports))))

(defun world.graph (&key worlds limit)
  "Return a structured graph for the current KEEworlds DAG."
  (let* ((selected-reports (limited-world-reports worlds limit))
         (reports (remove-duplicates
                   (append selected-reports
                           (missing-parent-world-reports selected-reports))
                   :test #'eq
                   :key (lambda (report) (getf report :name)))))
    (list :kind :world-graph
          :nodes (mapcar #'graph-world-node reports)
          :edges (remove nil (mapcar #'graph-world-edge selected-reports)))))

(defun dot-escape-string (value)
  (with-output-to-string (stream)
    (loop for char across (princ-to-string value)
          do (case char
               (#\\ (write-string "\\\\" stream))
               (#\" (write-string "\\\"" stream))
               (#\Newline (write-string "\\n" stream))
               (t (write-char char stream))))))

(defun dot-string (value)
  (format nil "\"~A\"" (dot-escape-string value)))

(defun dot-attr-name (key)
  (string-downcase (symbol-name key)))

(defun write-dot-attributes (stream attributes)
  (when attributes
    (format stream " [")
    (loop for (key value) on attributes by #'cddr
          for firstp = t then nil
          do (unless firstp (format stream ", "))
             (format stream "~A=~A"
                     (dot-attr-name key)
                     (dot-string value)))
    (format stream "]")))

(defun write-dot-node (stream id attributes)
  (format stream "~&  ~A" (dot-string id))
  (write-dot-attributes stream attributes)
  (format stream ";"))

(defun write-dot-edge (stream from to attributes)
  (format stream "~&  ~A -> ~A" (dot-string from) (dot-string to))
  (write-dot-attributes stream attributes)
  (format stream ";"))

(defun write-dot-header (stream name)
  (format stream "digraph ~A {" (dot-string name))
  (format stream "~&  rankdir=LR;")
  (format stream "~&  node [fontname=~A, shape=box];" (dot-string "Helvetica"))
  (format stream "~&  edge [fontname=~A];" (dot-string "Helvetica")))

(defun unit-node-label (node)
  (format nil "~A~%~D slots"
          (graph-symbol-label (getf node :name))
          (length (getf node :slots))))

(defun write.unit.graph.dot (stream &key kb units)
  "Write a Graphviz DOT unit hierarchy graph."
  (let ((graph (unit.graph :kb kb :units units)))
    (write-dot-header stream (format nil "kee_units_~A"
                                     (graph-symbol-label (getf graph :kb))))
    (dolist (node (getf graph :nodes))
      (write-dot-node stream
                      (getf node :id)
                      (list :label (unit-node-label node)
                            :tooltip (graph-symbol-label (getf node :name)))))
    (dolist (edge (getf graph :edges))
      (write-dot-edge stream
                      (getf edge :from)
                      (getf edge :to)
                      (list :label (graph-symbol-label (getf edge :relation))
                            :style (if (eq (getf edge :relation) 'member)
                                       "dashed"
                                       "solid"))))
    (format stream "~&}~%")
    (values)))

(defun unit.graph.dot (&key kb units)
  "Return a Graphviz DOT unit hierarchy graph as a string."
  (with-output-to-string (stream)
    (write.unit.graph.dot stream :kb kb :units units)))

(defun world-node-label (node)
  (format nil "~A~%facts: ~D~%nogoods: ~D"
          (graph-symbol-label (getf node :name))
          (getf node :fact-count)
          (getf node :nogood-count)))

(defun world-node-fillcolor (node)
  (if (getf node :inconsistent-p) "mistyrose" "white"))

(defun write.world.graph.dot (stream &key worlds limit)
  "Write a Graphviz DOT graph for KEEworlds."
  (let ((graph (world.graph :worlds worlds :limit limit)))
    (write-dot-header stream "kee_worlds")
    (dolist (node (getf graph :nodes))
      (write-dot-node stream
                      (getf node :id)
                      (list :label (world-node-label node)
                            :style "filled"
                            :fillcolor (world-node-fillcolor node))))
    (dolist (edge (getf graph :edges))
      (write-dot-edge stream
                      (getf edge :from)
                      (getf edge :to)
                      (list :label (graph-symbol-label
                                    (getf edge :relation)))))
    (format stream "~&}~%")
    (values)))

(defun world.graph.dot (&key worlds limit)
  "Return a Graphviz DOT KEEworlds graph as a string."
  (with-output-to-string (stream)
    (write.world.graph.dot stream :worlds worlds :limit limit)))
