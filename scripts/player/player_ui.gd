class_name PlayerUI
extends RefCounted

var player: CharacterBody3D
var state: PlayerState
var timer_label: Label
var score_label: Label
var speed_panel: Control
var speed_label: Label
var state_panel: Control
var state_label: Label
var level_complete_panel: Control
var level_complete_time: Label
var level_complete_score: Label
var level_complete_best: Label
var level_complete_restart_btn: Button
var level_complete_next_btn: Button

func _init(p: CharacterBody3D, s: PlayerState) -> void:
	player = p
	state = s
	timer_label = p.get_node_or_null(PlayerNodes.TIMER_LABEL)
	score_label = p.get_node_or_null(PlayerNodes.SCORE_LABEL)
	speed_panel = p.get_node_or_null(PlayerNodes.SPEED_PANEL)
	speed_label = p.get_node_or_null(PlayerNodes.SPEED_LABEL)
	state_panel = p.get_node_or_null(PlayerNodes.STATE_PANEL)
	state_label = p.get_node_or_null(PlayerNodes.STATE_LABEL)
	level_complete_panel = p.get_node_or_null(PlayerNodes.LEVEL_COMPLETE_PANEL)
	level_complete_time = p.get_node_or_null(PlayerNodes.LEVEL_COMPLETE_TIME)
	level_complete_score = p.get_node_or_null(PlayerNodes.LEVEL_COMPLETE_SCORE)
	level_complete_best = p.get_node_or_null(PlayerNodes.LEVEL_COMPLETE_BEST)
	level_complete_restart_btn = p.get_node_or_null(PlayerNodes.RESTART_BTN)
	level_complete_next_btn = p.get_node_or_null(PlayerNodes.NEXT_BTN)

func update_hud(speed: float) -> void:
	if timer_label:
		timer_label.text = LevelState.get_time_formatted()
	if score_label:
		score_label.text = str(LevelState.score)
		score_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3) if LevelState.score >= 0 else Color(0.95, 0.25, 0.2))
	if speed_panel:
		speed_panel.visible = SettingsManager.get_show_speed_indicator()
	if speed_label and speed_panel and speed_panel.visible:
		speed_label.text = "%.1f" % speed
	if state_panel:
		state_panel.visible = SettingsManager.get_debug_enabled()

func update_state(speed: float, on_floor: bool, is_on_ramp: bool, floor_surface: String) -> void:
	if not state_label or not state_panel or not state_panel.visible:
		return
	var lines: PackedStringArray = []
	lines.append("Скорость: %.1f" % speed)
	lines.append("Поверхность: %s" % floor_surface)
	lines.append("")
	lines.append("Пол: %s" % ("да" if on_floor else "нет"))
	lines.append("Рампа: %s" % ("да" if is_on_ramp else "нет"))
	lines.append("Стена: %s" % ("да" if state.is_on_wall else "нет"))
	lines.append("Зацеп: %s" % ("да (%.1fs)" % state.ledge_hang_timer if state.is_ledge_hanging else "нет"))
	lines.append("Слайд: %s" % ("да" if state.is_sliding else "нет"))
	lines.append("Присед: %s" % ("да" if state.is_crouching else "нет"))
	lines.append("Слайд cd: %.2f" % state.slide_cooldown)
	lines.append("")
	lines.append("Край: %s" % ("да" if state.at_edge else "нет"))
	lines.append("Shift/Charge: %s" % ("да (%.2f)" % state.long_jump_prep_timer if state.long_jump_prep_timer > 0 else "нет"))
	lines.append("LONG JUMP: %s" % ("да!" if state.long_jump_just_done > 0 else "нет"))
	lines.append("")
	lines.append("vel_y: %.2f" % player.velocity.y)
	lines.append("vel_h: %.1f" % (Vector2(player.velocity.x, player.velocity.z).length()))
	var keys: PackedStringArray = []
	if Input.is_action_pressed("move_forward"): keys.append("W")
	if Input.is_action_pressed("move_back"): keys.append("S")
	if Input.is_action_pressed("move_left"): keys.append("A")
	if Input.is_action_pressed("move_right"): keys.append("D")
	if Input.is_action_pressed("slide"): keys.append("C")
	if Input.is_action_pressed("crouch"): keys.append("Ctrl")
	if Input.is_action_pressed("jump"): keys.append("Sp")
	if Input.is_action_pressed("long_jump_prep"): keys.append("Sh")
	if keys.size() > 0:
		lines.append("")
		lines.append("Клавиши: %s" % ", ".join(keys))
	state_label.text = "\n".join(lines)

func show_level_complete(time: float) -> void:
	if level_complete_panel:
		level_complete_panel.visible = true
	if level_complete_time:
		level_complete_time.text = "Время: %s" % LevelState.format_time(time)
	if level_complete_score:
		level_complete_score.text = "Баллы: %d" % LevelState.score
		level_complete_score.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3) if LevelState.score >= 0 else Color(0.95, 0.25, 0.2))
	if level_complete_best:
		level_complete_best.text = "Рекорд: %s" % LevelState.format_time(LevelState.best_time)
	if level_complete_next_btn:
		level_complete_next_btn.visible = LevelState.has_next_level()
