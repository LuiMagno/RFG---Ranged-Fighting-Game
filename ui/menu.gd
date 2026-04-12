extends Control

@onready var btn_vs: Button = $Center/MainPanel/VBox/BtnVs
@onready var btn_training: Button = $Center/MainPanel/VBox/BtnTraining
@onready var btn_quit: Button = $Center/MainPanel/VBox/BtnQuit
@onready var _main_panel: Panel = $Center/MainPanel


func _ready() -> void:
	RunConfig.clear_p1_shoot_mouse_binding()
	MenuThemeUtil.apply_main_panel_style(_main_panel)
	MenuThemeUtil.style_menu_button(btn_vs, true)
	MenuThemeUtil.style_menu_button(btn_training, false)
	MenuThemeUtil.style_menu_button(btn_quit, false)
	btn_vs.pressed.connect(_on_vs_pressed)
	btn_training.pressed.connect(_on_training_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_vs.grab_focus()


func _on_vs_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/vs_character_menu.tscn")


func _on_training_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/training_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
