;; Pre-defined angle-vector to reach charged module
(setq avs (list #f(20.0 75.6304 80.2141 -11.4592 98.5487 0.0 95.111 0.0 0 0)
                #f(382.441 -5.42997 80.4294 -164.236 82.3799 2.74303 98.2338 0.27869 58 56)
                #f(363.818 -33.6209 66.9162 104.248 101.035 -109.471 79.8647 -52.4996 58 56)))
(setq tms (list 2000 4000 4000))

(send *ri* :angle-vector-sequence avs tms)
(unix:sleep 10)

;; angle-vector here should be decided by image recognition
(send *ri* :angle-vector
      (send *fetch* :angle-vector
            #f(354.395 -13.1424 84.8679 99.1065 92.4874 -142.43 46.1147 -43.2052 55.0564 75.1208))
      2000)
(send *ri* :wait-interpolation)
(send *ri* :start-grasp :wait t)

;; Reset arm
(send *ri* :angle-vector (send *fetch* :rarm :move-end-pos #f(0 0 50) :world) 2000)
(send *ri* :wait-interpolation)
(send *ri* :angle-vector-sequence (reverse avs) (reverse tms))
