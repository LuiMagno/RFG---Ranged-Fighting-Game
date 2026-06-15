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
	# ob.add_item("Pistoleiro", Player.CharacterKind.PISTOLEIRO)
	# ob.add_item("Arqueiro", Player.CharacterKind.ARQUEIRO)
	# ob.add_item("Mago", Player.CharacterKind.MAGO)
	ob.add_item("Esqueleto", Player.CharacterKind.ESQUELETO)
	ob.add_item("Ongma Epilef (teste)", Player.CharacterKind.ONGMA_EPILEF)


static func select_class_option(ob: OptionButton, kind: int) -> void:
	kind = RunConfig.clamp_character_kind(kind)
	for i in ob.item_count:
		if ob.get_item_id(i) == kind:
			ob.select(i)
			return
	if ob.item_count > 0:
		ob.select(0)


static func get_class_option_id(ob: OptionButton) -> int:
	if ob.item_count <= 0:
		return Player.CharacterKind.ESQUELETO
	return ob.get_item_id(ob.selected)


static func fill_esqueleto_build_slot_option(ob: OptionButton, slot_key: StringName, selected_id: StringName) -> void:
	ob.clear()
	var options := EsqueletoBuildCatalog.get_slot_options(slot_key)
	for opt in options:
		var idx := ob.item_count
		ob.add_item(String(opt.get("label", "")))
		ob.set_item_metadata(idx, opt.get("id", &""))
	select_esqueleto_build_slot_option(ob, selected_id)


static func select_esqueleto_build_slot_option(ob: OptionButton, selected_id: StringName) -> void:
	for i in ob.item_count:
		if ob.get_item_metadata(i) == selected_id:
			ob.select(i)
			return
	if ob.item_count > 0:
		ob.select(0)


static func get_esqueleto_build_slot_option_id(ob: OptionButton) -> StringName:
	if ob.item_count <= 0:
		return &""
	var meta: Variant = ob.get_item_metadata(ob.selected)
	if meta is StringName:
		return meta
	return &""


static func apply_esqueleto_build_side_panel_style(panel: Panel) -> void:
	apply_esqueleto_build_submenu_style(panel)


static func apply_esqueleto_build_submenu_style(panel: Panel) -> void:
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.09, 0.11, 0.15, 0.96)
	panel_sb.set_border_width_all(2)
	panel_sb.border_color = Color(0.35, 0.65, 0.92, 0.5)
	panel_sb.set_corner_radius_all(14)
	panel_sb.set_content_margin_all(2)
	panel_sb.shadow_color = Color(0, 0, 0, 0.2)
	panel_sb.shadow_size = 2
	panel_sb.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", panel_sb)


static func fill_stage_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("Normal", RunConfig.Stage.NORMAL)
	ob.add_item("Patamares + abismo", RunConfig.Stage.TIERED_ABYSS)
	ob.add_item("Fábrica antiga", RunConfig.Stage.OLD_FACTORY)


static func fill_ko_camera_impact_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("A — Slow motion", RunConfig.KoCameraImpactStyle.SLOW_MOTION)
	ob.add_item("B — Hit stop", RunConfig.KoCameraImpactStyle.HIT_STOP)
	ob.add_item("C — Híbrido", RunConfig.KoCameraImpactStyle.HYBRID)


static func fill_vs_intro_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("A — Rápido", RunConfig.VsIntroStyle.A_FAST)
	ob.add_item("B — Médio", RunConfig.VsIntroStyle.B_MEDIUM)
	ob.add_item("C — Cinemático", RunConfig.VsIntroStyle.C_CINEMATIC)


