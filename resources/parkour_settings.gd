extends Resource
class_name ParkourSettings

@export_group("Управление")
@export var mouse_sensitivity := 0.003
@export var invert_y := true
@export var fov_default := 90.0
@export var fov_speed := 108.0

@export_group("Звук")
@export_range(-80, 24) var master_volume_db := 0.0
@export_range(-80, 24) var sfx_volume_db := 0.0

@export_group("Интерфейс")
@export var show_speed_indicator := true
@export var debug_panel_enabled := false

@export_group("Графика")
@export var ssao_enabled := true
@export var ssil_enabled := true
@export var glow_enabled := true
@export var motion_blur_enabled := true
@export var sdfgi_enabled := false
@export var volumetric_fog_enabled := false
