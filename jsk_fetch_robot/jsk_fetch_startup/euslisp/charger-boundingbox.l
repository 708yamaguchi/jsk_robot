#!/usr/bin/env roseus

(ros::load-ros-manifest "posedetection_msgs")
(ros::load-ros-manifest "jsk_recognition_msgs")

(defclass charger-boundingbox
  :super propertied-object
  :slots (base-frame-id- charger-box-topic- marker-box-topic-
          marker-pose- marker-height- marker-width-))

(defmethod charger-boundingbox
  (:init ()
    (setq marker-height- (ros::get-param "point_pose_extractor/object_height"))
    (setq marker-width- (ros::get-param "point_pose_extractor/object_width"))
    (setq base-frame-id- "/base_link")
    (setq charger-box-topic- "/charger_box")
    (setq marker-box-topic- "/marker_box")
    (ros::advertise charger-box-topic- jsk_recognition_msgs::BoundingBox 1)
    (ros::advertise marker-box-topic- jsk_recognition_msgs::BoundingBox 1)
    (unless (boundp '*tfl*)
      (setq *tfl* (instance ros::transform-listener :init))))
  ;; Use marker pose with reliability greater than 92%
  (:calc-marker-pose (&optional (reliability-thre 0.92))
    (let (obj-msg obj)
      (while t
        (setq obj-msg (one-shot-subscribe "/ObjectDetection" posedetection_msgs::ObjectDetection))
        (setq obj (car (send obj-msg :objects)))
        (when (> (send obj :reliability) reliability-thre)
          (return)))
      (let* ((obj-pose-camera (send obj :pose))
             (cam->obj-coords (ros::tf-pose->coords obj-pose-camera))
             (base->cam-coords (send *tfl* :lookup-transform
                                     base-frame-id- (send obj-msg :header :frame_id)
                                     (ros::time 0)))
             (obj-pose-base (send (send base->cam-coords :copy-worldcoords)
                                  :transform cam->obj-coords)))
        ;; The origin of the obj-pose-base is the left upper corner of the marker
        (send obj-pose-base :translate
              (scale (* 0.5 1000) (float-vector marker-height- marker-width- 0))
              :local)
        obj-pose-base)))
  (:marker-pose->charger-pose (marker-pose)
    "
Convert the marker pose to the charger boundingbox
arg:
  - marker-pose: euslisp coords of the marker
return:
  - charger-pose: euslisp coords of the selected module
"
    (unless marker-pose
      (ros::ros-error "Input marker-pose is nil")
      (return-from :marker-pose->module-pose nil))
    (let ((translation #f(-30 0 -100))
          (charger-pose (send marker-pose :copy-worldcoords)))
      (send charger-pose :translate translation :local)
      ;; need rotation? (send module-pose :rotate (deg2rad -90) :y :local)
      charger-pose))
  (:publish-charger-box (&optional (reliability-thre 0.92))
    "
Recognize marker and publish module bounding boxes
"
    (setq marker-pose- (send self :calc-marker-pose reliability-thre))
    (let ((box-msg (instance jsk_recognition_msgs::BoundingBox :init))
          (stamp (ros::time-now)) ;; TODO Use /ObjectDetection stamp
          (frame-id base-frame-id-))
      (send box-msg :header :stamp stamp)
      (send box-msg :header :frame_id frame-id)
      (send box-msg :pose
            (ros::coords->tf-pose
             (send self :marker-pose->charger-pose marker-pose-)))
      (send box-msg :dimensions :x 0.1)
      (send box-msg :dimensions :y 0.1)
      (send box-msg :dimensions :z 0.1)
      (ros::publish charger-box-topic- box-msg)))
  (:publish-marker-box (&optional (reliability-thre 0.92))
    "
Recognize marker and publish marker bounding box
"
    (setq marker-pose- (send self :calc-marker-pose reliability-thre))
    (let ((box-msg (instance jsk_recognition_msgs::BoundingBox :init)))
      (send box-msg :header :stamp (ros::time-now))
      (send box-msg :header :frame_id base-frame-id-)
      (send box-msg :dimensions :x marker-height-)
      (send box-msg :dimensions :y marker-width-)
      (send box-msg :dimensions :z 0.02)
      (send box-msg :pose (ros::coords->tf-pose marker-pose-))
      (send box-msg :label 0)
      (ros::publish marker-box-topic- box-msg)))
  )

(defun main ()
  (ros::roseus "charger_boundingbox")
  (ros::rate 10)
  (let ((cb (instance charger-boundingbox :init)))
    (while (ros::ok)
      (send cb :publish-charger-box)
      (send cb :publish-marker-box)
      (ros::spin-once))))
