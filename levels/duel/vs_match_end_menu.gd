extends CanvasLayer
class_name VsMatchEndMenu

## Pós-partida (Vs): sair, escolher personagens ou revanche.

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Center/Panel/VBox/Title
@onready var _btn_exit: Button = $Root/Center/Panel/VBox/BtnExit
@onready var _btn_chars: Button = $Root/Center/Panel/VBox/BtnCharacters
@onready var _btn_rematch: Button = $Root/Center/Panel/VBox/BtnRematch


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_btn_exit.pressed.connect(_on_exit_pressed)
	_btn_chars.pressed.connect(_on_characters_pressed)
	_btn_rematch.pressed.connect(_on_rematch_pressed)
	_apply_panel_style()


func open_for_match_winner(match_winner_id: int) -> void:
	_title.text = "Jogador %d venceu a partida!" % match_winner_id
	_root.visible = true
	get_tree().paused = true
	_btn_rematch.grab_focus()


func close_menu() -> void:
	_root.visible = false


func _on_exit_pressed() -> void:
	get_tree().paused = false
	RunConfig.clear_p1_shoot_mouse_binding()
	get_tree().change_scene_to_file("res://ui/menu.tscn")


func _on_characters_pressed() -> void:
	get_tree().paused = false
	RunConfig.clear_p1_shoot_mouse_binding()
	get_tree().change_scene_to_file("res://ui/vs_character_menu.tscn")


func _on_rematch_pressed() -> void:
	var g := get_parent() as Game
	if g == null:
		return
	get_tree().paused = false
	close_menu()
	g.rematch_vs_after_post_game()


func _apply_panel_style() -> void:
	var panel: Panel = $Root/Center/Panel as Panel
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.12, 0.18, 0.98)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.45, 0.75, 0.98, 0.9)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	_style_primary(_btn_rematch)
	_style_secondary(_btn_chars)
	_style_secondary(_btn_exit)


func _style_primary(b: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.22, 0.52, 0.88, 1.0)
	n.set_corner_radius_all(8)
	n.set_content_margin_all(12)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.32, 0.62, 0.98, 1.0)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.16, 0.4, 0.72, 1.0)
	for sb in [n, h, p]:
		sb.set_corner_radius_all(8)
		sb.set_content_margin_all(12)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_font_size_override("font_size", 17)


func _style_secondary(b: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.2, 0.22, 0.28, 1.0)
	n.set_corner_radius_all(8)
	n.set_content_margin_all(12)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.28, 0.32, 0.4, 1.0)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.16, 0.18, 0.24, 1.0)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_font_size_override("font_size", 16)
