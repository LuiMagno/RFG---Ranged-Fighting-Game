extends Control

@onready var btn_vs: Button = $Center/MainPanel/VBox/BtnVs
@onready var btn_training: Button = $Center/MainPanel/VBox/BtnTraining
@onready var chk_dummy_shoot: CheckBox = $Center/MainPanel/VBox/TrainingBox/ChkDummyShoot
@onready var opt_p1_class: OptionButton = $Center/MainPanel/VBox/ClassP1Row/OptP1Class
@onready var opt_p2_class: OptionButton = $Center/MainPanel/VBox/ClassP2Row/OptP2Class
@onready var _main_panel: Panel = $Center/MainPanel


func _ready() -> void:
	RunConfig.clear_p1_shoot_mouse_binding()
	_apply_menu_theme()

	_fill_class_option(opt_p1_class)
	_fill_class_option(opt_p2_class)
	var imax := maxi(opt_p1_class.item_count - 1, 0)
	opt_p1_class.select(clampi(RunConfig.p1_character, 0, imax))
	opt_p2_class.select(clampi(RunConfig.p2_character, 0, imax))

	btn_vs.pressed.connect(_on_vs_pressed)
	btn_training.pressed.connect(_on_training_pressed)
	btn_vs.grab_focus()


func _apply_menu_theme() -> void:
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.11, 0.13, 0.18, 0.96)
	panel_sb.set_border_width_all(2)
	panel_sb.border_color = Color(0.35, 0.65, 0.92, 0.75)
	panel_sb.set_corner_radius_all(16)
	panel_sb.shadow_color = Color(0, 0, 0, 0.45)
	panel_sb.shadow_size = 6
	panel_sb.shadow_offset = Vector2(0, 4)
	_main_panel.add_theme_stylebox_override("panel", panel_sb)

	_style_menu_button(btn_vs, true)
	_style_menu_button(btn_training, false)
	_style_option(opt_p1_class)
	_style_option(opt_p2_class)
	_style_checkbox(chk_dummy_shoot)


func _style_menu_button(b: Button, primary: bool) -> void:
	var n := StyleBoxFlat.new()
	var h := StyleBoxFlat.new()
	var p := StyleBoxFlat.new()
	if primary:
		n.bg_color = Color(0.2, 0.5, 0.88, 1.0)
		h.bg_color = Color(0.28, 0.58, 0.98, 1.0)
		p.bg_color = Color(0.14, 0.38, 0.75, 1.0)
	else:
		n.bg_color = Color(0.22, 0.26, 0.34, 1.0)
		h.bg_color = Color(0.3, 0.35, 0.45, 1.0)
		p.bg_color = Color(0.16, 0.18, 0.24, 1.0)
	for sb in [n, h, p]:
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(14)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_font_size_override("font_size", 17)


func _style_option(ob: OptionButton) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.16, 0.18, 0.24, 1.0)
	n.set_corner_radius_all(8)
	n.set_content_margin_all(10)
	n.set_border_width_all(1)
	n.border_color = Color(0.35, 0.45, 0.6, 0.6)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.22, 0.25, 0.32, 1.0)
	ob.add_theme_stylebox_override("normal", n)
	ob.add_theme_stylebox_override("hover", h)
	ob.add_theme_font_size_override("font_size", 15)


func _style_checkbox(cb: CheckBox) -> void:
	cb.add_theme_font_size_override("font_size", 14)
	cb.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92, 1))


func _fill_class_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("Pistoleiro")
	ob.add_item("Arqueiro")
	ob.add_item("Mago")


func _apply_character_selection() -> void:
	RunConfig.p1_character = opt_p1_class.selected
	RunConfig.p2_character = opt_p2_class.selected


func _on_vs_pressed() -> void:
	_apply_character_selection()
	RunConfig.mode = RunConfig.Mode.VS_PLAYER
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_training_pressed() -> void:
	_apply_character_selection()
	RunConfig.mode = RunConfig.Mode.TRAINING
	RunConfig.training_dummy_shoot = chk_dummy_shoot.button_pressed
	RunConfig.training_dummy_interval = 3.0
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
