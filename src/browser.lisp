(in-package #:kee)

(defparameter *browser-commands*
  '((help "Show browser commands.")
    (kbs "List knowledge bases.")
    (units "List units in the current or named KB.")
    (unit "Inspect a unit: (unit NAME) or (unit NAME KB).")
    (slot "Inspect a slot: (slot UNIT SLOT) or (slot UNIT SLOT KB).")
    (worlds "List worlds, optionally limited: (worlds 20) or (worlds all).")
    (world "Inspect a world: (world NAME).")
    (summary "Print the compact KB/unit/world browser summary.")
    (dump-kb "Print a readable reconstructed KB dump: (dump-kb) or (dump-kb KB).")
    (unit-graph "Print a DOT unit hierarchy graph: (unit-graph) or (unit-graph KB).")
    (world-graph "Print a DOT worlds graph: (world-graph 20) or (world-graph all).")
    (viewer "Print a standalone HTML graph viewer: (viewer 40) or (viewer all).")
    (goto-kb "Set the current KB: (goto-kb NAME).")
    (goto-world "Set the current world: (goto-world NAME).")
    (current "Show the current KB and world.")
    (quit "Leave the interactive browser.")))

(defun browser.commands ()
  "Return the command table used by the terminal browser."
  (copy-tree *browser-commands*))

(defun command-name (command)
  (and (symbolp command) (symbol-name command)))

(defun command-named-p (command &rest names)
  (let ((command-name (command-name command)))
    (and command-name
         (some (lambda (name)
                 (string= command-name (string-upcase name)))
               names))))

(defun command-form (command)
  (if (consp command) command (list command)))

(defun command-limit (args default)
  (let ((value (first args)))
    (cond ((null args) default)
          ((command-named-p value "all") nil)
          ((and (integerp value) (not (minusp value))) value)
          (t (error "Expected a non-negative limit or ALL, got ~S." value)))))

(defun take-command-items (items limit)
  (if limit
      (subseq items 0 (min limit (length items)))
      items))

(defun print-browser-help (stream)
  (format stream "~&Commands:")
  (dolist (entry (browser.commands))
    (format stream "~&  ~A - ~A" (first entry) (second entry))))

(defun print-browser-kbs (stream)
  (format stream "~&Knowledge Bases: ~{~S~^, ~}" (list.kbs)))

(defun print-browser-units (stream &optional kb-designator)
  (let ((unit-names (mapcar #'unit.name (list.units kb-designator))))
    (format stream "~&Units~@[ in ~S~]: ~{~S~^, ~}" kb-designator unit-names)))

(defun unit-command-designator (unit-name kb-name)
  (if kb-name (list unit-name kb-name) unit-name))

(defun print-browser-unit (stream unit-name &optional kb-name)
  (print-unit stream (inspect.unit (unit-command-designator unit-name kb-name))))

(defun print-browser-slot (stream unit-name slot-name &optional kb-name)
  (print-slot stream (inspect.slot (unit-command-designator unit-name kb-name)
                                   slot-name)
              0))

(defun print-world-summary (stream world-report)
  (format stream "~&  ~S parent ~S inconsistent? ~S facts ~D nogoods ~D"
          (getf world-report :name)
          (getf world-report :parent)
          (getf world-report :inconsistent-p)
          (length (getf world-report :facts))
          (length (getf world-report :nogoods))))

(defun print-browser-worlds (stream &optional (limit 20))
  (let ((worlds (take-command-items (inspect.world.tree) limit)))
    (format stream "~&Worlds~@[ first ~D~]:" limit)
    (dolist (world worlds)
      (print-world-summary stream world))))

(defun print-browser-world (stream world-name)
  (print-world stream (inspect.world world-name)))

(defun print-browser-current (stream)
  (format stream "~&Current KB: ~S"
          (and *current-kb* (kb.name *current-kb*)))
  (format stream "~&Current world: ~S"
          (and (current.world) (get.world.name (current.world)))))

(defun browser.command (command &key (stream *standard-output*))
  "Execute one terminal-browser command form.

Returns :CONTINUE for ordinary commands and :QUIT for quit commands."
  (destructuring-bind (name &rest args) (command-form command)
    (cond ((or (command-named-p name "help")
               (command-named-p name "?"))
           (print-browser-help stream)
           :continue)
          ((command-named-p name "kbs")
           (print-browser-kbs stream)
           :continue)
          ((command-named-p name "units")
           (destructuring-bind (&optional kb-name) args
             (print-browser-units stream kb-name))
           :continue)
          ((command-named-p name "unit")
           (destructuring-bind (unit-name &optional kb-name) args
             (print-browser-unit stream unit-name kb-name))
           :continue)
          ((command-named-p name "slot")
           (destructuring-bind (unit-name slot-name &optional kb-name) args
             (print-browser-slot stream unit-name slot-name kb-name))
           :continue)
          ((command-named-p name "worlds")
           (print-browser-worlds stream (command-limit args 20))
           :continue)
          ((command-named-p name "world")
           (destructuring-bind (world-name) args
             (print-browser-world stream world-name))
           :continue)
          ((command-named-p name "summary")
           (print.browser :stream stream)
           :continue)
          ((command-named-p name "dump-kb" "dump.kb")
           (destructuring-bind (&optional kb-name) args
             (write.kb.dump stream kb-name))
           :continue)
          ((command-named-p name "unit-graph" "unit.graph")
           (destructuring-bind (&optional kb-name) args
             (write.unit.graph.dot stream :kb kb-name))
           :continue)
          ((command-named-p name "world-graph" "world.graph")
           (write.world.graph.dot stream :limit (command-limit args 20))
           :continue)
          ((command-named-p name "viewer" "html")
           (write.kee.viewer.html stream :world-limit (command-limit args 40))
           :continue)
          ((command-named-p name "goto-kb" "goto.kb")
           (destructuring-bind (kb-name) args
             (goto.kb kb-name)
             (format stream "~&Current KB: ~S" kb-name))
           :continue)
          ((command-named-p name "goto-world" "goto.world")
           (destructuring-bind (world-name) args
             (goto.world world-name)
             (format stream "~&Current world: ~S"
                     (get.world.name (current.world))))
           :continue)
          ((command-named-p name "current")
           (print-browser-current stream)
           :continue)
          ((command-named-p name "quit" "q" "exit")
           (format stream "~&Leaving KEE browser.")
           :quit)
          (t (error "Unknown browser command ~S. Try (HELP)." name)))))

(defun browse (&key (input *standard-input*) (output *standard-output*))
  "Run a small form-oriented terminal browser for the current KEE image."
  (format output "~&KEE browser. Type (help) for commands, (quit) to leave.~%")
  (loop
    (format output "~&kee> ")
    (finish-output output)
    (let ((form (read input nil :eof)))
      (when (eq form :eof)
        (format output "~&End of input.")
        (return :eof))
      (let ((result
              (handler-case
                  (browser.command form :stream output)
                (error (condition)
                  (format output "~&Error: ~A" condition)
                  :continue))))
        (when (eq result :quit)
          (return :quit))))))
