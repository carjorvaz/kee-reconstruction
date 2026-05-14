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

(defun viewer-details-json (unit-graph world-graph)
  (list (cons "units" (unit-detail-map-json unit-graph))
        (cons "worlds" (world-detail-map-json world-graph))
        (cons "activeImages" (active-image-detail-json unit-graph))))

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
         ".edge-label { fill: var(--muted); font-size: 11px; pointer-events: none; }"
         ".node { cursor: pointer; }"
         ".node rect { stroke: #8090a0; stroke-width: 1.3; }"
         ".node text { fill: var(--ink); font-size: 12px; pointer-events: none; }"
         ".node .title { font-weight: 700; font-size: 13px; }"
         ".node.selected rect { stroke: var(--accent); stroke-width: 2.5; }"
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
         ".meta { display: grid; grid-template-columns: 96px minmax(0, 1fr); gap: 6px 10px; font-size: 13px; }"
         ".meta dt { color: var(--muted); }"
         ".meta dd { margin: 0; min-width: 0; overflow-wrap: anywhere; }"
         ".pill-row { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 10px; }"
         ".pill { border: 1px solid var(--line); border-radius: 999px; padding: 3px 8px; font-size: 12px; background: #f9fafb; }"
         "button.pill { color: var(--accent); cursor: pointer; font-family: inherit; line-height: 1.2; }"
         "button.pill:hover { border-color: var(--accent); background: var(--accent-soft); }"
         ".detail-section { margin-top: 14px; padding-top: 12px; border-top: 1px solid var(--line); }"
         ".detail-section h3 { margin: 0 0 8px; font-size: 13px; color: var(--muted); }"
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
         "const state = { view: 'units', selected: null, query: '', zoom: 1, viewBox: null, focusSelected: false };"
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
         "  svg.setAttribute('width', model.width);"
         "  svg.setAttribute('height', model.height);"
         "  svg.innerHTML = `<defs><marker id='arrow' markerWidth='10' markerHeight='8' refX='9' refY='4' orient='auto'><path d='M0,0 L10,4 L0,8 Z' fill='#8e99a6'></path></marker></defs>`;"
         "  model.edges.forEach(edge => { const from = model.placed.get(edge.from); const to = model.placed.get(edge.to); const dim = !(matches(from, graph) || matches(to, graph)); const path = document.createElementNS('http://www.w3.org/2000/svg', 'path'); path.setAttribute('class', `edge ${edge.relation} ${dim ? 'dim' : ''}`); path.setAttribute('d', edgePath(from, to)); path.setAttribute('marker-end', 'url(#arrow)'); svg.appendChild(path); const text = document.createElementNS('http://www.w3.org/2000/svg', 'text'); text.setAttribute('class', `edge-label ${dim ? 'dim' : ''}`); text.setAttribute('x', (from.x + to.x + from.w) / 2); text.setAttribute('y', (from.y + to.y + from.h) / 2 - 8); text.textContent = edge.relation; svg.appendChild(text); });"
         "  model.nodes.forEach(node => { const dim = !matches(node, graph); const g = document.createElementNS('http://www.w3.org/2000/svg', 'g'); g.setAttribute('class', `node ${state.selected === node.id ? 'selected' : ''} ${dim ? 'dim' : ''}`); g.setAttribute('transform', `translate(${node.x}, ${node.y})`); g.dataset.id = node.id; const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect'); rect.setAttribute('width', node.w); rect.setAttribute('height', node.h); rect.setAttribute('rx', 7); rect.setAttribute('ry', 7); rect.setAttribute('fill', colorFor(node, graph)); g.appendChild(rect); const label = document.createElementNS('http://www.w3.org/2000/svg', 'text'); label.setAttribute('x', 12); label.setAttribute('y', 23); const title = document.createElementNS('http://www.w3.org/2000/svg', 'tspan'); title.setAttribute('class', 'title'); title.textContent = short(nodeLabel(node)); label.appendChild(title); const detail = document.createElementNS('http://www.w3.org/2000/svg', 'tspan'); detail.setAttribute('x', 12); detail.setAttribute('dy', 20); detail.textContent = nodeDetail(node, graph); label.appendChild(detail); g.appendChild(label); g.addEventListener('click', () => selectNode(node.id, model)); svg.appendChild(g); });"
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
         "function renderUnitDetail(detail) {"
         "  const parents = [...(detail.classParents || []), ...(detail.memberParents || [])];"
         "  const children = [...(detail.classChildren || []), ...(detail.memberChildren || [])];"
         "  const slots = detail.slots || [];"
         "  return `<section class='detail-section'><h3>Parents</h3>${pillList(parents, 'unit', detail.kb)}</section><section class='detail-section'><h3>Children</h3>${pillList(children, 'unit', detail.kb)}</section><section class='detail-section'><h3>Slots</h3>${slots.length ? slots.map(renderSlot).join('') : `<p class='empty'>None</p>`}</section>`;"
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
         "  inspector.innerHTML = summary + (detail ? (graph.kind === 'unit' ? renderUnitDetail(detail) : renderWorldDetail(detail)) : '');"
         "}"
         "browserPane.addEventListener('input', event => { const control = event.target.closest('[data-active-image-name]'); if (!control || control.type !== 'range') return; setActiveImageLocal(control.dataset.activeImageName, control.value); });"
         "browserPane.addEventListener('change', event => { const control = event.target.closest('[data-active-image-name]'); if (!control || control.type === 'range') return; setActiveImageLocal(control.dataset.activeImageName, control.value); });"
         "browserPane.addEventListener('click', event => { const activeControl = event.target.closest('button[data-active-image-name]'); if (activeControl) { const image = activeImageByName(activeControl.dataset.activeImageName); if (image && image.writableP) setActiveImageLocal(image.name, activeControl.classList.contains('active-image-switch') ? (activeImageOnP(image.value) ? 'OFF' : 'ON') : (image.value ?? 'TRUE')); return; } const ref = event.target.closest('[data-ref-kind]'); if (!ref) return; selectReference(ref.dataset.refKind, ref.dataset.refName, ref.dataset.refKb || null); });"
         "inspector.addEventListener('click', event => { const ref = event.target.closest('[data-ref-kind]'); if (!ref) return; selectReference(ref.dataset.refKind, ref.dataset.refName, ref.dataset.refKb || null); });"
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
