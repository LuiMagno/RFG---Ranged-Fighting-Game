extends RefCounted
class_name MenuThemeUtil


static func apply_main_panel_style(panel: Panel) -> void:
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.11, 0.13, 0.18, 0.96)
	panel_sb.set_border_width_all(2)
	panel_sb.border_color = Color(0.35, 0.65, 0.92, 0.75)
	panel_sb.set_corner_radius_all(16)
	panel_sb.shadow_color = Color(0, 0, 0, 0.45)
	panel_sb.shadow_size = 6
	panel_sb.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", panel_sb)


static func style_menu_button(b: Button, primary: bool) -> void:
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


static func style_option(ob: OptionButton) -> void:
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


static func style_checkbox(cb: CheckBox) -> void:
	cb.add_theme_font_size_override("font_size", 14)
	cb.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92, 1))


static func fill_class_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("Pistoleiro")
	ob.add_item("Arqueiro")
	ob.add_item("Mago")
	ob.add_item("Esqueleto")


## Índice = Player.CharacterKind (0..3). Usado no HUD do Vs.
static func vs_character_name(kind: int) -> String:
	match clampi(kind, 0, 3):
		0:
			return "Pistoleiro"
		1:
			return "Arqueiro"
		2:
			return "Mago"
		3:
			return "Esqueleto"
		_:
			return "—"


## Cor de destaque por classe (legível sobre fundo escuro).
static func vs_character_accent_color(kind: int) -> Color:
	match clampi(kind, 0, 3):
		0:
			return Color(0.52, 0.82, 1.0)
		1:
			return Color(0.38, 0.9, 0.58)
		2:
			return Color(0.78, 0.52, 1.0)
		3:
			return Color(0.92, 0.86, 0.58)
		_:
			return Color(0.9, 0.92, 0.96, 1)
