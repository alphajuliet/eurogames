(ns cli.games
  (:require [cheshire.core :as json]
            [clojure.string :as str]
            [clojure.tools.cli :refer [parse-opts]]
            [cli.output :as output]
            [babashka.fs :as fs]
            [pod.babashka.go-sqlite3 :as sql]))

(def cli-version "0.1.0")

(def cli-options
  [["-h" "--help" "Show help information"]
   ["-v" "--version" "Show version information"]
   ["-f" "--format FORMAT" "Output format: json (default), edn, plain, or table"
    :default "json"
    :validate [#(contains? #{"json" "edn" "plain" "table"} %) "Must be one of: json, edn, plain, table"]]
   ["-d" "--db PATH" "Database file path"
    :default "data/games.db"]
   ["-b" "--backup-dir PATH" "Backup directory path"
    :default "data/backup"]
   [nil "--verbose" "Enable verbose output"]])

(defn current-date
  "Return the current date in the format YYYY-MM-DD"
  []
  (let [date (java.time.LocalDate/now)]
    (format "%04d-%02d-%02d" (.getYear date) (.getMonthValue date) (.getDayOfMonth date))))

;; ------------------------------------------------------
(defn print-output
  "Print data according to the specified format"
  [data & {:keys [format] :or {format "json"}}]
  (println (output/format-output data format)))

(defn get-db [options]
  (or (:db options) "data/games.db"))

(defn list-games
  "List all games"
  [status options]
  (try
    (let [db (get-db options)
          q "SELECT notes.id, bgg.name FROM notes 
             LEFT JOIN bgg ON notes.id = bgg.id 
             WHERE status = ?
             ORDER BY name ASC"]
      (print-output (sql/query db [q status]) :format (:format options)))
    (catch Exception e
      (println (.getMessage e)))))

(defn lookup
  "Lookup games that match on title"
  [title options]
  (try
    (let [db (get-db options)
          q "SELECT * FROM bgg WHERE name LIKE ?"]
      (print-output (sql/query db [q (str "%" title "%")] :format (:format options))))
    (catch Exception e
      (println (.getMessage e)))))

(defn view-game
  "View a game with a given ID"
  [id options]
  (let [db (get-db options)
        q (str "SELECT * FROM bgg 
                LEFT JOIN notes ON notes.id = bgg.id 
                WHERE bgg.id = ?")]
    (print-output (sql/query db [q id]) :format (:format options))))

(defn last-played
  "Show last n games played"
  [n options]
  (let [db (get-db options)
        q "SELECT * FROM last_played LIMIT ?"]
    (print-output (sql/query db [q n]) :format (:format options))))

#_(defn view-release
  "Show a release and the tracks"
  [id options]
  (let [db (get-db options)
        tracks (sql/query db ["SELECT title, track_number, tracks.id, ISRC, length FROM releases
                              LEFT JOIN instances ON instances.release = releases.id
                              LEFT JOIN tracks ON instances.id = tracks.id
                              WHERE releases.id = ?
                              ORDER BY track_number" id])
        rel (sql/query db ["SELECT * FROM releases WHERE id = ?" id])
        duration (->> tracks
                      (map :length)
                      (map mmss-to-seconds)
                      (reduce +)
                      seconds-to-mmss)]
    (print-output (-> rel
                      first
                      (into {:tracks tracks :duration duration}))
                  :format (:format options))))

#_(defn add-track
  "Create a new track with minimal info"
  [title options]
  (try
    (let [db (get-db options)
          info {:artist "Cyjet"
                :type "Original"
                :title title
                :length "00:00"
                :year (current-year)}
          fields (->> info
                      keys
                      (map name)
                      (str/join ", "))
          values (->> info
                      vals
                      (map wrap-quote)
                      (str/join ", "))]
      (sql/execute! db ["INSERT INTO tracks (?) VALUES (?)" fields values])
      (println "OK"))
    (catch Exception e
      (println (.getMessage e)))))

#_(defn update-track
  "Update track info"
  [id field value options]
  (try
    (let [db (get-db options)
          q (str "UPDATE tracks SET " field " = ? WHERE id = ?")]
      (sql/execute! db [q value id])
      (println "OK"))
    (catch Exception e
      (println (.getMessage e)))))


(defn query
  "Query the db with SQL. No input checking is done."
  [query-str options]
  (let [db (get-db options)]
    (as-> query-str <>
      (sql/query db <>)
      (print-output <> :format (:format options)))))

(defn export-data [filename options]
  (let [db (get-db options)
        bgg-data (sql/query db "SELECT * FROM bgg")
        notes-data (sql/query db "SELECT * FROM notes")
        log-data (sql/query db "SELECT * FROM log")
        all-data {:bgg bgg-data
                  :notes notes-data
                  :log log-data}]
    (spit filename (json/generate-string all-data {:pretty true}))
    (println "Data exported to" filename)))

(defn backup
  "Create a backup of the database file to the nominated folder"
  [options]
  (let [db-file (:db-file options)
        backup-dir (:backup-dir options)
        timestamp (current-date)
        db-backup (fs/file-name (str/replace db-file #"\.db$" (str "_" timestamp ".db")))
        backup-file (fs/path backup-dir db-backup)]
    (fs/create-dirs backup-dir)
    (fs/copy db-file backup-file {:replace-existing true})
    (println "Backup created:" (str backup-file))))

(defn usage [options-summary]
  (str "Eurogames CLI

Usage: bb -m cli.games [options] command [args...]

Options:
" options-summary "

Commands:
    help                                 Show this help
    version                              Show version information
     
    list [<status>]                      List games with a given status
    lookup <name>                        Lookup games by name
    id <id>                              Show game info
    played [<limit>]                     Show last n games played

    new <id>                             Add a new game
    update-notes <id> <field> <value>    Update game notes

    query <sql>                          Run SQL query
    export-data <filename>               Export data to file
    backup                               Create a backup of the database"))

(defn help
  "Print help message"
  [options]
  (println (usage (:summary options))))

(defn version
  "Print version information"
  []
  (println "Eurogames CLI version" cli-version))

(defn -main
  [& args]
  (let [{:keys [options arguments errors summary]} (parse-opts args cli-options)]
    (cond
      ;; Handle global flags
      (:help options) (do (println (usage summary)) 0)
      (:version options) (do (version) 0)
      errors (do (println "Error:" (str/join "\n" errors)) 1)
      
      ;; Handle commands
      :else (let [cmd (first arguments)
                  cmd-args (rest arguments)]
              (case cmd
                "help" (help {:summary summary})
                "version" (version)
                "list" (list-games (or (first cmd-args) "Playing") options)
                "lookup" (lookup (first cmd-args) options)
                "id" (view-game (first cmd-args) options)
                "played" (last-played (or (first cmd-args) 100) options)
                "query" (query (str/join " " cmd-args) options)
                "export-data" (export-data (first cmd-args) options)
                "backup" (backup {:db-file (:db options) :backup-dir (:backup-dir options)})
                ;; else
                (do
                  (println "Unknown command:" cmd)
                  (println (usage summary))
                  1))))))

;; The End
