extends Control

@onready var opt_p1_class: OptionButton = $Center/MainPanel/VBox/ClassP1Row/OptP1Class
@onready var opt_stage: OptionButton = $Center/MainPanel/VBox/StageRow/OptStage
@onready var opt_p1_scheme: OptionButton = $Center/MainPanel/VBox/InputP1Row/OptP1Scheme
@onready var opt_p1_device: OptionButton = $Center/MainPanel/VBox/InputP1Row/OptP1Device
@onready var chk_dummy_shoot: CheckBox = $Center/MainPanel/VBox/TrainingBox/ChkDummyShoot
@onready var opt_ko_camera_impact: OptionButton = $Center/MainPanel/VBox/TrainingBox/KoCameraRow/OptKoCameraImpact
@onready var btn_back: Button = $Center/MainPanel/VBox/ButtonRow/BtnBack
@onready var btn_start: Button = $Center/MainPanel/VBox/ButtonRow/BtnStart
@onready var _main_panel: Panel = $Center/MainPanel


func _ready() -> void:
	RunConfig.clear_shoot_mouse_bindings_for_menu()
	_apply_training_menu_quick_test_defaults()
	MenuThemeUtil.apply_main_panel_style(_main_panel)
	MenuThemeUtil.fill_class_option(opt_p1_class)
	MenuThemeUtil.style_option(opt_p1_class)
	MenuThemeUtil.fill_stage_option(opt_stage)
	MenuThemeUtil.style_option(opt_stage)
	MenuThemeUtil.fill_input_scheme_option(opt_p1_scheme)
	MenuThemeUtil.fill_joy_device_option(opt_p1_device)
	MenuThemeUtil.style_option(opt_p1_scheme)
	MenuThemeUtil.style_option(opt_p1_device)
	MenuThemeUtil.style_checkbox(chk_dummy_shoot)
	_fill_ko_camera_impact_option()
	MenuThemeUtil.style_option(opt_ko_camera_impact)
	MenuThemeUtil.style_menu_button(btn_back, false)
	MenuThemeUtil.style_menu_button(btn_start, true)
	var imax := maxi(opt_p1_class.item_count - 1, 0)
	opt_p1_class.select(clampi(RunConfig.p1_character, 0, imax))
	var smax := maxi(opt_stage.item_count - 1, 0)
	opt_stage.select(clampi(int(RunConfig.stage), 0, smax))
	opt_p1_scheme.select(clampi(int(RunConfig.p1_input_scheme), 0, maxi(opt_p1_scheme.item_count - 1, 0)))
	opt_p1_device.select(clampi(RunConfig.p1_joy_device, 0, maxi(opt_p1_device.item_count - 1, 0)))
	opt_ko_camera_impact.select(clampi(int(RunConfig.ko_camera_impact_style), 0, maxi(opt_ko_camera_impact.item_count - 1, 0)))
	_refresh_p1_device_visible()
	opt_stage.item_selected.connect(_on_stage_selected)
	opt_p1_scheme.item_selected.connect(_on_p1_scheme_selected)
	opt_p1_device.item_selected.connect(_on_p1_device_selected)
	opt_ko_camera_impact.item_selected.connect(_on_ko_camera_impact_selected)
	chk_dummy_shoot.button_pressed = RunConfig.training_dummy_shoot
	btn_back.pressed.connect(_on_back_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_start.grab_focus()


## Ao abrir este menu: atalho para testar (Esqueleto + controle 0 + boneco sem tiro automático).
func _apply_training_menu_quick_test_defaults() -> void:
	RunConfig.p1_character = Player.CharacterKind.ESQUELETO
	RunConfig.p1_input_scheme = RunConfig.InputScheme.GAMEPAD
	RunConfig.p1_joy_device = 0
	RunConfig.training_dummy_shoot = false


func _fill_ko_camera_impact_option() -> void:
	opt_ko_camera_impact.clear()
	opt_ko_camera_impact.add_item("A — Slow motion", RunConfig.KoCameraImpactStyle.SLOW_MOTION)
	opt_ko_camera_impact.add_item("B — Hit stop", RunConfig.KoCameraImpactStyle.HIT_STOP)
	opt_ko_camera_impact.add_item("C — Híbrido", RunConfig.KoCameraImpactStyle.HYBRID)


func _refresh_p1_device_visible() -> void:
	opt_p1_device.visible = RunConfig.p1_input_scheme == RunConfig.InputScheme.GAMEPAD


func _on_stage_selected(index: int) -> void:
	RunConfig.stage = index as RunConfig.Stage


func _on_p1_scheme_selected(index: int) -> void:
	RunConfig.p1_input_scheme = index as RunConfig.InputScheme
	_refresh_p1_device_visible()


func _on_p1_device_selected(index: int) -> void:
	RunConfig.p1_joy_device = index


func _on_ko_camera_impact_selected(index: int) -> void:
	RunConfig.ko_camera_impact_style = index as RunConfig.KoCameraImpactStyle


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menu.tscn")


func _on_start_pressed() -> void:
	RunConfig.p1_character = opt_p1_class.selected
	RunConfig.stage = opt_stage.selected as RunConfig.Stage
	RunConfig.p1_input_scheme = opt_p1_scheme.selected as RunConfig.InputScheme
	RunConfig.p1_joy_device = opt_p1_device.selected
	RunConfig.mode = RunConfig.Mode.TRAINING
	RunConfig.training_dummy_shoot = chk_dummy_shoot.button_pressed
	RunConfig.training_dummy_interval = 3.0
	RunConfig.ko_camera_impact_style = opt_ko_camera_impact.selected as RunConfig.KoCameraImpactStyle
	get_tree().change_scene_to_file("res://levels/duel/main.tscn")
