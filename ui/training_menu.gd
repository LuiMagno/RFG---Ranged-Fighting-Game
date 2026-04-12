extends Control

@onready var opt_p1_class: OptionButton = $Center/MainPanel/VBox/ClassP1Row/OptP1Class
@onready var chk_dummy_shoot: CheckBox = $Center/MainPanel/VBox/TrainingBox/ChkDummyShoot
@onready var btn_back: Button = $Center/MainPanel/VBox/ButtonRow/BtnBack
@onready var btn_start: Button = $Center/MainPanel/VBox/ButtonRow/BtnStart
@onready var _main_panel: Panel = $Center/MainPanel


func _ready() -> void:
	RunConfig.clear_p1_shoot_mouse_binding()
	MenuThemeUtil.apply_main_panel_style(_main_panel)
	MenuThemeUtil.fill_class_option(opt_p1_class)
	MenuThemeUtil.style_option(opt_p1_class)
	MenuThemeUtil.style_checkbox(chk_dummy_shoot)
	MenuThemeUtil.style_menu_button(btn_back, false)
	MenuThemeUtil.style_menu_button(btn_start, true)
	var imax := maxi(opt_p1_class.item_count - 1, 0)
	opt_p1_class.select(clampi(RunConfig.p1_character, 0, imax))
	chk_dummy_shoot.button_pressed = RunConfig.training_dummy_shoot
	btn_back.pressed.connect(_on_back_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_start.grab_focus()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menu.tscn")


func _on_start_pressed() -> void:
	RunConfig.p1_character = opt_p1_class.selected
	RunConfig.mode = RunConfig.Mode.TRAINING
	RunConfig.training_dummy_shoot = chk_dummy_shoot.button_pressed
	RunConfig.training_dummy_interval = 3.0
	get_tree().change_scene_to_file("res://levels/duel/main.tscn")
