(in-package #:kee)

(defun json-bool (value)
  (list :json-bool (not (null value))))

(defun json-bool-p (value)
  (and (consp value) (eq (first value) :json-bool)))

(defun json-array (values)
  (list :json-array values))

(defun json-array-p (value)
  (and (consp value) (eq (first value) :json-array)))

(defun json-object-p (value)
  (and (consp value)
       (every (lambda (entry)
                (and (consp entry) (stringp (car entry))))
              value)))

(defun write-json-string (stream value)
  (write-char #\" stream)
  (loop for char across (princ-to-string value)
        do (case char
             (#\" (write-string "\\\"" stream))
             (#\\ (write-string "\\\\" stream))
             (#\Backspace (write-string "\\b" stream))
             (#\Page (write-string "\\f" stream))
             (#\Newline (write-string "\\n" stream))
             (#\Return (write-string "\\r" stream))
             (#\Tab (write-string "\\t" stream))
             (#\< (write-string "\\u003C" stream))
             (#\> (write-string "\\u003E" stream))
             (#\& (write-string "\\u0026" stream))
             (t (if (char< char #\Space)
                    (format stream "\\u~4,'0X" (char-code char))
                    (write-char char stream)))))
  (write-char #\" stream))

(defun write-json-array (stream values)
  (write-char #\[ stream)
  (loop for value in values
        for firstp = t then nil
        do (unless firstp (write-char #\, stream))
           (write-json-value stream value))
  (write-char #\] stream))

(defun write-json-object (stream object)
  (write-char #\{ stream)
  (loop for (key . value) in object
        for firstp = t then nil
        do (unless firstp (write-char #\, stream))
           (write-json-string stream key)
           (write-char #\: stream)
           (write-json-value stream value))
  (write-char #\} stream))

(defun write-json-value (stream value)
  (cond ((json-bool-p value)
         (write-string (if (second value) "true" "false") stream))
        ((json-array-p value)
         (write-json-array stream (second value)))
        ((eq value :json-null)
         (write-string "null" stream))
        ((null value)
         (write-string "null" stream))
        ((stringp value)
         (write-json-string stream value))
        ((numberp value)
         (write-string (princ-to-string value) stream))
        ((eq value t)
         (write-string "true" stream))
        ((symbolp value)
         (write-json-string stream (graph-symbol-label value)))
        ((json-object-p value)
         (write-json-object stream value))
        ((listp value)
         (write-json-array stream value))
        (t (write-json-string stream value))))

(defun json-string (object)
  (with-output-to-string (stream)
    (write-json-value stream object)))

(defun html-escape-string (value)
  (with-output-to-string (stream)
    (loop for char across (princ-to-string value)
          do (case char
               (#\& (write-string "&amp;" stream))
               (#\< (write-string "&lt;" stream))
               (#\> (write-string "&gt;" stream))
               (#\" (write-string "&quot;" stream))
               (#\' (write-string "&#39;" stream))
               (t (write-char char stream))))))

(defun relation-json-label (relation)
  (string-downcase (graph-symbol-label relation)))

(defun unit-graph-node-json (node)
  (list (cons "id" (getf node :id))
        (cons "name" (graph-symbol-label (getf node :name)))
        (cons "kb" (graph-symbol-label (getf node :kb)))
        (cons "slots" (json-array (mapcar #'graph-symbol-label
                                           (getf node :slots))))))

(defun world-graph-node-json (node)
  (list (cons "id" (getf node :id))
        (cons "name" (graph-symbol-label (getf node :name)))
        (cons "parent" (if (getf node :parent)
                           (graph-symbol-label (getf node :parent))
                           :json-null))
        (cons "inconsistentP" (json-bool (getf node :inconsistent-p)))
        (cons "factCount" (getf node :fact-count))
        (cons "nogoodCount" (getf node :nogood-count))))

(defun graph-edge-json (edge)
  (list (cons "from" (getf edge :from))
        (cons "to" (getf edge :to))
        (cons "relation" (relation-json-label (getf edge :relation)))))

(defun graph-json-object (graph)
  (let ((kind (getf graph :kind)))
    (ecase kind
      (:unit-graph
       (list (cons "kind" "unit")
             (cons "kb" (graph-symbol-label (getf graph :kb)))
             (cons "nodes" (json-array (mapcar #'unit-graph-node-json
                                                (getf graph :nodes))))
             (cons "edges" (json-array (mapcar #'graph-edge-json
                                                (getf graph :edges))))))
      (:world-graph
       (list (cons "kind" "world")
             (cons "nodes" (json-array (mapcar #'world-graph-node-json
                                                (getf graph :nodes))))
             (cons "edges" (json-array (mapcar #'graph-edge-json
                                                (getf graph :edges)))))))))

(defun detail-string (value)
  (cond ((null value) "NIL")
        ((symbolp value) (graph-symbol-label value))
        ((stringp value) value)
        (t (princ-to-string value))))

(defun detail-string-array (values)
  (json-array (mapcar #'detail-string values)))

(defun unit-detail-id (report)
  (graph-unit-id (getf report :kb) (getf report :name)))

(defun world-detail-id (report)
  (graph-world-id (getf report :name)))

(defun facet-detail-json (facet)
  (list (cons "name" (detail-string (car facet)))
        (cons "values" (detail-string-array (cdr facet)))))

(defun slot-detail-json (slot)
  (list (cons "name" (detail-string (getf slot :name)))
        (cons "kind" (detail-string (getf slot :kind)))
        (cons "localValues" (detail-string-array (getf slot :local-values)))
        (cons "inheritedValues"
              (detail-string-array (getf slot :inherited-values)))
        (cons "combinedValues"
              (detail-string-array (getf slot :combined-values)))
        (cons "inheritance" (if (getf slot :inheritance)
                                (detail-string (getf slot :inheritance))
                                :json-null))
        (cons "valueType" (if (getf slot :value-type)
                              (detail-string (getf slot :value-type))
                              :json-null))
        (cons "default" (if (getf slot :default)
                            (detail-string (getf slot :default))
                            :json-null))
        (cons "facets" (json-array (mapcar #'facet-detail-json
                                            (getf slot :facets))))))

(defun unit-detail-json (report)
  (list (cons "id" (unit-detail-id report))
        (cons "name" (detail-string (getf report :name)))
        (cons "kb" (detail-string (getf report :kb)))
        (cons "classParents"
              (detail-string-array (getf report :class-parents)))
        (cons "memberParents"
              (detail-string-array (getf report :member-parents)))
        (cons "classChildren"
              (detail-string-array (getf report :class-children)))
        (cons "memberChildren"
              (detail-string-array (getf report :member-children)))
        (cons "ruleReference" (unit-rule-reference-json report))
        (cons "slots" (json-array (mapcar #'slot-detail-json
                                           (getf report :slots))))))

(defun fact-detail-json (fact)
  (list (cons "kb" (detail-string (getf fact :kb)))
        (cons "unit" (detail-string (getf fact :unit)))
        (cons "slot" (detail-string (getf fact :slot)))
        (cons "values" (detail-string-array (getf fact :values)))
        (cons "labels" (json-array (mapcar #'label-detail-json
                                            (getf fact :labels))))))

(defun binding-detail-json (binding)
  (list (cons "variable" (detail-string (car binding)))
        (cons "value" (detail-string (cdr binding)))))

(defun rule-reference-entry-json (entry)
  (list (cons "kind" (detail-string (getf entry :kind)))
        (cons "context" (detail-string (getf entry :context)))
        (cons "operation" (detail-string (getf entry :operation)))
        (cons "unit" (if (getf entry :unit)
                         (detail-string (getf entry :unit))
                         :json-null))
        (cons "slot" (if (getf entry :slot)
                         (detail-string (getf entry :slot))
                         :json-null))
        (cons "value" (if (getf entry :value)
                          (detail-string (getf entry :value))
                          :json-null))
        (cons "proposition" (if (getf entry :proposition)
                                (detail-string (getf entry :proposition))
                                :json-null))
        (cons "source" (detail-string (getf entry :source)))))

(defun rule-reference-json (reference)
  (if reference
      (list (cons "rule" (detail-string (getf reference :rule)))
            (cons "kb" (detail-string (getf reference :kb)))
            (cons "kind" (detail-string (getf reference :kind)))
            (cons "ruleClasses"
                  (detail-string-array (getf reference :rule-classes)))
            (cons "reads"
                  (json-array (mapcar #'rule-reference-entry-json
                                       (getf reference :reads))))
            (cons "writes"
                  (json-array (mapcar #'rule-reference-entry-json
                                       (getf reference :writes))))
            (cons "asserts"
                  (json-array (mapcar #'rule-reference-entry-json
                                       (getf reference :asserts)))))
      :json-null))

(defun unit-rule-reference-json (report)
  (if (fboundp 'rule.references)
      (rule-reference-json
       (rule.references (list (getf report :name) (getf report :kb))))
      :json-null))

(defun assumption-detail-json (assumption)
  (list (cons "world" (detail-string (getf assumption :world)))
        (cons "parent" (if (getf assumption :parent)
                           (detail-string (getf assumption :parent))
                           :json-null))
        (cons "fact" (or (getf assumption :fact) :json-null))
        (cons "rule" (if (getf assumption :rule)
                         (detail-string (getf assumption :rule))
                         :json-null))
        (cons "bindings" (json-array (mapcar #'binding-detail-json
                                              (getf assumption :bindings))))
        (cons "conditions"
              (detail-string-array (getf assumption :conditions)))
        (cons "action" (or (getf assumption :action) :json-null))
        (cons "agendaId" (or (getf assumption :agenda-id) :json-null))
        (cons "activationId" (or (getf assumption :activation-id)
                                 :json-null))
        (cons "fireId" (or (getf assumption :fire-id) :json-null))))

(defun label-detail-json (label)
  (list (cons "kind" (detail-string (getf label :kind)))
        (cons "world" (detail-string (getf label :world)))
        (cons "fact" (or (getf label :fact) :json-null))
        (cons "environment"
              (json-array (mapcar #'assumption-detail-json
                                   (getf label :environment))))
        (cons "rule" (if (getf label :rule)
                         (detail-string (getf label :rule))
                         :json-null))
        (cons "bindings" (json-array (mapcar #'binding-detail-json
                                              (getf label :bindings))))
        (cons "conditions" (detail-string-array (getf label :conditions)))
        (cons "action" (or (getf label :action) :json-null))
        (cons "agendaId" (or (getf label :agenda-id) :json-null))
        (cons "activationId" (or (getf label :activation-id) :json-null))
        (cons "fireId" (or (getf label :fire-id) :json-null))))

(defun nogood-detail-json (nogood)
  (list (cons "world" (detail-string (getf nogood :world)))
        (cons "rule" (detail-string (getf nogood :rule)))
        (cons "bindings" (json-array (mapcar #'binding-detail-json
                                              (getf nogood :bindings))))
        (cons "conditions" (detail-string-array (getf nogood :conditions)))
        (cons "action" (detail-string (getf nogood :action)))
        (cons "proposition" (detail-string (getf nogood :proposition)))
        (cons "environment"
              (json-array (mapcar #'assumption-detail-json
                                   (getf nogood :environment))))))

(defun world-detail-json (report)
  (list (cons "id" (world-detail-id report))
        (cons "name" (detail-string (getf report :name)))
        (cons "parent" (if (getf report :parent)
                           (detail-string (getf report :parent))
                           :json-null))
        (cons "inconsistentP" (json-bool (getf report :inconsistent-p)))
        (cons "facts" (json-array (mapcar #'fact-detail-json
                                           (getf report :facts))))
        (cons "labels" (json-array (mapcar #'label-detail-json
                                            (getf report :labels))))
        (cons "environment" (json-array (mapcar #'assumption-detail-json
                                                 (getf report :environment))))
        (cons "nogoods" (json-array (mapcar #'nogood-detail-json
                                             (getf report :nogoods))))))

(defun unit-detail-map-json (unit-graph)
  (mapcar (lambda (node)
            (let ((report (inspect.unit (list (getf node :name)
                                              (getf node :kb)))))
              (cons (getf node :id) (unit-detail-json report))))
          (getf unit-graph :nodes)))

(defun world-detail-map-json (world-graph)
  (mapcar (lambda (node)
            (let ((report (inspect.world (getf node :name))))
              (cons (getf node :id) (world-detail-json report))))
          (getf world-graph :nodes)))

(defun active-image-json-value (value)
  (cond ((null value) :json-null)
        ((or (stringp value) (numberp value)) value)
        ((symbolp value) (detail-string value))
        (t (detail-string value))))

(defun active-image-json-array (values)
  (json-array (mapcar #'active-image-json-value values)))

(defun active-image-report-json (report)
  (list (cons "name" (detail-string (getf report :name)))
        (cons "kb" (detail-string (getf report :kb)))
        (cons "targetUnit" (detail-string (getf report :target-unit)))
        (cons "targetKb" (detail-string (getf report :target-kb)))
        (cons "targetSlot" (detail-string (getf report :target-slot)))
        (cons "targetFacet" (active-image-json-value
                              (getf report :target-facet)))
        (cons "widget" (string-downcase
                        (detail-string (getf report :widget))))
        (cons "label" (detail-string (getf report :label)))
        (cons "values" (active-image-json-array (getf report :values)))
        (cons "value" (active-image-json-value (getf report :value)))
        (cons "choices" (active-image-json-array (getf report :choices)))
        (cons "min" (active-image-json-value (getf report :min)))
        (cons "max" (active-image-json-value (getf report :max)))
        (cons "writableP" (json-bool (getf report :writable-p)))))

(defun active-image-detail-json (unit-graph)
  (json-array
   (when (and (fboundp 'list.active.images)
              (fboundp 'active.image.report))
     (mapcar (lambda (image)
               (active-image-report-json (active.image.report image)))
             (list.active.images (getf unit-graph :kb))))))

(defun picture-item-report-json (report)
  (list (cons "name" (detail-string (getf report :name)))
        (cons "kind" (string-downcase
                      (detail-string (getf report :kind))))
        (cons "label" (detail-string (getf report :label)))
        (cons "targetUnit" (active-image-json-value
                             (getf report :target-unit)))
        (cons "targetKb" (active-image-json-value
                           (getf report :target-kb)))
        (cons "targetSlot" (active-image-json-value
                             (getf report :target-slot)))
        (cons "activeImage" (active-image-json-value
                              (getf report :active-image)))
        (cons "value" (active-image-json-value (getf report :value)))))

(defun picture-windowpane-report-json (report)
  (list (cons "name" (detail-string (getf report :name)))
        (cons "label" (detail-string (getf report :label)))
        (cons "viewport" (detail-string (getf report :viewport)))
        (cons "width" (getf report :width))
        (cons "height" (getf report :height))
        (cons "openP" (json-bool (getf report :open-p)))))

(defun picture-viewport-report-json (report)
  (list (cons "name" (detail-string (getf report :name)))
        (cons "label" (detail-string (getf report :label)))
        (cons "picture" (detail-string (getf report :picture)))
        (cons "width" (getf report :width))
        (cons "height" (getf report :height))
        (cons "scale" (getf report :scale))
        (cons "windowpanes"
              (json-array
               (mapcar #'picture-windowpane-report-json
                       (getf report :windowpanes))))))

(defun picture-report-json (report)
  (list (cons "name" (detail-string (getf report :name)))
        (cons "kb" (detail-string (getf report :kb)))
        (cons "label" (detail-string (getf report :label)))
        (cons "width" (getf report :width))
        (cons "height" (getf report :height))
        (cons "items" (json-array
                       (mapcar #'picture-item-report-json
                               (getf report :items))))
        (cons "viewports" (json-array
                           (mapcar #'picture-viewport-report-json
                                   (getf report :viewports))))
        (cons "svg" (kee.picture.svg (list (getf report :name)
                                           (getf report :kb))))))

(defun picture-detail-json (unit-graph)
  (json-array
   (when (and (fboundp 'list.kee.pictures)
              (fboundp 'kee.picture.report)
              (fboundp 'kee.picture.svg))
     (mapcar (lambda (picture)
               (picture-report-json (kee.picture.report picture)))
             (list.kee.pictures (getf unit-graph :kb))))))

(defun panel-report-json (report)
  (list (cons "name" (detail-string (getf report :name)))
        (cons "kb" (detail-string (getf report :kb)))
        (cons "label" (detail-string (getf report :label)))
        (cons "kind" (string-downcase
                      (detail-string (getf report :kind))))
        (cons "message" (active-image-json-value
                          (getf report :message)))
        (cons "picture" (active-image-json-value
                          (getf report :picture)))
        (cons "viewport" (active-image-json-value
                           (getf report :viewport)))
        (cons "windowpane" (active-image-json-value
                             (getf report :windowpane)))
        (cons "openP" (json-bool (getf report :open-p)))
        (cons "pictureLabel" (active-image-json-value
                               (getf report :picture-label)))
        (cons "windowpaneLabel" (active-image-json-value
                                  (getf report :windowpane-label)))
        (cons "svg" (or (getf report :svg) ""))))

(defun panel-detail-json (unit-graph)
  (json-array
   (when (and (fboundp 'list.kee.panels)
              (fboundp 'kee.panel.report))
     (mapcar (lambda (panel)
               (panel-report-json (kee.panel.report panel)))
             (list.kee.panels (getf unit-graph :kb))))))

(defun rule-reference-detail-json (unit-graph)
  (json-array
   (when (fboundp 'rule.reference.index)
     (mapcar #'rule-reference-json
             (rule.reference.index :kb (getf unit-graph :kb))))))

(defun trace-json-value (value)
  (cond ((null value) :json-null)
        ((or (stringp value) (numberp value)) value)
        ((symbolp value) (detail-string value))
        ((listp value) (json-array (mapcar #'trace-json-value value)))
        (t (detail-string value))))

(defun trace-json-array (values)
  (json-array (mapcar #'trace-json-value values)))

(defun trace-binding-json (binding)
  (list (cons "variable" (detail-string (car binding)))
        (cons "value" (trace-json-value (cdr binding)))))

(defun trace-event-json (event)
  (list (cons "id" (getf event :id))
        (cons "kind" (detail-string (getf event :kind)))
        (cons "agendaId" (trace-json-value (getf event :agenda-id)))
        (cons "activationId" (trace-json-value (getf event :activation-id)))
        (cons "fireId" (trace-json-value (getf event :fire-id)))
        (cons "world" (trace-json-value (getf event :world)))
        (cons "parent" (trace-json-value (getf event :parent)))
        (cons "rule" (trace-json-value (getf event :rule)))
        (cons "ruleClass" (trace-json-value (getf event :rule-class)))
        (cons "unit" (trace-json-value (getf event :unit)))
        (cons "slot" (trace-json-value (getf event :slot)))
        (cons "panel" (trace-json-value (getf event :panel)))
        (cons "picture" (trace-json-value (getf event :picture)))
        (cons "item" (trace-json-value (getf event :item)))
        (cons "viewport" (trace-json-value (getf event :viewport)))
        (cons "windowpane" (trace-json-value (getf event :windowpane)))
        (cons "activeImage" (trace-json-value (getf event :active-image)))
        (cons "button" (trace-json-value (getf event :button)))
        (cons "x" (trace-json-value (getf event :x)))
        (cons "y" (trace-json-value (getf event :y)))
        (cons "value" (trace-json-value (getf event :value)))
        (cons "methodKind" (trace-json-value (getf event :method-kind)))
        (cons "method" (trace-json-value (getf event :method)))
        (cons "args" (trace-json-array (getf event :args)))
        (cons "oldValues" (trace-json-array (getf event :old-values)))
        (cons "newValues" (trace-json-array (getf event :new-values)))
        (cons "bindings" (json-array (mapcar #'trace-binding-json
                                              (getf event :bindings))))
        (cons "conditions" (detail-string-array (getf event :conditions)))
        (cons "action" (trace-json-value (getf event :action)))
        (cons "proposition" (trace-json-value (getf event :proposition)))
        (cons "fact" (trace-json-value (getf event :fact)))
        (cons "result" (trace-json-value (getf event :result)))
        (cons "message" (trace-json-value (getf event :message)))))

(defun graph-world-names (world-graph)
  (mapcar (lambda (node) (getf node :name))
          (getf world-graph :nodes)))

(defun trace-effect-event-p (event)
  (member (getf event :kind)
          '(:world-create :world-branch :world-slot-write :world-label-retract
            :nogood :contradiction)
          :test #'eq))

(defun trace-world-parent-index (events)
  (let ((index (make-hash-table :test #'equal)))
    (dolist (event events index)
      (when (and (eq (getf event :kind) :world-branch)
                 (getf event :world)
                 (getf event :parent))
        (setf (gethash (getf event :world) index)
              (getf event :parent))))))

(defun trace-ancestor-world-names (events world-names)
  (let ((parents (trace-world-parent-index events))
        (seen (make-hash-table :test #'equal))
        (names nil))
    (labels ((add (name)
               (when (and name (not (gethash name seen)))
                 (setf (gethash name seen) t)
                 (push name names)
                 (add (gethash name parents)))))
      (dolist (name world-names)
        (add name)))
    names))

(defun trace-touches-visible-world-p (event world-names)
  (and world-names
       (or (member (getf event :world) world-names :test #'equal)
           (member (getf event :parent) world-names :test #'equal))))

(defun trace-index-by (events kind key)
  (let ((index (make-hash-table :test #'equal)))
    (dolist (event events index)
      (when (and (eq (getf event :kind) kind)
                 (getf event key))
        (setf (gethash (getf event key) index) event)))))

(defun trace-provenance-events (events targets)
  (let ((agenda-by-id (trace-index-by events :agenda :agenda-id))
        (match-by-id (trace-index-by events :rule-match :activation-id))
        (fire-by-id (trace-index-by events :rule-fire :fire-id)))
    (loop for event in targets
          append (remove nil
                         (list (gethash (getf event :agenda-id)
                                        agenda-by-id)
                               (gethash (getf event :activation-id)
                                        match-by-id)
                               (gethash (getf event :fire-id)
                                        fire-by-id))))))

(defun unique-trace-events (events)
  (let ((seen (make-hash-table :test #'eql))
        (unique nil))
    (dolist (event events)
      (let ((id (getf event :id)))
        (unless (gethash id seen)
          (setf (gethash id seen) t)
          (push event unique))))
    (sort (nreverse unique) #'< :key (lambda (event) (getf event :id)))))

(defun trace-detail-events (&key (limit 200) world-graph)
  (let* ((events (trace.events))
         (world-names (trace-ancestor-world-names
                       events
                       (graph-world-names world-graph)))
         (recent (if limit
                     (last events (min limit (length events)))
                     events))
         (visible-effects
           (remove-if-not
            (lambda (event)
              (and (trace-effect-event-p event)
                   (trace-touches-visible-world-p event world-names)))
            events))
         (provenance (trace-provenance-events events visible-effects)))
    (unique-trace-events (append recent visible-effects provenance))))

(defun trace-detail-json (&key (limit 200) world-graph)
  (json-array
   (when (fboundp 'trace.events)
     (mapcar #'trace-event-json
             (trace-detail-events :limit limit :world-graph world-graph)))))

(defun viewer-details-json (unit-graph world-graph)
  (list (cons "units" (unit-detail-map-json unit-graph))
        (cons "worlds" (world-detail-map-json world-graph))
        (cons "activeImages" (active-image-detail-json unit-graph))
        (cons "pictures" (picture-detail-json unit-graph))
        (cons "panels" (panel-detail-json unit-graph))
        (cons "ruleReferences" (rule-reference-detail-json unit-graph))
        (cons "traces" (trace-detail-json :world-graph world-graph))))

(defun viewer-kbs-json (unit-graph)
  (detail-string-array
   (or (ignore-errors (list.kbs))
       (remove nil (list (getf unit-graph :kb))))))

(defun viewer-initial-json (&key view selected trace-family trace-kind
                                 trace-scope trace-query)
  (remove nil
          (list (when view (cons "view" (detail-string view)))
                (when selected (cons "selected" (detail-string selected)))
                (when trace-family
                  (cons "traceFamily" (detail-string trace-family)))
                (when trace-kind
                  (cons "traceKind" (detail-string trace-kind)))
                (when trace-scope
                  (cons "traceScope" (detail-string trace-scope)))
                (when trace-query
                  (cons "traceQuery" (detail-string trace-query))))))

(defun viewer-session-json (session)
  (labels ((lines (key)
             (detail-string-array (getf session key)))
           (maybe-string (key)
             (let ((value (getf session key)))
               (if value (detail-string value) :json-null))))
    (list (cons "listener" (lines :listener))
          (cons "typescript" (lines :typescript))
          (cons "prompt" (lines :prompt))
          (cons "desktopTitle" (maybe-string :desktop-title))
          (cons "desktopSubtitle" (maybe-string :desktop-subtitle))
          (cons "desktopNotice" (maybe-string :desktop-notice))
          (cons "tourNotes" (lines :tour-notes)))))

(defun viewer-json-object (unit-graph world-graph title initial session)
  (list (cons "title" title)
        (cons "initial" initial)
        (cons "session" (viewer-session-json session))
        (cons "kbs" (viewer-kbs-json unit-graph))
        (cons "units" (graph-json-object unit-graph))
        (cons "worlds" (graph-json-object world-graph))
        (cons "details" (viewer-details-json unit-graph world-graph))))

(defun write-html-lines (stream lines)
  (dolist (line lines)
    (write-line line stream)))

(defun write-viewer-head (stream title)
  (write-html-lines
   stream
   (list "<!doctype html>"
         "<html lang='en'>"
         "<head>"
         "<meta charset='utf-8'>"
         "<meta name='viewport' content='width=device-width, initial-scale=1'>"))
  (format stream "<title>~A</title>~%" (html-escape-string title))
  (write-html-lines
   stream
   (list "<style>"
         ":root { color-scheme: light; --bg: #f6f7f9; --panel: #ffffff; --ink: #1e252d; --muted: #66707a; --line: #c9d0d8; --accent: #1c6fb8; --accent-soft: #e8f2fb; --bad: #be3b3b; --bad-soft: #ffe7e4; --good-soft: #eef7ed; }"
         "* { box-sizing: border-box; }"
         "body { margin: 0; background: var(--bg); color: var(--ink); font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }"
         "#app { display: grid; grid-template-rows: 56px minmax(0, 1fr); height: 100vh; }"
         "header { display: flex; align-items: center; gap: 16px; padding: 10px 14px; background: var(--panel); border-bottom: 1px solid var(--line); min-width: 0; }"
         ".brand { display: flex; flex-direction: column; min-width: 160px; }"
         ".brand strong { font-size: 15px; font-weight: 700; line-height: 1.1; }"
         ".brand span { color: var(--muted); font-size: 12px; }"
         ".tabs, .actions { display: flex; align-items: center; gap: 6px; }"
         ".tabs button, .actions button { border: 1px solid var(--line); background: #f9fafb; color: var(--ink); min-height: 34px; padding: 0 12px; border-radius: 6px; font: inherit; cursor: pointer; }"
         ".tabs button.active { background: var(--accent); color: white; border-color: var(--accent); }"
         ".actions { margin-left: auto; }"
         "input[type='search'] { width: min(28vw, 260px); min-width: 120px; border: 1px solid var(--line); border-radius: 6px; padding: 0 10px; min-height: 34px; font: inherit; background: white; }"
         "main { display: grid; grid-template-columns: minmax(0, 1fr) 380px; min-height: 0; }"
         ".viewport { min-width: 0; min-height: 0; overflow: auto; background: linear-gradient(#eef2f5 1px, transparent 1px), linear-gradient(90deg, #eef2f5 1px, transparent 1px); background-size: 24px 24px; }"
         "svg { display: block; min-width: 100%; min-height: 100%; background: rgba(255, 255, 255, 0.52); }"
         ".edge { fill: none; stroke: #8e99a6; stroke-width: 1.6; }"
         ".edge.member { stroke-dasharray: 7 5; }"
         ".edge.background { opacity: 0.2; stroke-width: 1.1; }"
         ".edge.adjacent { stroke: #64748b; stroke-width: 2; }"
         ".edge.trace-hit { stroke: var(--accent); stroke-width: 3; }"
         ".edge-label { fill: var(--muted); font-size: 11px; pointer-events: none; }"
         ".edge-label.background { display: none; }"
         ".edge-label.adjacent { fill: #64748b; font-weight: 700; }"
         ".edge-label.trace-hit { fill: var(--accent); font-weight: 700; }"
         ".node { cursor: pointer; }"
         ".node rect { stroke: #8090a0; stroke-width: 1.3; }"
         ".node text { fill: var(--ink); font-size: 12px; pointer-events: none; }"
         ".node .title { font-weight: 700; font-size: 13px; }"
         ".node.selected rect { stroke: var(--accent); stroke-width: 2.5; }"
         ".node.trace-hit rect { stroke: var(--accent); stroke-width: 3; filter: drop-shadow(0 0 5px rgba(28,111,184,0.35)); }"
         ".dim { opacity: 0.22; }"
         "aside { min-width: 0; overflow: hidden; padding: 14px; background: var(--panel); border-left: 1px solid var(--line); display: grid; grid-template-rows: minmax(300px, 60vh) minmax(0, 1fr); gap: 12px; }"
         "aside h2 { margin: 0 0 10px; font-size: 16px; line-height: 1.2; }"
         ".browser-pane, .inspector-pane { min-width: 0; min-height: 0; overflow: auto; }"
         ".browser-pane { display: flex; flex-direction: column; gap: 10px; }"
         ".browser-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 8px; }"
         ".browser-head h2 { margin: 0; }"
         ".browser-head h3 { margin: 0; }"
         ".count { color: var(--muted); font-size: 12px; white-space: nowrap; }"
         ".kb-strip { display: grid; gap: 8px; padding-bottom: 10px; border-bottom: 1px solid var(--line); }"
         ".kb-line { display: flex; align-items: baseline; justify-content: space-between; gap: 10px; }"
         ".kb-label { color: var(--muted); font-size: 12px; }"
         ".kb-value { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: 13px; font-weight: 700; }"
         ".kb-list { display: flex; flex-wrap: wrap; gap: 6px; }"
         ".kb-chip { border: 1px solid var(--line); border-radius: 999px; padding: 3px 8px; background: #f9fafb; font-size: 12px; }"
         ".kb-chip.active { background: var(--accent-soft); border-color: #b7d0e6; color: var(--accent); }"
         ".review-tour { display: grid; gap: 8px; padding-bottom: 10px; border-bottom: 1px solid var(--line); }"
         ".review-tour h3 { margin: 0; font-size: 12px; color: var(--muted); }"
         ".tour-buttons { display: flex; flex-wrap: wrap; gap: 6px; }"
         ".tour-buttons button { border: 1px solid var(--line); border-radius: 6px; background: #f9fafb; color: var(--ink); min-height: 30px; padding: 0 8px; font: inherit; font-size: 12px; cursor: pointer; }"
         ".tour-buttons button:hover { border-color: var(--accent); background: var(--accent-soft); }"
         ".tour-buttons button:disabled { color: var(--muted); cursor: default; opacity: 0.58; }"
         ".desktop-context { display: grid; gap: 7px; padding-bottom: 10px; border-bottom: 1px solid var(--line); }"
         ".desktop-context:empty { display: none; }"
         ".desktop-context h3 { margin: 0; font-size: 12px; color: var(--muted); }"
         ".desktop-context p { margin: 0; font-size: 12px; line-height: 1.35; overflow-wrap: anywhere; }"
         ".desktop-context .desktop-notice { border: 1px solid #e2c56f; border-radius: 6px; background: #fff8dd; padding: 6px 7px; color: #68530b; }"
         ".desktop-context ul { margin: 0; padding-left: 17px; color: var(--muted); font-size: 12px; line-height: 1.35; }"
         ".desktop-roster { display: grid; gap: 8px; padding-bottom: 10px; border-bottom: 1px solid var(--line); }"
         ".desktop-roster h3 { margin: 0; font-size: 12px; color: var(--muted); }"
         ".desktop-windows { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }"
         ".desktop-window { min-width: 0; min-height: 42px; text-align: left; border: 1px solid var(--line); border-radius: 6px; background: #fbfcfd; color: var(--ink); padding: 6px 7px; font: inherit; cursor: pointer; }"
         ".desktop-window strong { display: block; font-size: 11px; line-height: 1.2; overflow-wrap: anywhere; }"
         ".desktop-window span { display: block; margin-top: 3px; color: var(--muted); font-size: 11px; line-height: 1.2; overflow-wrap: anywhere; }"
         ".desktop-window:hover { border-color: var(--accent); background: var(--accent-soft); }"
         ".desktop-window.active { border-color: var(--accent); background: var(--accent-soft); }"
         ".desktop-window:disabled { color: var(--muted); cursor: default; opacity: 0.58; background: #f9fafb; }"
         ".session-pane { display: grid; gap: 8px; padding-bottom: 10px; border-bottom: 1px solid var(--line); }"
         ".session-pane h3 { margin: 0; font-size: 12px; color: var(--muted); }"
         ".session-window { border: 1px solid var(--line); border-radius: 6px; background: #fbfcfd; padding: 8px; }"
         ".session-window pre { margin: 0; white-space: pre-wrap; overflow-wrap: anywhere; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: 11px; line-height: 1.45; }"
         ".browser-section { padding-top: 10px; border-top: 1px solid var(--line); }"
         ".browser-section h3 { margin: 0 0 8px; font-size: 12px; color: var(--muted); }"
         ".node-list { display: flex; flex-direction: column; gap: 5px; }"
         ".node-list.compact { gap: 4px; }"
         ".node-row { width: 100%; text-align: left; border: 1px solid transparent; border-radius: 6px; background: transparent; padding: 7px 8px; color: var(--ink); cursor: pointer; font: inherit; }"
         ".node-row:hover, .node-row.active { background: var(--accent-soft); border-color: #b7d0e6; }"
         ".node-row.bad { background: var(--bad-soft); }"
         ".node-row.static { cursor: default; color: var(--muted); }"
         ".node-row.static:hover { background: transparent; border-color: transparent; }"
         ".node-row-title { display: block; font-size: 13px; font-weight: 600; overflow-wrap: anywhere; }"
         ".node-row-meta { display: block; margin-top: 2px; color: var(--muted); font-size: 12px; }"
         ".node-row.bad .node-row-meta { color: var(--bad); }"
         ".slot-table { width: 100%; border-collapse: collapse; table-layout: fixed; font-size: 12px; }"
         ".slot-table th, .slot-table td { border-bottom: 1px solid var(--line); padding: 6px 4px; text-align: left; vertical-align: top; overflow-wrap: anywhere; }"
         ".slot-table th { color: var(--muted); font-weight: 600; }"
         ".slot-table th:nth-child(1) { width: 27%; }"
         ".slot-table th:nth-child(2) { width: 17%; }"
         ".slot-table th:nth-child(3) { width: 18%; }"
         ".slot-table th:nth-child(4) { width: 18%; }"
         ".slot-kind { display: block; margin-top: 3px; color: var(--muted); font-size: 11px; }"
         ".active-image-list { display: grid; gap: 8px; }"
         ".active-image { border: 1px solid var(--line); border-radius: 6px; padding: 8px; background: #fbfcfd; font-size: 12px; }"
         ".active-image strong, .active-image label { display: block; margin-bottom: 6px; font-size: 13px; }"
         ".active-image input, .active-image select, .active-image button { width: 100%; font: inherit; }"
         ".active-image output { display: block; margin-top: 5px; color: var(--muted); }"
         ".active-image-switch { text-align: left; cursor: pointer; }"
         ".active-image-switch.is-on { background: var(--good-soft); border-color: #b8d9b4; }"
         ".active-image-bars { display: flex; align-items: end; gap: 4px; height: 60px; }"
         ".active-image-bar { flex: 1; min-width: 5px; background: var(--accent); border-radius: 2px 2px 0 0; }"
         ".active-image-plot { width: 100%; height: 88px; color: var(--accent); background: #ffffff; }"
         ".picture-tabs { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 8px; }"
         ".picture-tabs button { border: 1px solid var(--line); border-radius: 6px; background: #f9fafb; color: var(--ink); min-height: 28px; padding: 0 8px; font: inherit; font-size: 12px; cursor: pointer; }"
         ".picture-tabs button.active { border-color: var(--accent); background: var(--accent-soft); }"
         ".panel-window-deck { display: grid; gap: 7px; margin-bottom: 8px; }"
         ".panel-window-card { width: 100%; min-width: 0; text-align: left; border: 1px solid var(--line); border-radius: 6px; background: #ffffff; color: var(--ink); padding: 0; font: inherit; cursor: pointer; overflow: hidden; }"
         ".panel-window-card.active { border-color: var(--accent); box-shadow: 0 0 0 2px var(--accent-soft); }"
         ".panel-window-card.open .panel-window-titlebar { background: var(--good-soft); }"
         ".panel-window-card:hover { border-color: var(--accent); }"
         ".panel-window-titlebar { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 8px; align-items: center; min-height: 28px; padding: 5px 7px; background: #eef2f5; border-bottom: 1px solid var(--line); }"
         ".panel-window-titlebar strong { min-width: 0; font-size: 12px; line-height: 1.2; overflow-wrap: anywhere; }"
         ".panel-window-body { display: grid; gap: 3px; padding: 6px 7px; color: var(--muted); font-size: 11px; line-height: 1.3; }"
         ".panel-window-body span { overflow-wrap: anywhere; }"
         ".kee-panel { border: 1px solid var(--line); border-radius: 6px; background: #fbfcfd; padding: 8px; display: grid; gap: 8px; }"
         ".panel-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; }"
         ".panel-head strong { min-width: 0; font-size: 13px; line-height: 1.25; overflow-wrap: anywhere; }"
         ".panel-state { border: 1px solid var(--line); border-radius: 999px; background: #f9fafb; color: var(--muted); padding: 2px 7px; font-size: 11px; line-height: 1.25; white-space: nowrap; }"
         ".panel-state.open { border-color: #b8d9b4; background: var(--good-soft); color: #2f6b39; }"
         ".panel-message { margin: 0; color: var(--muted); font-size: 12px; line-height: 1.35; overflow-wrap: anywhere; }"
         ".panel-actions { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 6px; }"
         ".panel-actions button { border: 1px solid var(--line); border-radius: 6px; background: #f9fafb; color: var(--ink); min-height: 30px; padding: 0 8px; font: inherit; font-size: 12px; cursor: pointer; }"
         ".panel-actions button:hover:not(:disabled) { border-color: var(--accent); background: var(--accent-soft); }"
         ".panel-actions button:disabled { color: var(--muted); cursor: default; opacity: 0.58; }"
         ".kee-picture-preview { border: 1px solid var(--line); border-radius: 6px; background: #ffffff; padding: 6px; overflow-x: auto; }"
         ".kee-picture-preview svg { display: block; width: 100%; height: auto; min-height: 0; background: #ffffff; }"
         ".trace-list { display: grid; gap: 8px; }"
         ".trace-event { border: 1px solid var(--line); border-radius: 6px; padding: 8px; background: #fbfcfd; font-size: 12px; }"
         ".trace-event strong { display: block; font-size: 13px; margin-bottom: 4px; }"
         ".trace-event.bad { background: var(--bad-soft); border-color: #f1b4ad; }"
         ".trace-event.focused { border-color: var(--accent); box-shadow: 0 0 0 2px var(--accent-soft); }"
         ".trace-meta { color: var(--muted); overflow-wrap: anywhere; }"
         ".trace-controls { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)) auto; gap: 8px; align-items: end; margin-bottom: 10px; }"
         ".trace-controls label { display: grid; gap: 3px; color: var(--muted); font-size: 11px; }"
         ".trace-controls select { width: 100%; border: 1px solid var(--line); border-radius: 6px; min-height: 30px; background: white; color: var(--ink); font: inherit; font-size: 12px; }"
         ".trace-search { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; gap: 6px; margin-bottom: 10px; }"
         ".trace-search input { min-width: 0; width: 100%; border: 1px solid var(--line); border-radius: 6px; min-height: 30px; padding: 0 8px; font: inherit; font-size: 12px; }"
         ".trace-search button { border: 1px solid var(--line); border-radius: 6px; background: #f9fafb; color: var(--ink); min-height: 30px; padding: 0 9px; font: inherit; font-size: 12px; cursor: pointer; }"
         ".trace-search button:hover { border-color: var(--accent); background: var(--accent-soft); }"
         ".xref-controls { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px; margin: 8px 0 10px; }"
         ".xref-controls label { display: grid; gap: 3px; color: var(--muted); font-size: 11px; }"
         ".xref-controls select { width: 100%; border: 1px solid var(--line); border-radius: 6px; min-height: 30px; background: white; color: var(--ink); font: inherit; font-size: 12px; }"
         ".trace-graph { display: grid; gap: 6px; margin-bottom: 10px; padding: 8px; border: 1px solid var(--line); border-radius: 6px; background: #ffffff; }"
         ".trace-graph-row { display: grid; grid-template-columns: minmax(0, 1fr) 28px minmax(0, 1fr); gap: 6px; align-items: center; font-size: 12px; }"
         ".causality-graph { display: grid; gap: 7px; margin-bottom: 10px; padding: 8px; border: 1px solid var(--line); border-radius: 6px; background: #ffffff; }"
         ".causal-row { display: flex; flex-wrap: wrap; gap: 5px; align-items: center; font-size: 12px; }"
         ".causal-node { max-width: 100%; border: 1px solid var(--line); border-radius: 5px; background: #fbfcfd; color: var(--ink); min-height: 26px; padding: 3px 7px; font: inherit; overflow-wrap: anywhere; cursor: pointer; }"
         ".causal-node:hover { border-color: var(--accent); background: var(--accent-soft); }"
         ".causal-node.fire { border-color: var(--accent); background: var(--accent-soft); }"
         ".causal-node.effect { background: var(--good-soft); }"
         ".causal-node.bad { background: var(--bad-soft); border-color: #f1b4ad; }"
         ".causal-node.focused { box-shadow: 0 0 0 2px var(--accent-soft); }"
         ".causal-arrow { color: var(--muted); }"
         ".why-trails { display: grid; gap: 8px; }"
         ".why-trail { display: grid; gap: 5px; padding: 7px; border: 1px solid var(--line); border-radius: 6px; background: #ffffff; }"
         ".why-trail strong { font-size: 12px; overflow-wrap: anywhere; }"
         ".trace-detail .why-trail { margin-top: 8px; }"
         ".assumption-trails { display: grid; gap: 8px; }"
         ".assumption-trails .why-trail { background: #fbfcfd; }"
         ".agenda-controls { display: grid; grid-template-columns: auto auto auto auto minmax(0, 1fr); gap: 6px; align-items: center; margin-bottom: 8px; }"
         ".agenda-controls button { border: 1px solid var(--line); border-radius: 6px; background: #f9fafb; color: var(--ink); min-height: 30px; padding: 0 9px; font: inherit; font-size: 12px; cursor: pointer; }"
         ".agenda-controls button:hover { border-color: var(--accent); background: var(--accent-soft); }"
         ".agenda-controls .count { justify-self: end; }"
         ".agenda-board { display: grid; gap: 8px; margin-bottom: 10px; }"
         ".agenda-pass { border: 1px solid var(--line); border-radius: 6px; padding: 8px; background: #ffffff; }"
         ".agenda-head { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 6px; align-items: center; margin-bottom: 6px; font-size: 12px; }"
         ".agenda-head strong { min-width: 0; overflow-wrap: anywhere; }"
         ".agenda-list { display: grid; gap: 5px; }"
         ".agenda-candidate { border: 1px solid var(--line); border-radius: 5px; padding: 6px; background: #fbfcfd; font-size: 12px; cursor: pointer; }"
         ".agenda-candidate.fired { border-color: var(--accent); background: var(--accent-soft); }"
         ".agenda-candidate.focused { box-shadow: 0 0 0 2px var(--accent-soft); }"
         ".agenda-status { display: inline-block; min-width: 42px; color: var(--muted); font-size: 11px; text-transform: uppercase; }"
         ".agenda-drilldown { display: grid; gap: 3px; margin-top: 6px; padding-top: 6px; border-top: 1px solid var(--line); }"
         ".agenda-line { display: grid; grid-template-columns: 68px minmax(0, 1fr); gap: 6px; }"
         ".agenda-line .detail-label { font-size: 11px; }"
         ".agenda-effect { display: grid; grid-template-columns: 68px minmax(0, 1fr); gap: 6px; }"
         ".agenda-effect.bad .agenda-status { color: var(--bad); }"
         ".trace-map { margin-bottom: 10px; border: 1px solid var(--line); border-radius: 6px; overflow-x: auto; background: #ffffff; }"
         ".trace-map-controls { display: grid; grid-template-columns: auto auto auto minmax(78px, auto) auto minmax(0, 1fr); gap: 6px; align-items: end; margin-bottom: 10px; }"
         ".trace-map-controls button { border: 1px solid var(--line); border-radius: 6px; background: #f9fafb; color: var(--ink); min-height: 30px; padding: 0 9px; font: inherit; font-size: 12px; cursor: pointer; }"
         ".trace-map-controls button:hover { border-color: var(--accent); background: var(--accent-soft); }"
         ".trace-map-controls label { display: grid; gap: 3px; color: var(--muted); font-size: 11px; }"
         ".trace-map-controls label.check { grid-auto-flow: column; align-items: center; gap: 5px; min-height: 30px; }"
         ".trace-map-controls select { width: 100%; border: 1px solid var(--line); border-radius: 6px; min-height: 30px; background: white; color: var(--ink); font: inherit; font-size: 12px; }"
         ".trace-map-controls input[type='checkbox'] { width: 14px; height: 14px; margin: 0; accent-color: var(--accent); }"
         ".trace-map-controls .count { justify-self: end; }"
         ".trace-map svg { width: 100%; min-width: 520px; min-height: 216px; background: #ffffff; }"
         ".trace-map-lane { stroke: #edf0f3; stroke-width: 1; }"
         ".trace-map-lane-label { fill: var(--muted); font-size: 10px; }"
         ".trace-map-link { stroke: #b9c3ce; stroke-width: 1.4; fill: none; }"
         ".trace-map-link.branch { stroke: #64748b; stroke-width: 1.9; stroke-dasharray: 4 3; }"
         ".trace-map-link.focused { stroke: var(--accent); stroke-width: 2.4; }"
         ".trace-map-event { cursor: pointer; }"
         ".trace-map-event rect { fill: #ffffff; stroke: #8090a0; stroke-width: 1.2; }"
         ".trace-map-event text { fill: var(--ink); font-size: 9px; pointer-events: none; }"
         ".trace-map-event.rules rect { fill: var(--accent-soft); }"
         ".trace-map-event.worlds rect { fill: var(--good-soft); }"
         ".trace-map-event.problems rect { fill: var(--bad-soft); stroke: #f1b4ad; }"
         ".trace-map-event.branch rect { stroke: #64748b; stroke-width: 1.8; }"
         ".trace-map-event.focused rect { stroke: var(--accent); stroke-width: 2.6; }"
         ".trace-node { min-width: 0; border: 1px solid var(--line); border-radius: 999px; padding: 3px 7px; background: #f9fafb; color: var(--ink); font: inherit; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }"
         "button.trace-node { cursor: pointer; }"
         "button.trace-node:hover { border-color: var(--accent); background: var(--accent-soft); }"
         ".trace-node.world { background: var(--good-soft); }"
         ".trace-node.rule { background: var(--accent-soft); }"
         ".trace-node.bad { background: var(--bad-soft); border-color: #f1b4ad; }"
         ".trace-arrow { color: var(--muted); text-align: center; }"
         ".trace-detail { border: 1px solid var(--line); border-radius: 6px; padding: 8px; margin-bottom: 10px; background: #ffffff; }"
         ".trace-detail strong { display: block; font-size: 13px; margin-bottom: 6px; }"
         ".trace-detail-grid { display: grid; grid-template-columns: 86px minmax(0, 1fr); gap: 4px 8px; font-size: 12px; }"
         ".trace-detail-grid dt { color: var(--muted); }"
         ".trace-detail-grid dd { margin: 0; min-width: 0; overflow-wrap: anywhere; }"
         ".trace-piece { display: inline-flex; align-items: center; gap: 4px; margin: 2px 6px 2px 0; }"
         ".trace-piece .pill { margin-left: 2px; }"
         ".meta { display: grid; grid-template-columns: 96px minmax(0, 1fr); gap: 6px 10px; font-size: 13px; }"
         ".meta dt { color: var(--muted); }"
         ".meta dd { margin: 0; min-width: 0; overflow-wrap: anywhere; }"
         ".pill-row { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 10px; }"
         ".pill { border: 1px solid var(--line); border-radius: 999px; padding: 3px 8px; font-size: 12px; background: #f9fafb; }"
         "button.pill { color: var(--accent); cursor: pointer; font-family: inherit; line-height: 1.2; }"
         "button.pill:hover { border-color: var(--accent); background: var(--accent-soft); }"
         ".detail-section { margin-top: 14px; padding-top: 12px; border-top: 1px solid var(--line); }"
         ".detail-section h3 { margin: 0 0 8px; font-size: 13px; color: var(--muted); }"
         ".detail-section h4 { margin: 10px 0 6px; font-size: 12px; color: var(--muted); }"
         ".detail-block { border: 1px solid var(--line); border-radius: 6px; padding: 8px; margin-top: 8px; background: #fbfcfd; }"
         ".detail-block strong { display: block; font-size: 13px; margin-bottom: 5px; }"
         ".detail-line { display: flex; gap: 6px; flex-wrap: wrap; font-size: 12px; margin-top: 4px; }"
         ".detail-label { color: var(--muted); }"
         ".code-text { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: 12px; overflow-wrap: anywhere; }"
         ".empty { color: var(--muted); font-size: 13px; }"
         "@media (max-width: 760px) { #app { grid-template-rows: auto minmax(0, 1fr); } header { flex-wrap: wrap; } .actions { margin-left: 0; width: 100%; } input[type='search'] { width: 100%; } main { grid-template-columns: 1fr; grid-template-rows: minmax(420px, 1fr) auto; } aside { border-left: 0; border-top: 1px solid var(--line); max-height: 54vh; grid-template-rows: minmax(220px, 1fr) minmax(0, 1fr); } }"
         "</style>"
         "</head>"
         "<body>"
         "<div id='app'>"
         "<header>"))
  (format stream "<div class='brand'><strong>~A</strong><span>Units and worlds</span></div>~%"
          (html-escape-string title))
  (write-html-lines
   stream
   (list "<nav class='tabs' aria-label='Graph views'>"
         "<button type='button' data-tab='units' class='active'>Units</button>"
         "<button type='button' data-tab='worlds'>Worlds</button>"
         "</nav>"
         "<div class='actions'>"
         "<input id='search' type='search' placeholder='Filter'>"
         "<button type='button' data-action='zoom-out'>-</button>"
         "<button type='button' data-action='zoom-in'>+</button>"
         "<button type='button' data-action='fit'>Fit</button>"
         "</div>"
         "</header>"
         "<main>"
         "<section class='viewport'><svg id='graph' role='img' aria-label='KEE graph'></svg></section>"
         "<aside>"
         "<section class='browser-pane'>"
         "<div class='browser-head'><h2>Browser</h2></div>"
         "<div class='kb-strip'>"
         "<div class='kb-line'><span class='kb-label'>Current KB</span><span id='current-kb' class='kb-value'></span></div>"
         "<div id='kb-list' class='kb-list'></div>"
         "</div>"
         "<section id='review-tour' class='review-tour' aria-label='Review tour'></section>"
         "<section id='desktop-context' class='desktop-context' aria-label='Desktop context'></section>"
         "<section id='desktop-roster' class='desktop-roster' aria-label='Desktop windows'></section>"
         "<section id='session-pane' class='session-pane' aria-label='Session window'></section>"
         "<div id='picture-browser'></div>"
         "<div id='hierarchy-browser' class='hierarchy-browser'></div>"
         "<div id='slot-browser'></div>"
         "<section class='browser-section graph-node-section'>"
         "<div class='browser-head'><h3>Graph Nodes</h3><span id='node-count' class='count'></span></div>"
         "<div id='node-list' class='node-list'></div>"
         "</section>"
         "</section>"
         "<section id='inspector' class='inspector-pane'></section>"
         "</aside>"
         "</main>"
         "</div>"
         "<script id='kee-data' type='application/json'>")))

(defun write-viewer-script (stream)
  (write-html-lines
   stream
   (list "</script>"
         "<script>"
         "const DATA = JSON.parse(document.getElementById('kee-data').textContent);"
         "const INITIAL = DATA.initial || {};"
         "const svg = document.getElementById('graph');"
         "const inspector = document.getElementById('inspector');"
         "const browserPane = document.querySelector('.browser-pane');"
         "const currentKb = document.getElementById('current-kb');"
         "const kbList = document.getElementById('kb-list');"
         "const reviewTour = document.getElementById('review-tour');"
         "const desktopContext = document.getElementById('desktop-context');"
         "const desktopRoster = document.getElementById('desktop-roster');"
         "const sessionPane = document.getElementById('session-pane');"
         "const pictureBrowser = document.getElementById('picture-browser');"
         "const hierarchyBrowser = document.getElementById('hierarchy-browser');"
         "const slotBrowser = document.getElementById('slot-browser');"
         "const nodeList = document.getElementById('node-list');"
         "const nodeCount = document.getElementById('node-count');"
         "const search = document.getElementById('search');"
         "const state = { view: INITIAL.view || 'units', selected: INITIAL.selected || null, query: '', zoom: 1, viewBox: null, focusSelected: !!INITIAL.selected, sessionWindow: 'listener', pictureName: null, panelName: null, traceFamily: INITIAL.traceFamily || 'all', traceKind: INITIAL.traceKind || 'all', traceScope: INITIAL.traceScope || 'selected', traceQuery: INITIAL.traceQuery || '', traceFocusId: null, traceReplaySpeed: 'normal', traceReplayLoop: false, xrefOperation: 'all', xrefSlot: 'all', xrefTarget: 'all' };"
         "let traceReplayTimer = null;"
         "function esc(value) { return String(value ?? '').replace(/[&<>\"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',\"'\":'&#39;'}[ch])); }"
         "function short(value, limit = 25) { const text = String(value ?? ''); return text.length > limit ? text.slice(0, limit - 3) + '...' : text; }"
         "function activeGraph() { return state.view === 'units' ? DATA.units : DATA.worlds; }"
         "function graphForKind(kind) { return kind === 'world' ? DATA.worlds : DATA.units; }"
         "function viewForKind(kind) { return kind === 'world' ? 'worlds' : 'units'; }"
         "function setView(view) { state.view = view; document.querySelectorAll('[data-tab]').forEach(item => item.classList.toggle('active', item.dataset.tab === view)); }"
         "function nodeLabel(node) { return node.name || node.id; }"
         "function nodeDetail(node, graph) { return graph.kind === 'unit' ? `${node.slots.length} slots` : `facts ${node.factCount} / nogoods ${node.nogoodCount}`; }"
         "function referenceId(kind, name, kb) { return kind === 'world' ? `world:${name}` : `unit:${kb || DATA.units.kb}/${name}`; }"
         "function referenceExists(kind, name, kb) { const id = referenceId(kind, name, kb); return graphForKind(kind).nodes.some(node => node.id === id); }"
         "function refButton(kind, name, kb = null, label = name) { return referenceExists(kind, name, kb) ? `<button type='button' class='pill' data-ref-kind='${esc(kind)}' data-ref-name='${esc(name)}' data-ref-kb='${esc(kb || '')}'>${esc(label)}</button>` : `<span class='pill'>${esc(label)}</span>`; }"
         "function traceRef(kind, name, kb = null, label = name, className = '') { if (!name) return `<span class='trace-node ${className}'>NIL</span>`; const attrs = `data-ref-kind='${esc(kind)}' data-ref-name='${esc(name)}' data-ref-kb='${esc(kb || '')}'`; return referenceExists(kind, name, kb) ? `<button type='button' class='trace-node ${className}' ${attrs}>${esc(label)}</button>` : `<span class='trace-node ${className}'>${esc(label)}</span>`; }"
         "function focusedTraceEvent() { return (DATA.details.traces || []).find(event => event.id === state.traceFocusId); }"
         "function worldNameFromId(id) { return String(id || '').replace(/^world:/, ''); }"
         "function worldParentByName() { const parents = new Map(); (DATA.worlds.edges || []).forEach(edge => parents.set(worldNameFromId(edge.to), worldNameFromId(edge.from))); return parents; }"
         "function worldPathNames(name) { if (!name) return []; const parents = worldParentByName(); const path = []; const seen = new Set(); for (let cursor = String(name); cursor && !seen.has(cursor); cursor = parents.get(cursor)) { path.unshift(cursor); seen.add(cursor); } return path; }"
         "function focusedTraceWorldPathNames() { const event = focusedTraceEvent(); if (!event) return []; const names = new Set(); [event.parent, event.world].filter(Boolean).forEach(name => worldPathNames(name).forEach(pathName => names.add(pathName))); return Array.from(names); }"
         "function focusedTraceReferenceIds(graph) { const event = focusedTraceEvent(); if (!event) return new Set(); const names = graph.kind === 'world' ? focusedTraceWorldPathNames() : [event.rule, event.ruleClass, event.unit]; return new Set(names.filter(Boolean).map(name => referenceId(graph.kind === 'world' ? 'world' : 'unit', name, DATA.units.kb))); }"
         "function searchableValues(node, graph) { const detail = detailMap(graph)[node.id]; return [node.id, node.name, node.kb, node.parent, ...(node.slots || []), detail ? JSON.stringify(detail) : null].filter(Boolean); }"
         "function matches(node, graph = activeGraph()) { const q = state.query.trim().toLowerCase(); if (!q) return true; return searchableValues(node, graph).some(v => String(v).toLowerCase().includes(q)); }"
         "function layout(graph) {"
         "  const nodes = graph.nodes.slice().sort((a, b) => nodeLabel(a).localeCompare(nodeLabel(b)));"
         "  const byId = new Map(nodes.map(node => [node.id, node]));"
         "  const children = new Map(nodes.map(node => [node.id, []]));"
         "  const indegree = new Map(nodes.map(node => [node.id, 0]));"
         "  graph.edges.forEach(edge => { if (byId.has(edge.from) && byId.has(edge.to)) { children.get(edge.from).push(edge.to); indegree.set(edge.to, indegree.get(edge.to) + 1); } });"
         "  const roots = nodes.filter(node => indegree.get(node.id) === 0).map(node => node.id);"
         "  const levels = new Map();"
         "  const queue = roots.map(id => [id, 0]);"
         "  while (queue.length) { const [id, level] = queue.shift(); if ((levels.get(id) ?? -1) >= level) continue; levels.set(id, level); (children.get(id) || []).forEach(child => queue.push([child, level + 1])); }"
         "  nodes.forEach(node => { if (!levels.has(node.id)) levels.set(node.id, 0); });"
         "  const groups = new Map();"
         "  nodes.forEach(node => { const level = levels.get(node.id); if (!groups.has(level)) groups.set(level, []); groups.get(level).push(node); });"
         "  const placed = new Map();"
         "  const xGap = graph.kind === 'unit' ? 260 : 230;"
         "  const yGap = 96;"
         "  Array.from(groups.keys()).sort((a, b) => a - b).forEach(level => { groups.get(level).forEach((node, index) => placed.set(node.id, { ...node, x: 52 + level * xGap, y: 48 + index * yGap, w: 190, h: 64 })); });"
         "  const positioned = Array.from(placed.values());"
         "  const width = Math.max(760, ...positioned.map(node => node.x + node.w + 80));"
         "  const height = Math.max(520, ...positioned.map(node => node.y + node.h + 80));"
         "  return { nodes: positioned, edges: graph.edges.filter(edge => placed.has(edge.from) && placed.has(edge.to)), placed, width, height };"
         "}"
         "function colorFor(node, graph) { if (graph.kind === 'world') return node.inconsistentP ? '#ffe7e4' : '#eef7ed'; return (node.slots && node.slots.length) ? '#e8f2fb' : '#ffffff'; }"
         "function edgePath(from, to) { const x1 = from.x + from.w; const y1 = from.y + from.h / 2; const x2 = to.x; const y2 = to.y + to.h / 2; const mid = x1 + Math.max(40, (x2 - x1) / 2); return `M ${x1} ${y1} C ${mid} ${y1}, ${mid} ${y2}, ${x2} ${y2}`; }"
         "function denseGraphP(graph) { return graph.edges.length > Math.max(30, graph.nodes.length * 1.15); }"
         "function edgeTouchesSelection(edge) { return !!state.selected && (edge.from === state.selected || edge.to === state.selected); }"
         "function setViewBox(width, height) { state.viewBox = { x: 0, y: 0, w: width / state.zoom, h: height / state.zoom }; svg.setAttribute('viewBox', `${state.viewBox.x} ${state.viewBox.y} ${state.viewBox.w} ${state.viewBox.h}`); }"
         "function clamp(value, min, max) { return Math.max(min, Math.min(max, value)); }"
         "function focusOnNode(node, model) { const width = state.viewBox?.w ?? model.width / state.zoom; const height = state.viewBox?.h ?? model.height / state.zoom; state.viewBox = { x: clamp(node.x + node.w / 2 - width / 2, 0, Math.max(0, model.width - width)), y: clamp(node.y + node.h / 2 - height / 2, 0, Math.max(0, model.height - height)), w: width, h: height }; }"
         "function selectNode(id, model, focus = false) { state.selected = id; const node = model.placed.get(id); if (focus && node) focusOnNode(node, model); render(); }"
         "function selectReference(kind, name, kb = null) { if (!referenceExists(kind, name, kb)) return; const view = viewForKind(kind); if (state.view !== view) state.viewBox = null; setView(view); state.selected = referenceId(kind, name, kb); state.focusSelected = true; render(); }"
         "function render() {"
         "  const graph = activeGraph();"
         "  const model = layout(graph);"
         "  if (!state.selected || !model.placed.has(state.selected)) state.selected = model.nodes[0]?.id || null;"
         "  if (state.focusSelected) { const target = state.selected && model.placed.get(state.selected); if (target) focusOnNode(target, model); state.focusSelected = false; }"
         "  ensureTraceFocus(filteredTraces(graph, detailMap(graph)[state.selected]));"
         "  const traceHits = focusedTraceReferenceIds(graph);"
         "  const denseEdges = denseGraphP(graph);"
         "  svg.setAttribute('width', model.width);"
         "  svg.setAttribute('height', model.height);"
         "  svg.innerHTML = `<defs><marker id='arrow' markerWidth='10' markerHeight='8' refX='9' refY='4' orient='auto'><path d='M0,0 L10,4 L0,8 Z' fill='#8e99a6'></path></marker></defs>`;"
         "  model.edges.forEach(edge => { const from = model.placed.get(edge.from); const to = model.placed.get(edge.to); const traceHit = traceHits.has(edge.from) && traceHits.has(edge.to); const adjacent = edgeTouchesSelection(edge); const background = denseEdges && !(adjacent || traceHit); const dim = !(matches(from, graph) || matches(to, graph)); const path = document.createElementNS('http://www.w3.org/2000/svg', 'path'); path.setAttribute('class', `edge ${edge.relation} ${background ? 'background' : ''} ${adjacent ? 'adjacent' : ''} ${traceHit ? 'trace-hit' : ''} ${dim && !traceHit ? 'dim' : ''}`); path.setAttribute('d', edgePath(from, to)); if (!background) path.setAttribute('marker-end', 'url(#arrow)'); svg.appendChild(path); if (!background) { const text = document.createElementNS('http://www.w3.org/2000/svg', 'text'); text.setAttribute('class', `edge-label ${adjacent ? 'adjacent' : ''} ${traceHit ? 'trace-hit' : ''} ${dim && !traceHit ? 'dim' : ''}`); text.setAttribute('x', (from.x + to.x + from.w) / 2); text.setAttribute('y', (from.y + to.y + from.h) / 2 - 8); text.textContent = edge.relation; svg.appendChild(text); } });"
         "  model.nodes.forEach(node => { const traceHit = traceHits.has(node.id); const dim = !matches(node, graph); const g = document.createElementNS('http://www.w3.org/2000/svg', 'g'); g.setAttribute('class', `node ${state.selected === node.id ? 'selected' : ''} ${traceHit ? 'trace-hit' : ''} ${dim && !traceHit ? 'dim' : ''}`); g.setAttribute('transform', `translate(${node.x}, ${node.y})`); g.dataset.id = node.id; const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect'); rect.setAttribute('width', node.w); rect.setAttribute('height', node.h); rect.setAttribute('rx', 7); rect.setAttribute('ry', 7); rect.setAttribute('fill', colorFor(node, graph)); g.appendChild(rect); const label = document.createElementNS('http://www.w3.org/2000/svg', 'text'); label.setAttribute('x', 12); label.setAttribute('y', 23); const title = document.createElementNS('http://www.w3.org/2000/svg', 'tspan'); title.setAttribute('class', 'title'); title.textContent = short(nodeLabel(node)); label.appendChild(title); const detail = document.createElementNS('http://www.w3.org/2000/svg', 'tspan'); detail.setAttribute('x', 12); detail.setAttribute('dy', 20); detail.textContent = nodeDetail(node, graph); label.appendChild(detail); g.appendChild(label); g.addEventListener('click', () => selectNode(node.id, model)); svg.appendChild(g); });"
         "  renderBrowser(model, graph);"
         "  renderInspector(model, graph);"
         "  if (!state.viewBox) setViewBox(model.width, model.height); else svg.setAttribute('viewBox', `${state.viewBox.x} ${state.viewBox.y} ${state.viewBox.w} ${state.viewBox.h}`);"
         "}"
         "function detailMap(graph) { return graph.kind === 'unit' ? DATA.details.units : DATA.details.worlds; }"
         "function loadedKbs() { const kbs = Array.isArray(DATA.kbs) ? DATA.kbs.filter(Boolean) : []; return kbs.length ? kbs : [DATA.units.kb].filter(Boolean); }"
         "function renderKbStrip() { currentKb.textContent = DATA.units.kb || 'NIL'; kbList.innerHTML = loadedKbs().map(kb => `<span class='kb-chip ${kb === DATA.units.kb ? 'active' : ''}'>${esc(kb)}</span>`).join(''); }"
         "function unitDetailValues() { return Object.values(DATA.details.units || {}); }"
         "function worldDetailValues() { return Object.values(DATA.details.worlds || {}); }"
         "function firstUnitDetail(predicate) { return unitDetailValues().find(predicate); }"
         "function firstWorldDetail(predicate) { return worldDetailValues().find(predicate); }"
         "function ruleReferenceEntriesFor(ref) { return ref ? [...(ref.reads || []), ...(ref.writes || []), ...(ref.asserts || [])] : []; }"
         "function reviewTourTarget(kind) {"
         "  if (kind === 'units') return { kind: 'unit', detail: firstUnitDetail(detail => detail.name === 'PEOPLE') || firstUnitDetail(detail => (detail.slots || []).length) || firstUnitDetail(() => true) };"
         "  if (kind === 'rules') return { kind: 'unit', detail: firstUnitDetail(detail => detail.ruleReference && detail.name !== 'CONSTRAINT.RULES') || firstUnitDetail(detail => detail.ruleReference) };"
         "  if (kind === 'xref') return { kind: 'unit', detail: firstUnitDetail(detail => detail.ruleReference && ruleReferenceEntriesFor(detail.ruleReference).length) || firstUnitDetail(detail => detail.ruleReference) };"
         "  if (kind === 'active-images') { const image = (DATA.details.activeImages || [])[0]; return image ? { kind: 'unit', detail: DATA.details.units[referenceId('unit', image.targetUnit, image.targetKb)] } : null; }"
         "  if (kind === 'kee-pictures') { const picture = (DATA.details.pictures || [])[0]; return picture ? { kind: 'picture', detail: picture } : null; }"
         "  if (kind === 'panels') { const panel = (DATA.details.panels || [])[0]; return panel ? { kind: 'panel', detail: panel } : null; }"
         "  if (kind === 'worlds' || kind === 'agenda') return { kind: 'world', detail: firstWorldDetail(detail => detail.inconsistentP && (detail.nogoods || []).length) || firstWorldDetail(detail => (detail.facts || []).length) || firstWorldDetail(() => true) };"
         "  return null;"
         "}"
         "function reviewTourAvailable(kind) { const target = reviewTourTarget(kind); return !!(target && target.detail); }"
         "function selectReviewTour(kind) {"
         "  const target = reviewTourTarget(kind);"
         "  if (!(target && target.detail)) return;"
         "  stopTraceReplay();"
         "  state.query = '';"
         "  search.value = '';"
         "  state.traceQuery = '';"
         "  state.traceKind = 'all';"
         "  state.traceFamily = kind === 'agenda' ? 'rules' : (kind === 'kee-pictures' || kind === 'panels') ? 'pictures' : 'all';"
         "  state.traceScope = (kind === 'kee-pictures' || kind === 'panels') ? 'all' : 'selected';"
         "  if (kind === 'xref') { state.xrefOperation = 'all'; state.xrefSlot = 'all'; state.xrefTarget = 'all'; }"
         "  if (target.kind === 'picture') { state.pictureName = target.detail.name; render(); return; }"
         "  if (target.kind === 'panel') { state.panelName = target.detail.name; state.pictureName = target.detail.picture || state.pictureName; render(); return; }"
         "  if (target.kind === 'world') selectReference('world', target.detail.name);"
         "  else selectReference('unit', target.detail.name, target.detail.kb);"
         "}"
         "function renderReviewTour() { const items = [['units', 'Units'], ['rules', 'Rules'], ['worlds', 'Worlds'], ['agenda', 'Agenda'], ['xref', 'Rule Xref'], ['kee-pictures', 'KEEpictures'], ['panels', 'Panels'], ['active-images', 'ActiveImages']]; reviewTour.innerHTML = `<h3>Review Tour</h3><div class='tour-buttons'>${items.map(([kind, label]) => `<button type='button' data-review-tour='${kind}' ${reviewTourAvailable(kind) ? '' : 'disabled'}>${label}</button>`).join('')}</div>`; }"
         "function renderDesktopContext() { const session = DATA.session || {}; const notes = session.tourNotes || []; if (!(session.desktopTitle || session.desktopSubtitle || session.desktopNotice || notes.length)) { desktopContext.innerHTML = ''; return; } const subtitle = session.desktopSubtitle ? `<p>${esc(session.desktopSubtitle)}</p>` : ''; const notice = session.desktopNotice ? `<p class='desktop-notice'>${esc(session.desktopNotice)}</p>` : ''; const noteList = notes.length ? `<ul>${notes.map(note => `<li>${esc(note)}</li>`).join('')}</ul>` : ''; desktopContext.innerHTML = `<h3>${esc(session.desktopTitle || 'Session Context')}</h3>${subtitle}${notice}${noteList}`; }"
         "function desktopWindowHtml(label, meta, kind = null, session = null) { const active = session && state.sessionWindow === session ? ' active' : ''; const attrs = session ? `data-session-window='${session}'` : (kind ? `data-desktop-tour='${kind}' ${reviewTourAvailable(kind) ? '' : 'disabled'}` : 'disabled'); return `<button type='button' class='desktop-window${active}' ${attrs}><strong>${esc(label)}</strong><span>${esc(meta)}</span></button>`; }"
         "function renderDesktopRoster() { const items = [['Lisp Listener', 'evaluation', null, 'listener'], ['Typescript', 'transcript', null, 'typescript'], ['Prompt', 'messages', null, 'prompt'], ['KB Browser', 'current KB', 'units'], ['Unit Window', 'classes', 'units'], ['Slot Window', 'facets', 'units'], ['Worlds', 'assumptions', 'worlds'], ['Agenda', 'conflict set', 'agenda'], ['Rule Xref', 'references', 'xref'], ['KEEpictures', 'graphics', 'kee-pictures'], ['Image Panels', 'workflow', 'panels'], ['ActiveImages', 'two-way graphics', 'active-images']]; desktopRoster.innerHTML = `<h3>Desktop</h3><div class='desktop-windows'>${items.map(([label, meta, kind, session]) => desktopWindowHtml(label, meta, kind, session)).join('')}</div>`; }"
         "function sessionLines(kind) { return (DATA.session && DATA.session[kind]) || []; }"
         "function renderSessionPane() { const labels = { listener: 'Lisp Listener', typescript: 'Typescript', prompt: 'Prompt' }; const lines = sessionLines(state.sessionWindow); sessionPane.innerHTML = `<h3>${esc(labels[state.sessionWindow] || 'Session')}</h3><div class='session-window'><pre>${esc(lines.length ? lines.join('\\n') : 'No session transcript')}</pre></div>`; }"
         "function keePictures() { return DATA.details.pictures || []; }"
         "function selectedPicture() { const pictures = keePictures(); return pictures.find(picture => picture.name === state.pictureName) || pictures[0] || null; }"
         "function pictureViewportSummary(picture) { const rows = (picture.viewports || []).map(viewport => { const panes = (viewport.windowpanes || []).map(pane => pane.label || pane.name).join(', ') || 'no windowpanes'; return `<div class='detail-line'><span class='detail-label'>${esc(viewport.label || viewport.name)}</span><span class='code-text'>${esc(`${viewport.width}x${viewport.height} / ${panes}`)}</span></div>`; }); return rows.length ? rows.join('') : `<p class='empty'>No viewports</p>`; }"
         "function keePanels() { return DATA.details.panels || []; }"
         "function selectedPanel() { const panels = keePanels(); return panels.find(panel => panel.name === state.panelName) || panels[0] || null; }"
         "function panelSummary(panel) { const rows = []; if (panel.picture) rows.push(['Picture', panel.pictureLabel || panel.picture]); if (panel.viewport) rows.push(['Viewport', panel.viewport]); if (panel.windowpane) rows.push(['Windowpane', panel.windowpaneLabel || panel.windowpane]); if (panel.message) rows.push(['Message', panel.message]); return rows.map(([label, value]) => `<div class='detail-line'><span class='detail-label'>${esc(label)}</span><span class='code-text'>${esc(value)}</span></div>`).join(''); }"
         "function panelActionButtons(panel) { return `<div class='panel-actions'><button type='button' data-panel-action='open' ${panel.openP ? 'disabled' : ''}>Open</button><button type='button' data-panel-action='close' ${panel.openP ? '' : 'disabled'}>Close</button></div>`; }"
         "function panelWindowCard(panel, selected) { const stateLabel = panel.openP ? 'open' : 'closed'; const active = panel.name === selected.name ? ' active' : ''; const open = panel.openP ? ' open' : ''; const meta = [panel.kind, panel.windowpaneLabel || panel.windowpane].filter(Boolean).join(' / '); return `<button type='button' data-panel-name='${esc(panel.name)}' class='panel-window-card${active}${open}'><span class='panel-window-titlebar'><strong>${esc(panel.label || panel.name)}</strong><span class='panel-state ${panel.openP ? 'open' : ''}'>${stateLabel}</span></span><span class='panel-window-body'><span>${esc(meta || 'image panel')}</span>${panel.message ? `<span>${esc(panel.message)}</span>` : ''}</span></button>`; }"
         "function renderPanelWindowDeck(panels, selected) { return `<div class='panel-window-deck' aria-label='Image panel windows'>${panels.map(panel => panelWindowCard(panel, selected)).join('')}</div>`; }"
         "function renderPanelBrowser() { const panels = keePanels(); if (!panels.length) return ''; const selected = selectedPanel(); state.panelName = selected.name; const tabs = panels.map(panel => `<button type='button' data-panel-name='${esc(panel.name)}' class='${panel.name === selected.name ? 'active' : ''}'>${esc(panel.label || panel.name)}</button>`).join(''); const stateLabel = selected.openP ? 'open' : 'closed'; const preview = selected.svg ? `<div class='kee-picture-preview'>${selected.svg}</div>` : ''; return `<section class='browser-section'><h3>Image Panel Windows</h3>${renderPanelWindowDeck(panels, selected)}<div class='picture-tabs'>${tabs}</div><div class='kee-panel'><div class='panel-head'><strong>${esc(selected.label || selected.name)}</strong><span class='panel-state ${selected.openP ? 'open' : ''}'>${stateLabel}</span></div>${selected.message ? `<p class='panel-message'>${esc(selected.message)}</p>` : ''}${panelSummary(selected)}${panelActionButtons(selected)}${preview}</div></section>`; }"
         "function renderPictureBrowser() { const panelHtml = renderPanelBrowser(); const pictures = keePictures(); if (!pictures.length) { pictureBrowser.innerHTML = panelHtml; return; } const selected = selectedPicture(); state.pictureName = selected.name; const tabs = pictures.map(picture => `<button type='button' data-picture-name='${esc(picture.name)}' class='${picture.name === selected.name ? 'active' : ''}'>${esc(picture.label || picture.name)}</button>`).join(''); pictureBrowser.innerHTML = `${panelHtml}<section class='browser-section'><h3>KEEpictures</h3><div class='picture-tabs'>${tabs}</div><div class='kee-picture-preview'>${selected.svg || ''}</div>${pictureViewportSummary(selected)}</section>`; }"
         "function canonicalUnitName(value) { return String(value ?? '').replace(/[^A-Za-z0-9]/g, '').toUpperCase(); }"
         "function activeBrowserUnitP(detail) { const names = [detail?.name, ...(detail?.classParents || []), ...(detail?.memberParents || [])].map(canonicalUnitName); return names.some(name => name.includes('ACTIVEIMAGE') || name.includes('ACTIVEVALUE')); }"
         "function unitDetails() { return Object.values(DATA.details.units || {}).filter(detail => detail.kb === DATA.units.kb); }"
         "function selectedUnitDetail(graph) { return graph.kind === 'unit' ? detailMap(graph)[state.selected] : null; }"
         "function unitTopLevels() { const units = unitDetails().filter(detail => !activeBrowserUnitP(detail)); const roots = units.filter(detail => !(detail.classParents || []).length && !(detail.memberParents || []).length); return (roots.length ? roots : units).sort((a, b) => a.name.localeCompare(b.name)); }"
         "function hierarchyButton(name, kb, meta = '') { const id = referenceId('unit', name, kb); const active = state.selected === id ? ' active' : ''; const label = `<span class='node-row-title'>${esc(name)}</span>${meta ? `<span class='node-row-meta'>${esc(meta)}</span>` : ''}`; return referenceExists('unit', name, kb) ? `<button type='button' class='node-row hierarchy-row${active}' data-ref-kind='unit' data-ref-name='${esc(name)}' data-ref-kb='${esc(kb || '')}'>${label}</button>` : `<div class='node-row static'>${label}</div>`; }"
         "function hierarchySection(title, names, kb, metaFn = null) { const rows = (names || []).filter(Boolean); const body = rows.length ? rows.map(name => hierarchyButton(name, kb, metaFn ? metaFn(name) : '')).join('') : `<p class='empty'>None</p>`; return `<section class='browser-section'><h3>${esc(title)}</h3><div class='node-list compact'>${body}</div></section>`; }"
         "function slotText(values) { return (values || []).join(', ') || 'NIL'; }"
         "function activeImagesForUnit(detail) { return (DATA.details.activeImages || []).filter(image => image.targetKb === detail.kb && image.targetUnit === detail.name); }"
         "function activeImageByName(name) { return (DATA.details.activeImages || []).find(image => image.name === name); }"
         "function activeImageNumber(value, fallback = 0) { const number = Number(value); return Number.isFinite(number) ? number : fallback; }"
         "function activeImageAttrs(image) { return `data-active-image-name='${esc(image.name)}'`; }"
         "function activeImageValueText(image) { return (image.values || []).length ? (image.values || []).join(', ') : 'NIL'; }"
         "function activeImageOnP(value) { const text = String(value ?? '').toUpperCase(); return !!text && !['NIL', 'FALSE', 'OFF', 'NO', '0'].includes(text); }"
         "function renderActiveImageChoice(image) { const choices = image.choices || []; if (!(image.writableP && choices.length)) return ''; return `<select ${activeImageAttrs(image)}>${choices.map(choice => `<option value='${esc(choice)}' ${String(choice) === String(image.value ?? '') ? 'selected' : ''}>${esc(choice)}</option>`).join('')}</select>`; }"
         "function renderActiveImageMeter(image, className) { const value = activeImageNumber(image.value, 0); const min = activeImageNumber(image.min, 0); const max = activeImageNumber(image.max, Math.max(100, value)); const control = image.writableP ? `<input type='range' min='${min}' max='${max}' value='${value}' ${activeImageAttrs(image)}><output>${esc(image.value ?? 'NIL')}</output>` : `<meter min='${min}' max='${max}' value='${value}'>${esc(image.value ?? 'NIL')}</meter><output>${esc(image.value ?? 'NIL')}</output>`; return `<div class='active-image ${className}'><label>${esc(image.label || image.name)}</label>${control}</div>`; }"
         "function renderActiveImageHistogram(image) { const numbers = (image.values || []).map(Number).filter(Number.isFinite); if (!numbers.length) return renderActiveImageValue(image); const max = Math.max(...numbers, 1); const bars = numbers.map(value => `<span class='active-image-bar' style='height:${Math.max(0, Math.min(100, (value / max) * 100))}%' title='${esc(value)}'></span>`).join(''); return `<div class='active-image active-image-histogram' ${activeImageAttrs(image)}><strong>${esc(image.label || image.name)}</strong><div class='active-image-bars'>${bars}</div></div>`; }"
         "function renderActiveImagePlot(image) { const numbers = (image.values || []).map(Number).filter(Number.isFinite); if (numbers.length < 2) return renderActiveImageValue(image); const min = Math.min(...numbers); const max = Math.max(...numbers); const span = max === min ? 1 : max - min; const points = numbers.map((value, index) => `${numbers.length === 1 ? 0 : (index / (numbers.length - 1)) * 100},${100 - ((value - min) / span) * 100}`).join(' '); return `<div class='active-image'><strong>${esc(image.label || image.name)}</strong><svg class='active-image-plot' viewBox='0 0 100 100' role='img' aria-label='${esc(image.label || image.name)}' ${activeImageAttrs(image)}><polyline points='${points}' fill='none' stroke='currentColor' stroke-width='3'></polyline></svg></div>`; }"
         "function renderActiveImageValue(image) { const choices = renderActiveImageChoice(image); if (choices) return `<div class='active-image'><strong>${esc(image.label || image.name)}</strong>${choices}</div>`; const value = esc(activeImageValueText(image)); const control = image.writableP ? `<input class='active-image-value-input' type='text' value='${value}' ${activeImageAttrs(image)}>` : `<span class='code-text'>${value}</span>`; return `<div class='active-image active-image-value'><strong>${esc(image.label || image.name)}</strong>${control}</div>`; }"
         "function renderActiveImage(image) { const widget = String(image.widget || 'value').toLowerCase(); if (widget === 'gauge') return renderActiveImageMeter(image, 'active-image-gauge'); if (widget === 'thermometer') return renderActiveImageMeter(image, 'active-image-thermometer'); if (widget === 'switch') { const on = activeImageOnP(image.value); return `<button type='button' class='active-image active-image-switch ${on ? 'is-on' : 'is-off'}' aria-pressed='${on ? 'true' : 'false'}' ${activeImageAttrs(image)} ${image.writableP ? '' : 'disabled'}>${esc(image.label || image.name)}: ${on ? 'ON' : 'OFF'}</button>`; } if (widget === 'button') return `<button type='button' class='active-image active-image-button' ${activeImageAttrs(image)} ${image.writableP ? '' : 'disabled'}>${esc(image.label || image.name)}</button>`; if (widget === 'histogram') return renderActiveImageHistogram(image); if (widget === 'plot') return renderActiveImagePlot(image); return renderActiveImageValue(image); }"
         "function renderActiveImageSection(detail) { const images = activeImagesForUnit(detail); return images.length ? `<section class='browser-section'><h3>ActiveImages</h3><div class='active-image-list'>${images.map(renderActiveImage).join('')}</div></section>` : ''; }"
         "function slotFacetText(slot) { return (slot.facets || []).map(facetSummary).join('; ') || 'NIL'; }"
         "function renderSlotTableRow(slot) { return `<tr><td><span class='code-text'>${esc(slot.name)}</span><span class='slot-kind'>${esc(slot.kind || 'NIL')}</span></td><td><span class='code-text'>${esc(slotText(slot.localValues))}</span></td><td><span class='code-text'>${esc(slotText(slot.inheritedValues))}</span></td><td><span class='code-text'>${esc(slotText(slot.combinedValues))}</span></td><td><span class='code-text'>${esc(slotFacetText(slot))}</span></td></tr>`; }"
         "function renderSlotBrowser(detail) { if (!detail) { slotBrowser.innerHTML = `<section class='browser-section'><h3>Slot Table</h3><p class='empty'>No unit selected</p></section>`; return; } const slots = detail.slots || []; const slotTable = `<section class='browser-section'><h3>Slot Table</h3>${slots.length ? `<table class='slot-table'><thead><tr><th>Slot</th><th>Local</th><th>Inherited</th><th>Combined</th><th>Facets</th></tr></thead><tbody>${slots.map(renderSlotTableRow).join('')}</tbody></table>` : `<p class='empty'>None</p>`}</section>`; slotBrowser.innerHTML = slotTable + renderActiveImageSection(detail); }"
         "function coerceActiveImageInput(image, value) { if ([image.value, image.min, image.max].some(item => typeof item === 'number')) { const number = Number(value); if (Number.isFinite(number)) return number; } return value; }"
         "function updateActiveImageTarget(image, value) { (DATA.details.activeImages || []).forEach(other => { if (other.targetKb === image.targetKb && other.targetUnit === image.targetUnit && other.targetSlot === image.targetSlot && other.targetFacet === image.targetFacet) { other.value = value; other.values = [value]; } }); if (image.targetFacet) return; const detail = DATA.details.units[referenceId('unit', image.targetUnit, image.targetKb)]; const slot = detail && (detail.slots || []).find(candidate => candidate.name === image.targetSlot); if (slot) { slot.localValues = [value]; slot.combinedValues = [value]; } }"
         "function setActiveImageLocal(name, rawValue) { const image = activeImageByName(name); if (!image || !image.writableP) return; const value = coerceActiveImageInput(image, rawValue); updateActiveImageTarget(image, value); render(); }"
         "function nextTraceId() { const rows = DATA.details.traces || (DATA.details.traces = []); return rows.reduce((max, event) => Math.max(max, Number(event.id) || 0), 0) + 1; }"
         "function panelTraceEvent(panel, openP, oldOpenP) { return { id: nextTraceId(), kind: openP ? 'PANEL-OPEN' : 'PANEL-CLOSE', agendaId: null, activationId: null, fireId: null, world: null, parent: null, rule: null, ruleClass: null, unit: panel.name, slot: null, panel: panel.name, picture: panel.picture || null, item: null, viewport: panel.viewport || null, windowpane: panel.windowpane || null, activeImage: null, button: null, x: null, y: null, value: null, methodKind: null, method: null, args: [], oldValues: [oldOpenP ? 'T' : null], newValues: [openP ? 'T' : null], bindings: [], conditions: [], action: openP ? 'OPEN-PANEL!' : 'CLOSE-PANEL!', proposition: null, fact: null, result: null, message: openP ? 'KEE image panel opened' : 'KEE image panel closed' }; }"
         "function setPanelLocal(name, openP) { const panel = keePanels().find(candidate => candidate.name === name); if (!panel) return; const oldOpenP = !!panel.openP; const newOpenP = !!openP; state.traceFamily = 'pictures'; state.traceScope = 'all'; state.traceKind = 'all'; state.traceQuery = ''; if (oldOpenP !== newOpenP) { panel.openP = newOpenP; const event = panelTraceEvent(panel, newOpenP, oldOpenP); (DATA.details.traces || (DATA.details.traces = [])).push(event); state.traceFocusId = event.id; } render(); }"
         "function renderHierarchyBrowser(model, graph) { const detail = selectedUnitDetail(graph); const topLevels = unitTopLevels(); const topNames = topLevels.map(unit => unit.name); const slotMeta = name => { const unit = unitDetails().find(candidate => candidate.name === name); const count = unit?.slots?.length ?? 0; return `${count} slots`; }; let html = hierarchySection('Top Level Units', topNames, DATA.units.kb, slotMeta); if (detail) { html += `<section class='browser-section'><h3>Current Unit</h3><div class='node-list compact'>${hierarchyButton(detail.name, detail.kb, `${(detail.slots || []).length} slots`)}</div></section>`; html += hierarchySection('Class Parents', detail.classParents, detail.kb); html += hierarchySection('Member Parents', detail.memberParents, detail.kb); html += hierarchySection('Subclass Children', detail.classChildren, detail.kb); html += hierarchySection('Member Children', detail.memberChildren, detail.kb); } else { html += `<section class='browser-section'><h3>Current Unit</h3><p class='empty'>No unit selected</p></section>`; } hierarchyBrowser.innerHTML = html; renderSlotBrowser(detail); renderNodeBrowser(model, graph); }"
         "function renderBrowser(model, graph) { renderKbStrip(); renderReviewTour(); renderDesktopContext(); renderDesktopRoster(); renderSessionPane(); renderPictureBrowser(); if (graph.kind === 'unit') { renderHierarchyBrowser(model, graph); return; } hierarchyBrowser.innerHTML = ''; slotBrowser.innerHTML = ''; renderNodeBrowser(model, graph); }"
         "function renderNodeBrowser(model, graph) {"
         "  const rows = model.nodes.filter(node => matches(node, graph));"
         "  nodeCount.textContent = `${rows.length}/${model.nodes.length}`;"
         "  nodeList.innerHTML = rows.length ? '' : `<p class='empty'>No matches</p>`;"
         "  rows.forEach(node => { const button = document.createElement('button'); button.type = 'button'; button.className = `node-row ${state.selected === node.id ? 'active' : ''} ${graph.kind === 'world' && node.inconsistentP ? 'bad' : ''}`; button.innerHTML = `<span class='node-row-title'>${esc(nodeLabel(node))}</span><span class='node-row-meta'>${esc(nodeDetail(node, graph))}</span>`; button.addEventListener('click', () => selectNode(node.id, model, true)); nodeList.appendChild(button); });"
         "}"
         "function pillList(items, refKind = null, kb = null) { return (items && items.length) ? `<div class='pill-row'>${items.map(item => refKind ? refButton(refKind, item, kb) : `<span class='pill'>${esc(item)}</span>`).join('')}</div>` : `<p class='empty'>None</p>`; }"
         "function detailLine(label, value) { return `<div class='detail-line'><span class='detail-label'>${esc(label)}</span><span class='code-text'>${esc(value ?? 'NIL')}</span></div>`; }"
         "function refLine(label, kind, name, kb = null) { return `<div class='detail-line'><span class='detail-label'>${esc(label)}</span>${refButton(kind, name, kb)}</div>`; }"
         "function facetSummary(facet) { return `${facet.name}: ${(facet.values || []).join(', ') || 'NIL'}`; }"
         "function renderSlot(slot) {"
         "  const localValues = (slot.localValues || []).join(', ');"
         "  const inheritedValues = (slot.inheritedValues || []).join(', ');"
         "  const combinedValues = (slot.combinedValues || []).join(', ');"
         "  const facets = (slot.facets || []).map(facetSummary).join('; ');"
         "  return `<div class='detail-block'><strong>${esc(slot.name)}</strong>${detailLine('kind', slot.kind)}${detailLine('values', combinedValues || 'NIL')}${localValues ? detailLine('local', localValues) : ''}${inheritedValues ? detailLine('inherited', inheritedValues) : ''}${slot.inheritance ? detailLine('inheritance', slot.inheritance) : ''}${slot.valueType ? detailLine('value type', slot.valueType) : ''}${slot.default ? detailLine('default', slot.default) : ''}${facets ? detailLine('facets', facets) : ''}</div>`;"
         "}"
         "function allRuleReferences() { return DATA.details.ruleReferences || []; }"
         "function ruleReferenceEntries(ref) { return [...(ref?.reads || []), ...(ref?.writes || []), ...(ref?.asserts || [])]; }"
         "function ruleReferenceTouchesUnit(ref, name) { return (ref.ruleClasses || []).includes(name) || ruleReferenceEntries(ref).some(entry => entry.unit === name); }"
         "function ruleReferencesForUnit(detail) { return allRuleReferences().filter(ref => ref.rule !== detail.name && ruleReferenceTouchesUnit(ref, detail.name)); }"
         "function xrefClassEntry(ref, name) { return { kind: 'CLASS', context: 'MEMBER', operation: 'MEMBER', unit: name, slot: null, value: ref.rule, source: 'rule class membership' }; }"
         "function xrefEntriesForDetail(detail) { const entries = detail.ruleReference ? ruleReferenceEntries(detail.ruleReference).slice() : []; ruleReferencesForUnit(detail).forEach(ref => { entries.push(...ruleReferenceEntries(ref).filter(entry => entry.unit === detail.name)); if ((ref.ruleClasses || []).includes(detail.name)) entries.push(xrefClassEntry(ref, detail.name)); }); return entries; }"
         "function uniqueSorted(values) { return Array.from(new Set(values.filter(Boolean))).sort((a, b) => String(a).localeCompare(String(b))); }"
         "function selectOptions(current, allLabel, values) { return [['all', allLabel], ...values.map(value => [value, value])].map(([value, label]) => `<option value='${esc(value)}' ${current === value ? 'selected' : ''}>${esc(label)}</option>`).join(''); }"
         "function xrefVariableTargetP(entry) { return [entry.unit, entry.slot].some(value => String(value || '').trim().startsWith('?')); }"
         "function xrefEntryMatches(entry, selectedName) { if (state.xrefOperation !== 'all' && entry.operation !== state.xrefOperation) return false; if (state.xrefSlot !== 'all' && entry.slot !== state.xrefSlot) return false; if (state.xrefTarget === 'selected' && entry.unit !== selectedName) return false; if (state.xrefTarget === 'variable' && !xrefVariableTargetP(entry)) return false; if (state.xrefTarget === 'concrete' && xrefVariableTargetP(entry)) return false; return true; }"
         "function xrefDefaultFiltersP() { return state.xrefOperation === 'all' && state.xrefSlot === 'all' && state.xrefTarget === 'all'; }"
         "function reconcileXrefFilters(detail) { const entries = xrefEntriesForDetail(detail); const operations = uniqueSorted(entries.map(entry => entry.operation)); const slots = uniqueSorted(entries.map(entry => entry.slot)); if (state.xrefOperation !== 'all' && !operations.includes(state.xrefOperation)) state.xrefOperation = 'all'; if (state.xrefSlot !== 'all' && !slots.includes(state.xrefSlot)) state.xrefSlot = 'all'; }"
         "function renderXrefControls(detail) { const entries = xrefEntriesForDetail(detail); const operationOptions = selectOptions(state.xrefOperation, 'all operations', uniqueSorted(entries.map(entry => entry.operation))); const slotOptions = selectOptions(state.xrefSlot, 'all slots', uniqueSorted(entries.map(entry => entry.slot))); const targetOptions = [['all', 'all targets'], ['selected', 'selected unit'], ['variable', 'variable targets'], ['concrete', 'concrete targets']].map(([value, label]) => `<option value='${value}' ${state.xrefTarget === value ? 'selected' : ''}>${label}</option>`).join(''); return `<div class='xref-controls'><label>Operation<select data-xref-control='operation'>${operationOptions}</select></label><label>Slot<select data-xref-control='slot'>${slotOptions}</select></label><label>Target<select data-xref-control='target'>${targetOptions}</select></label></div>`; }"
         "function renderRuleReferenceEntry(entry) { const unit = entry.unit ? refButton('unit', entry.unit, DATA.units.kb) : `<span class='pill'>NIL</span>`; const target = entry.slot ? `${unit}<span class='code-text'>.${esc(entry.slot)}</span>` : unit; const value = entry.value ? detailLine('value', entry.value) : ''; const proposition = entry.proposition ? detailLine('proposition', entry.proposition) : ''; return `<div class='detail-block'><strong>${esc(entry.operation || entry.kind || 'REFERENCE')}</strong><div class='detail-line'><span class='detail-label'>target</span>${target}</div>${value}${proposition}${detailLine('context', entry.context)}${detailLine('source', entry.source)}</div>`; }"
         "function renderRuleReferenceGroup(title, entries, selectedName) { const rows = (entries || []).filter(entry => xrefEntryMatches(entry, selectedName)); return rows.length ? `<h4>${esc(title)}</h4>${rows.map(renderRuleReferenceEntry).join('')}` : ''; }"
         "function renderOwnRuleReference(ref, selectedName) { if (!ref) return ''; const classes = ref.ruleClasses && ref.ruleClasses.length ? `<div class='pill-row'>${ref.ruleClasses.map(name => refButton('unit', name, ref.kb)).join('')}</div>` : ''; const groups = renderRuleReferenceGroup('Reads', ref.reads, selectedName) + renderRuleReferenceGroup('Writes', ref.writes, selectedName) + renderRuleReferenceGroup('Asserts', ref.asserts, selectedName); return (groups || xrefDefaultFiltersP()) ? `<div class='detail-block'><strong>${esc(ref.rule)}</strong>${classes}</div>${groups}` : ''; }"
         "function renderMentionedRule(ref, name) { const entries = ruleReferenceEntries(ref).filter(entry => entry.unit === name); if ((ref.ruleClasses || []).includes(name)) entries.unshift(xrefClassEntry(ref, name)); const labels = entries.filter(entry => xrefEntryMatches(entry, name)).map(entry => `${entry.operation}${entry.slot ? ' ' + entry.slot : ''}`); return labels.length ? `<div class='detail-block'><strong>${refButton('unit', ref.rule, ref.kb)}</strong>${detailLine('mentions', labels.join(', '))}</div>` : ''; }"
         "function renderRuleXref(detail) { const own = detail.ruleReference; const mentioned = ruleReferencesForUnit(detail); if (!own && !mentioned.length) return ''; reconcileXrefFilters(detail); const ownHtml = renderOwnRuleReference(own, detail.name); const mentionedRows = mentioned.map(ref => renderMentionedRule(ref, detail.name)).filter(Boolean); const mentionedHtml = mentionedRows.length ? `<h4>Referenced By</h4>${mentionedRows.join('')}` : ''; const body = ownHtml + mentionedHtml; return `<section class='detail-section'><h3>Rule Xref</h3>${renderXrefControls(detail)}${body || `<p class='empty'>No matching references</p>`}</section>`; }"
         "function renderUnitDetail(detail) {"
         "  const parents = [...(detail.classParents || []), ...(detail.memberParents || [])];"
         "  const children = [...(detail.classChildren || []), ...(detail.memberChildren || [])];"
         "  const slots = detail.slots || [];"
         "  return `<section class='detail-section'><h3>Parents</h3>${pillList(parents, 'unit', detail.kb)}</section><section class='detail-section'><h3>Children</h3>${pillList(children, 'unit', detail.kb)}</section>${renderRuleXref(detail)}<section class='detail-section'><h3>Slots</h3>${slots.length ? slots.map(renderSlot).join('') : `<p class='empty'>None</p>`}</section>`;"
         "}"
         "function factLabelSummary(label) { const env = (label.environment || []).map(assumption => traceFactLabel(assumption.fact)).join(' | ') || 'base'; return `${label.kind || 'label'} ${label.rule || 'direct'} env ${env}`; }"
         "function renderFactLabels(fact) { const labels = fact.labels || []; return labels.length ? detailLine('labels', labels.map(factLabelSummary).join(' ; ')) : ''; }"
         "function renderFact(fact) { return `<div class='detail-block'><strong>${esc(fact.slot)}</strong>${refLine('unit', 'unit', fact.unit, fact.kb)}${pillList(fact.values || [])}${renderFactLabels(fact)}</div>`; }"
         "function renderNogood(nogood) {"
         "  const bindings = (nogood.bindings || []).map(binding => `${binding.variable}=${binding.value}`);"
         "  const conditions = (nogood.conditions || []).join(' | ');"
         "  return `<div class='detail-block'><strong>${refButton('unit', nogood.rule, DATA.units.kb)}</strong>${detailLine('proposition', nogood.proposition)}${bindings.length ? pillList(bindings) : ''}${conditions ? detailLine('conditions', conditions) : ''}${detailLine('action', nogood.action)}</div>`;"
         "}"
         "function traceFactParts(fact) { if (!Array.isArray(fact) || fact.length < 4) return null; const values = Array.isArray(fact[3]) ? fact[3] : [fact[3]]; return { kb: fact[0], unit: fact[1], slot: fact[2], values }; }"
         "function traceFactLabel(fact) { const parts = traceFactParts(fact); return parts ? `${parts.unit}.${parts.slot}=${traceValueText(parts.values)}` : traceValueText(fact); }"
         "function traceWorldParentByName(rows) { const parents = worldParentByName(); rows.filter(event => traceKind(event) === 'world-branch' && event.world && event.parent).forEach(event => parents.set(event.world, event.parent)); return parents; }"
         "function worldAssumptionNames(name, rows = DATA.details.traces || []) { const parents = traceWorldParentByName(rows); const names = []; const seen = new Set(); for (let cursor = name; cursor && parents.has(cursor) && !seen.has(cursor); cursor = parents.get(cursor)) { names.push(cursor); seen.add(cursor); } return names.reverse(); }"
         "function branchTraceForWorld(name, rows = DATA.details.traces || []) { return lastTrace(rows, event => traceKind(event) === 'world-branch' && event.world === name); }"
         "function branchWriteTrace(branch, rows = DATA.details.traces || []) { const fact = traceFactParts(branch?.fact); return lastTrace(rows, event => traceKind(event) === 'world-slot-write' && event.world === branch?.world && (!fact || (event.unit === fact.unit && event.slot === fact.slot && sameTraceValues(event.newValues, fact.values)))); }"
         "function assumptionRecordEvent(assumption, rows) { if (assumption.fireId) { const byFire = lastTrace(rows, event => event.fireId === assumption.fireId && event.world === assumption.world && ['world-slot-write', 'world-branch'].includes(traceKind(event))); if (byFire) return byFire; } return lastTrace(rows, event => traceKind(event) === 'world-branch' && event.world === assumption.world); }"
         "function worldAssumptionsFromRecords(detail, rows) { return (detail.environment || []).map(assumption => { const event = assumptionRecordEvent(assumption, rows); return event ? { world: assumption.world, parent: assumption.parent, label: assumption.fact ? traceFactLabel(assumption.fact) : causalEffectLabel(event), event } : null; }).filter(Boolean); }"
         "function worldAssumptions(detail) { const rows = DATA.details.traces || []; const records = worldAssumptionsFromRecords(detail, rows); if (records.length) return records; const parents = traceWorldParentByName(rows); return worldAssumptionNames(detail.name, rows).map(name => { const branch = branchTraceForWorld(name, rows); const write = branch && branchWriteTrace(branch, rows); const event = write || branch; return event ? { world: name, parent: branch?.parent || parents.get(name), label: branch?.fact ? traceFactLabel(branch.fact) : causalEffectLabel(event), event } : null; }).filter(Boolean); }"
         "function renderWorldAssumption(assumption, index) { const hop = `${index + 1}. ${assumption.parent || 'ROOT'} -> ${assumption.world}`; const label = `${hop} / ${assumption.label}`; return renderWhyTrail(label, assumption.event); }"
         "function renderWorldAssumptions(detail) { const assumptions = worldAssumptions(detail); if (!assumptions.length) return ''; return `<section class='detail-section'><h3>Assumptions</h3><div class='assumption-trails'>${assumptions.map(renderWorldAssumption).join('')}</div></section>`; }"
         "function renderWorldDetail(detail) {"
         "  const facts = detail.facts || [];"
         "  const nogoods = detail.nogoods || [];"
         "  return `<section class='detail-section'><h3>Facts</h3>${facts.length ? facts.map(renderFact).join('') : `<p class='empty'>None</p>`}</section><section class='detail-section'><h3>Nogoods</h3>${nogoods.length ? nogoods.map(renderNogood).join('') : `<p class='empty'>None</p>`}</section>${renderWorldAssumptions(detail)}${renderWorldWhyTrails(detail)}`;"
         "}"
         "function traceKind(event) { return String(event.kind || '').toLowerCase(); }"
         "function traceFamily(event) { const kind = traceKind(event); if (kind.startsWith('method-')) return 'methods'; if (kind.startsWith('rule-') || kind === 'agenda') return 'rules'; if (kind.startsWith('world-')) return 'worlds'; if (kind.startsWith('picture-') || kind.startsWith('panel-')) return 'pictures'; if (kind === 'nogood' || kind === 'contradiction') return 'problems'; return 'other'; }"
         "function traceBad(event) { return ['nogood', 'contradiction'].includes(traceKind(event)); }"
         "function traceValueText(value) { if (Array.isArray(value)) return value.map(traceValueText).join(' '); return String(value ?? 'NIL'); }"
         "function traceBindings(event) { const bindings = event.bindings || []; return bindings.length ? bindings.map(binding => `${binding.variable}=${traceValueText(binding.value)}`).join(', ') : ''; }"
         "function traceKinds() { return Array.from(new Set((DATA.details.traces || []).map(traceKind).filter(Boolean))).sort(); }"
         "function traceTargets(event) { const targets = []; const add = (kind, name, kb = null, label = null) => { if (!name) return; const id = `${kind}:${kb || ''}:${name}`; if (!targets.some(target => target.id === id)) targets.push({ id, kind, name, kb, label: label || name }); }; add('world', event.world, null, 'world ' + event.world); add('world', event.parent, null, 'parent ' + event.parent); add('unit', event.rule, DATA.units.kb, 'rule ' + event.rule); add('unit', event.ruleClass, DATA.units.kb, 'class ' + event.ruleClass); add('unit', event.unit, DATA.units.kb, 'unit ' + event.unit); add('unit', event.panel, DATA.units.kb, 'panel ' + event.panel); return targets; }"
         "function traceSearchText(event) { return `${traceFamily(event)} ${JSON.stringify(event)}`.toLowerCase(); }"
         "function traceMatchesQuery(event) { const query = state.traceQuery.trim().toLowerCase(); return !query || traceSearchText(event).includes(query); }"
         "function traceInSelectedScope(event, graph, detail) { if (state.traceScope !== 'selected' || !detail) return true; if (graph.kind === 'world') return [event.world, event.parent].includes(detail.name); return [event.rule, event.ruleClass, event.unit, event.panel].includes(detail.name); }"
         "function filteredTraces(graph, detail) { return (DATA.details.traces || []).filter(event => (state.traceFamily === 'all' || traceFamily(event) === state.traceFamily) && (state.traceKind === 'all' || traceKind(event) === state.traceKind) && traceInSelectedScope(event, graph, detail) && traceMatchesQuery(event)); }"
         "function renderTraceControls(rows, total) { const familyOptions = [['all', 'all families'], ['methods', 'methods'], ['rules', 'rules'], ['worlds', 'worlds'], ['pictures', 'pictures'], ['problems', 'problems']].map(([value, label]) => `<option value='${value}' ${state.traceFamily === value ? 'selected' : ''}>${label}</option>`).join(''); const kindOptions = ['all', ...traceKinds()].map(kind => `<option value='${esc(kind)}' ${state.traceKind === kind ? 'selected' : ''}>${esc(kind === 'all' ? 'all kinds' : kind)}</option>`).join(''); const scopeOptions = [['selected', 'selected node'], ['all', 'all events']].map(([value, label]) => `<option value='${value}' ${state.traceScope === value ? 'selected' : ''}>${label}</option>`).join(''); const search = `<div class='trace-search'><input type='search' data-trace-search value='${esc(state.traceQuery)}' placeholder='Search traces'><button type='button' data-trace-jump='prev'>Prev</button><button type='button' data-trace-jump='next'>Next</button></div>`; return `<div class='trace-controls'><label>Family<select data-trace-control='family'>${familyOptions}</select></label><label>Kind<select data-trace-control='kind'>${kindOptions}</select></label><label>Scope<select data-trace-control='scope'>${scopeOptions}</select></label><span class='count'>${rows.length}/${total}</span></div>${search}`; }"
         "function traceTitleHtml(event) { const kind = traceKind(event); if (kind === 'rule-fire') return `Rule fired: ${refButton('unit', event.rule, DATA.units.kb)}`; if (kind === 'rule-match') return `Rule matched: ${refButton('unit', event.rule, DATA.units.kb)}`; if (kind === 'agenda') return `Agenda: ${refButton('unit', event.ruleClass, DATA.units.kb)}`; if (kind === 'method-dispatch') return `Method dispatch: ${refButton('unit', event.unit, DATA.units.kb)}.${esc(event.slot || 'NIL')}`; if (kind === 'method-call') return `Method ${esc(String(event.methodKind || '').toLowerCase())}: ${refButton('unit', event.unit, DATA.units.kb)}.${esc(event.slot || 'NIL')}`; if (kind === 'method-return') return `Method returned: ${refButton('unit', event.unit, DATA.units.kb)}.${esc(event.slot || 'NIL')}`; if (kind === 'world-create') return `World created: ${refButton('world', event.world)}`; if (kind === 'world-branch') return `World branch: ${refButton('world', event.world)}`; if (kind === 'world-slot-write') return `World slot write: ${refButton('unit', event.unit, DATA.units.kb)}.${esc(event.slot || 'NIL')}`; if (kind === 'world-label-retract') return `Label retracted: ${refButton('unit', event.unit, DATA.units.kb)}.${esc(event.slot || 'NIL')}`; if (kind === 'picture-mouse') return `Picture mouse: ${esc(event.picture || 'NIL')}.${esc(event.item || 'NIL')}`; if (kind === 'panel-open') return `Panel opened: ${refButton('unit', event.panel, DATA.units.kb)}`; if (kind === 'panel-close') return `Panel closed: ${refButton('unit', event.panel, DATA.units.kb)}`; if (kind === 'nogood') return `Nogood: ${refButton('unit', event.rule, DATA.units.kb)}`; if (kind === 'contradiction') return `Contradiction: ${refButton('world', event.world)}`; return esc(event.kind || 'Trace'); }"
         "function traceMetaHtml(event) { const parts = []; if (event.world) parts.push(`world ${refButton('world', event.world)}`); if (event.parent) parts.push(`parent ${refButton('world', event.parent)}`); if (event.rule && !traceKind(event).includes('rule')) parts.push(`rule ${refButton('unit', event.rule, DATA.units.kb)}`); if (event.panel) parts.push(`panel <span class='code-text'>${esc(event.panel)}</span>`); if (event.picture) parts.push(`picture <span class='code-text'>${esc(event.picture)}</span>`); if (event.viewport) parts.push(`viewport <span class='code-text'>${esc(event.viewport)}</span>`); if (event.windowpane) parts.push(`windowpane <span class='code-text'>${esc(event.windowpane)}</span>`); if (event.activeImage) parts.push(`active image <span class='code-text'>${esc(event.activeImage)}</span>`); if (event.method) parts.push(`method <span class='code-text'>${esc(traceValueText(event.method))}</span>`); if (event.args && event.args.length) parts.push(`args <span class='code-text'>${esc(traceValueText(event.args))}</span>`); if (traceKind(event) === 'method-return' || (Object.prototype.hasOwnProperty.call(event, 'result') && event.result !== null)) parts.push(`result <span class='code-text'>${esc(traceValueText(event.result))}</span>`); if (event.action) parts.push(`action <span class='code-text'>${esc(traceValueText(event.action))}</span>`); if (Object.prototype.hasOwnProperty.call(event, 'value') && event.value !== null) parts.push(`value <span class='code-text'>${esc(traceValueText(event.value))}</span>`); if (event.proposition) parts.push(`proposition <span class='code-text'>${esc(traceValueText(event.proposition))}</span>`); const bindings = traceBindings(event); if (bindings) parts.push(`<span class='code-text'>${esc(bindings)}</span>`); if (event.message) parts.push(esc(event.message)); return parts.map(part => `<span class='trace-piece'>${part}</span>`).join(''); }"
         "function renderTraceEvent(event) { const meta = traceMetaHtml(event); const classes = ['trace-event']; if (traceBad(event)) classes.push('bad'); if (event.id === state.traceFocusId) classes.push('focused'); return `<div class='${classes.join(' ')}' data-trace-id='${esc(event.id)}'><strong>${traceTitleHtml(event)}</strong>${meta ? `<div class='trace-meta'>${meta}</div>` : ''}</div>`; }"
         "function traceGraphEventP(event) { return ['agenda', 'rule-fire', 'world-branch', 'world-label-retract', 'nogood', 'contradiction'].includes(traceKind(event)); }"
         "function renderTraceGraphEvent(event) { const kind = traceKind(event); const bad = traceBad(event); const left = event.parent ? traceRef('world', event.parent, null, event.parent, 'world') : event.world ? traceRef('world', event.world, null, event.world, `world ${bad ? 'bad' : ''}`) : `<span class='trace-node'>GLOBAL</span>`; const rightName = event.rule || event.ruleClass || event.unit || event.world; const rightKind = (event.rule || event.ruleClass || event.unit) ? 'unit' : 'world'; const rightClass = `${rightKind === 'unit' ? 'rule' : 'world'} ${bad ? 'bad' : ''}`; const arrow = bad ? '!' : kind === 'world-branch' ? '+' : '->'; return `<div class='trace-graph-row'>${left}<span class='trace-arrow'>${esc(arrow)}</span>${traceRef(rightKind, rightName, rightKind === 'unit' ? DATA.units.kb : null, rightName || kind, rightClass)}</div>`; }"
         "function renderTraceGraph(rows) { const graphRows = rows.filter(traceGraphEventP).slice(-18); return graphRows.length ? `<div class='trace-graph'>${graphRows.map(renderTraceGraphEvent).join('')}</div>` : ''; }"
         "function causalNode(event, label, className = '') { return `<button type='button' class='causal-node ${className}' data-trace-id='${esc(event.id)}'>${esc(label)}</button>`; }"
         "function causalEffectLabel(event) { const kind = traceKind(event); if (kind === 'world-slot-write') return `slot ${event.unit}.${event.slot}`; if (kind === 'world-label-retract') return `retract ${event.unit}.${event.slot}`; if (kind === 'world-branch') return `branch ${event.world || 'NIL'}`; if (kind === 'nogood') return `nogood ${event.world || 'NIL'}`; if (kind === 'contradiction') return `contradiction ${event.world || 'NIL'}`; return kind; }"
         "function agendaMatchForFire(group, fire) { return group.matches.find(match => sameRuleActivation(match, fire)); }"
         "function renderCausalityFlow(group, fire, rows) { const agenda = group.agenda; const match = agendaMatchForFire(group, fire); const effects = agendaEffectEvents(fire, rows).slice(0, 4); const nodes = []; if (agenda) nodes.push(causalNode(agenda, `agenda ${agenda.ruleClass || group.world || ''}`, 'agenda')); if (match) nodes.push(causalNode(match, `match ${match.rule || ''}`, 'match')); nodes.push(causalNode(fire, `fire ${fire.rule || ''}`, 'fire')); effects.forEach(effect => nodes.push(causalNode(effect, causalEffectLabel(effect), `effect ${traceBad(effect) ? 'bad' : ''}`))); return `<div class='causal-row'>${nodes.map((node, index) => index ? `<span class='causal-arrow'>-&gt;</span>${node}` : node).join('')}</div>`; }"
         "function renderCausalityGraph(rows) { const flows = []; agendaGroups(rows).forEach(group => group.fires.forEach(fire => flows.push(renderCausalityFlow(group, fire, rows)))); return flows.length ? `<div class='causality-graph'>${flows.slice(-8).reverse().join('')}</div>` : ''; }"
         "function normalizedTraceValues(values) { return (values || []).map(traceValueText); }"
         "function sameTraceValues(left, right) { return JSON.stringify(normalizedTraceValues(left)) === JSON.stringify(normalizedTraceValues(right)); }"
         "function lastTrace(rows, predicate) { for (let index = rows.length - 1; index >= 0; index -= 1) { if (predicate(rows[index])) return rows[index]; } return null; }"
         "function whyTraceLabel(event) { const kind = traceKind(event); if (kind === 'agenda') return `agenda ${event.ruleClass || event.world || ''}`; if (kind === 'rule-match') return `match ${event.rule || ''}`; if (kind === 'rule-fire') return `fire ${event.rule || ''}`; if (agendaEffectP(event)) return causalEffectLabel(event); if (kind === 'world-create') return `create ${event.world || ''}`; return kind; }"
         "function whyNodeClass(event, target) { const classes = []; const kind = traceKind(event); if (kind === 'rule-fire') classes.push('fire'); if (agendaEffectP(event) || kind === 'world-create') classes.push('effect'); if (traceBad(event)) classes.push('bad'); if (target && event.id === target.id) classes.push('focused'); return classes.join(' '); }"
         "function provenanceTrail(event, rows = DATA.details.traces || []) { const trail = []; const add = candidate => { if (candidate && !trail.some(existing => existing.id === candidate.id)) trail.push(candidate); }; if (event.agendaId) add(rows.find(candidate => traceKind(candidate) === 'agenda' && candidate.agendaId === event.agendaId)); if (event.activationId) add(rows.find(candidate => traceKind(candidate) === 'rule-match' && candidate.activationId === event.activationId)); if (event.fireId) add(rows.find(candidate => traceKind(candidate) === 'rule-fire' && candidate.fireId === event.fireId)); add(event); return trail; }"
         "function renderWhyTrail(label, event, rows = DATA.details.traces || []) { const nodes = provenanceTrail(event, rows).map(item => causalNode(item, whyTraceLabel(item), whyNodeClass(item, event))); return `<div class='why-trail'><strong>${esc(label)}</strong><div class='causal-row'>${nodes.map((node, index) => index ? `<span class='causal-arrow'>-&gt;</span>${node}` : node).join('')}</div></div>`; }"
         "function factWriteTrace(fact, worldName, rows) { return lastTrace(rows, event => traceKind(event) === 'world-slot-write' && event.world === worldName && event.unit === fact.unit && event.slot === fact.slot && sameTraceValues(event.newValues, fact.values)); }"
         "function nogoodTrace(nogood, worldName, rows) { return lastTrace(rows, event => traceKind(event) === 'nogood' && event.world === worldName && event.rule === nogood.rule && event.proposition === nogood.proposition); }"
         "function whyTrailTargets(detail) { const rows = DATA.details.traces || []; const targets = []; const add = (label, event) => { if (event && !targets.some(target => target.event.id === event.id)) targets.push({ label, event }); }; add(`world ${detail.name}`, lastTrace(rows, event => traceKind(event) === 'world-branch' && event.world === detail.name) || lastTrace(rows, event => traceKind(event) === 'world-create' && event.world === detail.name)); (detail.facts || []).forEach(fact => add(`fact ${fact.unit}.${fact.slot}`, factWriteTrace(fact, detail.name, rows))); (detail.nogoods || []).forEach(nogood => add(`problem ${nogood.proposition || nogood.rule}`, nogoodTrace(nogood, detail.name, rows))); add(`contradiction ${detail.name}`, lastTrace(rows, event => traceKind(event) === 'contradiction' && event.world === detail.name)); return targets; }"
         "function renderWorldWhyTrails(detail) { const targets = whyTrailTargets(detail); if (!targets.length) return ''; const shown = targets.slice(0, 12).map(target => renderWhyTrail(target.label, target.event)); const more = targets.length > shown.length ? `<p class='empty'>${targets.length - shown.length} more trails</p>` : ''; return `<section class='detail-section'><h3>Why</h3><div class='why-trails'>${shown.join('')}${more}</div></section>`; }"
         "function agendaTraceP(event) { return ['agenda', 'rule-match', 'rule-fire'].includes(traceKind(event)); }"
         "function makeAgendaGroup(agenda = null, world = null) { return { agenda, agendaId: agenda?.agendaId || null, world: world || agenda?.world || null, matches: [], fires: [] }; }"
         "function agendaGroupKey(event) { return event.agendaId ? `agenda:${event.agendaId}` : `world:${event.world || ''}`; }"
         "function agendaGroups(rows) { const groups = []; const byKey = new Map(); let current = null; rows.filter(agendaTraceP).forEach(event => { const kind = traceKind(event); if (event.agendaId) { const key = agendaGroupKey(event); current = byKey.get(key); if (!current) { current = makeAgendaGroup(kind === 'agenda' ? event : null, event.world); current.agendaId = event.agendaId; byKey.set(key, current); groups.push(current); } if (kind === 'agenda') { current.agenda = event; current.world = event.world; } } else if (kind === 'agenda' || !current || current.world !== event.world) { current = makeAgendaGroup(kind === 'agenda' ? event : null, event.world); groups.push(current); } if (kind === 'rule-match') current.matches.push(event); if (kind === 'rule-fire') current.fires.push(event); }); return groups.filter(group => group.agenda || group.matches.length || group.fires.length); }"
         "function sameTraceBindings(left, right) { return JSON.stringify(left || []) === JSON.stringify(right || []); }"
         "function sameRuleActivation(left, right) { if (left.activationId && right.activationId) return left.activationId === right.activationId; return left.rule === right.rule && left.world === right.world && sameTraceBindings(left.bindings, right.bindings); }"
         "function agendaCandidates(group) { const candidates = group.matches.slice(); group.fires.forEach(fire => { if (!candidates.some(candidate => sameRuleActivation(candidate, fire))) candidates.push(fire); }); return candidates; }"
         "function agendaCandidateState(candidate, group) { return group.fires.some(fire => sameRuleActivation(candidate, fire)) ? 'fired' : 'matched'; }"
         "function agendaSummary(group, candidates) { const fired = candidates.filter(candidate => agendaCandidateState(candidate, group) === 'fired').length; return `${candidates.length} candidates / ${fired} fired`; }"
         "function agendaCandidateFire(candidate, group) { return group.fires.find(fire => sameRuleActivation(candidate, fire)); }"
         "function agendaCandidateConditions(candidate, group) { const fire = agendaCandidateFire(candidate, group); return (candidate.conditions && candidate.conditions.length) ? candidate.conditions : (fire?.conditions || []); }"
         "function agendaCandidateAction(candidate, group) { const fire = agendaCandidateFire(candidate, group); return fire?.action || (traceKind(candidate) === 'rule-fire' ? candidate.action : null); }"
         "function agendaDrillLine(label, value) { return `<div class='agenda-line'><span class='detail-label'>${esc(label)}</span><span class='code-text'>${esc(value)}</span></div>`; }"
         "function agendaEffectP(event) { return ['world-slot-write', 'world-label-retract', 'world-branch', 'nogood', 'contradiction'].includes(traceKind(event)); }"
         "function agendaEffectEvents(fire, rows) { if (fire.fireId) return rows.filter(event => event.fireId === fire.fireId && event.id !== fire.id && agendaEffectP(event)); const start = rows.findIndex(event => event.id === fire.id); if (start < 0) return []; const effects = []; for (let index = start + 1; index < rows.length; index += 1) { const event = rows[index]; const kind = traceKind(event); if (agendaTraceP(event)) break; if (agendaEffectP(event)) effects.push(event); } return effects; }"
         "function agendaEffectText(event) { const kind = traceKind(event); if (kind === 'world-slot-write') return `${event.unit}.${event.slot}: ${traceValueText(event.oldValues)} -> ${traceValueText(event.newValues)}`; if (kind === 'world-label-retract') return `${event.unit}.${event.slot}: ${traceValueText(event.fact)}`; if (kind === 'world-branch') return `${event.parent || 'NIL'} -> ${event.world || 'NIL'} ${traceValueText(event.fact)}`; if (kind === 'nogood') return `${event.world || 'NIL'} ${traceValueText(event.proposition)}`; if (kind === 'contradiction') return `${event.world || 'NIL'} ${traceValueText(event.proposition)}`; return JSON.stringify(event); }"
         "function renderAgendaEffect(event) { const classes = ['agenda-effect']; if (traceBad(event)) classes.push('bad'); return `<div class='${classes.join(' ')}'><span class='agenda-status'>${esc(traceKind(event))}</span><span class='code-text'>${esc(agendaEffectText(event))}</span></div>`; }"
         "function renderAgendaEffects(fire, rows) { const effects = agendaEffectEvents(fire, rows); if (!effects.length) return ''; const shown = effects.slice(0, 6).map(renderAgendaEffect); if (effects.length > shown.length) shown.push(agendaDrillLine('more', `${effects.length - shown.length} effects`)); return shown.join(''); }"
         "function renderAgendaDrilldown(candidate, group, rows) { const fire = agendaCandidateFire(candidate, group); const conditions = agendaCandidateConditions(candidate, group); const action = agendaCandidateAction(candidate, group); const lines = []; if (conditions.length) lines.push(agendaDrillLine('conditions', conditions.map(traceValueText).join(' | '))); if (action) lines.push(agendaDrillLine('action', traceValueText(action))); if (fire) lines.push(renderAgendaEffects(fire, rows)); const body = lines.filter(Boolean).join(''); return body ? `<div class='agenda-drilldown'>${body}</div>` : ''; }"
         "function renderAgendaCandidate(candidate, group, rows) { const stateName = agendaCandidateState(candidate, group); const bindings = traceBindings(candidate); const classes = ['agenda-candidate', stateName]; if (candidate.id === state.traceFocusId) classes.push('focused'); return `<div class='${classes.join(' ')}' data-trace-id='${esc(candidate.id)}'><span class='agenda-status'>${stateName === 'fired' ? 'fired' : 'match'}</span>${refButton('unit', candidate.rule, DATA.units.kb)}${bindings ? ` <span class='code-text'>${esc(bindings)}</span>` : ''}${renderAgendaDrilldown(candidate, group, rows)}</div>`; }"
         "function renderAgendaGroup(group, rows) { const candidates = agendaCandidates(group).slice(-10); const title = group.agenda ? `Agenda ${refButton('unit', group.agenda.ruleClass, DATA.units.kb)}` : 'Conflict Set'; const world = group.world ? `world ${group.world}` : 'global'; const body = candidates.length ? `<div class='agenda-list'>${candidates.map(candidate => renderAgendaCandidate(candidate, group, rows)).join('')}</div>` : `<p class='empty'>No candidates</p>`; return `<div class='agenda-pass'><div class='agenda-head'><strong>${title}</strong><span class='count'>${esc(world)} / ${esc(agendaSummary(group, candidates))}</span></div>${body}</div>`; }"
         "function agendaJumpRows(rows, mode = 'all') { const groups = agendaGroups(rows); if (mode === 'fired') return groups.flatMap(group => group.fires); return groups.flatMap(group => agendaCandidates(group)); }"
         "function renderAgendaControls(rows) { const candidates = agendaJumpRows(rows); const fired = agendaJumpRows(rows, 'fired'); if (!candidates.length) return ''; return `<div class='agenda-controls'><button type='button' data-agenda-jump='prev' data-agenda-mode='all'>Prev Candidate</button><button type='button' data-agenda-jump='next' data-agenda-mode='all'>Next Candidate</button><button type='button' data-agenda-jump='prev' data-agenda-mode='fired'>Prev Fired</button><button type='button' data-agenda-jump='next' data-agenda-mode='fired'>Next Fired</button><span class='count'>${candidates.length}/${fired.length}</span></div>`; }"
         "function renderAgendaPane(rows) { const groups = agendaGroups(rows).slice(-5).reverse(); return groups.length ? `${renderAgendaControls(rows)}<div class='agenda-board'>${groups.map(group => renderAgendaGroup(group, rows)).join('')}</div>` : ''; }"
         "function jumpAgenda(direction, mode = 'all') { const graph = activeGraph(); const detail = detailMap(graph)[state.selected]; const rows = agendaJumpRows(filteredTraces(graph, detail), mode); if (!rows.length) { render(); return; } const current = rows.findIndex(event => event.id === state.traceFocusId); const next = current < 0 ? (direction > 0 ? 0 : rows.length - 1) : (current + direction + rows.length) % rows.length; state.traceFocusId = rows[next].id; render(); }"
         "function traceMapEventP(event) { return ['agenda', 'rule-match', 'rule-fire', 'world-create', 'world-branch', 'world-label-retract', 'picture-mouse', 'panel-open', 'panel-close', 'nogood', 'contradiction'].includes(traceKind(event)); }"
         "function traceMapLane(event) { const kind = traceKind(event); if (kind.startsWith('world-')) return { name: 'worlds', y: 42 }; if (kind.startsWith('picture-') || kind.startsWith('panel-')) return { name: 'pictures', y: 132 }; if (kind === 'nogood' || kind === 'contradiction') return { name: 'problems', y: 176 }; return { name: 'rules', y: 86 }; }"
         "function traceMapLabel(event) { const kind = traceKind(event); if (kind === 'agenda') return event.ruleClass || kind; if (kind.startsWith('rule-') || kind === 'nogood') return event.rule || kind; if (kind.startsWith('world-') || kind === 'contradiction') return event.world || kind; if (kind.startsWith('panel-')) return event.panel || kind; if (kind.startsWith('picture-')) return event.item || event.picture || kind; return event.unit || kind; }"
         "function traceTouchesWorldPath(event, pathNames) { return !!pathNames.size && [event.world, event.parent].some(name => pathNames.has(name)); }"
         "function renderTraceMapEvent(event, index, pathNames = new Set()) { const x = 46 + index * 74; const lane = traceMapLane(event); const family = traceBad(event) ? 'problems' : traceFamily(event); const label = traceMapLabel(event); const title = `${traceKind(event)} ${label}`; const classes = ['trace-map-event', family]; if (traceTouchesWorldPath(event, pathNames)) classes.push('branch'); if (event.id === state.traceFocusId) classes.push('focused'); return `<g class='${classes.map(esc).join(' ')}' data-trace-id='${esc(event.id)}'><title>${esc(title)}</title><rect x='${x - 31}' y='${lane.y - 15}' width='62' height='30' rx='5'></rect><text x='${x}' y='${lane.y - 3}' text-anchor='middle'>${esc(short(traceKind(event), 12))}</text><text x='${x}' y='${lane.y + 10}' text-anchor='middle'>${esc(short(label, 12))}</text></g>`; }"
         "function traceMapRows(rows) { return rows.filter(traceMapEventP); }"
         "function stopTraceReplay() { if (!traceReplayTimer) return; clearInterval(traceReplayTimer); traceReplayTimer = null; }"
         "function traceReplayDelay() { return { slow: 1500, normal: 900, fast: 350 }[state.traceReplaySpeed] || 900; }"
         "function startTraceReplayTimer() { traceReplayTimer = setInterval(() => stepTraceMap(1, state.traceReplayLoop), traceReplayDelay()); }"
         "function restartTraceReplay() { if (!traceReplayTimer) return; stopTraceReplay(); startTraceReplayTimer(); }"
         "function stepTraceMap(direction, wrap = true) { const graph = activeGraph(); const detail = detailMap(graph)[state.selected]; const events = traceMapRows(filteredTraces(graph, detail)); if (!events.length) { state.traceFocusId = null; stopTraceReplay(); render(); return false; } const current = events.findIndex(event => event.id === state.traceFocusId); let next = current < 0 ? (direction > 0 ? 0 : events.length - 1) : current + direction; if (next < 0 || next >= events.length) { if (!wrap) { stopTraceReplay(); render(); return false; } next = (next + events.length) % events.length; } state.traceFocusId = events[next].id; render(); return true; }"
         "function focusTraceMapStart(events) { if (!events.length) { state.traceFocusId = null; return false; } if (!events.some(event => event.id === state.traceFocusId)) state.traceFocusId = events[0].id; return true; }"
         "function toggleTraceReplay() { if (traceReplayTimer) { stopTraceReplay(); render(); return; } const graph = activeGraph(); const detail = detailMap(graph)[state.selected]; const events = traceMapRows(filteredTraces(graph, detail)); if (!focusTraceMapStart(events)) { render(); return; } startTraceReplayTimer(); render(); }"
         "function traceMapPosition(events) { const index = events.findIndex(event => event.id === state.traceFocusId); return index < 0 ? `0/${events.length}` : `${index + 1}/${events.length}`; }"
         "function renderTraceMapControls(events) { const speedOptions = [['slow', 'slow'], ['normal', 'normal'], ['fast', 'fast']].map(([value, label]) => `<option value='${value}' ${state.traceReplaySpeed === value ? 'selected' : ''}>${label}</option>`).join(''); return `<div class='trace-map-controls'><button type='button' data-trace-map-step='prev'>Prev</button><button type='button' data-trace-map-play>${traceReplayTimer ? 'Pause' : 'Play'}</button><button type='button' data-trace-map-step='next'>Next</button><label>Speed<select data-trace-map-speed>${speedOptions}</select></label><label class='check'><input type='checkbox' data-trace-map-loop ${state.traceReplayLoop ? 'checked' : ''}>Loop</label><span class='count'>${traceMapPosition(events)} map events</span></div>`; }"
         "function renderTraceMap(rows) { const allEvents = traceMapRows(rows); const events = allEvents.slice(-32); if (!events.length) return ''; const width = Math.max(520, 92 + (events.length - 1) * 74); const lanes = [['worlds', 42], ['rules', 86], ['pictures', 132], ['problems', 176]]; const pathNames = new Set(focusedTraceWorldPathNames()); const laneLines = lanes.map(([label, y]) => `<line class='trace-map-lane' x1='42' y1='${y}' x2='${width - 18}' y2='${y}'></line><text class='trace-map-lane-label' x='6' y='${y + 3}'>${label}</text>`).join(''); const links = events.slice(1).map((event, index) => { const previous = events[index]; const x1 = 46 + index * 74; const y1 = traceMapLane(previous).y; const x2 = 46 + (index + 1) * 74; const y2 = traceMapLane(event).y; const focused = [previous.id, event.id].includes(state.traceFocusId); const branch = traceTouchesWorldPath(previous, pathNames) && traceTouchesWorldPath(event, pathNames); return `<path class='trace-map-link ${branch ? 'branch' : ''} ${focused ? 'focused' : ''}' d='M ${x1 + 32} ${y1} C ${x1 + 48} ${y1}, ${x2 - 48} ${y2}, ${x2 - 32} ${y2}'></path>`; }).join(''); return `${renderTraceMapControls(allEvents)}<div class='trace-map'><svg viewBox='0 0 ${width} 216' role='img' aria-label='Trace map'>${laneLines}${links}${events.map((event, index) => renderTraceMapEvent(event, index, pathNames)).join('')}</svg></div>`; }"
         "function ensureTraceFocus(rows) { if (state.traceFocusId && rows.some(event => event.id === state.traceFocusId)) return; state.traceFocusId = state.traceQuery.trim() && rows.length ? rows[rows.length - 1].id : null; }"
         "function traceVisibleRows(rows) { let visible = rows.slice(-40).reverse(); const focused = rows.find(event => event.id === state.traceFocusId); if (focused && !visible.some(event => event.id === focused.id)) visible = [focused, ...visible.slice(0, 39)]; return visible; }"
         "function traceDetailValueP(value) { return value !== null && value !== undefined && !(Array.isArray(value) && !value.length); }"
         "function traceTargetButtons(event) { const targets = traceTargets(event); return targets.length ? `<div class='pill-row'>${targets.map(target => refButton(target.kind, target.name, target.kb, target.label)).join('')}</div>` : ''; }"
         "function renderFocusedTraceWhy(event, rows) { const trail = provenanceTrail(event, DATA.details.traces || rows); return trail.length > 1 ? renderWhyTrail('Why Trail', event, DATA.details.traces || rows) : ''; }"
         "function traceDetailHtml(rows) { const event = rows.find(candidate => candidate.id === state.traceFocusId); if (!event) return ''; const fields = Object.entries(event).filter(([, value]) => traceDetailValueP(value)); const body = fields.map(([key, value]) => `<dt>${esc(key)}</dt><dd><span class='code-text'>${esc(traceValueText(value))}</span></dd>`).join(''); return `<div class='trace-detail'><strong>Focused Trace ${esc(event.id)}</strong>${traceTargetButtons(event)}${renderFocusedTraceWhy(event, rows)}<dl class='trace-detail-grid'>${body}</dl></div>`; }"
         "function jumpTrace(direction) { const graph = activeGraph(); const detail = detailMap(graph)[state.selected]; const rows = filteredTraces(graph, detail); if (!rows.length) { state.traceFocusId = null; render(); return; } const current = rows.findIndex(event => event.id === state.traceFocusId); const next = current < 0 ? (direction > 0 ? 0 : rows.length - 1) : (current + direction + rows.length) % rows.length; state.traceFocusId = rows[next].id; render(); }"
         "function renderTracePane(graph, detail) { const all = DATA.details.traces || []; const filtered = filteredTraces(graph, detail); ensureTraceFocus(filtered); const rows = traceVisibleRows(filtered); return `<section class='detail-section'><h3>Trace</h3>${renderTraceControls(filtered, all.length)}${renderAgendaPane(filtered)}${renderCausalityGraph(filtered)}${renderTraceMap(filtered)}${renderTraceGraph(filtered)}${traceDetailHtml(filtered)}${rows.length ? `<div class='trace-list'>${rows.map(renderTraceEvent).join('')}</div>` : `<p class='empty'>No trace events</p>`}</section>`; }"
         "function renderInspector(model, graph) {"
         "  const node = model.placed.get(state.selected) || model.nodes[0];"
         "  if (!node) { inspector.innerHTML = `<h2>Inspector</h2><p class='empty'>No nodes</p>`; return; }"
         "  const incoming = graph.edges.filter(edge => edge.to === node.id);"
         "  const outgoing = graph.edges.filter(edge => edge.from === node.id);"
         "  const detail = detailMap(graph)[node.id];"
         "  const title = detail ? detail.name : nodeLabel(node);"
         "  const slotCount = detail?.slots?.length ?? (node.slots || []).length;"
         "  const parent = detail?.parent ? `<dt>Parent</dt><dd>${refButton('world', detail.parent)}</dd>` : '';"
         "  const summary = `<h2>${esc(title)}</h2><dl class='meta'><dt>ID</dt><dd>${esc(node.id)}</dd>${detail?.kb ? `<dt>KB</dt><dd>${esc(detail.kb)}</dd>` : ''}${parent}${graph.kind === 'world' ? `<dt>Facts</dt><dd>${node.factCount}</dd><dt>Nogoods</dt><dd>${node.nogoodCount}</dd><dt>Status</dt><dd>${node.inconsistentP ? 'inconsistent' : 'consistent'}</dd>` : `<dt>Slots</dt><dd>${slotCount}</dd>`}<dt>Incoming</dt><dd>${incoming.length}</dd><dt>Outgoing</dt><dd>${outgoing.length}</dd></dl>`;"
         "  inspector.innerHTML = summary + (detail ? (graph.kind === 'unit' ? renderUnitDetail(detail) : renderWorldDetail(detail)) : '') + renderTracePane(graph, detail);"
         "}"
         "browserPane.addEventListener('input', event => { const control = event.target.closest('[data-active-image-name]'); if (!control || control.type !== 'range') return; setActiveImageLocal(control.dataset.activeImageName, control.value); });"
         "browserPane.addEventListener('change', event => { const control = event.target.closest('[data-active-image-name]'); if (!control || control.type === 'range') return; setActiveImageLocal(control.dataset.activeImageName, control.value); });"
         "browserPane.addEventListener('click', event => { const sessionControl = event.target.closest('[data-session-window]'); if (sessionControl) { state.sessionWindow = sessionControl.dataset.sessionWindow; render(); return; } const panelAction = event.target.closest('[data-panel-action]'); if (panelAction) { setPanelLocal(state.panelName || selectedPanel()?.name, panelAction.dataset.panelAction === 'open'); return; } const panelControl = event.target.closest('[data-panel-name]'); if (panelControl) { state.panelName = panelControl.dataset.panelName; render(); return; } const pictureControl = event.target.closest('[data-picture-name]'); if (pictureControl) { state.pictureName = pictureControl.dataset.pictureName; render(); return; } const tourControl = event.target.closest('[data-review-tour], [data-desktop-tour]'); if (tourControl) { selectReviewTour(tourControl.dataset.reviewTour || tourControl.dataset.desktopTour); return; } const activeControl = event.target.closest('button[data-active-image-name]'); if (activeControl) { const image = activeImageByName(activeControl.dataset.activeImageName); if (image && image.writableP) setActiveImageLocal(image.name, activeControl.classList.contains('active-image-switch') ? (activeImageOnP(image.value) ? 'OFF' : 'ON') : (image.value ?? 'TRUE')); return; } const ref = event.target.closest('[data-ref-kind]'); if (!ref) return; selectReference(ref.dataset.refKind, ref.dataset.refName, ref.dataset.refKb || null); });"
         "inspector.addEventListener('input', event => { const traceSearch = event.target.closest('[data-trace-search]'); if (!traceSearch) return; stopTraceReplay(); const cursor = traceSearch.selectionStart; state.traceQuery = traceSearch.value; state.traceFocusId = null; render(); const replacement = inspector.querySelector('[data-trace-search]'); if (replacement) { replacement.focus(); replacement.setSelectionRange(cursor, cursor); } });"
         "inspector.addEventListener('change', event => { const traceMapSpeed = event.target.closest('[data-trace-map-speed]'); if (traceMapSpeed) { state.traceReplaySpeed = traceMapSpeed.value; restartTraceReplay(); render(); return; } const traceMapLoop = event.target.closest('[data-trace-map-loop]'); if (traceMapLoop) { state.traceReplayLoop = traceMapLoop.checked; restartTraceReplay(); render(); return; } const traceControl = event.target.closest('[data-trace-control]'); if (traceControl) { stopTraceReplay(); if (traceControl.dataset.traceControl === 'family') state.traceFamily = traceControl.value; if (traceControl.dataset.traceControl === 'kind') state.traceKind = traceControl.value; if (traceControl.dataset.traceControl === 'scope') state.traceScope = traceControl.value; render(); return; } const xrefControl = event.target.closest('[data-xref-control]'); if (!xrefControl) return; if (xrefControl.dataset.xrefControl === 'operation') state.xrefOperation = xrefControl.value; if (xrefControl.dataset.xrefControl === 'slot') state.xrefSlot = xrefControl.value; if (xrefControl.dataset.xrefControl === 'target') state.xrefTarget = xrefControl.value; render(); });"
         "inspector.addEventListener('click', event => { const traceMapStep = event.target.closest('[data-trace-map-step]'); if (traceMapStep) { stopTraceReplay(); stepTraceMap(traceMapStep.dataset.traceMapStep === 'next' ? 1 : -1); return; } const traceMapPlay = event.target.closest('[data-trace-map-play]'); if (traceMapPlay) { toggleTraceReplay(); return; } const agendaJump = event.target.closest('[data-agenda-jump]'); if (agendaJump) { stopTraceReplay(); jumpAgenda(agendaJump.dataset.agendaJump === 'next' ? 1 : -1, agendaJump.dataset.agendaMode || 'all'); return; } const traceJump = event.target.closest('[data-trace-jump]'); if (traceJump) { stopTraceReplay(); jumpTrace(traceJump.dataset.traceJump === 'next' ? 1 : -1); return; } const ref = event.target.closest('[data-ref-kind]'); if (ref) { stopTraceReplay(); selectReference(ref.dataset.refKind, ref.dataset.refName, ref.dataset.refKb || null); return; } const traceEvent = event.target.closest('[data-trace-id]'); if (!traceEvent) return; stopTraceReplay(); state.traceFocusId = Number(traceEvent.dataset.traceId); render(); });"
         "document.querySelectorAll('[data-tab]').forEach(button => button.addEventListener('click', () => { setView(button.dataset.tab); state.selected = null; state.viewBox = null; render(); }));"
         "search.addEventListener('input', () => { state.query = search.value; render(); });"
         "document.querySelector('[data-action=\"fit\"]').addEventListener('click', () => { state.zoom = 1; state.viewBox = null; render(); });"
         "document.querySelector('[data-action=\"zoom-in\"]').addEventListener('click', () => { state.zoom = Math.min(3, state.zoom * 1.2); state.viewBox = null; render(); });"
         "document.querySelector('[data-action=\"zoom-out\"]').addEventListener('click', () => { state.zoom = Math.max(0.4, state.zoom / 1.2); state.viewBox = null; render(); });"
         "setView(state.view);"
         "render();"
         "</script>"
         "</body>"
         "</html>")))

(defun write.graph.viewer.html
    (stream &key unit-graph world-graph (title "KEE Graph Browser")
              initial-view initial-selection initial-trace-family
              initial-trace-kind initial-trace-scope initial-trace-query
              session)
  "Write a standalone HTML/SVG viewer for structured KEE graphs."
  (write-viewer-head stream title)
  (write-json-value
   stream
   (viewer-json-object
    unit-graph
    world-graph
    title
    (viewer-initial-json :view initial-view
                         :selected initial-selection
                         :trace-family initial-trace-family
                         :trace-kind initial-trace-kind
                         :trace-scope initial-trace-scope
                         :trace-query initial-trace-query)
    session))
  (write-viewer-script stream)
  (values))

(defun graph.viewer.html (&key unit-graph world-graph
                               (title "KEE Graph Browser")
                               initial-view initial-selection
                               initial-trace-family initial-trace-kind
                               initial-trace-scope initial-trace-query
                               session)
  "Return a standalone HTML/SVG viewer for structured KEE graphs."
  (with-output-to-string (stream)
    (write.graph.viewer.html stream
                             :unit-graph unit-graph
                             :world-graph world-graph
                             :title title
                             :initial-view initial-view
                             :initial-selection initial-selection
                             :initial-trace-family initial-trace-family
                             :initial-trace-kind initial-trace-kind
                             :initial-trace-scope initial-trace-scope
                             :initial-trace-query initial-trace-query
                             :session session)))

(defun write.kee.viewer.html
    (stream &key kb units worlds world-limit (title "KEE Graph Browser")
              initial-view initial-selection initial-trace-family
              initial-trace-kind initial-trace-scope initial-trace-query
              session)
  "Write a standalone HTML/SVG viewer for the current KEE image."
  (write.graph.viewer.html stream
                           :unit-graph (unit.graph :kb kb :units units)
                           :world-graph (world.graph :worlds worlds
                                                     :limit world-limit)
                           :title title
                           :initial-view initial-view
                           :initial-selection initial-selection
                           :initial-trace-family initial-trace-family
                           :initial-trace-kind initial-trace-kind
                           :initial-trace-scope initial-trace-scope
                           :initial-trace-query initial-trace-query
                           :session session))

(defun kee.viewer.html (&key kb units worlds world-limit
                             (title "KEE Graph Browser")
                             initial-view initial-selection
                             initial-trace-family initial-trace-kind
                             initial-trace-scope initial-trace-query
                             session)
  "Return a standalone HTML/SVG viewer for the current KEE image."
  (with-output-to-string (stream)
    (write.kee.viewer.html stream
                           :kb kb
                           :units units
                           :worlds worlds
                           :world-limit world-limit
                           :title title
                           :initial-view initial-view
                           :initial-selection initial-selection
                           :initial-trace-family initial-trace-family
                           :initial-trace-kind initial-trace-kind
                           :initial-trace-scope initial-trace-scope
                           :initial-trace-query initial-trace-query
                           :session session)))
