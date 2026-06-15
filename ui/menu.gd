extends Control

@onready var btn_vs: Button = $Center/MainPanel/VBox/BtnVs
@onready var btn_training: Button = $Center/MainPanel/VBox/BtnTraining
@onready var btn_test_options: Button = $Center/MainPanel/VBox/BtnTestOptions
@onready var btn_quit: Button = $Center/MainPanel/VBox/BtnQuit
@onready var _hint: Label = $Center/MainPanel/VBox/Hint
@onready var _main_panel: Panel = $Center/MainPanel


func _ready() -> void:
	RunConfig.clear_shoot_mouse_bindings_for_menu()
	if _hint != null:
		_hint.text = RunConfig.get_main_menu_controls_hint()
		_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuThemeUtil.apply_main_panel_style(_main_panel)
	MenuThemeUtil.style_menu_button(btn_vs, true)
	MenuThemeUtil.style_menu_button(btn_training, false)
	MenuThemeUtil.style_menu_button(btn_test_options, false)
	MenuThemeUtil.style_menu_button(btn_quit, false)
	btn_vs.pressed.connect(_on_vs_pressed)
	btn_training.pressed.connect(_on_training_pressed)
	btn_test_options.pressed.connect(_on_test_options_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	_configure_focus_chain()
	btn_vs.grab_focus()


func _configure_focus_chain() -> void:
	btn_training.focus_neighbor_bottom = btn_test_options.get_path()
	btn_test_options.focus_neighbor_top = btn_training.get_path()
	btn_test_options.focus_neighbor_bottom = btn_quit.get_path()
	btn_quit.focus_neighbor_top = btn_test_options.get_path()


func _on_vs_pressed() -> void:
	get_tree().change_scene_to_file(MenuPaths.SCENE_VS_SETUP)


func _on_training_pressed() -> void:
	get_tree().change_scene_to_file(MenuPaths.SCENE_TRAINING_SETUP)


func _on_test_options_pressed() -> void:
	call_deferred("_open_test_options_menu")


func _open_test_options_menu() -> void:
	var err := get_tree().change_scene_to_file(MenuPaths.SCENE_TEST_OPTIONS)
	if err != OK:
		push_error("Opções de Teste: falha ao abrir menu (%s)." % error_string(err))


func _on_quit_pressed() -> void:
	get_tree().quit()
