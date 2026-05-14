(in-package #:kee)

(defparameter *kee-panel-class-name* 'kee.panels)

(defun kee-panel-kb (kb-designator)
  (cond ((typep kb-designator 'knowledge-base) kb-designator)
        (kb-designator (kb kb-designator))
        (t (kb))))

(defun ensure-kee-panel-class (&optional kb-designator)
  (let* ((target-kb (kee-panel-kb kb-designator))
         (kb-name (knowledge-base-name target-kb)))
    (or (unit.exists.p *kee-panel-class-name* kb-name)
        (create.unit *kee-panel-class-name*
                     target-kb
                     nil
                     nil
                     "Reconstructed KEE image panels class."))))

(defun panel-derived-name (panel-name suffix)
  (intern (format nil "~A.~A" (symbol-name panel-name) suffix)
          (or (symbol-package panel-name) *package*)))

(defun maybe-create-panel-viewport (name picture label)
  (let ((viewport-name (panel-derived-name name "VIEWPORT")))
    (or (unit.exists.p viewport-name (kb.name (unit.kb picture)))
        (create.picture.viewport viewport-name
                                 picture
                                 :label label
                                 :width (get.value picture 'picture.width)
                                 :height (get.value picture 'picture.height)))))

(defun maybe-create-panel-windowpane (name viewport label open-p)
  (let ((windowpane-name (panel-derived-name name "WINDOW")))
    (or (unit.exists.p windowpane-name (kb.name (unit.kb viewport)))
        (create.picture.windowpane windowpane-name
                                   viewport
                                   :label label
                                   :open-p open-p
                                   :width (get.value viewport 'width)
                                   :height (get.value viewport 'height)))))

(defun panel-unit-name (designator)
  (and designator (unit.name (unit designator))))

(defun create.kee.panel
    (name &key kb (kind :image) label message picture viewport windowpane open-p)
  "Create a reconstructed KEE image/workflow panel.

Panels are ordinary units under KEE.PANELS. They can point at an existing
KEEpicture, viewport, and windowpane, and install KEE-style `open-panel!`,
`close-panel!`, `open!`, and `close!` message methods. This is a clean-room
support API, not a recovered IntelliCorp constructor."
  (let* ((explicit-kb (and kb (kee-panel-kb kb)))
         (explicit-kb-name (and explicit-kb (kb.name explicit-kb)))
         (picture-unit (and picture (unit picture explicit-kb-name)))
         (target-kb (cond (picture-unit (unit.kb picture-unit))
                          (explicit-kb explicit-kb)
                          (t (kb))))
         (class (ensure-kee-panel-class target-kb))
         (label (or label name))
         (viewport-unit
           (cond (viewport (unit viewport (kb.name target-kb)))
                 (picture-unit
                  (maybe-create-panel-viewport name picture-unit label))))
         (windowpane-unit
           (cond (windowpane (unit windowpane (kb.name target-kb)))
                 (viewport-unit
                  (maybe-create-panel-windowpane name viewport-unit label open-p))))
         (panel (create.unit name
                             target-kb
                             nil
                             (list class)
                             "Reconstructed KEE image panel.")))
    (put.value panel 'panel.kind (picture-keyword kind :image))
    (put.value panel 'label label)
    (when message
      (put.value panel 'panel.message message))
    (when picture-unit
      (put.value panel 'panel.picture (unit.name picture-unit)))
    (when viewport-unit
      (put.value panel 'panel.viewport (unit.name viewport-unit)))
    (when windowpane-unit
      (put.value panel 'panel.windowpane (unit.name windowpane-unit)))
    (put.value panel 'open.p (not (null open-p)))
    (when windowpane-unit
      (put.value windowpane-unit 'open.p (not (null open-p))))
    (add.method panel 'open-panel! :primary 'panel.open-panel!)
    (add.method panel 'close-panel! :primary 'panel.close-panel!)
    (add.method panel 'open! :primary 'panel.open!)
    (add.method panel 'close! :primary 'panel.close!)
    panel))

(defun list.kee.panels (&optional kb-designator)
  "Return reconstructed image/workflow panel units in KB-DESIGNATOR."
  (let* ((target-kb (kee-panel-kb kb-designator))
         (class (unit.exists.p *kee-panel-class-name*
                               (knowledge-base-name target-kb))))
    (sort (and class (copy-list (unit.children class 'member)))
          #'string<
          :key #'unit.name)))

(defun panel.open.p (panel-designator)
  "Return true when PANEL-DESIGNATOR is marked open."
  (not (null (get.value panel-designator 'open.p))))

(defun panel-linked-unit (panel slot-name)
  (let ((name (get.value panel slot-name)))
    (and name (unit.exists.p name (kb.name (unit.kb panel))))))

(defun panel-picture-unit (panel)
  (panel-linked-unit panel 'panel.picture))

(defun panel-viewport-unit (panel)
  (panel-linked-unit panel 'panel.viewport))

(defun panel-windowpane-unit (panel)
  (panel-linked-unit panel 'panel.windowpane))

(defun set-panel-open-state (panel open-p action)
  (let* ((old-open-p (panel.open.p panel))
         (new-open-p (not (null open-p)))
         (picture (panel-picture-unit panel))
         (viewport (panel-viewport-unit panel))
         (windowpane (panel-windowpane-unit panel)))
    (put.value panel 'open.p new-open-p)
    (when windowpane
      (put.value windowpane 'open.p new-open-p))
    (record.trace.event
     (if new-open-p :panel-open :panel-close)
     :panel (unit.name panel)
     :unit (unit.name panel)
     :picture (panel-unit-name picture)
     :viewport (panel-unit-name viewport)
     :windowpane (panel-unit-name windowpane)
     :action action
     :old-values (list old-open-p)
     :new-values (list new-open-p)
     :message (if new-open-p "KEE image panel opened"
                  "KEE image panel closed"))
    panel))

(defun panel.open-panel! (panel)
  (set-panel-open-state panel t 'open-panel!))

(defun panel.close-panel! (panel)
  (set-panel-open-state panel nil 'close-panel!))

(defun panel.open! (panel)
  (set-panel-open-state panel t 'open!))

(defun panel.close! (panel)
  (set-panel-open-state panel nil 'close!))

(defun open.panel (panel-designator)
  "Open PANEL-DESIGNATOR by sending the reconstructed OPEN-PANEL! message."
  (unitmsg panel-designator 'open-panel!))

(defun close.panel (panel-designator)
  "Close PANEL-DESIGNATOR by sending the reconstructed CLOSE-PANEL! message."
  (unitmsg panel-designator 'close-panel!))

(defun kee.panel.report (panel-designator)
  "Return a plist describing a reconstructed image/workflow panel."
  (let* ((panel (unit panel-designator))
         (picture (panel-picture-unit panel))
         (viewport (panel-viewport-unit panel))
         (windowpane (panel-windowpane-unit panel)))
    (list :name (unit.name panel)
          :kb (kb.name (unit.kb panel))
          :label (or (get.value panel 'label) (unit.name panel))
          :kind (picture-keyword (get.value panel 'panel.kind) :image)
          :message (get.value panel 'panel.message)
          :picture (panel-unit-name picture)
          :viewport (panel-unit-name viewport)
          :windowpane (panel-unit-name windowpane)
          :open-p (panel.open.p panel)
          :picture-label (and picture
                              (or (get.value picture 'label)
                                  (unit.name picture)))
          :windowpane-label (and windowpane
                                  (or (get.value windowpane 'label)
                                      (unit.name windowpane)))
          :svg (and picture
                    (kee.picture.svg picture)))))
