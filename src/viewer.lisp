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
        (cons "values" (detail-string-array (getf fact :values)))))

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

(defun nogood-detail-json (nogood)
  (list (cons "world" (detail-string (getf nogood :world)))
        (cons "rule" (detail-string (getf nogood :rule)))
        (cons "bindings" (json-array (mapcar #'binding-detail-json
                                              (getf nogood :bindings))))
        (cons "conditions" (detail-string-array (getf nogood :conditions)))
        (cons "action" (detail-string (getf nogood :action)))
        (cons "proposition" (detail-string (getf nogood :proposition)))))

(defun world-detail-json (report)
  (list (cons "id" (world-detail-id report))
        (cons "name" (detail-string (getf report :name)))
        (cons "parent" (if (getf report :parent)
                           (detail-string (getf report :parent))
                           :json-null))
        (cons "inconsistentP" (json-bool (getf report :inconsistent-p)))
        (cons "facts" (json-array (mapcar #'fact-detail-json
                                           (getf report :facts))))
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
        (cons "world" (trace-json-value (getf event :world)))
        (cons "parent" (trace-json-value (getf event :parent)))
        (cons "rule" (trace-json-value (getf event :rule)))
        (cons "ruleClass" (trace-json-value (getf event :rule-class)))
        (cons "unit" (trace-json-value (getf event :unit)))
        (cons "slot" (trace-json-value (getf event :slot)))
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

(defun trace-detail-json (&key (limit 200))
  (json-array
   (when (fboundp 'trace.events)
     (mapcar #'trace-event-json (trace.events :limit limit)))))

(defun viewer-details-json (unit-graph world-graph)
  (list (cons "units" (unit-detail-map-json unit-graph))
        (cons "worlds" (world-detail-map-json world-graph))
        (cons "activeImages" (active-image-detail-json unit-graph))
        (cons "ruleReferences" (rule-reference-detail-json unit-graph))
        (cons "traces" (trace-detail-json))))

(defun viewer-kbs-json (unit-graph)
  (detail-string-array
   (or (ignore-errors (list.kbs))
       (remove nil (list (getf unit-graph :kb))))))

(defun viewer-json-object (unit-graph world-graph title)
  (list (cons "title" title)
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
         ".edge.trace-hit { stroke: var(--accent); stroke-width: 3; }"
         ".edge-label { fill: var(--muted); font-size: 11px; pointer-events: none; }"
         ".edge-label.trace-hit { fill: var(--accent); font-weight: 700; }"
         ".node { cursor: pointer; }"
         ".node rect { stroke: #8090a0; stroke-width: 1.3; }"
         ".node text { fill: var(--ink); font-size: 12px; pointer-events: none; }"
         ".node .title { font-weight: 700; font-size: 13px; }"
         ".node.selected rect { stroke: var(--accent); stroke-width: 2.5; }"
         ".node.trace-hit rect { stroke: var(--accent); stroke-width: 3; filter: drop-shadow(0 0 5px rgba(28,111,184,0.35)); }"
         ".dim { opacity: 0.22; }"
         "aside { min-width: 0; overflow: hidden; padding: 14px; background: var(--panel); border-left: 1px solid var(--line); display: grid; grid-template-rows: minmax(260px, 52vh) minmax(0, 1fr); gap: 12px; }"
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
         ".slot-table th:nth-child(1) { width: 34%; }"
         ".slot-table th:nth-child(2) { width: 22%; }"
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
         ".trace-map { margin-bottom: 10px; border: 1px solid var(--line); border-radius: 6px; overflow-x: auto; background: #ffffff; }"
         ".trace-map svg { width: 100%; min-width: 520px; min-height: 172px; background: #ffffff; }"
         ".trace-map-lane { stroke: #edf0f3; stroke-width: 1; }"
         ".trace-map-lane-label { fill: var(--muted); font-size: 10px; }"
         ".trace-map-link { stroke: #b9c3ce; stroke-width: 1.4; fill: none; }"
         ".trace-map-event { cursor: pointer; }"
         ".trace-map-event rect { fill: #ffffff; stroke: #8090a0; stroke-width: 1.2; }"
         ".trace-map-event text { fill: var(--ink); font-size: 9px; pointer-events: none; }"
         ".trace-map-event.rules rect { fill: var(--accent-soft); }"
         ".trace-map-event.worlds rect { fill: var(--good-soft); }"
         ".trace-map-event.problems rect { fill: var(--bad-soft); stroke: #f1b4ad; }"
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
         "const svg = document.getElementById('graph');"
         "const inspector = document.getElementById('inspector');"
         "const browserPane = document.querySelector('.browser-pane');"
         "const currentKb = document.getElementById('current-kb');"
         "const kbList = document.getElementById('kb-list');"
         "const hierarchyBrowser = document.getElementById('hierarchy-browser');"
         "const slotBrowser = document.getElementById('slot-browser');"
         "const nodeList = document.getElementById('node-list');"
         "const nodeCount = document.getElementById('node-count');"
         "const search = document.getElementById('search');"
         "const state = { view: 'units', selected: null, query: '', zoom: 1, viewBox: null, focusSelected: false, traceFamily: 'all', traceKind: 'all', traceScope: 'selected', traceQuery: '', traceFocusId: null, xrefOperation: 'all', xrefSlot: 'all', xrefTarget: 'all' };"
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
         "function focusedTraceReferenceIds(graph) { const event = focusedTraceEvent(); if (!event) return new Set(); const names = graph.kind === 'world' ? [event.world, event.parent] : [event.rule, event.ruleClass, event.unit]; return new Set(names.filter(Boolean).map(name => referenceId(graph.kind === 'world' ? 'world' : 'unit', name, DATA.units.kb))); }"
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
         "  svg.setAttribute('width', model.width);"
         "  svg.setAttribute('height', model.height);"
         "  svg.innerHTML = `<defs><marker id='arrow' markerWidth='10' markerHeight='8' refX='9' refY='4' orient='auto'><path d='M0,0 L10,4 L0,8 Z' fill='#8e99a6'></path></marker></defs>`;"
         "  model.edges.forEach(edge => { const from = model.placed.get(edge.from); const to = model.placed.get(edge.to); const traceHit = traceHits.has(edge.from) && traceHits.has(edge.to); const dim = !(matches(from, graph) || matches(to, graph)); const path = document.createElementNS('http://www.w3.org/2000/svg', 'path'); path.setAttribute('class', `edge ${edge.relation} ${traceHit ? 'trace-hit' : ''} ${dim && !traceHit ? 'dim' : ''}`); path.setAttribute('d', edgePath(from, to)); path.setAttribute('marker-end', 'url(#arrow)'); svg.appendChild(path); const text = document.createElementNS('http://www.w3.org/2000/svg', 'text'); text.setAttribute('class', `edge-label ${traceHit ? 'trace-hit' : ''} ${dim && !traceHit ? 'dim' : ''}`); text.setAttribute('x', (from.x + to.x + from.w) / 2); text.setAttribute('y', (from.y + to.y + from.h) / 2 - 8); text.textContent = edge.relation; svg.appendChild(text); });"
         "  model.nodes.forEach(node => { const traceHit = traceHits.has(node.id); const dim = !matches(node, graph); const g = document.createElementNS('http://www.w3.org/2000/svg', 'g'); g.setAttribute('class', `node ${state.selected === node.id ? 'selected' : ''} ${traceHit ? 'trace-hit' : ''} ${dim && !traceHit ? 'dim' : ''}`); g.setAttribute('transform', `translate(${node.x}, ${node.y})`); g.dataset.id = node.id; const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect'); rect.setAttribute('width', node.w); rect.setAttribute('height', node.h); rect.setAttribute('rx', 7); rect.setAttribute('ry', 7); rect.setAttribute('fill', colorFor(node, graph)); g.appendChild(rect); const label = document.createElementNS('http://www.w3.org/2000/svg', 'text'); label.setAttribute('x', 12); label.setAttribute('y', 23); const title = document.createElementNS('http://www.w3.org/2000/svg', 'tspan'); title.setAttribute('class', 'title'); title.textContent = short(nodeLabel(node)); label.appendChild(title); const detail = document.createElementNS('http://www.w3.org/2000/svg', 'tspan'); detail.setAttribute('x', 12); detail.setAttribute('dy', 20); detail.textContent = nodeDetail(node, graph); label.appendChild(detail); g.appendChild(label); g.addEventListener('click', () => selectNode(node.id, model)); svg.appendChild(g); });"
         "  renderBrowser(model, graph);"
         "  renderInspector(model, graph);"
         "  if (!state.viewBox) setViewBox(model.width, model.height); else svg.setAttribute('viewBox', `${state.viewBox.x} ${state.viewBox.y} ${state.viewBox.w} ${state.viewBox.h}`);"
         "}"
         "function detailMap(graph) { return graph.kind === 'unit' ? DATA.details.units : DATA.details.worlds; }"
         "function loadedKbs() { const kbs = Array.isArray(DATA.kbs) ? DATA.kbs.filter(Boolean) : []; return kbs.length ? kbs : [DATA.units.kb].filter(Boolean); }"
         "function renderKbStrip() { currentKb.textContent = DATA.units.kb || 'NIL'; kbList.innerHTML = loadedKbs().map(kb => `<span class='kb-chip ${kb === DATA.units.kb ? 'active' : ''}'>${esc(kb)}</span>`).join(''); }"
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
         "function renderSlotBrowser(detail) { if (!detail) { slotBrowser.innerHTML = `<section class='browser-section'><h3>Slot Table</h3><p class='empty'>No unit selected</p></section>`; return; } const slots = detail.slots || []; const slotTable = `<section class='browser-section'><h3>Slot Table</h3>${slots.length ? `<table class='slot-table'><thead><tr><th>Slot</th><th>Kind</th><th>Values</th></tr></thead><tbody>${slots.map(slot => `<tr><td><span class='code-text'>${esc(slot.name)}</span></td><td>${esc(slot.kind || 'NIL')}</td><td><span class='code-text'>${esc(slotText(slot.combinedValues))}</span></td></tr>`).join('')}</tbody></table>` : `<p class='empty'>None</p>`}</section>`; slotBrowser.innerHTML = slotTable + renderActiveImageSection(detail); }"
         "function coerceActiveImageInput(image, value) { if ([image.value, image.min, image.max].some(item => typeof item === 'number')) { const number = Number(value); if (Number.isFinite(number)) return number; } return value; }"
         "function updateActiveImageTarget(image, value) { (DATA.details.activeImages || []).forEach(other => { if (other.targetKb === image.targetKb && other.targetUnit === image.targetUnit && other.targetSlot === image.targetSlot && other.targetFacet === image.targetFacet) { other.value = value; other.values = [value]; } }); if (image.targetFacet) return; const detail = DATA.details.units[referenceId('unit', image.targetUnit, image.targetKb)]; const slot = detail && (detail.slots || []).find(candidate => candidate.name === image.targetSlot); if (slot) { slot.localValues = [value]; slot.combinedValues = [value]; } }"
         "function setActiveImageLocal(name, rawValue) { const image = activeImageByName(name); if (!image || !image.writableP) return; const value = coerceActiveImageInput(image, rawValue); updateActiveImageTarget(image, value); render(); }"
         "function renderHierarchyBrowser(model, graph) { const detail = selectedUnitDetail(graph); const topLevels = unitTopLevels(); const topNames = topLevels.map(unit => unit.name); const slotMeta = name => { const unit = unitDetails().find(candidate => candidate.name === name); const count = unit?.slots?.length ?? 0; return `${count} slots`; }; let html = hierarchySection('Top Level Units', topNames, DATA.units.kb, slotMeta); if (detail) { html += `<section class='browser-section'><h3>Current Unit</h3><div class='node-list compact'>${hierarchyButton(detail.name, detail.kb, `${(detail.slots || []).length} slots`)}</div></section>`; html += hierarchySection('Class Parents', detail.classParents, detail.kb); html += hierarchySection('Member Parents', detail.memberParents, detail.kb); html += hierarchySection('Subclass Children', detail.classChildren, detail.kb); html += hierarchySection('Member Children', detail.memberChildren, detail.kb); } else { html += `<section class='browser-section'><h3>Current Unit</h3><p class='empty'>No unit selected</p></section>`; } hierarchyBrowser.innerHTML = html; renderSlotBrowser(detail); renderNodeBrowser(model, graph); }"
         "function renderBrowser(model, graph) { renderKbStrip(); if (graph.kind === 'unit') { renderHierarchyBrowser(model, graph); return; } hierarchyBrowser.innerHTML = ''; slotBrowser.innerHTML = ''; renderNodeBrowser(model, graph); }"
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
         "function renderFact(fact) { return `<div class='detail-block'><strong>${esc(fact.slot)}</strong>${refLine('unit', 'unit', fact.unit, fact.kb)}${pillList(fact.values || [])}</div>`; }"
         "function renderNogood(nogood) {"
         "  const bindings = (nogood.bindings || []).map(binding => `${binding.variable}=${binding.value}`);"
         "  const conditions = (nogood.conditions || []).join(' | ');"
         "  return `<div class='detail-block'><strong>${refButton('unit', nogood.rule, DATA.units.kb)}</strong>${detailLine('proposition', nogood.proposition)}${bindings.length ? pillList(bindings) : ''}${conditions ? detailLine('conditions', conditions) : ''}${detailLine('action', nogood.action)}</div>`;"
         "}"
         "function renderWorldDetail(detail) {"
         "  const facts = detail.facts || [];"
         "  const nogoods = detail.nogoods || [];"
         "  return `<section class='detail-section'><h3>Facts</h3>${facts.length ? facts.map(renderFact).join('') : `<p class='empty'>None</p>`}</section><section class='detail-section'><h3>Nogoods</h3>${nogoods.length ? nogoods.map(renderNogood).join('') : `<p class='empty'>None</p>`}</section>`;"
         "}"
         "function traceKind(event) { return String(event.kind || '').toLowerCase(); }"
         "function traceFamily(event) { const kind = traceKind(event); if (kind.startsWith('method-')) return 'methods'; if (kind.startsWith('rule-') || kind === 'agenda') return 'rules'; if (kind.startsWith('world-')) return 'worlds'; if (kind === 'nogood' || kind === 'contradiction') return 'problems'; return 'other'; }"
         "function traceBad(event) { return ['nogood', 'contradiction'].includes(traceKind(event)); }"
         "function traceValueText(value) { if (Array.isArray(value)) return value.map(traceValueText).join(' '); return String(value ?? 'NIL'); }"
         "function traceBindings(event) { const bindings = event.bindings || []; return bindings.length ? bindings.map(binding => `${binding.variable}=${traceValueText(binding.value)}`).join(', ') : ''; }"
         "function traceKinds() { return Array.from(new Set((DATA.details.traces || []).map(traceKind).filter(Boolean))).sort(); }"
         "function traceTargets(event) { const targets = []; const add = (kind, name, kb = null, label = null) => { if (!name) return; const id = `${kind}:${kb || ''}:${name}`; if (!targets.some(target => target.id === id)) targets.push({ id, kind, name, kb, label: label || name }); }; add('world', event.world, null, 'world ' + event.world); add('world', event.parent, null, 'parent ' + event.parent); add('unit', event.rule, DATA.units.kb, 'rule ' + event.rule); add('unit', event.ruleClass, DATA.units.kb, 'class ' + event.ruleClass); add('unit', event.unit, DATA.units.kb, 'unit ' + event.unit); return targets; }"
         "function traceSearchText(event) { return `${traceFamily(event)} ${JSON.stringify(event)}`.toLowerCase(); }"
         "function traceMatchesQuery(event) { const query = state.traceQuery.trim().toLowerCase(); return !query || traceSearchText(event).includes(query); }"
         "function traceInSelectedScope(event, graph, detail) { if (state.traceScope !== 'selected' || !detail) return true; if (graph.kind === 'world') return [event.world, event.parent].includes(detail.name); return [event.rule, event.ruleClass, event.unit].includes(detail.name); }"
         "function filteredTraces(graph, detail) { return (DATA.details.traces || []).filter(event => (state.traceFamily === 'all' || traceFamily(event) === state.traceFamily) && (state.traceKind === 'all' || traceKind(event) === state.traceKind) && traceInSelectedScope(event, graph, detail) && traceMatchesQuery(event)); }"
         "function renderTraceControls(rows, total) { const familyOptions = [['all', 'all families'], ['methods', 'methods'], ['rules', 'rules'], ['worlds', 'worlds'], ['problems', 'problems']].map(([value, label]) => `<option value='${value}' ${state.traceFamily === value ? 'selected' : ''}>${label}</option>`).join(''); const kindOptions = ['all', ...traceKinds()].map(kind => `<option value='${esc(kind)}' ${state.traceKind === kind ? 'selected' : ''}>${esc(kind === 'all' ? 'all kinds' : kind)}</option>`).join(''); const scopeOptions = [['selected', 'selected node'], ['all', 'all events']].map(([value, label]) => `<option value='${value}' ${state.traceScope === value ? 'selected' : ''}>${label}</option>`).join(''); const search = `<div class='trace-search'><input type='search' data-trace-search value='${esc(state.traceQuery)}' placeholder='Search traces'><button type='button' data-trace-jump='prev'>Prev</button><button type='button' data-trace-jump='next'>Next</button></div>`; return `<div class='trace-controls'><label>Family<select data-trace-control='family'>${familyOptions}</select></label><label>Kind<select data-trace-control='kind'>${kindOptions}</select></label><label>Scope<select data-trace-control='scope'>${scopeOptions}</select></label><span class='count'>${rows.length}/${total}</span></div>${search}`; }"
         "function traceTitleHtml(event) { const kind = traceKind(event); if (kind === 'rule-fire') return `Rule fired: ${refButton('unit', event.rule, DATA.units.kb)}`; if (kind === 'rule-match') return `Rule matched: ${refButton('unit', event.rule, DATA.units.kb)}`; if (kind === 'agenda') return `Agenda: ${refButton('unit', event.ruleClass, DATA.units.kb)}`; if (kind === 'method-dispatch') return `Method dispatch: ${refButton('unit', event.unit, DATA.units.kb)}.${esc(event.slot || 'NIL')}`; if (kind === 'method-call') return `Method ${esc(String(event.methodKind || '').toLowerCase())}: ${refButton('unit', event.unit, DATA.units.kb)}.${esc(event.slot || 'NIL')}`; if (kind === 'method-return') return `Method returned: ${refButton('unit', event.unit, DATA.units.kb)}.${esc(event.slot || 'NIL')}`; if (kind === 'world-create') return `World created: ${refButton('world', event.world)}`; if (kind === 'world-branch') return `World branch: ${refButton('world', event.world)}`; if (kind === 'world-slot-write') return `World slot write: ${refButton('unit', event.unit, DATA.units.kb)}.${esc(event.slot || 'NIL')}`; if (kind === 'nogood') return `Nogood: ${refButton('unit', event.rule, DATA.units.kb)}`; if (kind === 'contradiction') return `Contradiction: ${refButton('world', event.world)}`; return esc(event.kind || 'Trace'); }"
         "function traceMetaHtml(event) { const parts = []; if (event.world) parts.push(`world ${refButton('world', event.world)}`); if (event.parent) parts.push(`parent ${refButton('world', event.parent)}`); if (event.rule && !traceKind(event).includes('rule')) parts.push(`rule ${refButton('unit', event.rule, DATA.units.kb)}`); if (event.method) parts.push(`method <span class='code-text'>${esc(traceValueText(event.method))}</span>`); if (event.args && event.args.length) parts.push(`args <span class='code-text'>${esc(traceValueText(event.args))}</span>`); if (traceKind(event) === 'method-return' || (Object.prototype.hasOwnProperty.call(event, 'result') && event.result !== null)) parts.push(`result <span class='code-text'>${esc(traceValueText(event.result))}</span>`); if (event.action) parts.push(`action <span class='code-text'>${esc(traceValueText(event.action))}</span>`); if (event.proposition) parts.push(`proposition <span class='code-text'>${esc(traceValueText(event.proposition))}</span>`); const bindings = traceBindings(event); if (bindings) parts.push(`<span class='code-text'>${esc(bindings)}</span>`); if (event.message) parts.push(esc(event.message)); return parts.map(part => `<span class='trace-piece'>${part}</span>`).join(''); }"
         "function renderTraceEvent(event) { const meta = traceMetaHtml(event); const classes = ['trace-event']; if (traceBad(event)) classes.push('bad'); if (event.id === state.traceFocusId) classes.push('focused'); return `<div class='${classes.join(' ')}' data-trace-id='${esc(event.id)}'><strong>${traceTitleHtml(event)}</strong>${meta ? `<div class='trace-meta'>${meta}</div>` : ''}</div>`; }"
         "function traceGraphEventP(event) { return ['agenda', 'rule-fire', 'world-branch', 'nogood', 'contradiction'].includes(traceKind(event)); }"
         "function renderTraceGraphEvent(event) { const kind = traceKind(event); const bad = traceBad(event); const left = event.parent ? traceRef('world', event.parent, null, event.parent, 'world') : event.world ? traceRef('world', event.world, null, event.world, `world ${bad ? 'bad' : ''}`) : `<span class='trace-node'>GLOBAL</span>`; const rightName = event.rule || event.ruleClass || event.unit || event.world; const rightKind = (event.rule || event.ruleClass || event.unit) ? 'unit' : 'world'; const rightClass = `${rightKind === 'unit' ? 'rule' : 'world'} ${bad ? 'bad' : ''}`; const arrow = bad ? '!' : kind === 'world-branch' ? '+' : '->'; return `<div class='trace-graph-row'>${left}<span class='trace-arrow'>${esc(arrow)}</span>${traceRef(rightKind, rightName, rightKind === 'unit' ? DATA.units.kb : null, rightName || kind, rightClass)}</div>`; }"
         "function renderTraceGraph(rows) { const graphRows = rows.filter(traceGraphEventP).slice(-18); return graphRows.length ? `<div class='trace-graph'>${graphRows.map(renderTraceGraphEvent).join('')}</div>` : ''; }"
         "function traceMapEventP(event) { return ['agenda', 'rule-match', 'rule-fire', 'world-create', 'world-branch', 'nogood', 'contradiction'].includes(traceKind(event)); }"
         "function traceMapLane(event) { const kind = traceKind(event); if (kind.startsWith('world-')) return { name: 'worlds', y: 42 }; if (kind === 'nogood' || kind === 'contradiction') return { name: 'problems', y: 132 }; return { name: 'rules', y: 86 }; }"
         "function traceMapLabel(event) { const kind = traceKind(event); if (kind === 'agenda') return event.ruleClass || kind; if (kind.startsWith('rule-') || kind === 'nogood') return event.rule || kind; if (kind.startsWith('world-') || kind === 'contradiction') return event.world || kind; return event.unit || kind; }"
         "function renderTraceMapEvent(event, index) { const x = 46 + index * 74; const lane = traceMapLane(event); const family = traceBad(event) ? 'problems' : traceFamily(event); const label = traceMapLabel(event); const title = `${traceKind(event)} ${label}`; return `<g class='trace-map-event ${esc(family)} ${event.id === state.traceFocusId ? 'focused' : ''}' data-trace-id='${esc(event.id)}'><title>${esc(title)}</title><rect x='${x - 31}' y='${lane.y - 15}' width='62' height='30' rx='5'></rect><text x='${x}' y='${lane.y - 3}' text-anchor='middle'>${esc(short(traceKind(event), 12))}</text><text x='${x}' y='${lane.y + 10}' text-anchor='middle'>${esc(short(label, 12))}</text></g>`; }"
         "function renderTraceMap(rows) { const events = rows.filter(traceMapEventP).slice(-32); if (!events.length) return ''; const width = Math.max(520, 92 + (events.length - 1) * 74); const lanes = [['worlds', 42], ['rules', 86], ['problems', 132]]; const laneLines = lanes.map(([label, y]) => `<line class='trace-map-lane' x1='42' y1='${y}' x2='${width - 18}' y2='${y}'></line><text class='trace-map-lane-label' x='6' y='${y + 3}'>${label}</text>`).join(''); const links = events.slice(1).map((event, index) => { const previous = events[index]; const x1 = 46 + index * 74; const y1 = traceMapLane(previous).y; const x2 = 46 + (index + 1) * 74; const y2 = traceMapLane(event).y; return `<path class='trace-map-link' d='M ${x1 + 32} ${y1} C ${x1 + 48} ${y1}, ${x2 - 48} ${y2}, ${x2 - 32} ${y2}'></path>`; }).join(''); return `<div class='trace-map'><svg viewBox='0 0 ${width} 172' role='img' aria-label='Trace map'>${laneLines}${links}${events.map(renderTraceMapEvent).join('')}</svg></div>`; }"
         "function ensureTraceFocus(rows) { if (state.traceFocusId && rows.some(event => event.id === state.traceFocusId)) return; state.traceFocusId = state.traceQuery.trim() && rows.length ? rows[rows.length - 1].id : null; }"
         "function traceVisibleRows(rows) { let visible = rows.slice(-40).reverse(); const focused = rows.find(event => event.id === state.traceFocusId); if (focused && !visible.some(event => event.id === focused.id)) visible = [focused, ...visible.slice(0, 39)]; return visible; }"
         "function traceDetailValueP(value) { return value !== null && value !== undefined && !(Array.isArray(value) && !value.length); }"
         "function traceTargetButtons(event) { const targets = traceTargets(event); return targets.length ? `<div class='pill-row'>${targets.map(target => refButton(target.kind, target.name, target.kb, target.label)).join('')}</div>` : ''; }"
         "function traceDetailHtml(rows) { const event = rows.find(candidate => candidate.id === state.traceFocusId); if (!event) return ''; const fields = Object.entries(event).filter(([, value]) => traceDetailValueP(value)); const body = fields.map(([key, value]) => `<dt>${esc(key)}</dt><dd><span class='code-text'>${esc(traceValueText(value))}</span></dd>`).join(''); return `<div class='trace-detail'><strong>Focused Trace ${esc(event.id)}</strong>${traceTargetButtons(event)}<dl class='trace-detail-grid'>${body}</dl></div>`; }"
         "function jumpTrace(direction) { const graph = activeGraph(); const detail = detailMap(graph)[state.selected]; const rows = filteredTraces(graph, detail); if (!rows.length) { state.traceFocusId = null; render(); return; } const current = rows.findIndex(event => event.id === state.traceFocusId); const next = current < 0 ? (direction > 0 ? 0 : rows.length - 1) : (current + direction + rows.length) % rows.length; state.traceFocusId = rows[next].id; render(); }"
         "function renderTracePane(graph, detail) { const all = DATA.details.traces || []; const filtered = filteredTraces(graph, detail); ensureTraceFocus(filtered); const rows = traceVisibleRows(filtered); return `<section class='detail-section'><h3>Trace</h3>${renderTraceControls(filtered, all.length)}${renderTraceMap(filtered)}${renderTraceGraph(filtered)}${traceDetailHtml(filtered)}${rows.length ? `<div class='trace-list'>${rows.map(renderTraceEvent).join('')}</div>` : `<p class='empty'>No trace events</p>`}</section>`; }"
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
         "browserPane.addEventListener('click', event => { const activeControl = event.target.closest('button[data-active-image-name]'); if (activeControl) { const image = activeImageByName(activeControl.dataset.activeImageName); if (image && image.writableP) setActiveImageLocal(image.name, activeControl.classList.contains('active-image-switch') ? (activeImageOnP(image.value) ? 'OFF' : 'ON') : (image.value ?? 'TRUE')); return; } const ref = event.target.closest('[data-ref-kind]'); if (!ref) return; selectReference(ref.dataset.refKind, ref.dataset.refName, ref.dataset.refKb || null); });"
         "inspector.addEventListener('input', event => { const traceSearch = event.target.closest('[data-trace-search]'); if (!traceSearch) return; const cursor = traceSearch.selectionStart; state.traceQuery = traceSearch.value; state.traceFocusId = null; render(); const replacement = inspector.querySelector('[data-trace-search]'); if (replacement) { replacement.focus(); replacement.setSelectionRange(cursor, cursor); } });"
         "inspector.addEventListener('change', event => { const traceControl = event.target.closest('[data-trace-control]'); if (traceControl) { if (traceControl.dataset.traceControl === 'family') state.traceFamily = traceControl.value; if (traceControl.dataset.traceControl === 'kind') state.traceKind = traceControl.value; if (traceControl.dataset.traceControl === 'scope') state.traceScope = traceControl.value; render(); return; } const xrefControl = event.target.closest('[data-xref-control]'); if (!xrefControl) return; if (xrefControl.dataset.xrefControl === 'operation') state.xrefOperation = xrefControl.value; if (xrefControl.dataset.xrefControl === 'slot') state.xrefSlot = xrefControl.value; if (xrefControl.dataset.xrefControl === 'target') state.xrefTarget = xrefControl.value; render(); });"
         "inspector.addEventListener('click', event => { const traceJump = event.target.closest('[data-trace-jump]'); if (traceJump) { jumpTrace(traceJump.dataset.traceJump === 'next' ? 1 : -1); return; } const ref = event.target.closest('[data-ref-kind]'); if (ref) { selectReference(ref.dataset.refKind, ref.dataset.refName, ref.dataset.refKb || null); return; } const traceEvent = event.target.closest('[data-trace-id]'); if (!traceEvent) return; state.traceFocusId = Number(traceEvent.dataset.traceId); render(); });"
         "document.querySelectorAll('[data-tab]').forEach(button => button.addEventListener('click', () => { setView(button.dataset.tab); state.selected = null; state.viewBox = null; render(); }));"
         "search.addEventListener('input', () => { state.query = search.value; render(); });"
         "document.querySelector('[data-action=\"fit\"]').addEventListener('click', () => { state.zoom = 1; state.viewBox = null; render(); });"
         "document.querySelector('[data-action=\"zoom-in\"]').addEventListener('click', () => { state.zoom = Math.min(3, state.zoom * 1.2); state.viewBox = null; render(); });"
         "document.querySelector('[data-action=\"zoom-out\"]').addEventListener('click', () => { state.zoom = Math.max(0.4, state.zoom / 1.2); state.viewBox = null; render(); });"
         "render();"
         "</script>"
         "</body>"
         "</html>")))

(defun write.graph.viewer.html
    (stream &key unit-graph world-graph (title "KEE Graph Browser"))
  "Write a standalone HTML/SVG viewer for structured KEE graphs."
  (write-viewer-head stream title)
  (write-json-value stream (viewer-json-object unit-graph world-graph title))
  (write-viewer-script stream)
  (values))

(defun graph.viewer.html (&key unit-graph world-graph
                               (title "KEE Graph Browser"))
  "Return a standalone HTML/SVG viewer for structured KEE graphs."
  (with-output-to-string (stream)
    (write.graph.viewer.html stream
                             :unit-graph unit-graph
                             :world-graph world-graph
                             :title title)))

(defun write.kee.viewer.html
    (stream &key kb units worlds world-limit (title "KEE Graph Browser"))
  "Write a standalone HTML/SVG viewer for the current KEE image."
  (write.graph.viewer.html stream
                           :unit-graph (unit.graph :kb kb :units units)
                           :world-graph (world.graph :worlds worlds
                                                     :limit world-limit)
                           :title title))

(defun kee.viewer.html (&key kb units worlds world-limit
                             (title "KEE Graph Browser"))
  "Return a standalone HTML/SVG viewer for the current KEE image."
  (with-output-to-string (stream)
    (write.kee.viewer.html stream
                           :kb kb
                           :units units
                           :worlds worlds
                           :world-limit world-limit
                           :title title)))
