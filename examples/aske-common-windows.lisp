(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/active-images.lisp" *load-truename*))
(load (merge-pathnames "../src/traces.lisp" *load-truename*))
(load (merge-pathnames "../src/pictures.lisp" *load-truename*))
(load (merge-pathnames "../src/panels.lisp" *load-truename*))
(load (merge-pathnames "../src/worlds.lisp" *load-truename*))
(load (merge-pathnames "../src/rules.lisp" *load-truename*))
(load (merge-pathnames "../src/inspect.lisp" *load-truename*))
(load (merge-pathnames "../src/graph.lisp" *load-truename*))
(load (merge-pathnames "../src/viewer.lisp" *load-truename*))

(in-package #:cl-user)

(defun aske-symbol (prefix suffix)
  (intern (format nil "~A.~A" (symbol-name prefix) suffix)))

(defun aske-box (picture name title x y width height
                 &key (fill "#FBFCFD") (stroke "#7D8A96"))
  (kee:create.picture.item picture name :rectangle
                           :x x :y y :width width :height height
                           :fill fill :stroke stroke)
  (kee:create.picture.item picture (aske-symbol name "TITLE") :text
                           :text title
                           :x (+ x 10)
                           :y (+ y 18)
                           :stroke "#1E252D"))

(defun aske-text (picture name text x y &key (stroke "#1E252D"))
  (kee:create.picture.item picture name :text
                           :text text
                           :x x
                           :y y
                           :stroke stroke))

(defun aske-icon (picture name label x y &key (width 78))
  (kee:create.picture.item picture name :rectangle
                           :x x :y y :width width :height 34
                           :fill "#E9EEF3" :stroke "#7D8A96")
  (kee:create.picture.item picture (aske-symbol name "LABEL") :text
                           :text label
                           :x (+ x 8)
                           :y (+ y 22)
                           :stroke "#1E252D"))

(defun aske-create-panel-window (picture viewport window label)
  (kee:create.picture.viewport viewport picture
                               :label (format nil "~A View" label)
                               :width 700
                               :height 430)
  (kee:create.picture.windowpane window viewport
                                 :label (format nil "~A Window" label)
                                 :width 720
                                 :height 462
                                 :open-p nil))

(defun setup-aske-domain-model ()
  (kee:create.unit 'aske.session 'aske.demo nil nil
                   "Reconstructed ASKE/Common Windows demo session state.")
  (kee:put.value 'aske.session 'current.interface 'aske)
  (kee:put.value 'aske.session 'current.kb 'askedata)
  (kee:put.value 'aske.session 'last.action 'new.kb)
  (kee:put.value 'aske.session 'selected.context 'activities.t)
  (kee:put.value 'aske.session 'selected.class 'butchering.t)
  (kee:put.value 'aske.session 'selected.rule 'if.butchering.then.occupancy)
  (kee:create.unit 'templates 'aske.demo nil nil
                   "ASKE template root from the public thesis evidence.")
  (dolist (name '(gtemp atemp rtemp wtemp))
    (kee:create.unit name 'aske.demo '(templates) nil
                     "ASKE template type."))
  (kee:create.unit 'archaeology 'aske.demo nil '(gtemp))
  (kee:create.unit 'interpretation 'aske.demo nil '(atemp))
  (kee:create.unit 'burial.sites 'aske.demo nil '(rtemp))
  (kee:create.unit 'settlement.sites 'aske.demo nil '(wtemp))
  (kee:create.unit 'central.concepts 'aske.demo nil nil
                   "ASKE central concepts root.")
  (dolist (name '(activities artifacts features site.profile))
    (kee:create.unit name 'aske.demo '(central.concepts) nil))
  (kee:create.unit 'butchering 'aske.demo '(activities) nil)
  (kee:create.unit 'occupancy 'aske.demo '(site.profile) nil)
  (kee:put.value 'butchering 'asserted t)
  (kee:put.value 'occupancy 'inferred.from 'butchering)
  (kee:put.values 'settlement.sites 'main.concept.categories
                  '(activities artifacts features site.profile))
  (kee:put.values 'settlement.sites 'notebook.pages
                  '(gtemp atemp rtemp wtemp central.concepts temp.rules))
  (kee:create.unit 'temp.rules 'aske.demo nil nil
                   "ASKE rule root shown in the Notebook/Rulemaker evidence.")
  (kee:put.value 'temp.rules 'kee:parse #'kee:parse)
  (kee:create.unit 'activities.t 'aske.demo nil '(temp.rules))
  (kee:create.unit 'butchering.t 'aske.demo '(activities.t) nil)
  (kee:create.unit 'if.butchering.then.occupancy 'aske.demo nil '(butchering.t))
  (kee:put.value 'if.butchering.then.occupancy 'kee:external.form
                 '(if (the asserted of butchering is t)
                      then
                      (lisp (put.value 'occupancy
                                       'inferred.from
                                       'butchering))))
  (kee:unitmsg 'if.butchering.then.occupancy 'kee:parse))

(defun create-aske-interface-picture ()
  (kee:create.kee.picture 'aske.interface.picture
                          :kb 'aske.demo
                          :label "Aske Interface"
                          :width 700
                          :height 430
                          :background "#F4F7FA")
  (aske-box 'aske.interface.picture 'aske.window.frame
            "Aske Interface / KEE 3.1 Common Windows" 12 12 676 392
            :fill "#FFFFFF")
  (loop for (name label x) in
        '((aske.icon.new-kb "New KB" 28)
          (aske.icon.load-kb "Load KB" 112)
          (aske.icon.save-kb "Save KB" 196)
          (aske.icon.quit "Quit" 280)
          (aske.icon.help "Help" 364)
          (aske.icon.rulemaker "Rulemaker" 448))
        do (aske-icon 'aske.interface.picture name label x 46))
  (aske-box 'aske.interface.picture 'aske.interaction.window
            "Interaction Window" 28 104 278 258)
  (aske-text 'aske.interface.picture 'aske.interaction.line.1
             "Problem definition: archaeology / interpretation" 44 144)
  (aske-text 'aske.interface.picture 'aske.interaction.line.2
             "Selected RTEMP: burial.sites" 44 168)
  (aske-text 'aske.interface.picture 'aske.interaction.line.3
             "Prompt: enter main data and solution categories" 44 192)
  (aske-text 'aske.interface.picture 'aske.interaction.line.4
             "Stage one is question-answering; stage two uses graphics" 44 216)
  (aske-text 'aske.interface.picture 'aske.interaction.line.5
             "Central Concepts Window opens from Notebook pages" 44 264)
  (aske-box 'aske.interface.picture 'aske.notebook
            "Notebook" 330 104 150 110)
  (loop for (name label x y) in
        '((aske.page.gtemp "GTEMP" 344 132)
          (aske.page.atemp "ATEMP" 410 132)
          (aske.page.rtemp "RTEMP" 344 158)
          (aske.page.wtemp "WTEMP" 410 158)
          (aske.page.central "Central" 344 184)
          (aske.page.rules "Rules" 410 184))
        do (aske-icon 'aske.interface.picture name label x y :width 58))
  (aske-box 'aske.interface.picture 'aske.display.window
            "Display Window / KB: askedata" 500 104 162 258)
  (aske-text 'aske.interface.picture 'aske.display.line.1
             "central.concepts" 516 144)
  (aske-text 'aske.interface.picture 'aske.display.line.2
             "  activities" 516 168)
  (aske-text 'aske.interface.picture 'aske.display.line.3
             "    butchering" 516 192)
  (aske-text 'aske.interface.picture 'aske.display.line.4
             "  artifacts" 516 216)
  (aske-text 'aske.interface.picture 'aske.display.line.5
             "  features" 516 240)
  (aske-text 'aske.interface.picture 'aske.display.line.6
             "  site.profile" 516 264)
  (aske-text 'aske.interface.picture 'aske.display.line.7
             "    occupancy" 516 288))

(defun create-rulemaker-picture ()
  (kee:create.kee.picture 'rulemaker.interface.picture
                          :kb 'aske.demo
                          :label "Rulemaker Interface"
                          :width 700
                          :height 430
                          :background "#F4F7FA")
  (aske-box 'rulemaker.interface.picture 'rulemaker.window.frame
            "Rulemaker Interface / contexts, classes, rules" 12 12 676 392
            :fill "#FFFFFF")
  (loop for (name label x) in
        '((rulemaker.icon.context "Context" 28)
          (rulemaker.icon.class "Class" 112)
          (rulemaker.icon.rule "Rule" 196)
          (rulemaker.icon.aske "Aske" 280)
          (rulemaker.icon.help "Help" 364))
        do (aske-icon 'rulemaker.interface.picture name label x 46))
  (aske-box 'rulemaker.interface.picture 'rulemaker.rule.dw
            "Rule DW" 28 104 252 258)
  (aske-text 'rulemaker.interface.picture 'rulemaker.rule.line.1
             "IF butchering" 44 144)
  (aske-text 'rulemaker.interface.picture 'rulemaker.rule.line.2
             "THEN occupancy" 44 168)
  (aske-text 'rulemaker.interface.picture 'rulemaker.rule.line.3
             "left click: premise" 44 216)
  (aske-text 'rulemaker.interface.picture 'rulemaker.rule.line.4
             "middle click: conclusion" 44 240)
  (aske-box 'rulemaker.interface.picture 'rulemaker.context.dw
            "Context DW" 314 104 156 116)
  (aske-text 'rulemaker.interface.picture 'rulemaker.context.line.1
             "activities.t" 330 144)
  (aske-text 'rulemaker.interface.picture 'rulemaker.context.line.2
             "site.profile.t" 330 168)
  (aske-box 'rulemaker.interface.picture 'rulemaker.class.dw
            "Class DW" 496 104 166 116)
  (aske-text 'rulemaker.interface.picture 'rulemaker.class.line.1
             "butchering.t" 512 144)
  (aske-text 'rulemaker.interface.picture 'rulemaker.class.line.2
             "occupancy.t" 512 168)
  (aske-box 'rulemaker.interface.picture 'rulemaker.edit.window
            "Rule Editing Window" 314 248 348 114)
  (aske-text 'rulemaker.interface.picture 'rulemaker.edit.line.1
             "Buffer shows premise or conclusion from Rule DW click" 330 288)
  (aske-text 'rulemaker.interface.picture 'rulemaker.edit.line.2
             "Merge and create rules from Class DW" 330 312))

(defun create-aske-panels ()
  (aske-create-panel-window 'aske.interface.picture
                            'aske.interface.viewport
                            'aske.interface.window
                            "Aske Interface")
  (kee:create.kee.panel 'aske.interface.panel
                        :kind :common-windows
                        :label "Aske Interface Panel"
                        :message "Six icons, Interaction Window, Notebook, and current-KB Display Window from the ASKE thesis."
                        :picture 'aske.interface.picture
                        :viewport 'aske.interface.viewport
                        :windowpane 'aske.interface.window)
  (aske-create-panel-window 'rulemaker.interface.picture
                            'rulemaker.interface.viewport
                            'rulemaker.interface.window
                            "Rulemaker Interface")
  (kee:create.kee.panel 'rulemaker.interface.panel
                        :kind :common-windows
                        :label "Rulemaker Interface Panel"
                        :message "Five icons, Rule/Context/Class display windows, and Rule Editing Window."
                        :picture 'rulemaker.interface.picture
                        :viewport 'rulemaker.interface.viewport
                        :windowpane 'rulemaker.interface.window))

(defun setup-aske-common-windows-demo ()
  (kee:reset-kee)
  (kee:create.kb 'aske.demo)
  (setup-aske-domain-model)
  (create-aske-interface-picture)
  (create-rulemaker-picture)
  (create-aske-panels)
  (kee:open.panel 'aske.interface.panel)
  (kee:picture.mouse.event 'aske.interface.picture
                           'aske.icon.rulemaker
                           :mouse-left
                           :viewport 'aske.interface.viewport
                           :windowpane 'aske.interface.window
                           :x 484
                           :y 62
                           :button :left)
  (kee:put.value 'aske.session 'last.action 'rulemaker)
  (kee:put.value 'aske.session 'current.interface 'rulemaker)
  (kee:close.panel 'aske.interface.panel)
  (kee:open.panel 'rulemaker.interface.panel)
  (kee:picture.mouse.event 'rulemaker.interface.picture
                           'rulemaker.context.dw
                           :mouse-left
                           :viewport 'rulemaker.interface.viewport
                           :windowpane 'rulemaker.interface.window
                           :x 344
                           :y 144
                           :button :left)
  (kee:picture.mouse.event 'rulemaker.interface.picture
                           'rulemaker.class.dw
                           :mouse-left
                           :viewport 'rulemaker.interface.viewport
                           :windowpane 'rulemaker.interface.window
                           :x 520
                           :y 144
                           :button :left)
  (kee:picture.mouse.event 'rulemaker.interface.picture
                           'rulemaker.rule.dw
                           :mouse-left
                           :viewport 'rulemaker.interface.viewport
                           :windowpane 'rulemaker.interface.window
                           :x 72
                           :y 144
                           :button :left)
  (kee:picture.mouse.event 'rulemaker.interface.picture
                           'rulemaker.rule.dw
                           :mouse-middle
                           :viewport 'rulemaker.interface.viewport
                           :windowpane 'rulemaker.interface.window
                           :x 72
                           :y 168
                           :button :middle)
  (kee:put.value 'aske.session 'last.action 'rule.editing.window)
  t)

(defun aske-demo-session ()
  (list :listener
        (list "CL-USER> (SETUP-ASKE-COMMON-WINDOWS-DEMO)"
              "ASKE.DEMO"
              "CL-USER> (KEE:OPEN.PANEL 'ASKE.INTERFACE.PANEL)"
              "ASKE.INTERFACE.PANEL"
              "CL-USER> (KEE:UNITMSG 'IF.BUTCHERING.THEN.OCCUPANCY 'KEE:PARSE)"
              "IF.BUTCHERING.THEN.OCCUPANCY")
        :typescript
        (list "Generated ASKE/Common Windows reviewer demo"
              "Source lead: Open University ASKE thesis, Chapter V"
              "Aske interface: icons + Interaction Window + Notebook + Display Window"
              "Central Concepts Window is represented as a Notebook/display target"
              "Rulemaker interface: Rule DW + Context DW + Class DW + Rule Editing Window")
        :prompt
        (list "Current KB: ASKE.DEMO"
              "View: Panels"
              "Selected unit: ASKE.SESSION"
              "Question for reviewer: normal KEE/Common Windows idiom or ASKE-specific?")
        :desktop-title "KEE desktop"
        :desktop-subtitle
        "ASKE.DEMO / KEE 3.1 on Unisys Explorer / Common Windows evidence from public thesis"
        :tour-notes
        (list "Panel sequence: Aske interface -> Rulemaker interface"
              "Reviewer target: Common Windows workspace names, icon actions, display windows, mouse distinctions")))

(setup-aske-common-windows-demo)
(kee:write.kee.viewer.html *standard-output*
                           :kb 'aske.demo
                           :world-limit 0
                           :title "ASKE Common Windows Demo"
                           :initial-view "units"
                           :initial-selection "unit:ASKE.DEMO/ASKE.SESSION"
                           :initial-trace-family "pictures"
                           :initial-trace-scope "all"
                           :session (aske-demo-session))
