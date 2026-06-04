extends CanvasLayer

## Treinamento: Enter ou Start abre/fecha; continuar, configurações do treino (boneco) ou voltar à seleção de modo.
## PROCESS_MODE_ALWAYS para funcionar com get_tree().paused.

@onready var _root: Control = $Root
@onready var _main_menu: VBoxContainer = $Root/Center/Panel/MainMenu
@onready var _settings_menu: VBoxContainer = $Root/Center/Panel/SettingsMenu
@onready var _btn_resume: Button = $Root/Center/Panel/MainMenu/BtnResume
@onready var _btn_settings: Button = $Root/Center/Panel/MainMenu/BtnTrainingSettings
@onready var _btn_mode_menu: Button = $Root/Center/Panel/MainMenu/BtnModeMenu
@onready var _opt_p1_class: OptionButton = $Root/Center/Panel/SettingsMenu/ClassP1Row/OptP1Class
@onready var _opt_p1_scheme: OptionButton = $Root/Center/Panel/SettingsMenu/InputP1Row/OptP1Scheme
@onready var _opt_p1_device: OptionButton = $Root/Center/Panel/SettingsMenu/InputP1Row/OptP1Device
@onready var _opt_esqueleto_projetil_vel: OptionButton = (
	$Root/Center/Panel/SettingsMenu/EsqueletoProjetilVelRow/OptEsqueletoProjetilVel
)
@onready var _chk_dummy: CheckBox = $Root/Center/Panel/SettingsMenu/ChkDummyShoot
@onready var _btn_back_settings: Button = $Root/Center/Panel/SettingsMenu/BtnBackSettings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_btn_resume.pressed.connect(_on_resume_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_mode_menu.pressed.connect(_on_mode_menu_pressed)
	_btn_back_settings.pressed.connect(_on_back_settings_pressed)
	_chk_dummy.toggled.connect(_on_dummy_toggled)
	MenuThemeUtil.fill_class_option(_opt_p1_class)
	MenuThemeUtil.style_option(_opt_p1_class)
	MenuThemeUtil.fill_input_scheme_option(_opt_p1_scheme)
	MenuThemeUtil.fill_joy_device_option(_opt_p1_device)
	MenuThemeUtil.style_option(_opt_p1_scheme)
	MenuThemeUtil.style_option(_opt_p1_device)
	MenuThemeUtil.fill_esqueleto_projetil_velocidade_option(_opt_esqueleto_projetil_vel)
	MenuThemeUtil.style_option(_opt_esqueleto_projetil_vel)
	_opt_esqueleto_projetil_vel.item_selected.connect(_on_esqueleto_projetil_vel_selected)
	_opt_p1_scheme.item_selected.connect(_on_p1_scheme_selected)
	_opt_p1_device.item_selected.connect(_on_p1_device_selected)
	var imax := maxi(_opt_p1_class.item_count - 1, 0)
	_opt_p1_class.select(clampi(RunConfig.p1_character, 0, imax))
	_opt_p1_class.item_selected.connect(_on_p1_class_selected)
	_apply_panel_style()
	_sync_settings_controls()


func _unhandled_input(event: InputEvent) -> void:
	if RunConfig.mode != RunConfig.Mode.TRAINING:
		return
	if not event.is_action_pressed("ui_game_pause"):
		return
	get_viewport().set_input_as_handled()
	if not _root.visible:
		_open_pause()
		return
	if _settings_menu.visible:
		_show_main_menu()
		return
	_close_pause()


func _open_pause() -> void:
	_show_main_menu()
	_root.visible = true
	get_tree().paused = true
	_sync_settings_controls()
	_btn_resume.grab_focus()


func _close_pause() -> void:
	_root.visible = false
	get_tree().paused = false


func _show_main_menu() -> void:
	_settings_menu.visible = false
	_main_menu.visible = true


func _show_settings_menu() -> void:
	_main_menu.visible = false
	_settings_menu.visible = true
	_sync_settings_controls()
	_opt_p1_class.grab_focus()


func _on_resume_pressed() -> void:
	_close_pause()


func _on_settings_pressed() -> void:
	_show_settings_menu()


func _on_back_settings_pressed() -> void:
	_show_main_menu()
	_btn_settings.grab_focus()


func _on_mode_menu_pressed() -> void:
	get_tree().paused = false
	RunConfig.clear_shoot_mouse_bindings_for_menu()
	get_tree().change_scene_to_file("res://ui/menu.tscn")


func _sync_settings_controls() -> void:
	var imax := maxi(_opt_p1_class.item_count - 1, 0)
	_opt_p1_class.select(clampi(RunConfig.p1_character, 0, imax))
	_opt_p1_scheme.select(clampi(int(RunConfig.p1_input_scheme), 0, maxi(_opt_p1_scheme.item_count - 1, 0)))
	MenuThemeUtil.select_joy_device_option(_opt_p1_device, RunConfig.p1_joy_device)
	_opt_p1_device.visible = RunConfig.p1_input_scheme == RunConfig.InputScheme.GAMEPAD
	_chk_dummy.set_pressed_no_signal(RunConfig.training_dummy_shoot)
	MenuThemeUtil.select_esqueleto_projetil_velocidade_option(
		_opt_esqueleto_projetil_vel, int(RunConfig.esqueleto_projetil_velocidade)
	)


func _push_input_map_to_game() -> void:
	var g := get_tree().current_scene
	if g != null and g.has_method("apply_input_map_from_run_config"):
		(g as Object).call("apply_input_map_from_run_config")


func _on_p1_scheme_selected(index: int) -> void:
	RunConfig.p1_input_scheme = index as RunConfig.InputScheme
	_opt_p1_device.visible = RunConfig.p1_input_scheme == RunConfig.InputScheme.GAMEPAD
	_push_input_map_to_game()


func _on_p1_device_selected(index: int) -> void:
	RunConfig.p1_joy_device = _opt_p1_device.get_item_id(index)
	RunConfig.clamp_joy_devices_for_local_multiplayer()
	_push_input_map_to_game()


func _on_p1_class_selected(index: int) -> void:
	if RunConfig.p1_character == index:
		return
	RunConfig.p1_character = index
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_dummy_toggled(pressed: bool) -> void:
	RunConfig.training_dummy_shoot = pressed


func _on_esqueleto_projetil_vel_selected(_index: int) -> void:
	RunConfig.esqueleto_projetil_velocidade = (
		MenuThemeUtil.get_esqueleto_projetil_velocidade_option_id(_opt_esqueleto_projetil_vel)
		as RunConfig.EsqueletoProjetilVelocidade
	)


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
	_style_secondary_button(_btn_settings)
	_style_secondary_button(_btn_mode_menu)
	_style_secondary_button(_btn_back_settings)
	_style_checkbox(_chk_dummy)


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


func _style_checkbox(cb: CheckBox) -> void:
	cb.add_theme_font_size_override("font_size", 15)
	cb.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98, 1))
