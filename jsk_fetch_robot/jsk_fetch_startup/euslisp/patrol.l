#!/usr/bin/env roseus

(ros::roseus "patrol")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(ros::roseus-add-srvs "jsk_patrol")

(setq *place-name* (ros::get-param "~place_name"))
(setq *mail-title* (ros::get-param "~mail_title"))
(setq *from-address* (ros::get-param "~from_address"))
(setq *to-address* (ros::get-param "~to_address"))
(setq *message* (ros::get-param "~message"))


(defun call-mail-service (place-name
                          mail-title
                          from-address
                          to-address
                          message)
  (let (service-request-instance)
    (setq service-request-instance (instance jsk_patrol::PatrolMailNotifyRequest :init))
    (send service-request-instance :place_name
          (instance std_msgs::String :init :data place-name))
    (send service-request-instance :mail_title
          (instance std_msgs::String :init :data mail-title))
    (send service-request-instance :from_address
          (instance std_msgs::String :init :data from-address))
    (send service-request-instance :to_address
          (instance std_msgs::String :init :data to-address))
    (send service-request-instance :message
          (instance std_msgs::String :init :data message))
    (ros::service-call "/mail_notify/notify" service-request-instance)))


;; TODO *place-name* may be no more needed because fetch patrols a lot of areas
(defun go-to-kitchen ()
  (send *ri* :speak-jp "キッチンに向かうよ" :wait t)
  (go-to-spot "/eng2/7f/room73B2-sink-front1" (make-coords :pos #f(100 -1000 0)) t)
  (unix:sleep 1)
  (send *ri* :speak-jp "キッチンについたよ")
  (send *fetch* :head :neck-y :joint-angle -30)
  (send *fetch* :head :neck-p :joint-angle 40)
  (send *fetch* :torso_lift_joint :joint-angle 400)
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  ;; start taking photos
  (unix:sleep 7) ;; wait for camera image stabilization
  (call-mail-service "73B2 kitchen" ;; *place-name*
                     *mail-title*
                     *from-address*
                     *to-address*
                     *message*) ;; calling send mail service
  (send *ri* :speak-jp "かしゃっ")
  (send *fetch* :head :neck-y :joint-angle (+ 60 (send *fetch* :head :neck-y :joint-angle)))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  (unix:sleep 7) ;; wait for camera image stabilization
  (call-mail-service "73B2 kitchen" ;; *place-name*
                     *mail-title*
                     *from-address*
                     *to-address*
                     *message*) ;; calling send mail service
  (send *ri* :speak-jp "かしゃっ")
  (send *fetch* :head :neck-y :joint-angle (+ -120 (send *fetch* :head :neck-y :joint-angle)))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  (unix:sleep 7) ;; wait for camera image stabilization
  (call-mail-service "73B2 kitchen" ;; *place-name*
                     *mail-title*
                     *from-address*
                     *to-address*
                     *message*) ;; calling send mail service
  (send *ri* :speak-jp "かしゃっ")
  ;; stop taking photos
  (send *fetch* :reset-pose)
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  (send *ri* :wait-interpolation)
  )

(defun go-to-table ()
  (send *ri* :speak-jp "テーブルに向かうよ" :wait t)
  (go-to-spot "/eng2/7f/room73B2-table-side1" (make-coords :pos #f(100 -500 0)) t)
  (unix:sleep 1)
  (send *ri* :speak-jp "テーブルについたよ")
  (send *fetch* :head :neck-p :joint-angle 26.3)
  (send *fetch* :head :neck-y :joint-angle -5.9)
  (send *fetch* :torso_lift_joint :joint-angle 400)
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  ;; start taking photos
  (unix:sleep 7) ;; wait for camera image stabilization
  (call-mail-service "73B2 table" ;; *place-name*
                     *mail-title*
                     *from-address*
                     *to-address*
                     *message*) ;; calling send mail service
  (send *ri* :speak-jp "かしゃっ")
  (send *fetch* :head :neck-y :joint-angle (+ 60 (send *fetch* :head :neck-y :joint-angle)))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  (unix:sleep 7) ;; wait for camera image stabilization
  (call-mail-service "73B2 table" ;; *place-name*
                     *mail-title*
                     *from-address*
                     *to-address*
                     *message*) ;; calling send mail service
  (send *ri* :speak-jp "かしゃっ")
  (send *fetch* :head :neck-y :joint-angle (+ -120 (send *fetch* :head :neck-y :joint-angle)))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  (unix:sleep 7) ;; wait for camera image stabilization
  (call-mail-service "73B2 table" ;; *place-name*
                     *mail-title*
                     *from-address*
                     *to-address*
                     *message*) ;; calling send mail service
  (send *ri* :speak-jp "かしゃっ")
  ;; stop taking photos
  (send *fetch* :reset-pose)
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  (send *ri* :wait-interpolation)
  )

(defun go-to-73b2-center ()
  (send *ri* :speak-jp "部屋の真ん中に向かうよ" :wait t)
  (go-to-spot "/eng2/7f/room73B2-center" (make-coords :pos #f(0 -1000 0)) t)
  (unix:sleep 1)
  (send *ri* :speak-jp "部屋の真ん中に来たよ")
  (send *fetch* :head :neck-p :joint-angle 7.7)
  (send *fetch* :head :neck-y :joint-angle 32.0)
  (send *fetch* :torso_lift_joint :joint-angle 400)
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  ;; start taking photos
  (unix:sleep 7) ;; wait for camera image stabilization
  (call-mail-service "73B2 center" ;; *place-name*
                     *mail-title*
                     *from-address*
                     *to-address*
                     *message*) ;; calling send mail service
  (send *ri* :speak-jp "かしゃっ")
  (send *fetch* :head :neck-y :joint-angle (+ 60 (send *fetch* :head :neck-y :joint-angle)))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  (unix:sleep 7) ;; wait for camera image stabilization
  (call-mail-service "73B2 center" ;; *place-name*
                     *mail-title*
                     *from-address*
                     *to-address*
                     *message*) ;; calling send mail service
  (send *ri* :speak-jp "かしゃっ")
  (send *fetch* :head :neck-y :joint-angle (+ -120 (send *fetch* :head :neck-y :joint-angle)))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  (unix:sleep 7) ;; wait for camera image stabilization
  (call-mail-service "73B2 center" ;; *place-name*
                     *mail-title*
                     *from-address*
                     *to-address*
                     *message*) ;; calling send mail service
  (send *ri* :speak-jp "かしゃっ")
  ;; stop taking photos
  (send *fetch* :reset-pose)
  (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  (send *ri* :wait-interpolation)
  )

;; main function
(defun patrol ()
  ;; patrol in 73B2 and notify the result via email and twitter
  (go-to-kitchen)
  (go-to-table)
  (go-to-73b2-center)
  ;; auto docking
  (send *ri* :speak-jp "ドックに戻るね" :wait t)
  (auto-dock)
  )

(patrol)
(exit)
