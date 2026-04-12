extends CanvasLayer

## Só em Vs Player. Enter abre/fecha; Continuar / Voltar ao menu.
## PROCESS_MODE_ALWAYS para funcionar com get_tree().paused.

@onready var _root: Control = $Root
@onready var _btn_resume: Button = $Root/Center/Panel/VBox/BtnResume
@onready var _btn_menu: Button = $Root/Center/Panel/VBox/BtnMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_btn_resume.pressed.connect(_on_resume_pressed)
	_btn_menu.pressed.connect(_on_menu_pressed)
	_apply_panel_style()


func _unhandled_input(event: InputEvent) -> void:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER:
		return
	if not event.is_action_pressed("ui_game_pause"):
		return
	var main := get_parent()
	if main is Game and (main as Game).blocks_vs_pause_menu():
		get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
	_toggle_pause()


func _toggle_pause() -> void:
	if _root.visible:
		_close_pause()
	else:
		_open_pause()


func _open_pause() -> void:
	_root.visible = true
	get_tree().paused = true
	_btn_resume.grab_focus()


func _close_pause() -> void:
	_root.visible = false
	get_tree().paused = false


func _on_resume_pressed() -> void:
	_close_pause()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	RunConfig.clear_p1_shoot_mouse_binding()
	get_tree().change_scene_to_file("res://ui/menu.tscn")


func _apply_panel_style() -> void:
	var panel: Panel = $Root/Center/Panel as Panel
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.2, 0.97)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.4, 0.72, 0.95, 0.85)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	_style_primary_button(_btn_resume)
	_style_secondary_button(_btn_menu)


func _style_primary_button(b: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.22, 0.52, 0.88, 1.0)
	n.set_corner_radius_all(8)
	n.set_content_margin_all(12)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.32, 0.62, 0.98, 1.0)
	h.set_corner_radius_all(8)
	h.set_content_margin_all(12)
	var p := StyleBoxFlat.new()
	p.bg_color = Color(0.16, 0.4, 0.72, 1.0)
	p.set_corner_radius_all(8)
	p.set_content_margin_all(12)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_font_size_override("font_size", 18)


func _style_secondary_button(b: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.2, 0.22, 0.28, 1.0)
	n.set_corner_radius_all(8)
	n.set_content_margin_all(12)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.28, 0.32, 0.4, 1.0)
	h.set_corner_radius_all(8)
	h.set_content_margin_all(12)
	var p := StyleBoxFlat.new()
	p.bg_color = Color(0.16, 0.18, 0.24, 1.0)
	p.set_corner_radius_all(8)
	p.set_content_margin_all(12)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_font_size_override("font_size", 16)
