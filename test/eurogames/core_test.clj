(ns eurogames.core-test
  (:require [clojure.test :refer [deftest testing is]]
            [eurogames.core :as e]))

(deftest bgg-test
  (testing "Get data from BGG"
    (let [data (e/game-details (e/bgg-game 35677))]
      (is "35677" (:id data))
      (is "Le Havre" (:name data)))))

;; The End