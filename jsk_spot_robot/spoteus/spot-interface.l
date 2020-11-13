(ros::roseus "spot")

(require "package://spoteus/spot-utils.l")
(require "package://pr2eus/robot-interface.l")

(ros::roseus-add-srvs "std_srvs")
(ros::roseus-add-msgs "spot_msgs")

(defun call-trigger-service (srvname &key (wait nil))
  "Call std_srv/Trigger service"
  (let (r)
    (if wait (ros::wait-for-service srvname))
    (setq r (ros::service-call srvname (instance std_srvs::TriggerRequest :init)))
    (ros::ros-info "Call \"~A\" returns \"~A\"" srvname (send r :message))
    (send r :success)))

(defclass spot-interface
  :super robot-move-base-interface
  :slots ()
  )

(defmethod spot-interface
  (:init
   (&rest args)
   (prog1
       (send-super* :init :robot spot-robot :base-frame-id "base_link" :odom-topic "/odom_combined" :base-controller-action-name nil args)
     ;; http://www.clearpathrobotics.com/assets/guides/melodic/spot-ros/ros_usage.html#view-the-robot
     ;; spot_msgs version 0.0.0
     (ros::subscribe "/spot/status/metrics" spot_msgs::Metrics #'send self :spot-status-metrics-callback :groupname groupname)
     (ros::subscribe "/spot/status/leases" spot_msgs::LeaseArray #'send self :spot-status-leases-callback :groupname groupname)
     (ros::subscribe "/spot/status/feet" spot_msgs::FootStateArray #'send self :spot-status-feet-callback :groupname groupname)
     (ros::subscribe "/spot/status/estop" spot_msgs::EStopStateArray #'send self :spot-status-estop-callback :groupname groupname)
     (ros::subscribe "/spot/status/wifi" spot_msgs::WiFiState #'send self :spot-status-wifi-callback :groupname groupname)
     (ros::subscribe "/spot/status/power_state" spot_msgs::PowerState #'send self :spot-status-power-state-callback :groupname groupname)
     (ros::subscribe "/spot/status/battery_states" spot_msgs::BatteryStateArray #'send self :spot-status-battery-states-callback :groupname groupname)
     (ros::subscribe "/spot/status/behavior_faults" spot_msgs::BehaviorFaultState #'send self :spot-status-behavior-faults-callback :groupname groupname)
     (ros::subscribe "/spot/status/system_faults" spot_msgs::SystemFaultState #'send self :spot-status-system-faults-callback :groupname groupname)
     (ros::subscribe "/spot/status/feedback" spot_msgs::Feedback #'send self :spot-feedback-callback :groupname groupname)
     ))
  (:default-controller () ) ;; spot does not provide any JTA controllers
  (:spot-status-metrics-callback
   (msg)
   (send self :set-robot-state1 :metrics-distance (send msg :distance))
   (send self :set-robot-state1 :metrics-gaint-cycles (send msg :gait_cycles))
   (send self :set-robot-state1 :metrics-time-moving (send (send msg :time_moving) :to-sec))
   (send self :set-robot-state1 :metrics-electric-power (send (send msg :electric_power) :to-sec)))
  (:spot-status-leases-callback
   (msg)
   (dolist (resource (send msg :resources))
     (let ((r (string-upcase (send resource :resource))))
       (send self :set-robot-state1 (intern (format nil "LEASES-~A-RESOURCE" r) *keyword-package*)
             (send resource :lease :resource))
       (send self :set-robot-state1 (intern (format nil "LEASES-~A-EPOCH" r) *keyword-package*)
             (send resource :lease :epoch))
       (send self :set-robot-state1 (intern (format nil "LEASES-~A-SEQUENCE" r) *keyword-package*)
             (send resource :lease :sequence))
       (send self :set-robot-state1 (intern (format nil "LEASES-~A-CLIENT-NAME" r) *keyword-package*)
             (send resource :lease_owner :client_name))
       (send self :set-robot-state1 (intern (format nil "LEASES-~A-USER-NAME" r) *keyword-package*)
             (send resource :lease_owner :user_name)))))
  (:spot-status-feet-callback
   (msg)
   (send self :set-robot-state1 :feet
         (mapcar #'(lambda (state)
                     (list (cons :foot-position-rt-body (ros::tf-point->pos (send state :foot_position_rt_body)))
                           (cons :contact (case (send state :contact) (0 'unknown) (1 'made) (2 'lost))))) (send msg :states))))
  (:spot-status-estop-callback
   (msg)
   (dolist (state (send msg :estop_states))
     (let ((s (string-upcase (substitute #\- #\_ (send state :name)))))
       (send self :set-robot-state1 (intern (format nil "ESTOP-~A-NAME" s) *keyword-package*)
             (send state :name))
       (send self :set-robot-state1 (intern (format nil "ESTOP-~A-TYPE" s) *keyword-package*)
             (case (send state :type) (0 'unknown) (1 'hardware) (2 'software)))
       (send self :set-robot-state1 (intern (format nil "ESTOP-~A-STATE" s) *keyword-package*)
             (case (send state :state) (0 'unknown) (1 'estopped) (2 'not-estopped)))
       (send self :set-robot-state1 (intern (format nil "ESTOP-~A-STATE-DESCRIPTION" s) *keyword-package*)
             (send state :state_description)))))
  (:spot-status-wifi-callback
   (msg)
   (send self :set-robot-state1 :wifi-current-mode
         (case (send msg :current_mode)
               (0 'unknown) (1 'access-point) (2 'client)))
   (send self :set-robot-state1 :wifi-essid (send msg :essid)))
  (:spot-status-power-state-callback
   (msg)
   (send self :set-robot-state1 :power-state-motor-power-state
         (case (send msg :motor_power_state)
               (0 'unknown) (1 'off) (2 'on) (3 'powering-on) (4 'powering-off) (5 'error)))
   (send self :set-robot-state1 :power-state-shore-power-state
         (case (send msg :shore_power_state)
               (0 'unknown-shore-power) (1 'on-shore-power) (2 'off-shore-power)))
   (send self :set-robot-state1 :power-state-locomotion-charge-percentage (send msg :locomotion_charge_percentage))
   (send self :set-robot-state1 :power-state-locomotion-estimated-runtime (send (send msg :locomotion_estimated_runtime) :to-sec)))
  (:spot-status-battery-states-callback
   (msg)
   (dolist (state (send msg :battery_states))
     (let ((s (string-upcase (substitute #\- #\_ (send state :identifier)))))
       (send self :set-robot-state1 (intern (format nil "BATTERY-STATES-~A-IDENTIFIER" s) *keyword-package*)
             (send state :identifier))
       (send self :set-robot-state1 (intern (format nil "BATTERY-STATES-~A-CHARGE-PERCENTAGE" s) *keyword-package*)
             (send state :charge_percentage))
       (send self :set-robot-state1 (intern (format nil "BATTERY-STATES-~A-ESTIMATED-RUNTIME" s) *keyword-package*)
             (send (send state :estimated_runtime) :to-sec))
       (send self :set-robot-state1 (intern (format nil "BATTERY-STATES-~A-CURRENT" s) *keyword-package*)
             (send state :current))
       (send self :set-robot-state1 (intern (format nil "BATTERY-STATES-~A-VOLTAGE" s) *keyword-package*)
             (send state :voltage))
       (send self :set-robot-state1 (intern (format nil "BATTERY-STATES-~A-TEMPERATURES" s) *keyword-package*)
             (send state :temperatures))
       (send self :set-robot-state1 (intern (format nil "BATTERY-STATES-~A-STATUS" s) *keyword-package*)
             (case (send state :status) (0 'unknown) (1 'missing) (2 'charging) (3 'discharging) (4 'booting))))))
  (:spot-status-behavior-faults-callback
   (msg)
   (send self :set-robot-state1 :behavior-faults
         (mapcar #'(lambda (fault)
                     (list (cons :behavior-fault-id (send fault :behavior_fault_id))
                           (cons :cause (case (send fault :cause) (0 'unknown) (1 'fall) (2 'hardware)))
                           (cons :status (case (send fault :status) (0 'unknown) (1 'clearable) (2 'unclearable)))))
                     (send msg :faults))))
  (:spot-status-system-faults-callback
   (msg)
   (dolist (fault (send msg :faults))
     (let ((s (string-upcase (substitute #\- #\_ (send fault :name)))))
       (send self :set-robot-state1 (intern (format nil "SYSTEM-FAULTS-~A-NAME" s) *keyword-package*)
             (send fault :NAME))
       (send self :set-robot-state1 (intern (format nil "SYSTEM-FAULTS-~A-DURATION" s) *keyword-package*)
             (send (send fault :duration) :to-sec))
       (send self :set-robot-state1 (intern (format nil "SYSTEM-FAULTS-~A-CODE" s) *keyword-package*)
             (send fault :code))
       (send self :set-robot-state1 (intern (format nil "SYSTEM-FAULTS-~A-UID" s) *keyword-package*)
             (send fault :uid))
       (send self :set-robot-state1 (intern (format nil "SYSTEM-FAULTS-~A-ERROR_MESSAGE" s) *keyword-package*)
             (send fault :error_message))
       (send self :set-robot-state1 (intern (format nil "SYSTEM-FAULTS-~A-ATTRIBUTES" s) *keyword-package*)
             (send fault :attributes))
       (send self :set-robot-state1 (intern (format nil "SYSTEM-FAULTS-~A-SEVERITY" s) *keyword-package*)
             (case (send fault :sevirity) (0 'unknown) (1 'info) (2 'warn) (3 'critical))))))
  (:spot-feedback-callback
   (msg)
   (send self :set-robot-state1 :feedback-standing (send msg :standing))
   (send self :set-robot-state1 :feedback-sitting (send msg :sitting))
   (send self :set-robot-state1 :feedback-moving (send msg :moving))
   (send self :set-robot-state1 :feedback-serial-number (send msg :serial_number))
   (send self :set-robot-state1 :feedback-species (send msg :species))
   (send self :set-robot-state1 :feedback-version (send msg :version))
   (send self :set-robot-state1 :feedback-nickname (send msg :nickname))
   (send self :set-robot-state1 :feedback-computer-serial-number(send msg :computer_serial_number)))
  (:state
   (&rest args)
   "use :metrics, :leases :feet, :estop, :wifi, :power-state, :battery-states, :behvior-faults, :system-fault, :feedback to get spot status, you can also acess to the specific data by concatenating these method name + key value, for example :metrics-time-moving"
   (prog1
       (send-message* self robot-interface :state args)
     (flet ((gen-status
             (key)
             (mapcan #'(lambda (x) (if (substringp (string key) (string (car x))) (list (cons (intern (subseq (string (car x)) (1+ (length (string key)))) *keyword-package*) (cdr x))))) robot-state)))
     (case (car args)
       (:metrics (return-from :state (gen-status :metrics)))
       (:leases  (return-from :state (gen-status :leases)))
       ;; (:feet    (return-from :state (gen-status :feet)))
       (:estop  (return-from :state (gen-status :estop)))
       (:wifi   (return-from :state (gen-status :wifi)))
       (:power-state     (return-from :state (gen-status :power-state)))
       (:battery-states  (return-from :state (gen-status :battery-states)))
       ;; (:behavior-faults (return-from :state (gen-status :behavior-faults)))
       (:system-faults   (return-from :state (gen-status :system-faults)))
       (:feedback        (return-from :state (gen-status :feedback)))
       (:angle-vector
	(return-from :state (send robot :angle-vector)))
       (:worldcoords
	(unless joint-action-enable
	  (return-from :state (send self :worldcoords)))
        (return-from :state (send *tfl* :lookup-transform "vision" base-frame-id (ros::time 0))))))))
  ;;
  (:estop-gentle () (call-trigger-service "/spot/estop/gentle"))
  (:estop-hard () (call-trigger-service "/spot/estop/hard"))
  (:claim () "Claim the robot control" (call-trigger-service "/spot/claim"))
  (:release () "Relase the robot control" (call-trigger-service "/spot/release"))
  (:power-on () "Power on the robot" (call-trigger-service "/spot/power_on"))
  (:power-off () "Power off the robot" (call-trigger-service "/spot/power_off"))
  (:self-right () (call-trigger-service "/spot/self_right"))
  (:stand () "Stand the robot up" (call-trigger-service "/spot/stand"))
  (:sit () "Sit the robot down" (call-trigger-service "/spot/sit"))
  (:stop () "Stop the robot in place with minimal motion" (call-trigger-service "/spot/stop"))
  ;;
  (:send-cmd-vel-raw
   (x y d &key (topic-name "/spot/cmd_vel"))
   (when (send self :simulation-modep)
     (return-from :send-cmd-vel-raw t))
    (unless (ros::get-topic-publisher topic-name)
      (ros::advertise topic-name geometry_msgs::Twist 1)
      (unix:sleep 1))
    (let ((msg (instance geometry_msgs::Twist :init)))
      (send msg :linear :x x)
      (send msg :linear :y y)
      (send msg :angular :z d)
      (ros::publish topic-name msg)))
  (:go-velocity
    (x y d ;; [m/sec] [m/sec] [rad/sec]
       &optional (msec 1000) ;; msec is total animation time [msec]
       &key (stop t) (wait t))
    "contorl the robot velocity x([m/sec]) y([m/sec]) d([rad/sec]) msec([msec]). msec is the time to travel."
    (unless wait
      (ros::ros-error ":go-velocity without wait is unsupported")
      (return-from :go-velocity nil))
    (ros::rate 100)
    (let ((start-time (ros::time-now)))
      (while (and (ros::ok)
                  (< (* 1000.0 (send (ros::time- (ros::time-now) start-time) :to-sec)) msec))
        (send self :spin-once)
        (send self :send-cmd-vel-raw x y d)
        (ros::sleep)))
    (when stop
      (send self :send-cmd-vel-raw 0 0 0))
    (ros::rate 10)
    t)

  )

(defun spot-init (&optional (create-viewer))
  (unless (boundp '*spot*) (spot) (send *spot* :reset-pose))
  (unless (ros::ok) (ros::roseus "spot_eus_interface"))
  (unless (boundp '*ri*) (setq *ri* (instance spot-interface :init)))

  (ros::spin-once)
  (send *ri* :spin-once)
  (send *ri* :claim)

  (when create-viewer (objects (list *spot*)))
  )