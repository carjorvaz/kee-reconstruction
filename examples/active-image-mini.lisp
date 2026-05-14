(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/active-images.lisp" *load-truename*))
(load (merge-pathnames "../src/traces.lisp" *load-truename*))
(load (merge-pathnames "../src/pictures.lisp" *load-truename*))

(in-package #:cl-user)

(defun setup-active-image-mini ()
  (kee:reset-kee)
  (kee:create.kb 'demo)
  (kee:create.unit 'entities 'demo nil nil)
  (kee:create.unit 'sensors 'demo 'entities nil)
  (kee:create.unit 'temperature.sensor 'demo nil 'sensors)
  (kee:create.slot 'temperature.sensor 'temperature 'member '(21)
                   nil nil nil '((kee:active.values audit.av)))
  (kee:create.unit 'audit.av 'demo 'entities nil)
  (kee:put.value 'audit.av 'kee:value-written
                 (lambda (self target slot old new)
                   (declare (ignore self))
                   (format t "~&ActiveValue: ~S/~S ~S -> ~S~%"
                           (kee:unit.name target) slot old new)))
  (kee:create.active.image 'temperature.gauge
                           'temperature.sensor
                           'temperature
                           :widget :gauge
                           :label "Temperature"
                           :min 0
                           :max 100
                           :writable-p t)
  (kee:create.kee.picture 'sensor.panel
                          :width 240
                          :height 120
                          :label "Sensor Panel")
  (kee:create.picture.item 'sensor.panel 'panel.title :text
                           :x 18
                           :y 28
                           :text "KEEpicture sensor panel")
  (kee:create.picture.item 'sensor.panel 'temperature.card :active-image
                           :active-image 'temperature.gauge
                           :x 18
                           :y 42
                           :width 150
                           :height 58)
  (kee:create.picture.viewport 'sensor.viewport 'sensor.panel
                               :label "Sensor View"
                               :width 240
                               :height 120)
  (kee:create.picture.windowpane 'sensor.window 'sensor.viewport
                                 :label "Sensor Window"
                                 :width 260
                                 :height 150))

(defun run ()
  (setup-active-image-mini)
  (format t "~&Initial ActiveImage: ~A~%"
          (kee:active.image.html 'temperature.gauge))
  (kee:picture.mouse.event 'sensor.panel 'temperature.card :mouse-left
                           :viewport 'sensor.viewport
                           :windowpane 'sensor.window
                           :x 82
                           :y 68
                           :button :left
                           :value 42)
  (format t "~&Updated ActiveImage: ~A~%"
          (kee:active.image.html 'temperature.gauge))
  (format t "~&Picture SVG: ~A~%"
          (kee:kee.picture.svg 'sensor.panel))
  (format t "~&Picture Trace: ~S~%"
          (first (last (kee:trace.events :kind :picture-mouse)))))

(run)
