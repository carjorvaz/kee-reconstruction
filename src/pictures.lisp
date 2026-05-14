(in-package #:kee)

(defparameter *kee-picture-class-name* 'kee.pictures)
(defparameter *kee-picture-item-class-name* 'kee.picture.items)

(defun kee-picture-kb (kb-designator)
  (cond ((typep kb-designator 'knowledge-base) kb-designator)
        (kb-designator (kb kb-designator))
        (t (kb))))

(defun ensure-kee-picture-classes (&optional kb-designator)
  (let* ((target-kb (kee-picture-kb kb-designator))
         (kb-name (knowledge-base-name target-kb))
         (picture-class
           (or (unit.exists.p *kee-picture-class-name* kb-name)
               (create.unit *kee-picture-class-name*
                            target-kb
                            nil
                            nil
                            "Reconstructed KEEpictures class.")))
         (item-class
           (or (unit.exists.p *kee-picture-item-class-name* kb-name)
               (create.unit *kee-picture-item-class-name*
                            target-kb
                            nil
                            nil
                            "Reconstructed KEEpicture items class."))))
    (values picture-class item-class)))

(defun picture-keyword (value &optional (default :rectangle))
  (cond ((null value) default)
        ((keywordp value) value)
        ((symbolp value) (intern (symbol-name value) "KEYWORD"))
        ((stringp value) (intern (string-upcase value) "KEYWORD"))
        (t default)))

(defun create.kee.picture
    (name &key kb (width 320) (height 180) label (background "#FFFFFF"))
  "Create a reconstructed KEEpicture as an ordinary KEE unit.

This is a support API for experiments and demos. It models a KEEpicture as a
unit under KEE.PICTURES with child picture-item units, not as recovered
IntelliCorp source or an exact original constructor."
  (let ((target-kb (kee-picture-kb kb)))
    (multiple-value-bind (picture-class item-class)
        (ensure-kee-picture-classes target-kb)
      (declare (ignore item-class))
      (let ((picture (create.unit name
                                  target-kb
                                  nil
                                  (list picture-class)
                                  "Reconstructed KEEpicture.")))
        (put.value picture 'picture.width width)
        (put.value picture 'picture.height height)
        (put.value picture 'background background)
        (when label
          (put.value picture 'label label))
        picture))))

(defun list.kee.pictures (&optional kb-designator)
  "Return reconstructed KEEpicture units in KB-DESIGNATOR."
  (let* ((target-kb (kee-picture-kb kb-designator))
         (class (unit.exists.p *kee-picture-class-name*
                               (knowledge-base-name target-kb))))
    (sort (and class (copy-list (unit.children class 'member)))
          #'string<
          :key #'unit.name)))

(defun create.picture.item
    (picture-designator name kind
     &key (x 0) (y 0) (width 120) (height 40) text label
       (fill "#FBFCFD") (stroke "#8090A0") target-unit target-kb target-slot
       target-facet active-image min max)
  "Create a reconstructed picture item inside PICTURE-DESIGNATOR.

Supported item kinds are currently :RECTANGLE, :TEXT, :VALUE, and
:ACTIVE-IMAGE. :VALUE items read TARGET-UNIT/TARGET-SLOT. :ACTIVE-IMAGE items
reference an existing ActiveImage unit through ACTIVE-IMAGE."
  (let* ((picture (unit picture-designator))
         (target-picture-kb (unit.kb picture)))
    (multiple-value-bind (picture-class item-class)
        (ensure-kee-picture-classes target-picture-kb)
      (declare (ignore picture-class))
      (let ((item (create.unit name
                               target-picture-kb
                               nil
                               (list item-class picture)
                               "Reconstructed KEEpicture item.")))
        (put.value item 'picture.kind (picture-keyword kind))
        (put.value item 'x x)
        (put.value item 'y y)
        (put.value item 'width width)
        (put.value item 'height height)
        (put.value item 'fill fill)
        (put.value item 'stroke stroke)
        (when text
          (put.value item 'text text))
        (when label
          (put.value item 'label label))
        (when target-unit
          (let ((target (unit target-unit target-kb)))
            (put.value item 'target.unit (unit.name target))
            (put.value item 'target.kb (kb.name (unit.kb target)))))
        (when target-slot
          (put.value item 'target.slot target-slot))
        (when target-facet
          (put.value item 'target.facet target-facet))
        (when active-image
          (put.value item 'active.image (unit.name (unit active-image))))
        (when min
          (put.value item 'min.value min))
        (when max
          (put.value item 'max.value max))
        item))))

(defun picture.items (picture-designator)
  "Return picture item units contained by PICTURE-DESIGNATOR."
  (sort (copy-list (unit.children picture-designator 'member))
        #'string<
        :key #'unit.name))

(defun picture-number (value &optional (default 0))
  (cond ((numberp value) value)
        ((stringp value)
         (or (ignore-errors (parse-integer value :junk-allowed t))
             default))
        (t default)))

(defun picture-target-designator (item)
  (let ((target-name (get.value item 'target.unit))
        (target-kb (get.value item 'target.kb)))
    (when target-name
      (list target-name target-kb))))

(defun picture-item-values (item)
  (let ((target (picture-target-designator item))
        (slot-name (get.value item 'target.slot))
        (facet (get.value item 'target.facet)))
    (when (and target slot-name)
      (if facet
          (slot.facet.values target slot-name facet)
          (get.values target slot-name)))))

(defun picture.item.report (item-designator)
  (let* ((item (unit item-designator))
         (kind (picture-keyword (get.value item 'picture.kind)))
         (active-image-name (get.value item 'active.image))
         (active-image-report
           (and active-image-name
                (active.image.report active-image-name)))
         (values (or (and active-image-report
                          (getf active-image-report :values))
                     (picture-item-values item))))
    (list :name (unit.name item)
          :kb (kb.name (unit.kb item))
          :kind kind
          :x (picture-number (get.value item 'x) 0)
          :y (picture-number (get.value item 'y) 0)
          :width (picture-number (get.value item 'width) 120)
          :height (picture-number (get.value item 'height) 40)
          :text (get.value item 'text)
          :label (or (get.value item 'label)
                     (and active-image-report
                          (getf active-image-report :label))
                     (unit.name item))
          :fill (or (get.value item 'fill) "#FBFCFD")
          :stroke (or (get.value item 'stroke) "#8090A0")
          :target-unit (get.value item 'target.unit)
          :target-kb (get.value item 'target.kb)
          :target-slot (get.value item 'target.slot)
          :target-facet (get.value item 'target.facet)
          :active-image active-image-name
          :active-image-report active-image-report
          :values values
          :value (first values))))

(defun kee.picture.report (picture-designator)
  "Return a plist describing PICTURE-DESIGNATOR and its current item values."
  (let ((picture (unit picture-designator)))
    (list :name (unit.name picture)
          :kb (kb.name (unit.kb picture))
          :label (or (get.value picture 'label) (unit.name picture))
          :width (picture-number (get.value picture 'picture.width) 320)
          :height (picture-number (get.value picture 'picture.height) 180)
          :background (or (get.value picture 'background) "#FFFFFF")
          :items (mapcar #'picture.item.report
                         (picture.items picture)))))

(defun picture-svg-string (value)
  (active-image-html-escape-string value))

(defun picture-svg-attrs (item)
  (format nil
          "class='kee-picture-item ~A' data-picture-item='~A'"
          (string-downcase (symbol-name (getf item :kind)))
          (picture-svg-string (getf item :name))))

(defun picture-percent (value min max)
  (if (= min max)
      0
      (active-image-clamp (* 100 (/ (- value min) (- max min))) 0 100)))

(defun picture-rect-item-svg (item)
  (format nil
          "<rect ~A x='~A' y='~A' width='~A' height='~A' rx='4' fill='~A' stroke='~A'></rect>"
          (picture-svg-attrs item)
          (getf item :x)
          (getf item :y)
          (getf item :width)
          (getf item :height)
          (picture-svg-string (getf item :fill))
          (picture-svg-string (getf item :stroke))))

(defun picture-text-item-svg (item)
  (format nil
          "<text ~A x='~A' y='~A' fill='~A' font-size='12' font-family='monospace'>~A</text>"
          (picture-svg-attrs item)
          (getf item :x)
          (getf item :y)
          (picture-svg-string (getf item :stroke))
          (picture-svg-string (or (getf item :text)
                                  (getf item :label)))))

(defun picture-value-item-svg (item)
  (let ((x (getf item :x))
        (y (getf item :y)))
    (format nil
            "<g ~A><text x='~A' y='~A' fill='#66707A' font-size='11' font-family='monospace'>~A</text><text x='~A' y='~A' fill='#1E252D' font-size='14' font-family='monospace'>~A</text></g>"
            (picture-svg-attrs item)
            x
            y
            (picture-svg-string (getf item :label))
            x
            (+ y 18)
            (picture-svg-string (or (getf item :value) "NIL")))))

(defun picture-active-image-value-text (report)
  (active-image-string (getf report :value)))

(defun picture-active-image-meter-svg (item image)
  (let* ((x (getf item :x))
         (y (getf item :y))
         (width (getf item :width))
         (height (getf item :height))
         (value (picture-number (getf image :value) 0))
         (min (picture-number (getf image :min) 0))
         (max (picture-number (getf image :max) (max 100 value)))
         (bar-width (* (- width 16) (/ (picture-percent value min max) 100))))
    (format nil
            "<g ~A><rect x='~A' y='~A' width='~A' height='~A' rx='5' fill='#FBFCFD' stroke='#8090A0'></rect><text x='~A' y='~A' fill='#1E252D' font-size='11' font-family='monospace'>~A</text><rect x='~A' y='~A' width='~A' height='12' fill='#E8F2FB' stroke='#B7D0E6'></rect><rect x='~A' y='~A' width='~,2F' height='12' fill='#1C6FB8'></rect><text x='~A' y='~A' fill='#66707A' font-size='10' font-family='monospace'>~A</text></g>"
            (picture-svg-attrs item)
            x y width height
            (+ x 8) (+ y 15)
            (picture-svg-string (getf image :label))
            (+ x 8) (+ y 24) (- width 16)
            (+ x 8) (+ y 24) bar-width
            (+ x 8) (+ y 48)
            (picture-svg-string (picture-active-image-value-text image)))))

(defun picture-active-image-switch-svg (item image)
  (let* ((x (getf item :x))
         (y (getf item :y))
         (width (getf item :width))
         (height (getf item :height))
         (on-p (active-image-switch-on-p (getf image :value))))
    (format nil
            "<g ~A><rect x='~A' y='~A' width='~A' height='~A' rx='5' fill='~A' stroke='#8090A0'></rect><text x='~A' y='~A' fill='#1E252D' font-size='11' font-family='monospace'>~A</text><text x='~A' y='~A' fill='#1E252D' font-size='14' font-family='monospace'>~A</text></g>"
            (picture-svg-attrs item)
            x y width height
            (if on-p "#EEF7ED" "#FFE7E4")
            (+ x 8) (+ y 15)
            (picture-svg-string (getf image :label))
            (+ x 8) (+ y 35)
            (if on-p "ON" "OFF"))))

(defun picture-active-image-generic-svg (item image)
  (let ((item-with-value
          (append (list :value (getf image :value)
                        :label (getf image :label))
                  item)))
    (picture-value-item-svg item-with-value)))

(defun picture-active-image-item-svg (item)
  (let* ((image (getf item :active-image-report))
         (widget (and image (getf image :widget))))
    (cond ((null image)
           (picture-value-item-svg item))
          ((member widget '(:gauge :thermometer))
           (picture-active-image-meter-svg item image))
          ((eq widget :switch)
           (picture-active-image-switch-svg item image))
          (t (picture-active-image-generic-svg item image)))))

(defun picture-item-svg (item)
  (case (getf item :kind)
    (:rectangle (picture-rect-item-svg item))
    (:text (picture-text-item-svg item))
    (:value (picture-value-item-svg item))
    (:active-image (picture-active-image-item-svg item))
    (otherwise (picture-rect-item-svg item))))

(defun kee.picture.svg (picture-designator)
  "Return an SVG rendering of reconstructed KEEpicture PICTURE-DESIGNATOR."
  (let ((report (kee.picture.report picture-designator)))
    (with-output-to-string (stream)
      (format stream
              "<svg class='kee-picture' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 ~A ~A' role='img' aria-label='~A'>"
              (getf report :width)
              (getf report :height)
              (picture-svg-string (getf report :label)))
      (format stream
              "<rect class='kee-picture-background' x='0' y='0' width='~A' height='~A' fill='~A'></rect>"
              (getf report :width)
              (getf report :height)
              (picture-svg-string (getf report :background)))
      (dolist (item (getf report :items))
        (write-string (picture-item-svg item) stream))
      (write-string "</svg>" stream))))

(defun write.kee.picture.svg (stream picture-designator)
  "Write an SVG rendering of PICTURE-DESIGNATOR to STREAM."
  (write-string (kee.picture.svg picture-designator) stream)
  (values))
