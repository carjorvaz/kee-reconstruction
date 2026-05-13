(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/rules.lisp" *load-truename*))

(in-package #:cl-user)

(defun setup ()
  (kee:reset-kee)
  (kee:create.kb 'veg)
  (kee:create.unit 'classes 'veg nil nil)
  (kee:create.unit 'entities 'veg nil nil)
  (kee:create.unit 'wavelength.data 'veg 'entities 'classes)
  (kee:create.unit 'estimate.hemispherical.reflectance 'veg 'entities nil)
  (kee:create.unit 'technique.selection.rules 'veg 'entities 'classes)
  (kee:put.value 'technique.selection.rules 'kee:parse #'kee:parse))

(defun define-data ()
  (let ((wave (kee:create.unit 'wavelength.1 'veg nil 'wavelength.data)))
    (kee:add.value 'estimate.hemispherical.reflectance
                   'current.sample.wavelengths
                   wave)
    (kee:put.value wave 'wavelength 0.64)
    (kee:put.value wave 'reflectance.data '((0 0 0.31) (30 180 0.28)))
    wave))

(defun define-rule ()
  (kee:create.unit 'pgcswr.10 'veg nil 'technique.selection.rules)
  (kee:put.value 'pgcswr.10 'kee:external.form
                 '(if (the current.sample.wavelengths
                       of estimate.hemispherical.reflectance
                       is ?x)
                      (lisp (consp (get.value ?x 'reflectance.data)))
                      then
                      (lisp (add.value ?x 'techniques 'pgc.near.nadir))))
  (kee:unitmsg 'pgcswr.10 'kee:parse))

(defun run ()
  (setup)
  (let ((wave (define-data)))
    (define-rule)
    (let ((fired (kee:forward.chain 'technique.selection.rules)))
      (format t "~&Fired: ~S~%" (mapcar #'kee:unit.name fired))
      (format t "Techniques: ~S~%" (kee:get.values wave 'techniques)))))

(run)
