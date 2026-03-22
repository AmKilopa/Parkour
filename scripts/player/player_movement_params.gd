class_name PlayerMovementParams
extends RefCounted

var walk_speed: float
var speed_reference: float
var air_acceleration: float
var air_drag: float
var air_control: float
var ground_friction: float
var jump_velocity: float
var coyote_time: float
var jump_buffer_time: float
var slide_friction_slow: float
var slide_friction_fast: float
var slide_fast_threshold: float
var slide_accel: float
var slide_min_speed: float
var slide_max_distance_stand: float
var slide_max_time_stand: float
var slide_landing_boost: float
var slide_steer: float
var slide_end_cooldown: float
var slide_ramp_landing_boost: float
var slope_accel_stand: float
var slope_accel_slide: float
var ramp_launch_base: float
var ramp_launch_speed_factor: float
var ramp_launch_max_vy: float
var ramp_launch_min_speed: float
var ramp_climb_speed: float
var wall_run_min_speed: float
var wall_run_gravity: float
var wall_jump_velocity: float
var void_y: float
var long_jump_prep_window: float
var long_jump_horizontal: float
var long_jump_vertical: float
var ledge_grab_reach: float = 0.7
var ledge_hang_max_time: float = 1.5
var mantle_velocity: float = 6.5
var mantle_windup_time: float = 0.22
var crouch_walk_speed_multiplier: float = 0.5
var crouch_capsule_height: float = 0.9