static func fill_test_aim_mode_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("Padrão — horizontal", RunConfig.TestAimMode.LOCKED_HORIZONTAL)
	ob.add_item("Free aim — stick dir / mouse", RunConfig.TestAimMode.FREE_AIM_RIGHT_STICK)
	ob.add_item("Free aim — stick esq. (mov + tiro)", RunConfig.TestAimMode.FREE_AIM_LEFT_STICK)
	ob.add_item("3-way — stick dir (quantizado)", RunConfig.TestAimMode.RIGHT_STICK_3_WAY)
	ob.add_item("5-way — stick dir (quantizado)", RunConfig.TestAimMode.RIGHT_STICK_5_WAY)
	ob.add_item("Auto aim — 5 direções", RunConfig.TestAimMode.AUTO_AIM_5_WAY)
	ob.add_item("Auto aim — 360° exacto", RunConfig.TestAimMode.AUTO_AIM_360)
	ob.add_item("Hybrid manual — 3 intenções (stick esq.)", RunConfig.TestAimMode.HYBRID_MANUAL)
	ob.add_item("Lock-on face — horizontal + virar ao alvo", RunConfig.TestAimMode.LOCK_ON_FACE)


static func get_test_aim_mode_summary(mode: int) -> String:
	match mode:
		RunConfig.TestAimMode.FREE_AIM_RIGHT_STICK:
			return "Modo actual: free aim — stick dir / mouse"
		RunConfig.TestAimMode.FREE_AIM_LEFT_STICK:
			return "Modo actual: free aim — stick esq."
		RunConfig.TestAimMode.RIGHT_STICK_3_WAY:
			return "Modo actual: 3-way quantizado"
		RunConfig.TestAimMode.RIGHT_STICK_5_WAY:
			return "Modo actual: 5-way quantizado"
		RunConfig.TestAimMode.AUTO_AIM_5_WAY:
			return "Modo actual: auto aim — 5 direções"
		RunConfig.TestAimMode.AUTO_AIM_360:
			return "Modo actual: auto aim — 360° exacto"
		RunConfig.TestAimMode.HYBRID_MANUAL:
			return "Modo actual: hybrid manual — 3 intenções"
		RunConfig.TestAimMode.LOCK_ON_FACE:
			return "Modo actual: lock-on face — horizontal + virar ao alvo"
		_:
			return "Modo actual: padrão — horizontal"


static func get_test_aim_mode_debug_name(mode: int) -> String:
	match mode:
		RunConfig.TestAimMode.FREE_AIM_RIGHT_STICK:
			return "FREE_AIM_RIGHT_STICK"
		RunConfig.TestAimMode.FREE_AIM_LEFT_STICK:
			return "FREE_AIM_LEFT_STICK"
		RunConfig.TestAimMode.RIGHT_STICK_3_WAY:
			return "RIGHT_STICK_3_WAY"
		RunConfig.TestAimMode.RIGHT_STICK_5_WAY:
			return "RIGHT_STICK_5_WAY"
		RunConfig.TestAimMode.AUTO_AIM_5_WAY:
			return "AUTO_AIM_5_WAY"
		RunConfig.TestAimMode.AUTO_AIM_360:
			return "AUTO_AIM_360"
		RunConfig.TestAimMode.HYBRID_MANUAL:
			return "HYBRID_MANUAL"
		RunConfig.TestAimMode.LOCK_ON_FACE:
			return "LOCK_ON_FACE"
		_:
			return "LOCKED_HORIZONTAL"


static func get_test_aim_summary_with_assist() -> String:
	var summary := get_test_aim_mode_summary(int(RunConfig.test_aim_mode))
	if RunConfig.is_aim_assist_test_active():
		summary += " + AIM_ASSIST " + RunConfig.get_test_aim_assist_level_label()
	return summary


static func fill_test_aim_assist_level_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("OFF", RunConfig.TestAimAssistLevel.OFF)
	ob.add_item("LOW", RunConfig.TestAimAssistLevel.LOW)
	ob.add_item("HIGH", RunConfig.TestAimAssistLevel.HIGH)


static func get_test_aim_assist_level_option_id(ob: OptionButton) -> int:
	return ob.get_item_id(ob.selected)


