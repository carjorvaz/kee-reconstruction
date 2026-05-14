(in-package #:kee)

(defparameter *active-image-class-name* 'active.images)

(defun active-image-kb (kb-designator)
  (cond ((typep kb-designator 'knowledge-base) kb-designator)
        (kb-designator (kb kb-designator))
        (t (kb))))

(defun ensure-active-image-class (&optional kb-designator)
  (let* ((target-kb (active-image-kb kb-designator))
         (kb-name (knowledge-base-name target-kb)))
    (or (unit.exists.p *active-image-class-name* kb-name)
        (create.unit *active-image-class-name*
                     target-kb
                     nil
                     nil
                     "Reconstructed ActiveImages class."))))

(defun active-image-widget-key (widget)
  (cond ((null widget) :value)
        ((keywordp widget) widget)
        ((symbolp widget) (intern (symbol-name widget) "KEYWORD"))
        ((stringp widget) (intern (string-upcase widget) "KEYWORD"))
        (t :value)))

(defun create.active.image
    (name target-unit target-slot
     &key kb target-kb target-facet facet (widget :value) label min max choices
       writable-p)
  "Create an ActiveImage unit bound to TARGET-UNIT/TARGET-SLOT.

This is a reconstruction primitive: ActiveImages are represented as ordinary
KEE units whose slots describe a display binding and optional write-back
policy."
  (let* ((image-kb (active-image-kb kb))
         (class (ensure-active-image-class image-kb))
         (target (unit target-unit target-kb))
         (image (create.unit name image-kb nil (list class)
                             "Reconstructed ActiveImage.")))
    (put.value image 'target.unit (unit.name target))
    (put.value image 'target.kb (kb.name (unit.kb target)))
    (put.value image 'target.slot target-slot)
    (let ((target-facet (or target-facet facet)))
      (when target-facet
        (put.value image 'target.facet target-facet)))
    (put.value image 'widget (active-image-widget-key widget))
    (when label
      (put.value image 'label label))
    (when min
      (put.value image 'min.value min))
    (when max
      (put.value image 'max.value max))
    (when choices
      (put.values image 'choices choices))
    (put.value image 'writable.p (not (null writable-p)))
    image))

(defun list.active.images (&optional kb-designator)
  "Return ActiveImage units in KB-DESIGNATOR."
  (let* ((target-kb (active-image-kb kb-designator))
         (class (unit.exists.p *active-image-class-name*
                               (knowledge-base-name target-kb))))
    (sort (and class (copy-list (unit.children class 'member)))
          #'string<
          :key #'unit.name)))

(defun active-image-target-designator (image)
  (let ((target-name (get.value image 'target.unit))
        (target-kb (get.value image 'target.kb)))
    (unless target-name
      (error "ActiveImage ~S has no TARGET.UNIT slot." (unit.name image)))
    (list target-name target-kb)))

(defun active-image-target-slot (image)
  (or (get.value image 'target.slot)
      (error "ActiveImage ~S has no TARGET.SLOT slot." (unit.name image))))

(defun active-image-target-facet (image)
  (get.value image 'target.facet))

(defun active.image.values (active-image-designator)
  "Read the values currently displayed by ACTIVE-IMAGE-DESIGNATOR."
  (let* ((image (unit active-image-designator))
         (target (active-image-target-designator image))
         (slot-name (active-image-target-slot image))
         (facet (active-image-target-facet image)))
    (if facet
        (slot.facet.values target slot-name facet)
        (get.values target slot-name))))

(defun active.image.value (active-image-designator)
  "Read the first displayed value for ACTIVE-IMAGE-DESIGNATOR."
  (first (active.image.values active-image-designator)))

(defun active-image-choices (image target slot-name)
  (or (get.values image 'choices)
      (slot.allowed.values target slot-name)))

(defun active.image.report (active-image-designator)
  "Return a plist describing an ActiveImage and its current target value."
  (let* ((image (unit active-image-designator))
         (target-designator (active-image-target-designator image))
         (target (unit target-designator))
         (slot-name (active-image-target-slot image))
         (values (active.image.values image)))
    (list :name (unit.name image)
          :kb (kb.name (unit.kb image))
          :target-unit (unit.name target)
          :target-kb (kb.name (unit.kb target))
          :target-slot slot-name
          :target-facet (active-image-target-facet image)
          :widget (active-image-widget-key (or (get.value image 'widget)
                                               :value))
          :label (or (get.value image 'label) (unit.name image))
          :values values
          :value (first values)
          :choices (active-image-choices image target slot-name)
          :min (get.value image 'min.value)
          :max (get.value image 'max.value)
          :writable-p (not (null (get.value image 'writable.p))))))

(defun set.active.image.value (active-image-designator value)
  "Write VALUE through ACTIVE-IMAGE-DESIGNATOR's target binding."
  (let* ((image (unit active-image-designator))
         (report (active.image.report image)))
    (unless (getf report :writable-p)
      (error "ActiveImage ~S is read-only." (unit.name image)))
    (if (getf report :target-facet)
        (put.facet.value (list (getf report :target-unit)
                               (getf report :target-kb))
                         (getf report :target-slot)
                         (getf report :target-facet)
                         value)
        (put.value (list (getf report :target-unit)
                         (getf report :target-kb))
                   (getf report :target-slot)
                   value))))

(defun active-image-string (value)
  (cond ((null value) "NIL")
        ((symbolp value) (symbol-name value))
        (t (princ-to-string value))))

(defun active-image-html-escape-string (value)
  (with-output-to-string (stream)
    (loop for char across (active-image-string value)
          do (case char
               (#\& (write-string "&amp;" stream))
               (#\< (write-string "&lt;" stream))
               (#\> (write-string "&gt;" stream))
               (#\" (write-string "&quot;" stream))
               (#\' (write-string "&#39;" stream))
               (t (write-char char stream))))))

(defun active-image-number (value &optional (default 0))
  (cond ((numberp value) value)
        ((stringp value)
         (or (ignore-errors (parse-integer value :junk-allowed t))
             default))
        (t default)))

(defun active-image-number-values (values)
  (remove nil
          (mapcar (lambda (value)
                    (and (numberp value) value))
                  values)))

(defun active-image-clamp (value min max)
  (max min (min max value)))

(defun active-image-percent (value min max)
  (if (= min max)
      0
      (active-image-clamp (* 100 (/ (- value min) (- max min))) 0 100)))

(defun active-image-attrs (report)
  (format nil
          "data-active-image='~A' data-target-unit='~A' data-target-slot='~A'"
          (active-image-html-escape-string (getf report :name))
          (active-image-html-escape-string (getf report :target-unit))
          (active-image-html-escape-string (getf report :target-slot))))

(defun active-image-value-html (report)
  (format nil
          "<div class='active-image active-image-value' ~A><strong>~A</strong><span>~A</span></div>"
          (active-image-attrs report)
          (active-image-html-escape-string (getf report :label))
          (active-image-html-escape-string (getf report :value))))

(defun active-image-meter-html (report class)
  (let* ((value (active-image-number (getf report :value)))
         (min (active-image-number (getf report :min) 0))
         (max (active-image-number (getf report :max) (max 100 value))))
    (format nil
            "<div class='active-image ~A' ~A><label>~A</label><meter min='~A' max='~A' value='~A'>~A</meter><span>~A</span></div>"
            class
            (active-image-attrs report)
            (active-image-html-escape-string (getf report :label))
            min
            max
            value
            value
            (active-image-html-escape-string (getf report :value)))))

(defun active-image-switch-on-p (value)
  (and value
       (not (member value '(nil false off no 0) :test #'equalp))))

(defun active-image-switch-html (report)
  (let* ((on-p (active-image-switch-on-p (getf report :value)))
         (class (if on-p "active-image-switch is-on"
                    "active-image-switch is-off")))
    (format nil
            "<button type='button' class='active-image ~A' aria-pressed='~A' ~A>~A: ~A</button>"
            class
            (if on-p "true" "false")
            (active-image-attrs report)
            (active-image-html-escape-string (getf report :label))
            (if on-p "ON" "OFF"))))

(defun active-image-button-html (report)
  (format nil
          "<button type='button' class='active-image active-image-button' ~A>~A</button>"
          (active-image-attrs report)
          (active-image-html-escape-string (getf report :label))))

(defun active-image-histogram-html (report)
  (let* ((numbers (active-image-number-values (getf report :values)))
         (max (if numbers (reduce #'max numbers) 1)))
    (if numbers
        (format nil
                "<div class='active-image active-image-histogram' ~A><strong>~A</strong><div class='active-image-bars'>~{~A~}</div></div>"
                (active-image-attrs report)
                (active-image-html-escape-string (getf report :label))
                (mapcar (lambda (value)
                          (format nil
                                  "<span class='active-image-bar' style='height:~,2F%' title='~A'></span>"
                                  (active-image-percent value 0 max)
                                  (active-image-html-escape-string value)))
                        numbers))
        (active-image-value-html report))))

(defun active-image-plot-html (report)
  (let* ((numbers (active-image-number-values (getf report :values)))
         (max (if numbers (reduce #'max numbers) 1))
         (min (if numbers (reduce #'min numbers) 0))
         (count (length numbers)))
    (if (> count 1)
        (let ((points
                (loop for value in numbers
                      for index from 0
                      collect (format nil "~,2F,~,2F"
                                      (if (= count 1)
                                          0
                                          (* 100 (/ index (1- count))))
                                      (- 100 (active-image-percent value min max))))))
          (format nil
                  "<svg class='active-image active-image-plot' viewBox='0 0 100 100' role='img' aria-label='~A' ~A><polyline points='~{~A~^ ~}' fill='none' stroke='currentColor' stroke-width='3'></polyline></svg>"
                  (active-image-html-escape-string (getf report :label))
                  (active-image-attrs report)
                  points))
        (active-image-value-html report))))

(defun active.image.html (active-image-designator)
  "Return a small HTML fragment for ACTIVE-IMAGE-DESIGNATOR."
  (let* ((report (active.image.report active-image-designator))
         (widget (getf report :widget)))
    (case widget
      (:button (active-image-button-html report))
      (:gauge (active-image-meter-html report "active-image-gauge"))
      (:thermometer (active-image-meter-html report "active-image-thermometer"))
      (:switch (active-image-switch-html report))
      (:histogram (active-image-histogram-html report))
      (:plot (active-image-plot-html report))
      (otherwise (active-image-value-html report)))))

(defun write.active.image.html (stream active-image-designator)
  "Write a small HTML fragment for ACTIVE-IMAGE-DESIGNATOR to STREAM."
  (write-string (active.image.html active-image-designator) stream)
  (values))
