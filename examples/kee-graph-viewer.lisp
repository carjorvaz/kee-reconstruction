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
(defparameter *run-hamburg-puzzle-demo* nil)
(load (merge-pathnames "hamburg-puzzle-mini.lisp" *load-truename*))

(in-package #:cl-user)

(setup)
(kee:create.world 'hypothesis-root)
(kee:run.world.agenda '(constraint.rules hypothesis.rules) :max-iterations 20)

(defun demo-review-world ()
  (or (find-if (lambda (world)
                 (and (kee:world.inconsistent.p world)
                      (kee:world.nogoods world)
                      (kee:world.facts world)))
               (sort (copy-list (kee:$worlds))
                     #'string<
                     :key (lambda (world)
                            (symbol-name (kee:get.world.name world)))))
      (first (kee:$worlds))))

(defun demo-review-rule (world)
  (let ((justification (first (kee:why.false world))))
    (and justification
         (kee:justification.rule justification))))

(defun demo-session (world)
  (let* ((world-name (symbol-name (kee:get.world.name world)))
         (rule (demo-review-rule world))
         (rule-name (if rule (symbol-name rule) "NIL"))
         (facts (length (kee:world.facts world)))
         (nogoods (length (kee:world.nogoods world))))
    (list :listener
          (list "CL-USER> (SETUP)"
                "PUZZLE"
                "CL-USER> (KEE:CREATE.WORLD 'HYPOTHESIS-ROOT)"
                "HYPOTHESIS-ROOT"
                "CL-USER> (KEE:RUN.WORLD.AGENDA '(CONSTRAINT.RULES HYPOTHESIS.RULES) :MAX-ITERATIONS 20)"
                "20")
          :typescript
          (list "Generated Hamburg puzzle viewer"
                "Complete consistent worlds: 12"
                (format nil "Review world: ~A" world-name)
                (format nil "~A facts ~D / nogoods ~D"
                        world-name facts nogoods))
          :prompt
          (list "Current KB: PUZZLE"
                "View: Worlds"
                (format nil "Selected: ~A" world-name)
                (format nil "First nogood rule: ~A" rule-name))
          :desktop-title "KEE desktop"
          :desktop-subtitle
          "Hamburg puzzle review session / Units, Worlds, KEEpictures, Image Panels"
          :tour-notes
          (list "Reviewer target: worlds, rules, KEEpicture, ActiveImage, panel traces"
                "Best correction areas: desktop/window behavior and agenda tracing"))))

(defun review-world-value (world unit-name slot-name fallback)
  (or (kee:with-world (world)
        (kee:get.value unit-name slot-name))
      fallback))

(defun install-gui-demo-artifacts (review-world)
  (let* ((world-name (kee:get.world.name review-world))
         (sport (review-world-value review-world 'tom 'sport 'golf))
         (phobia (review-world-value review-world 'tom 'phobia 'heights)))
    (kee:create.unit 'review.state 'puzzle nil 'entities
                     "Reviewer-facing GUI demo state.")
    (kee:create.slot 'review.state 'focus.sport 'member nil nil nil nil
                     '((kee:value.class (kee:one.of golf basketball sailing))))
    (kee:put.value 'review.state 'review.world world-name)
    (kee:put.value 'review.state 'focus.person 'tom)
    (kee:put.value 'review.state 'focus.sport sport)
    (kee:put.value 'review.state 'focus.phobia phobia)
    (kee:put.value 'review.state 'confidence 63)
    (kee:create.active.image 'review.confidence.gauge
                             'review.state
                             'confidence
                             :widget :gauge
                             :label "Review confidence"
                             :min 0
                             :max 100
                             :writable-p t)
    (kee:create.active.image 'review.sport.choice
                             'review.state
                             'focus.sport
                             :widget :value
                             :label "Focus sport"
                             :choices '(golf basketball sailing)
                             :writable-p t)
    (kee:create.kee.picture 'hamburg.review.panel
                            :kb 'puzzle
                            :label "Hamburg Review Panel"
                            :width 360
                            :height 210
                            :background "#FFFFFF")
    (kee:create.picture.item 'hamburg.review.panel
                             'review.00.frame
                             :rectangle
                             :x 12
                             :y 12
                             :width 336
                             :height 186
                             :fill "#F7FAFC"
                             :stroke "#7D8A96")
    (kee:create.picture.item 'hamburg.review.panel
                             'review.10.title
                             :text
                             :text "KEEpicture review panel"
                             :x 28
                             :y 36
                             :stroke "#1E252D")
    (kee:create.picture.item 'hamburg.review.panel
                             'review.20.world.value
                             :value
                             :label "world"
                             :target-unit 'review.state
                             :target-slot 'review.world
                             :x 28
                             :y 62)
    (kee:create.picture.item 'hamburg.review.panel
                             'review.30.sport.value
                             :value
                             :label "Tom sport"
                             :target-unit 'review.state
                             :target-slot 'focus.sport
                             :x 28
                             :y 102)
    (kee:create.picture.item 'hamburg.review.panel
                             'review.40.confidence.card
                             :active-image
                             :active-image 'review.confidence.gauge
                             :x 178
                             :y 62
                             :width 150
                             :height 74)
    (kee:create.picture.viewport 'hamburg.review.viewport
                                 'hamburg.review.panel
                                 :label "Hamburg Review View"
                                 :width 360
                                 :height 210)
    (kee:create.picture.windowpane 'hamburg.review.window
                                   'hamburg.review.viewport
                                   :label "Hamburg Review Window"
                                   :width 380
                                   :height 240
                                   :open-p nil)
    (kee:create.kee.panel 'hamburg.review.image.panel
                          :kind :status
                          :label "Hamburg Review Image Panel"
                          :message "Review the selected generated world"
                          :picture 'hamburg.review.panel
                          :viewport 'hamburg.review.viewport
                          :windowpane 'hamburg.review.window
                          :open-p nil)
    (kee:open.panel 'hamburg.review.image.panel)
    (kee:picture.mouse.event 'hamburg.review.panel
                             'review.40.confidence.card
                             :mouse-left
                             :viewport 'hamburg.review.viewport
                             :windowpane 'hamburg.review.window
                             :x 250
                             :y 94
                             :button :left
                             :value 78)))

(let* ((review-world (demo-review-world))
       (review-world-id (format nil "world:~A"
                                (symbol-name
                                 (kee:get.world.name review-world)))))
  (install-gui-demo-artifacts review-world)
  (kee:write.kee.viewer.html *standard-output*
                             :kb 'puzzle
                             :world-limit 80
                             :title "Hamburg Puzzle"
                             :initial-view "worlds"
                             :initial-selection review-world-id
                             :initial-trace-scope "selected"
                             :session (demo-session review-world)))
