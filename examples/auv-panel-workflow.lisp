(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/active-images.lisp" *load-truename*))
(load (merge-pathnames "../src/traces.lisp" *load-truename*))
(load (merge-pathnames "../src/pictures.lisp" *load-truename*))
(load (merge-pathnames "../src/panels.lisp" *load-truename*))
(load (merge-pathnames "../src/worlds.lisp" *load-truename*))
(load (merge-pathnames "../src/inspect.lisp" *load-truename*))
(load (merge-pathnames "../src/graph.lisp" *load-truename*))
(load (merge-pathnames "../src/viewer.lisp" *load-truename*))

(in-package #:cl-user)

(defun create-panel-window (picture viewport window label)
  (kee:create.picture.viewport viewport picture
                               :label (format nil "~A View" label)
                               :width 360
                               :height 210)
  (kee:create.picture.windowpane window viewport
                                 :label (format nil "~A Window" label)
                                 :width 380
                                 :height 240
                                 :open-p nil))

(defun create-panel-frame (picture title)
  (kee:create.picture.item picture
                           (intern (format nil "~A.FRAME" (symbol-name picture)))
                           :rectangle
                           :x 12
                           :y 12
                           :width 336
                           :height 186
                           :fill "#F7FAFC"
                           :stroke "#7D8A96")
  (kee:create.picture.item picture
                           (intern (format nil "~A.TITLE" (symbol-name picture)))
                           :text
                           :text title
                           :x 28
                           :y 36
                           :stroke "#1E252D"))

(defun setup-auv-panel-workflow ()
  (kee:reset-kee)
  (kee:create.kb 'auv.workflow)
  (kee:create.unit 'mission.state 'auv.workflow nil nil
                   "AUV mission-planning state for the panel workflow demo.")
  (kee:put.value 'mission.state 'workflow.phase 'mission-selection)
  (kee:put.value 'mission.state 'mission.profile 'harbor.survey)
  (kee:put.value 'mission.state 'max.depth.meters 120)
  (kee:put.value 'mission.state 'duration.minutes 45)
  (kee:put.value 'mission.state 'battery.percent 88)
  (kee:put.value 'mission.state 'acoustic.link 'off)
  (kee:put.value 'mission.state 'survey.status 'not-started)
  (kee:create.active.image 'mission.profile.choice
                           'mission.state
                           'mission.profile
                           :widget :value
                           :label "Mission profile"
                           :choices '(harbor.survey pipeline.inspect
                                      mine.countermeasure)
                           :writable-p t)
  (kee:create.active.image 'max.depth.gauge
                           'mission.state
                           'max.depth.meters
                           :widget :gauge
                           :label "Max depth"
                           :min 0
                           :max 300
                           :writable-p t)
  (kee:create.active.image 'duration.gauge
                           'mission.state
                           'duration.minutes
                           :widget :thermometer
                           :label "Duration"
                           :min 0
                           :max 180
                           :writable-p t)
  (kee:create.active.image 'battery.gauge
                           'mission.state
                           'battery.percent
                           :widget :gauge
                           :label "Battery"
                           :min 0
                           :max 100
                           :writable-p t)
  (kee:create.active.image 'acoustic.link.switch
                           'mission.state
                           'acoustic.link
                           :widget :switch
                           :label "Acoustic link"
                           :writable-p t)
  (kee:create.kee.picture 'workflow.10.selection.picture
                          :kb 'auv.workflow
                          :label "Mission Selection Picture"
                          :width 360
                          :height 210)
  (create-panel-frame 'workflow.10.selection.picture "Mission selection")
  (kee:create.picture.item 'workflow.10.selection.picture
                           'selection.20.phase
                           :value
                           :label "phase"
                           :target-unit 'mission.state
                           :target-slot 'workflow.phase
                           :x 28
                           :y 62)
  (kee:create.picture.item 'workflow.10.selection.picture
                           'selection.30.profile
                           :active-image
                           :active-image 'mission.profile.choice
                           :x 28
                           :y 108
                           :width 210
                           :height 54)
  (create-panel-window 'workflow.10.selection.picture
                       'workflow.10.selection.viewport
                       'workflow.10.selection.window
                       "Mission Selection")
  (kee:create.kee.panel 'workflow.10.selection.panel
                        :kind :selection
                        :label "Mission Selection Panel"
                        :message "Choose the mission profile"
                        :picture 'workflow.10.selection.picture
                        :viewport 'workflow.10.selection.viewport
                        :windowpane 'workflow.10.selection.window)
  (kee:create.kee.picture 'workflow.20.parameters.picture
                          :kb 'auv.workflow
                          :label "Parameter Entry Picture"
                          :width 360
                          :height 210)
  (create-panel-frame 'workflow.20.parameters.picture "Parameter entry")
  (kee:create.picture.item 'workflow.20.parameters.picture
                           'parameters.20.depth
                           :active-image
                           :active-image 'max.depth.gauge
                           :x 28
                           :y 62
                           :width 145
                           :height 70)
  (kee:create.picture.item 'workflow.20.parameters.picture
                           'parameters.30.duration
                           :active-image
                           :active-image 'duration.gauge
                           :x 188
                           :y 62
                           :width 145
                           :height 70)
  (create-panel-window 'workflow.20.parameters.picture
                       'workflow.20.parameters.viewport
                       'workflow.20.parameters.window
                       "Parameter Entry")
  (kee:create.kee.panel 'workflow.20.parameters.panel
                        :kind :entry
                        :label "Parameter Entry Panel"
                        :message "Tune mission parameters"
                        :picture 'workflow.20.parameters.picture
                        :viewport 'workflow.20.parameters.viewport
                        :windowpane 'workflow.20.parameters.window)
  (kee:create.kee.picture 'workflow.30.monitoring.picture
                          :kb 'auv.workflow
                          :label "Mission Monitoring Picture"
                          :width 360
                          :height 210)
  (create-panel-frame 'workflow.30.monitoring.picture "Mission monitoring")
  (kee:create.picture.item 'workflow.30.monitoring.picture
                           'monitoring.20.status
                           :value
                           :label "status"
                           :target-unit 'mission.state
                           :target-slot 'survey.status
                           :x 28
                           :y 62)
  (kee:create.picture.item 'workflow.30.monitoring.picture
                           'monitoring.30.battery
                           :active-image
                           :active-image 'battery.gauge
                           :x 28
                           :y 108
                           :width 145
                           :height 70)
  (kee:create.picture.item 'workflow.30.monitoring.picture
                           'monitoring.40.link
                           :active-image
                           :active-image 'acoustic.link.switch
                           :x 188
                           :y 108
                           :width 145
                           :height 70)
  (create-panel-window 'workflow.30.monitoring.picture
                       'workflow.30.monitoring.viewport
                       'workflow.30.monitoring.window
                       "Mission Monitoring")
  (kee:create.kee.panel 'workflow.30.monitoring.panel
                        :kind :monitoring
                        :label "Mission Monitoring Panel"
                        :message "Watch the live mission state"
                        :picture 'workflow.30.monitoring.picture
                        :viewport 'workflow.30.monitoring.viewport
                        :windowpane 'workflow.30.monitoring.window)
  (kee:open.panel 'workflow.10.selection.panel)
  (kee:picture.mouse.event 'workflow.10.selection.picture
                           'selection.30.profile
                           :mouse-left
                           :viewport 'workflow.10.selection.viewport
                           :windowpane 'workflow.10.selection.window
                           :x 82
                           :y 124
                           :button :left
                           :value 'pipeline.inspect)
  (kee:close.panel 'workflow.10.selection.panel)
  (kee:open.panel 'workflow.20.parameters.panel)
  (kee:picture.mouse.event 'workflow.20.parameters.picture
                           'parameters.20.depth
                           :mouse-left
                           :viewport 'workflow.20.parameters.viewport
                           :windowpane 'workflow.20.parameters.window
                           :x 92
                           :y 92
                           :button :left
                           :value 180)
  (kee:picture.mouse.event 'workflow.20.parameters.picture
                           'parameters.30.duration
                           :mouse-left
                           :viewport 'workflow.20.parameters.viewport
                           :windowpane 'workflow.20.parameters.window
                           :x 240
                           :y 92
                           :button :left
                           :value 90)
  (kee:close.panel 'workflow.20.parameters.panel)
  (kee:put.value 'mission.state 'workflow.phase 'monitoring)
  (kee:put.value 'mission.state 'survey.status 'running)
  (kee:put.value 'mission.state 'battery.percent 74)
  (kee:open.panel 'workflow.30.monitoring.panel)
  (kee:picture.mouse.event 'workflow.30.monitoring.picture
                           'monitoring.40.link
                           :mouse-left
                           :viewport 'workflow.30.monitoring.viewport
                           :windowpane 'workflow.30.monitoring.window
                           :x 214
                           :y 136
                           :button :left
                           :value 'locked)
  t)

(defun auv-demo-session ()
  (list :listener
        (list "CL-USER> (SETUP-AUV-PANEL-WORKFLOW)"
              "AUV.WORKFLOW"
              "CL-USER> (KEE:OPEN.PANEL 'WORKFLOW.10.SELECTION.PANEL)"
              "WORKFLOW.10.SELECTION.PANEL"
              "CL-USER> (KEE:OPEN.PANEL 'WORKFLOW.30.MONITORING.PANEL)"
              "WORKFLOW.30.MONITORING.PANEL")
        :typescript
        (list "Generated AUV panel workflow viewer"
              "Panels: selection -> parameters -> monitoring"
              "Mouse events update mission.state through ActiveImages")
        :prompt
        (list "Current KB: AUV.WORKFLOW"
              "View: Panels"
              "Selected unit: MISSION.STATE"
              "Evidence lead: NPS AUV image-panel workflow")
        :desktop-title "KEE desktop"
        :desktop-subtitle
        "AUV.WORKFLOW / Symbolics 3675 development evidence / TI Micro-Explorer delivery target noted"
        :tour-notes
        (list "Panel sequence: mission selection -> parameter entry -> monitoring"
              "Reviewer target: image panels, KEEpictures, ActiveImages, picture mouse traces")))

(setup-auv-panel-workflow)
(kee:write.kee.viewer.html *standard-output*
                           :kb 'auv.workflow
                           :world-limit 0
                           :title "AUV Panel Workflow"
                           :initial-view "units"
                           :initial-selection "unit:AUV.WORKFLOW/MISSION.STATE"
                           :initial-trace-family "pictures"
                           :initial-trace-scope "all"
                           :session (auv-demo-session))
