extends Node

const SETTINGS_PATH := "user://settings.tres"
const DEFAULT_SETTINGS_PATH := "res://resources/default_settings.tres"
const SYNC_KEYS: Array = [
	"mouse_sensitivity", "invert_y", "fov_default", "fov_speed", "show_speed_indicator",
	"ssao_enabled", "ssil_enabled", "glow_enabled", "motion_blur_enabled", "sfx_volume_db",
	"sdfgi_enabled", "volumetric_fog_enabled"
]

var settings: Resource
var _runtime: Dictionary = {}
var _debug_panel_enabled := false

func _ready() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var loaded := load(SETTINGS_PATH) as Resource
		if loaded:
			settings = loaded
	if not settings:
		settings = load(DEFAULT_SETTINGS_PATH) as Resource
		if not settings:
			push_warning("SettingsManager: failed to load default settings from %s" % DEFAULT_SETTINGS_PATH)
	_sync_runtime_from_settings()
	_load_debug_from_default()

func _load_debug_from_default() -> void:
	var default_res := load(DEFAULT_SETTINGS_PATH) as Resource
	if default_res:
		var v = default_res.get("debug_panel_enabled")
		if v != null:
			_debug_panel_enabled = bool(v)

func _get_float(key: String, default_val: float) -> float:
	if _runtime.has(key):
		return float(_runtime[key])
	if settings:
		var v = settings.get(key)
		if v != null:
			return float(v)
	return default_val

func _get_bool(key: String, default_val: bool) -> bool:
	if _runtime.has(key):
		return bool(_runtime[key])
	if settings:
		var v = settings.get(key)
		if v != null:
			return bool(v)
	return default_val

func _sync_runtime_from_settings() -> void:
	if not settings:
		return
	for key in SYNC_KEYS:
		var v = settings.get(key)
		if v != null:
			_runtime[key] = v

func _set_val(key: String, val: Variant) -> void:
	_runtime[key] = val
	if settings:
		settings.set(key, val)

func get_mouse_sensitivity() -> float:
	return _get_float("mouse_sensitivity", 0.003)

func get_invert_y() -> bool:
	return _get_bool("invert_y", true)

func set_invert_y(v: bool) -> void:
	_set_val("invert_y", v)

func get_fov_default() -> float:
	return _get_float("fov_default", 90.0)

func get_fov_speed() -> float:
	return _get_float("fov_speed", 108.0)

func get_show_speed_indicator() -> bool:
	return _get_bool("show_speed_indicator", true)

func get_debug_enabled() -> bool:
	return _debug_panel_enabled

func get_ssao_enabled() -> bool:
	return _get_bool("ssao_enabled", true)

func get_ssil_enabled() -> bool:
	return _get_bool("ssil_enabled", true)

func get_glow_enabled() -> bool:
	return _get_bool("glow_enabled", true)

func get_motion_blur_enabled() -> bool:
	return _get_bool("motion_blur_enabled", true)

func get_sdfgi_enabled() -> bool:
	return _get_bool("sdfgi_enabled", false)

func get_volumetric_fog_enabled() -> bool:
	return _get_bool("volumetric_fog_enabled", false)

func get_sfx_volume_db() -> float:
	return _get_float("sfx_volume_db", 0.0)

func set_mouse_sensitivity(v: float) -> void:
	_set_val("mouse_sensitivity", v)

func set_fov_default(v: float) -> void:
	_set_val("fov_default", v)

func set_show_speed_indicator(v: bool) -> void:
	_set_val("show_speed_indicator", v)

func set_ssao_enabled(v: bool) -> void:
	_set_val("ssao_enabled", v)

func set_ssil_enabled(v: bool) -> void:
	_set_val("ssil_enabled", v)

func set_glow_enabled(v: bool) -> void:
	_set_val("glow_enabled", v)

func set_motion_blur_enabled(v: bool) -> void:
	_set_val("motion_blur_enabled", v)

func set_sdfgi_enabled(v: bool) -> void:
	_set_val("sdfgi_enabled", v)

func set_volumetric_fog_enabled(v: bool) -> void:
	_set_val("volumetric_fog_enabled", v)

func set_sfx_volume_db(v: float) -> void:
	_set_val("sfx_volume_db", v)

func save() -> bool:
	if not settings:
		settings = load(DEFAULT_SETTINGS_PATH) as Resource
	if not settings:
		settings = ParkourSettings.new()
	if not settings:
		return false
	for key in _runtime:
		settings.set(key, _runtime[key])
	var err := ResourceSaver.save(settings, SETTINGS_PATH)
	if err != OK:
		push_error("SettingsManager: failed to save settings, error %d" % err)
		return false
	return true
