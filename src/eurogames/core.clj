(ns eurogames.core
  (:require [clj-http.client :as client]
            [cheshire.core :as json]
            [clj-xpath.core :as xpath]))

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

(def get-games
  "Get all the games in Airtable"
  (memoize
   (fn []
     (let [api-key (System/getenv "AIRTABLE_API_KEY")
           app-id "appawmxJtv4xJYiT3"
           table "games"]
       (-> (get-airtable-records api-key app-id table "")
           (:body)
           (json/parse-string true)
           (:records))))))

(defn bgg-game
  "Get details of a given game"
  [game-id]
  (let [uri (str "https://www.boardgamegeek.com/xmlapi/boardgame/" game-id "?stats=1")]
    (-> uri
        (slurp)
        (xpath/xml->doc))))

(defn game-details
  "Extract the key detail from the BGG XML data."
  [xml]
  {:id (:objectid (xpath/$x:attrs "//boardgame" xml))
   :name (first (xpath/$x:text+ "//boardgame/name[@primary='true']" xml))
   :year (xpath/$x:text "//yearpublished" xml)
   :weight (xpath/$x:text "//averageweight" xml)
   :ranking (first (xpath/$x:text* "//rank[@name='boardgame']/@value" xml))})

(defn compare-games
  "Compare my records and BGG"
  []
  (for [game (get-games)]
    (let [record-id (:id game)
          mine (:fields game)
          bgg (game-details (bgg-game (:BGG_ID mine)))
          my-ranking (:BGG_ranking mine)
          bgg-ranking (Integer. (:ranking bgg))]

      (when (not= my-ranking bgg-ranking)
        {:name (:name bgg)
         :my-ranking my-ranking
         :bgg-ranking bgg-ranking}))))
;; The End