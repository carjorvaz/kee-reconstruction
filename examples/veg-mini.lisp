(load (merge-pathnames "../src/package.lisp" *load-truename*))
(load (merge-pathnames "../src/core.lisp" *load-truename*))
(load (merge-pathnames "../src/worlds.lisp" *load-truename*))

(in-package #:cl-user)

(defun setup-veg-mini ()
  (kee:reset-kee)
  (kee:create.kb 'veg)
  (kee:create.unit 'classes 'veg nil nil)
  (kee:create.unit 'entities 'veg nil nil)
  (kee:create.unit 'target.data 'veg 'entities 'classes)
  (kee:create.unit 'wavelength.data 'veg 'entities 'classes)
  (kee:create.unit 'estimate.hemispherical.reflectance 'veg 'entities nil)
  (kee:create.unit 'initialize.system 'veg 'entities nil)
  (kee:put.value 'target.data 'source 'manual)
  (kee:put.value 'initialize.system 'initialize.system
                 (lambda (self)
                   (declare (ignore self))
                   (kee:put.value 'estimate.hemispherical.reflectance
                                  'status
                                  'ready))))

(defun store-sample-data (description wavelength reflectance-data)
  (let ((sample (kee:create.unit (gensym "FILE-SAMPLE-") 'veg nil 'target.data)))
    (kee:add.value 'estimate.hemispherical.reflectance 'new.samples sample)
    (kee:put.value sample 'complete.description description)
    (let ((wave (kee:create.unit (gensym "W") 'veg nil 'wavelength.data)))
      (kee:add.value sample 'current.sample.wavelengths wave)
      (kee:put.value wave 'wavelength wavelength)
      (kee:put.value wave 'reflectance.data reflectance-data))
    sample))

(defun run ()
  (setup-veg-mini)
  (kee:unitmsg 'initialize.system 'initialize.system)
  (let ((sample (store-sample-data "demo cover type" 0.64
                                   '((0 0 0.31) (30 180 0.28)))))
    (format t "~&Status: ~S~%" (kee:get.value 'estimate.hemispherical.reflectance
                                             'status))
    (format t "Sample: ~S~%" (kee:unit.name sample))
    (format t "Inherited source: ~S~%" (kee:get.value sample 'source))
    (format t "Wavelength children: ~S~%"
            (mapcar #'kee:unit.name
                    (kee:get.values sample 'current.sample.wavelengths)))))

(run)
