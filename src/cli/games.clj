(ns cli.games
  (:require [cheshire.core :as json]
            [clojure.string :as str]
            [clojure.tools.cli :refer [parse-opts]]
            [clojure.data.csv :as csv]
            [cli.output :as output]
            [clojure.java.shell :as shell]
            [babashka.fs :as fs]
            [pod.babashka.go-sqlite3 :as sql]))

(def cli-version "0.1.4")

(def cli-options
  [["-h" "--help" "Show help information"]
   ["-v" "--version" "Show version information"]
   ["-f" "--format FORMAT" "Output format: table (default), json, edn, or plain"
    :default "table"
    :validate [#(contains? #{"json" "edn" "plain" "table"} %) "Must be one of: json, edn, plain, table"]]
   ["-s" "--sort-by COLUMN" "Sort output by the specified column (for table format)"
    :default nil]
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
  [data & {:keys [format sort-by] :or {format "json"}}]
  (println (output/format-output data format :sort-by sort-by)))

(defn get-db [options]
  (or (:db options) "data/games.db"))

(defn list-games
  "List all games"
  [status options]
  (try
    (let [db (get-db options)
          q "SELECT id, name FROM game_list2 WHERE status = ?"]
      (print-output (sql/query db [q status]) 
                   :format (:format options)
                   :sort-by (:sort-by options)))
    (catch Exception e
      (println (.getMessage e)))))

(defn lookup
  "Lookup games that match on title"
  [title options]
  (try
    (let [db (get-db options)
          q "SELECT * FROM bgg WHERE name LIKE ?"]
      (print-output (sql/query db [q (str "%" title "%")]) 
                   :format (:format options)
                   :sort-by (:sort-by options)))
    (catch Exception e
      (println (.getMessage e)))))

(defn view-game
  "View a game with a given ID"
  [id options]
  (let [db (get-db options)
        q "SELECT * FROM game_list2 WHERE id = ?"]
    (print-output (sql/query db [q id]) 
                 :format (:format options)
                 :sort-by (:sort-by options))))

(defn history
  "Show game history for a specific game"
  [id options]
  (let [db (get-db options)
        q "SELECT * FROM played WHERE id = ? ORDER BY date DESC"]
    (print-output (sql/query db [q id]) 
                 :format (:format options)
                 :sort-by (:sort-by options))))

(defn last-played
  "Show when the games were last played"
  [n options]
  (let [db (get-db options)
        q "SELECT * FROM last_played LIMIT ?"]
    (print-output (sql/query db [q n]) 
                 :format (:format options)
                 :sort-by (:sort-by options))))

(defn results
  "Show the last n results"
  [n options]
  (let [db (get-db options)
        q "SELECT * FROM played LIMIT ?"]
    (print-output (sql/query db [q n]) 
                 :format (:format options)
                 :sort-by (:sort-by options))))

(defn wins
  "Show games won"
  [options]
  (let [db (get-db options)
        q "SELECT * FROM winner"]
    (print-output (sql/query db q) 
                 :format (:format options)
                 :sort-by (:sort-by options))))

(defn win-totals
  "Show total wins per player across all games"
  [options]
  (let [db (get-db options)
        q "SELECT 'Andrew' AS player, SUM(Andrew) AS total_wins FROM winner
           UNION
           SELECT 'Trish' AS player, SUM(Trish) AS total_wins FROM winner
           UNION
           SELECT 'Draw' AS player, SUM(Draw) AS total_wins FROM winner
           ORDER BY total_wins DESC"]
    (print-output (sql/query db q) 
                 :format (:format options)
                 :sort-by (:sort-by options))))

(defn insert-csv
  "Insert CSV data into the database"
  [id csv options]
  (try
    (let [db (get-db options)
          [header row] (csv/read-csv csv)
          values (map #(str "'" % "'") row)
          q1 (str "INSERT INTO bgg (" (str/join ", " header) ") VALUES (" (str/join ", " values) ")")
          q2 (str "INSERT INTO notes ( id, status, platform ) VALUES (" id ", 'Inbox', 'BGA')")] 
      (println q1)
      (println q2)
      (sql/execute! db q1)
      (sql/execute! db q2)
      (println "OK"))
    (catch Exception e
      (println "Error in insert-csv:" (.getMessage e)))))

(defn update-csv
  "Update the bgg table with new CSV data"
  [id csv options]
  (try
    (let [db (get-db options)
          [header rows] (csv/read-csv csv)
          assignments (->> (map (fn [h v] (str h " = '" v "'")) header rows)
                           (str/join ", "))
          q1 (str "UPDATE bgg SET " assignments " WHERE id = " id)]
      (sql/execute! db q1)
      (println "OK"))
    (catch Exception e
      (println "Error in update-csv:" (.getMessage e)))))

(defn add-game
  "Get game data from BGG"
  [id options]
  (try
    (let [{:keys [exit out err]} (shell/sh "src/sync/bgg.rkt" id)]
      (if (zero? exit)
        (insert-csv id out options)
        (println "Error:" exit ":" err)))
    (catch Exception e
      (println "Error in add-game:" (.getMessage e)))))

(defn update-game-data
  "Update game data with latest data from BGG. Check first that the games exists in the db"
  [id options]
  (try
    (let [db (get-db options)
          qcheck "SELECT 1 from bgg WHERE id = ? LIMIT 1"]
      (if (seq (sql/query db [qcheck id]))
        (let [{:keys [exit out err]} (shell/sh "src/sync/bgg.rkt" id)]
          (if (zero? exit)
            (update-csv id out options)
            (println "Error:" exit ":" err))) 
        ;; else
        (println "Game not found in database")))
    (catch Exception e
      (println "Error in update-game-data:" (.getMessage e)))))

(defn update-notes
  "Update game notes"
  [id field value options]
  (try
    (let [db (get-db options)
          qcheck "SELECT 1 from bgg WHERE id = ? LIMIT 1"
          q ["UPDATE notes SET " field " = ? WHERE id = ?"]]
      (if (seq (sql/query db [qcheck id]))
        (do
          (sql/execute! db [q value id])
          (println "OK"))
        (println "Game not found")))
    (catch Exception e
      (println (.getMessage e)))))

(defn add-result
  "Add a game result"
  [id winner score options]
  (try
    (let [db (get-db options)
          date (current-date)
          qcheck "SELECT 1 from bgg WHERE id = ? LIMIT 1"
          q "INSERT INTO log (date, id, winner, scores) VALUES (?, ?, ?, ?)"]
      (if (seq (sql/query db [qcheck id]))
        (do
          (sql/execute! db [q date id winner score])
          (println "OK"))
        (println "Game not found")))
    (catch Exception e
      (println (.getMessage e)))))

(defn query
  "Query the db with SQL. No input checking is done."
  [query-str options]
  (let [db (get-db options)]
    (as-> query-str <>
      (sql/query db <>)
      (print-output <> 
                   :format (:format options)
                   :sort-by (:sort-by options)))))

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
    history <id>                         Show game history
    last [<limit>]                       Show when games last played
    results [<limit>]                    Show the results of the latest games
    wins                                 Show games won
    win-totals                           Show total wins per player across all games

    add-game <id>                        Add a new game
    update <id>                          Update game with latest data from BGG
    update-notes <id> <field> <value>    Update game notes
    add-result <id> <winner> <score>     Add a game result

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
                "history" (history (first cmd-args) options)
                "last" (last-played (or (first cmd-args) 100) options)
                "results" (results (or (first cmd-args) 15) options)
                "wins" (wins options)
                "win-totals" (win-totals options)
                "update" (update-game-data (first cmd-args) options)
                "update-notes" (update-notes (first cmd-args) (second cmd-args) (nth cmd-args 2) options)
                "add-game" (add-game (first cmd-args) options)
                "add-result" (add-result (first cmd-args) (second cmd-args) (nth cmd-args 2) options)
                "query" (query (str/join " " cmd-args) options)
                "export-data" (export-data (first cmd-args) options)
                "backup" (backup {:db-file (:db options) :backup-dir (:backup-dir options)})
                ;; else
                (do
                  (println "Unknown command:" cmd)
                  (println (usage summary))
                  1))))))

;; The End
