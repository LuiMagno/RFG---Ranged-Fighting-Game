extends Control

@onready var opt_p1_class: OptionButton = $CenterHost/MenuCluster/MainPanel/VBox/ClassP1Row/OptP1Class
@onready var opt_p2_class: OptionButton = $CenterHost/MenuCluster/MainPanel/VBox/ClassP2Row/OptP2Class
@onready var opt_stage: OptionButton = $CenterHost/MenuCluster/MainPanel/VBox/StageRow/OptStage
@onready var opt_p1_scheme: OptionButton = $CenterHost/MenuCluster/MainPanel/VBox/InputP1Row/OptP1Scheme
@onready var opt_p1_device: OptionButton = $CenterHost/MenuCluster/MainPanel/VBox/InputP1Row/OptP1Device
@onready var opt_p2_scheme: OptionButton = $CenterHost/MenuCluster/MainPanel/VBox/InputP2Row/OptP2Scheme
@onready var opt_p2_device: OptionButton = $CenterHost/MenuCluster/MainPanel/VBox/InputP2Row/OptP2Device
@onready var btn_back: Button = $CenterHost/MenuCluster/MainPanel/VBox/ButtonRow/BtnBack
@onready var btn_start: Button = $CenterHost/MenuCluster/MainPanel/VBox/ButtonRow/BtnStart
@onready var _main_panel: Panel = $CenterHost/MenuCluster/MainPanel
@onready var _build_panel: EsqueletoBuildSidePanel = $CenterHost/MenuCluster/EsqueletoBuildSidePanel


func _ready() -> void:
	RunConfig.clear_shoot_mouse_bindings_for_menu()
	RunConfig.ensure_valid_input_scheme_pair()
	MenuThemeUtil.apply_main_panel_style(_main_panel)
	MenuThemeUtil.fill_class_option(opt_p1_class)
	MenuThemeUtil.fill_class_option(opt_p2_class)
	MenuThemeUtil.style_option(opt_p1_class)
	MenuThemeUtil.style_option(opt_p2_class)
	MenuThemeUtil.fill_stage_option(opt_stage)
	MenuThemeUtil.style_option(opt_stage)
	MenuThemeUtil.fill_input_scheme_option(opt_p1_scheme)
	MenuThemeUtil.fill_input_scheme_option(opt_p2_scheme)
	MenuThemeUtil.fill_joy_device_option(opt_p1_device)
	MenuThemeUtil.fill_joy_device_option(opt_p2_device)
	MenuThemeUtil.style_option(opt_p1_scheme)
	MenuThemeUtil.style_option(opt_p2_scheme)
	MenuThemeUtil.style_option(opt_p1_device)
	MenuThemeUtil.style_option(opt_p2_device)
	MenuThemeUtil.style_menu_button(btn_back, false)
	MenuThemeUtil.style_menu_button(btn_start, true)
	MenuThemeUtil.select_class_option(opt_p1_class, RunConfig.p1_character)
	MenuThemeUtil.select_class_option(opt_p2_class, RunConfig.p2_character)
	var smax := maxi(opt_stage.item_count - 1, 0)
	opt_stage.select(clampi(int(RunConfig.stage), 0, smax))
	_sync_input_controls_from_run_config()
	opt_stage.item_selected.connect(_on_stage_selected)
	opt_p1_scheme.item_selected.connect(_on_p1_scheme_selected)
	opt_p1_device.item_selected.connect(_on_p1_device_selected)
	opt_p2_scheme.item_selected.connect(_on_p2_scheme_selected)
	opt_p2_device.item_selected.connect(_on_p2_device_selected)
	opt_p1_class.item_selected.connect(_on_p1_class_selected)
	opt_p2_class.item_selected.connect(_on_p2_class_selected)
	btn_back.pressed.connect(_on_back_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	_build_panel.configure_for_vs()
	_sync_build_panel_height()
	btn_start.grab_focus()


func _sync_input_controls_from_run_config() -> void:
	opt_p1_scheme.select(clampi(int(RunConfig.p1_input_scheme), 0, maxi(opt_p1_scheme.item_count - 1, 0)))
	opt_p2_scheme.select(clampi(int(RunConfig.p2_input_scheme), 0, maxi(opt_p2_scheme.item_count - 1, 0)))
	MenuThemeUtil.select_joy_device_option(opt_p1_device, RunConfig.p1_joy_device)
	MenuThemeUtil.select_joy_device_option(opt_p2_device, RunConfig.p2_joy_device)
	_refresh_device_controls_enabled()


func _refresh_device_controls_enabled() -> void:
	var p1_pad := RunConfig.p1_input_scheme == RunConfig.InputScheme.GAMEPAD
	var p2_pad := RunConfig.p2_input_scheme == RunConfig.InputScheme.GAMEPAD
	opt_p1_device.visible = p1_pad
	opt_p2_device.visible = p2_pad


func _on_stage_selected(index: int) -> void:
	RunConfig.stage = index as RunConfig.Stage


func _on_p1_scheme_selected(index: int) -> void:
	RunConfig.p1_input_scheme = index as RunConfig.InputScheme
	RunConfig.resolve_exclusive_keyboard_mouse(1)
	_sync_input_controls_from_run_config()


func _on_p1_device_selected(index: int) -> void:
	RunConfig.p1_joy_device = opt_p1_device.get_item_id(index)


func _on_p2_scheme_selected(index: int) -> void:
	RunConfig.p2_input_scheme = index as RunConfig.InputScheme
	RunConfig.resolve_exclusive_keyboard_mouse(2)
	_sync_input_controls_from_run_config()


func _on_p2_device_selected(index: int) -> void:
	RunConfig.p2_joy_device = opt_p2_device.get_item_id(index)


func _on_p1_class_selected(_index: int) -> void:
	_build_panel.bind_player(1)


func _on_p2_class_selected(_index: int) -> void:
	_build_panel.bind_player(2)


func _sync_build_panel_height() -> void:
	var h := int(_main_panel.custom_minimum_size.y)
	if h > 0:
		_build_panel.custom_minimum_size.y = h


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MenuPaths.SCENE_MAIN_MENU)


func _on_start_pressed() -> void:
	RunConfig.p1_character = MenuThemeUtil.get_class_option_id(opt_p1_class)
	RunConfig.p2_character = MenuThemeUtil.get_class_option_id(opt_p2_class)
	RunConfig.stage = opt_stage.selected as RunConfig.Stage
	RunConfig.p1_input_scheme = opt_p1_scheme.selected as RunConfig.InputScheme
	RunConfig.p2_input_scheme = opt_p2_scheme.selected as RunConfig.InputScheme
	RunConfig.ensure_valid_input_scheme_pair()
	RunConfig.p1_joy_device = MenuThemeUtil.get_joy_device_option_id(opt_p1_device)
	RunConfig.p2_joy_device = MenuThemeUtil.get_joy_device_option_id(opt_p2_device)
	RunConfig.clamp_joy_devices_for_local_multiplayer()
	RunConfig.mode = RunConfig.Mode.VS_PLAYER
	get_tree().change_scene_to_file(MenuPaths.SCENE_GAME)
