#!/usr/bin/env roseus

(require :fetch-interface "package://fetcheus/fetch-interface.l")

(setq *flag* nil)

(defun enable-look-at (req)
  (let ((res (instance std_srvs::SetBoolResponse :init)))
    (setq *flag* (send req :data))
    (send res :success t)
    (if *flag*
      (send res :message "enable look-at")
      (send res :message "disable look-at"))
    res))

(defun cb-look-at (msg)
  (let ((direction (send msg :data)))
    (if *flag*
      (progn
        (send *fetch* :angle-vector (send *ri* :state :potentio-vector :wait-until-update t))
        (setq direction (mod (+ (round (send *fetch* :head :neck-y :joint-angle)) (- 180 direction)) 360))
        (if (>= direction 180)
          (setq direction (- direction 360)))
        (if (<= direction -180)
          (setq direction (+ direction 360)))
        (send *fetch* :head :neck-y :joint-angle direction)
        (send *ri* :angle-vector (send *fetch* :angle-vector) 2000)
        (send *ri* :wait-interpolation)))))


(defun main ()
  (ros::roseus "look_at")
  (ros::subscribe "/sound_direction" std_msgs::Int32 #'cb-look-at 1)
  (ros::advertise-service "enable_look_at" std_srvs::SetBool #'enable-look-at)
  (unless (boundp '*ri*)
    (fetch-init))
  (ros::rate 0.2)
  (do-until-key
   (ros::spin-once)
   (ros::sleep)))

(main)
