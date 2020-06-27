(ns eurogames.core
  (:require [clj-http.client :as client]
            [cheshire.core :as json]
            [clojure.data.xml :as xml]
            [clojure.zip :as zip]
            [clojure.data.zip.xml :as zx]))

(defn get-airtable-records
  "Read a single page of records from Airtable."
  [api-key app-id table offset]
  (let [uri (str "https://api.airtable.com/v0/" app-id "/" table)]
    (client/get uri {:headers {:Authorization (str "Bearer " api-key)}
                     :accept :json
                     :query {:offset offset}})))

;;----------------
;; Aggregate data over multiple paginated calls

#_(defn read-table
    [api-key app-id table records offset]
    (let [resp (get-data api-key app-id table offset)
          data (concat records (:records resp))]
      (if (contains? :offset resp)
        (read-table api-key app-id table data (:offset resp))
        ;else
        data)))

(defn get-games
  "Get all the games in Airtable"
  []
  (let [api-key (System/getenv "AIRTABLE_API_KEY")
        app-id "appawmxJtv4xJYiT3"
        table "games"]
    (-> (get-airtable-records api-key app-id table "")
        (:body)
        (json/parse-string true)
        (:records))))

(defn bgg-game
  "Get details of a given game"
  [game-id]
  (let [uri (str "https://www.boardgamegeek.com/xmlapi/boardgame/" game-id)]
    (-> (client/get uri {:query-params {:stats 1}})
        (:body)
        (java.io.StringReader.)
        (xml/parse)
        (zip/xml-zip))))

(defn game-details
  [zipper]
  {:name (zx/xml1-> zipper 
                    :boardgames 
                    :boardgame 
                    :name 
                    zx/text)
   :year (zx/xml1-> zipper 
                    :boardgames 
                    :boardgame 
                    :yearpublished 
                    zx/text)
   :weight (zx/xml1-> zipper 
                      :boardgames 
                      :boardgame 
                      :statistics 
                      :ratings 
                      :averageweight 
                      zx/text)
   :ranking (zx/xml1-> zipper 
                       :boardgames 
                       :boardgame 
                       :statistics
                       :ratings 
                       :ranks 
                       :rank
                       (zx/attr= :name "boardgame")
                       (zx/attr :value))})

;; The End