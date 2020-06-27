(defproject eurogames "0.1.0-SNAPSHOT" 
  :description "Games info sandpit."
  :url "https://alphajuliet.com/ns/eurogames/" 
  :license {:name "EPL-2.0 OR GPL-2.0-or-later WITH Classpath-exception-2.0"}
  :dependencies [[org.clojure/clojure "1.10.1"]
                 [clj-http "3.10.1"]
                 [cheshire "5.10.0"]
                 [org.clojure/data.xml "0.0.8"]
                 [org.clojure/data.zip "1.0.0"]]
  :repl-options {:init-ns eurogames.core})
