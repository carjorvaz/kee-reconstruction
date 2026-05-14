(asdf:defsystem #:kee-core
  :description "Evidence-led reconstruction of the KEE core object system."
  :author "Carlos Vaz and Codex"
  :license "Research prototype"
  :serial t
  :components ((:file "src/package")
               (:file "src/core")
               (:file "src/active-images")
               (:file "src/pictures")
               (:file "src/traces")
               (:file "src/worlds")
               (:file "src/rules")
               (:file "src/inspect")
               (:file "src/graph")
               (:file "src/viewer")
               (:file "src/browser")))
