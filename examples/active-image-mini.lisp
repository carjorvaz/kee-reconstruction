(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/active-images.lisp" *load-truename*))

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
                           :writable-p t))

(defun run ()
  (setup-active-image-mini)
  (format t "~&Initial ActiveImage: ~A~%"
          (kee:active.image.html 'temperature.gauge))
  (kee:set.active.image.value 'temperature.gauge 42)
  (format t "~&Updated ActiveImage: ~A~%"
          (kee:active.image.html 'temperature.gauge)))

(run)
