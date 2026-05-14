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

(defun viewer-json-object (unit-graph world-graph title)
  (list (cons "title" title)
        (cons "units" (graph-json-object unit-graph))
        (cons "worlds" (graph-json-object world-graph))))

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
         "main { display: grid; grid-template-columns: minmax(0, 1fr) 330px; min-height: 0; }"
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
         "aside { min-width: 0; overflow: auto; padding: 14px; background: var(--panel); border-left: 1px solid var(--line); }"
         "aside h2 { margin: 0 0 10px; font-size: 16px; line-height: 1.2; }"
         ".meta { display: grid; grid-template-columns: 96px minmax(0, 1fr); gap: 6px 10px; font-size: 13px; }"
         ".meta dt { color: var(--muted); }"
         ".meta dd { margin: 0; min-width: 0; overflow-wrap: anywhere; }"
         ".pill-row { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 10px; }"
         ".pill { border: 1px solid var(--line); border-radius: 999px; padding: 3px 8px; font-size: 12px; background: #f9fafb; }"
         ".empty { color: var(--muted); font-size: 13px; }"
         "@media (max-width: 760px) { #app { grid-template-rows: auto minmax(0, 1fr); } header { flex-wrap: wrap; } .actions { margin-left: 0; width: 100%; } input[type='search'] { width: 100%; } main { grid-template-columns: 1fr; grid-template-rows: minmax(420px, 1fr) auto; } aside { border-left: 0; border-top: 1px solid var(--line); max-height: 40vh; } }"
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
         "<aside id='inspector'></aside>"
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
         "const search = document.getElementById('search');"
         "const state = { view: 'units', selected: null, query: '', zoom: 1, viewBox: null };"
         "function esc(value) { return String(value ?? '').replace(/[&<>\"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',\"'\":'&#39;'}[ch])); }"
         "function short(value, limit = 25) { const text = String(value ?? ''); return text.length > limit ? text.slice(0, limit - 3) + '...' : text; }"
         "function activeGraph() { return state.view === 'units' ? DATA.units : DATA.worlds; }"
         "function nodeLabel(node) { return node.name || node.id; }"
         "function nodeDetail(node, graph) { return graph.kind === 'unit' ? `${node.slots.length} slots` : `facts ${node.factCount} / nogoods ${node.nogoodCount}`; }"
         "function matches(node) { const q = state.query.trim().toLowerCase(); if (!q) return true; return [node.id, node.name, node.kb, node.parent, ...(node.slots || [])].filter(Boolean).some(v => String(v).toLowerCase().includes(q)); }"
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
         "function render() {"
         "  const graph = activeGraph();"
         "  const model = layout(graph);"
         "  svg.setAttribute('width', model.width);"
         "  svg.setAttribute('height', model.height);"
         "  svg.innerHTML = `<defs><marker id='arrow' markerWidth='10' markerHeight='8' refX='9' refY='4' orient='auto'><path d='M0,0 L10,4 L0,8 Z' fill='#8e99a6'></path></marker></defs>`;"
         "  model.edges.forEach(edge => { const from = model.placed.get(edge.from); const to = model.placed.get(edge.to); const dim = !(matches(from) || matches(to)); const path = document.createElementNS('http://www.w3.org/2000/svg', 'path'); path.setAttribute('class', `edge ${edge.relation} ${dim ? 'dim' : ''}`); path.setAttribute('d', edgePath(from, to)); path.setAttribute('marker-end', 'url(#arrow)'); svg.appendChild(path); const text = document.createElementNS('http://www.w3.org/2000/svg', 'text'); text.setAttribute('class', `edge-label ${dim ? 'dim' : ''}`); text.setAttribute('x', (from.x + to.x + from.w) / 2); text.setAttribute('y', (from.y + to.y + from.h) / 2 - 8); text.textContent = edge.relation; svg.appendChild(text); });"
         "  model.nodes.forEach(node => { const dim = !matches(node); const g = document.createElementNS('http://www.w3.org/2000/svg', 'g'); g.setAttribute('class', `node ${state.selected === node.id ? 'selected' : ''} ${dim ? 'dim' : ''}`); g.setAttribute('transform', `translate(${node.x}, ${node.y})`); g.dataset.id = node.id; const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect'); rect.setAttribute('width', node.w); rect.setAttribute('height', node.h); rect.setAttribute('rx', 7); rect.setAttribute('ry', 7); rect.setAttribute('fill', colorFor(node, graph)); g.appendChild(rect); const label = document.createElementNS('http://www.w3.org/2000/svg', 'text'); label.setAttribute('x', 12); label.setAttribute('y', 23); const title = document.createElementNS('http://www.w3.org/2000/svg', 'tspan'); title.setAttribute('class', 'title'); title.textContent = short(nodeLabel(node)); label.appendChild(title); const detail = document.createElementNS('http://www.w3.org/2000/svg', 'tspan'); detail.setAttribute('x', 12); detail.setAttribute('dy', 20); detail.textContent = nodeDetail(node, graph); label.appendChild(detail); g.appendChild(label); g.addEventListener('click', () => { state.selected = node.id; renderInspector(model, graph); render(); }); svg.appendChild(g); });"
         "  if (!state.selected || !model.placed.has(state.selected)) state.selected = model.nodes[0]?.id || null;"
         "  renderInspector(model, graph);"
         "  if (!state.viewBox) setViewBox(model.width, model.height); else svg.setAttribute('viewBox', `${state.viewBox.x} ${state.viewBox.y} ${state.viewBox.w} ${state.viewBox.h}`);"
         "}"
         "function renderInspector(model, graph) {"
         "  const node = model.placed.get(state.selected) || model.nodes[0];"
         "  if (!node) { inspector.innerHTML = `<h2>Inspector</h2><p class='empty'>No nodes</p>`; return; }"
         "  const incoming = graph.edges.filter(edge => edge.to === node.id);"
         "  const outgoing = graph.edges.filter(edge => edge.from === node.id);"
         "  const slots = node.slots || [];"
         "  inspector.innerHTML = `<h2>${esc(nodeLabel(node))}</h2><dl class='meta'><dt>ID</dt><dd>${esc(node.id)}</dd>${node.kb ? `<dt>KB</dt><dd>${esc(node.kb)}</dd>` : ''}${node.parent ? `<dt>Parent</dt><dd>${esc(node.parent)}</dd>` : ''}${graph.kind === 'world' ? `<dt>Facts</dt><dd>${node.factCount}</dd><dt>Nogoods</dt><dd>${node.nogoodCount}</dd><dt>Status</dt><dd>${node.inconsistentP ? 'inconsistent' : 'consistent'}</dd>` : `<dt>Slots</dt><dd>${slots.length}</dd>`}<dt>Incoming</dt><dd>${incoming.length}</dd><dt>Outgoing</dt><dd>${outgoing.length}</dd></dl>${slots.length ? `<div class='pill-row'>${slots.map(slot => `<span class='pill'>${esc(slot)}</span>`).join('')}</div>` : ''}`;"
         "}"
         "document.querySelectorAll('[data-tab]').forEach(button => button.addEventListener('click', () => { document.querySelectorAll('[data-tab]').forEach(item => item.classList.toggle('active', item === button)); state.view = button.dataset.tab; state.selected = null; state.viewBox = null; render(); }));"
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
