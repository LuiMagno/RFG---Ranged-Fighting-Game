extends Control

@onready var opt_p1_class: OptionButton = $Center/MainPanel/VBox/ClassP1Row/OptP1Class
@onready var opt_p1_scheme: OptionButton = $Center/MainPanel/VBox/InputP1Row/OptP1Scheme
@onready var opt_p1_device: OptionButton = $Center/MainPanel/VBox/InputP1Row/OptP1Device
@onready var chk_dummy_shoot: CheckBox = $Center/MainPanel/VBox/TrainingBox/ChkDummyShoot
@onready var btn_back: Button = $Center/MainPanel/VBox/ButtonRow/BtnBack
@onready var btn_start: Button = $Center/MainPanel/VBox/ButtonRow/BtnStart
@onready var _main_panel: Panel = $Center/MainPanel


func _ready() -> void:
	RunConfig.clear_p1_shoot_mouse_binding()
	MenuThemeUtil.apply_main_panel_style(_main_panel)
	MenuThemeUtil.fill_class_option(opt_p1_class)
	MenuThemeUtil.style_option(opt_p1_class)
	MenuThemeUtil.fill_input_scheme_option(opt_p1_scheme)
	MenuThemeUtil.fill_joy_device_option(opt_p1_device)
	MenuThemeUtil.style_option(opt_p1_scheme)
	MenuThemeUtil.style_option(opt_p1_device)
	MenuThemeUtil.style_checkbox(chk_dummy_shoot)
	MenuThemeUtil.style_menu_button(btn_back, false)
	MenuThemeUtil.style_menu_button(btn_start, true)
	var imax := maxi(opt_p1_class.item_count - 1, 0)
	opt_p1_class.select(clampi(RunConfig.p1_character, 0, imax))
	opt_p1_scheme.select(clampi(int(RunConfig.p1_input_scheme), 0, maxi(opt_p1_scheme.item_count - 1, 0)))
	opt_p1_device.select(clampi(RunConfig.p1_joy_device, 0, maxi(opt_p1_device.item_count - 1, 0)))
	_refresh_p1_device_visible()
	opt_p1_scheme.item_selected.connect(_on_p1_scheme_selected)
	opt_p1_device.item_selected.connect(_on_p1_device_selected)
	chk_dummy_shoot.button_pressed = RunConfig.training_dummy_shoot
	btn_back.pressed.connect(_on_back_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_start.grab_focus()


func _refresh_p1_device_visible() -> void:
	opt_p1_device.visible = RunConfig.p1_input_scheme == RunConfig.InputScheme.GAMEPAD


func _on_p1_scheme_selected(index: int) -> void:
	RunConfig.p1_input_scheme = index as RunConfig.InputScheme
	_refresh_p1_device_visible()


func _on_p1_device_selected(index: int) -> void:
	RunConfig.p1_joy_device = index


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menu.tscn")


func _on_start_pressed() -> void:
	RunConfig.p1_character = opt_p1_class.selected
	RunConfig.p1_input_scheme = opt_p1_scheme.selected as RunConfig.InputScheme
	RunConfig.p1_joy_device = opt_p1_device.selected
	RunConfig.mode = RunConfig.Mode.TRAINING
	RunConfig.training_dummy_shoot = chk_dummy_shoot.button_pressed
	RunConfig.training_dummy_interval = 3.0
	get_tree().change_scene_to_file("res://levels/duel/main.tscn")
