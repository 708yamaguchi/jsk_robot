#!/usr/bin/env roseus

(ros::roseus "twitter_client_move")

(load "package://jsk_robot_startup/lifelog/tweet_client.l")
(ros::load-ros-manifest "control_msgs")
(ros::load-ros-manifest "move_base_msgs")

;; Convert status variable to status string
(setq *status-table* (make-hash-table :test #'equal)))
(sethash actionlib_msgs::GoalStatus::*PENDING* *status-table* "PENDING")
(sethash actionlib_msgs::GoalStatus::*ACTIVE* *status-table* "ACTIVE")
(sethash actionlib_msgs::GoalStatus::*PREEMPTED* *status-table* "PREEMPTED")
(sethash actionlib_msgs::GoalStatus::*SUCCEEDED* *status-table* "SUCCEEDED")
(sethash actionlib_msgs::GoalStatus::*ABORTED* *status-table* "ABORTED")
(sethash actionlib_msgs::GoalStatus::*REJECTED* *status-table* "REJECTED")
(sethash actionlib_msgs::GoalStatus::*PREEMPTING* *status-table* "PREEMPTING")
(sethash actionlib_msgs::GoalStatus::*RECALLING* *status-table* "RECALLING")
(sethash actionlib_msgs::GoalStatus::*RECALLED* *status-table* "RECALLED")
(sethash actionlib_msgs::GoalStatus::*LOST* *status-table* "LOST")

(defun result-cb (msg)
  (let ((status (send (send msg :status) :status)))
    (tweet-string (format nil "move_base finished with status ~A at ~0,3f"
                          (gethash status *status-table*)
                          (send (ros::time-now) :to-sec))
                  :warning-time 1 :with-image t)))

(ros::subscribe "follow_joint_trajectory/result"
                control_msgs::FollowJointTrajectoryActionResult #'result-cb)
(ros::subscribe "move_base/result"
                move_base_msgs::MoveBaseActionResult #'result-cb)

;; Callback once in 30 minutes
(ros::rate (/ 1.0 1800))
(while (ros::ok)
  (ros::spin-once)
  (ros::sleep)
  )