static func style_hslider(sl: HSlider) -> void:
	sl.add_theme_font_size_override("font_size", 13)


static func format_aim_deadzone(v: float) -> String:
	return "%.2f" % v


static func format_aim_sensitivity(v: float) -> String:
	return "%.2f" % v


static func format_aim_smoothing(v: float) -> String:
	return "%.2fs" % v


static func format_aim_angle_threshold(v: float) -> String:
	return "%.0f°" % v


static func format_hybrid_manual_threshold(v: float) -> String:
	return "%.2f" % v


static func format_aim_assist_angle_window(v: float) -> String:
	return "%.0f°" % v


static func format_aim_assist_strength(v: float) -> String:
	return "%.0f%%" % (v * 100.0)


static func format_aim_assist_max_correction(v: float) -> String:
	return "%.0f°" % v


static func fill_esqueleto_projetil_velocidade_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("1.0× — Baseline", RunConfig.EsqueletoProjetilVelocidade.MUL_100)
	ob.add_item("1.25× — +25%", RunConfig.EsqueletoProjetilVelocidade.MUL_125)
	ob.add_item("1.5× — +50%", RunConfig.EsqueletoProjetilVelocidade.MUL_150)
	ob.add_item("1.75× — +75%", RunConfig.EsqueletoProjetilVelocidade.MUL_175)


static func select_esqueleto_projetil_velocidade_option(ob: OptionButton, preset: int) -> void:
	for i in ob.item_count:
		if ob.get_item_id(i) == preset:
			ob.select(i)
			return
	ob.select(0)


static func get_esqueleto_projetil_velocidade_option_id(ob: OptionButton) -> int:
	var idx := ob.selected
	if idx < 0 or idx >= ob.item_count:
		return RunConfig.EsqueletoProjetilVelocidade.MUL_150
	return ob.get_item_id(idx)


static func fill_input_scheme_option(ob: OptionButton) -> void:
	ob.clear()
	ob.add_item("Teclado e mouse", RunConfig.InputScheme.KEYBOARD_MOUSE)
	ob.add_item("Controle", RunConfig.InputScheme.GAMEPAD)


static func fill_joy_device_option(ob: OptionButton) -> void:
	ob.clear()
	var pads: PackedInt32Array = Input.get_connected_joypads()
	if pads.is_empty():
		for i in 8:
			ob.add_item("Controle nº %d" % i, i)
		return
	var sorted: Array = []
	for d in pads:
		sorted.append(int(d))
	sorted.sort()
	for d in sorted:
		ob.add_item("Controle nº %d" % d, d)


## Seleciona pelo índice SDL (`item` id), não pelo índice da linha no OptionButton.
static func select_joy_device_option(ob: OptionButton, device_id: int) -> void:
	for i in ob.item_count:
		if ob.get_item_id(i) == device_id:
			ob.select(i)
			return
	if ob.item_count > 0:
		ob.select(0)


static func get_joy_device_option_id(ob: OptionButton) -> int:
	if ob.item_count <= 0:
		return 0
	return ob.get_item_id(ob.selected)


## Índice = Player.CharacterKind (0..4). Usado no HUD do Vs.
static func vs_character_name(kind: int) -> String:
	match clampi(kind, 0, 4):
		0:
			return "Pistoleiro"
		1:
			return "Arqueiro"
		2:
			return "Mago"
		3:
			return "Esqueleto"
		4:
			return "Ongma Epilef"
		_:
			return "—"


## Cor de destaque por classe (legível sobre fundo escuro).
static func vs_character_accent_color(kind: int) -> Color:
	match clampi(kind, 0, 4):
		0:
			return Color(0.52, 0.82, 1.0)
		1:
			return Color(0.38, 0.9, 0.58)
		2:
			return Color(0.78, 0.52, 1.0)
		3:
			return Color(0.92, 0.86, 0.58)
		4:
			return Color(0.55, 0.78, 0.95)
		_:
			return Color(0.9, 0.92, 0.96, 1)
