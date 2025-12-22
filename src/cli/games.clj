(ns cli.games
  (:require [cheshire.core :as json]
            [clojure.string :as str]
            [clojure.tools.cli :refer [parse-opts]]
            [clojure.data.csv :as csv]
            [cli.output :as output]
            [clojure.java.shell :as shell]))

(def cli-version "0.2.0")

(def cli-options
  [["-h" "--help" "Show help information"]
   ["-v" "--version" "Show version information"]
   ["-f" "--format FORMAT" "Output format: table (default), json, edn, or plain"
    :default "table"
    :validate [#(contains? #{"json" "edn" "plain" "table"} %) "Must be one of: json, edn, plain, table"]]
   ["-s" "--sort-by COLUMN" "Sort output by the specified column (for table format)"
    :default nil]
   [nil "--verbose" "Enable verbose output"]])

(defn current-date
  "Return the current date in the format YYYY-MM-DD"
  []
  (let [date (java.time.LocalDate/now)]
    (format "%04d-%02d-%02d" (.getYear date) (.getMonthValue date) (.getDayOfMonth date))))

;; ------------------------------------------------------
;; D1 Database Functions
;; ------------------------------------------------------

(defn escape-sql
  "Escape single quotes in SQL strings"
  [s]
  (str/replace (str s) "'" "''"))

(defn sql-string
  "Wrap a value in SQL single quotes with proper escaping"
  [s]
  (str "'" (escape-sql s) "'"))

(defn d1-query
  "Execute a SQL query against D1 and return results"
  [sql-query]
  (let [{:keys [exit out err]} (shell/sh "wrangler" "d1" "execute" "games"
                                          "--remote" "--json"
                                          "--command" sql-query)]
    (if (zero? exit)
      (-> out (json/parse-string true) first :results)
      (throw (ex-info "D1 query failed" {:error err :sql sql-query})))))

(defn d1-execute!
  "Execute a SQL statement against D1 (for INSERT/UPDATE/DELETE)"
  [sql-statement]
  (let [{:keys [exit out err]} (shell/sh "wrangler" "d1" "execute" "games"
                                          "--remote" "--json"
                                          "--command" sql-statement)]
    (if (zero? exit)
      (-> out (json/parse-string true) first :meta)
      (throw (ex-info "D1 execute failed" {:error err :sql sql-statement})))))

;; ------------------------------------------------------
(defn print-output
  "Print data according to the specified format"
  [data & {:keys [format sort-by] :or {format "json"}}]
  (println (output/format-output data format :sort-by sort-by)))

(defn query
  "Query the db with SQL and print output."
  [sql-query options]
  (try
    (print-output (d1-query sql-query)
                  :format (:format options)
                  :sort-by (:sort-by options))
    (catch Exception e
      (println (.getMessage e)))))

(defn list-games
  "List all games"
  [status options]
  (query (str "SELECT id, name FROM game_list2 WHERE status = " (sql-string status)) options))

(defn lookup
  "Lookup games that match on title"
  [title options]
  (query (str "SELECT * FROM bgg WHERE name LIKE " (sql-string (str "%" title "%"))) options))

(defn view-game
  "View a game with a given ID"
  [id options]
  (query (str "SELECT * FROM game_list2 WHERE id = " id) (assoc options :format "json")))

(defn history
  "Show game history for a specific game"
  [id options]
  (query (str "SELECT * FROM played WHERE id = " id " ORDER BY date DESC") options))

(defn last-played
  "Show when the games were last played"
  [n options]
  (query (str "SELECT * FROM last_played LIMIT " n) options))

(defn recent
  "Show recent games played"
  [n options]
  (query (str "SELECT * FROM played LIMIT " n) options))

(defn stats
  "Show win statistics and totals"
  [options]
  (query "SELECT * FROM winner" options))

(defn insert-csv
  "Insert CSV data into the database"
  [id csv]
  (try
    (let [[header row] (csv/read-csv csv)
          values (map sql-string row)
          q1 (str "INSERT INTO bgg (" (str/join ", " header) ") VALUES (" (str/join ", " values) ")")
          q2 (str "INSERT INTO notes (id, status, platform) VALUES (" id ", 'Inbox', 'BGA')")]
      (d1-execute! q1)
      (d1-execute! q2)
      (println "OK"))
    (catch Exception e
      (println "Error in insert-csv:" (.getMessage e)))))

(defn update-csv
  "Update the bgg table with new CSV data"
  [id csv]
  (try
    (let [[header rows] (csv/read-csv csv)
          set-clauses (map #(str %1 " = " (sql-string %2)) header rows)
          q1 (str "UPDATE bgg SET " (str/join ", " set-clauses) " WHERE id = " id)]
      (d1-execute! q1)
      (println "OK"))
    (catch Exception e
      (println "Error in update-csv:" (.getMessage e)))))

(defn add-game
  "Get game data from BGG"
  [id]
  (try
    (let [{:keys [exit out err]} (shell/sh "src/sync/bgg.rkt" id)]
      (if (zero? exit)
        (insert-csv id out)
        (println "Error:" exit ":" err)))
    (catch Exception e
      (println "Error in add-game:" (.getMessage e)))))

(defn update-game-data
  "Update game data with latest data from BGG. Check first that the games exists in the db"
  [id]
  (try
    (if (seq (d1-query (str "SELECT 1 FROM bgg WHERE id = " id " LIMIT 1")))
      (let [{:keys [exit out err]} (shell/sh "src/sync/bgg.rkt" id)]
        (if (zero? exit)
          (update-csv id out)
          (println "Error:" exit ":" err)))
      ;; else
      (println "Game not found in database"))
    (catch Exception e
      (println "Error in update-game-data:" (.getMessage e)))))

(defn update-notes
  "Update game notes"
  [id field value]
  (try
    (let [qcheck (str "SELECT " field " FROM notes WHERE id = " id " LIMIT 1")
          q (str "UPDATE notes SET " field " = " (sql-string value) " WHERE id = " id)]
      (if (seq (d1-query qcheck))
        (do
          (d1-execute! q)
          (println "OK"))
        (println "Game not found")))
    (catch Exception e
      (println (.getMessage e)))))

(defn add-result
  "Add a game result"
  [id winner score]
  (try
    (let [date (current-date)
          qcheck (str "SELECT 1 FROM bgg WHERE id = " id " LIMIT 1")
          q (str "INSERT INTO log (date, id, winner, scores) VALUES ("
                 (sql-string date) ", " id ", " (sql-string winner) ", " (sql-string score) ")")]
      (if (seq (d1-query qcheck))
        (do
          (d1-execute! q)
          (println "OK"))
        (println "Game not found")))
    (catch Exception e
      (println (.getMessage e)))))

(defn adhoc-query
  "Query the db with SQL. No input checking is done."
  [query-str options]
  (print-output (d1-query query-str)
                :format (:format options)
                :sort-by (:sort-by options)))

(defn export-data [filename]
  (let [bgg-data (d1-query "SELECT * FROM bgg")
        notes-data (d1-query "SELECT * FROM notes")
        log-data (d1-query "SELECT * FROM log")
        all-data {:bgg bgg-data
                  :notes notes-data
                  :log log-data}]
    (spit filename (json/generate-string all-data {:pretty true}))
    (println "Data exported to" filename)))

(defn usage [options-summary]
  (str "Eurogames CLI (D1)

Usage: bb -m cli.games [options] command [args...]

Options:
" options-summary "

Commands:
    help                                 Show this help
    version                              Show version information

  Game Management:
    list [<status>]                      List games with a given status
    search <name>                        Search games by name
    show <id>                            Show detailed game info
    add <bgg-id>                         Add a new game from BGG
    sync <id>                            Update game data from BGG

  Game Play Tracking:
    play <id> <winner> [<score>]         Record a game result
    history <id>                         Show play history for a game
    last [<limit>]                       Show when games were last played
    recent [<limit>]                     Show recent game results

  Statistics & Analysis:
    stats                                Show win statistics and totals
    notes <id> <field> <value>           Update game notes

  Utilities:
    query <sql>                          Run custom SQL query
    export <filename>                    Export data to file"))

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
  (let [{:keys [options arguments errors summary]} (parse-opts args cli-options)
        [cmd & cmd-args] arguments]
    (cond
      ;; Handle global flags
      (:help options) (do (println (usage summary)) 0)
      (:version options) (do (version) 0)
      errors (do (println "Error:" (str/join "\n" errors)) 1)

      ;; Handle commands
      :else (case cmd
              "help" (help {:summary summary})
              "version" (version)
              "list" (list-games (or (first cmd-args) "Playing") options)
              "search" (lookup (first cmd-args) options)
              "show" (view-game (first cmd-args) options)
              "history" (history (first cmd-args) options)
              "last" (last-played (or (first cmd-args) 100) options)
              "recent" (recent (or (first cmd-args) 15) options)
              "stats" (stats options)
              "sync" (update-game-data (first cmd-args))
              "notes" (update-notes (first cmd-args) (second cmd-args) (nth cmd-args 2))
              "add" (add-game (first cmd-args))
              "play" (add-result (first cmd-args) (second cmd-args) (nth cmd-args 2))
              "query" (adhoc-query (str/join " " cmd-args) options)
              "export" (export-data (first cmd-args))
              ;; else
              (do
                (println "Unknown command:" cmd)
                (println (usage summary))
                1)))))
;; The End
