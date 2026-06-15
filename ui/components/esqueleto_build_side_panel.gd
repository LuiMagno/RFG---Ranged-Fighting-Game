extends Control
class_name EsqueletoBuildSidePanel

signal panel_visibility_changed(is_visible: bool)

@onready var _main_panel: Panel = $MainPanel
@onready var _player_tabs: HBoxContainer = $MainPanel/VBox/PlayerTabs
@onready var _btn_player_1: Button = $MainPanel/VBox/PlayerTabs/BtnPlayer1
@onready var _btn_player_2: Button = $MainPanel/VBox/PlayerTabs/BtnPlayer2
@onready var _subtitle: Label = $MainPanel/VBox/Subtitle
@onready var _opt_skill_1: OptionButton = $MainPanel/VBox/Skill1Block/OptSkill1
@onready var _opt_skill_2: OptionButton = $MainPanel/VBox/Skill2Block/OptSkill2
@onready var _opt_basic_shot: OptionButton = $MainPanel/VBox/BasicShotBlock/OptBasicShot
@onready var _opt_dash: OptionButton = $MainPanel/VBox/DashBlock/OptDash
@onready var _opt_ult: OptionButton = $MainPanel/VBox/UltBlock/OptUlt

var _player_id: int = 1
var _slot_options: Dictionary = {}


func _ready() -> void:
	MenuThemeUtil.apply_esqueleto_build_submenu_style(_main_panel)
	_slot_options = {
		EsqueletoBuildCatalog.SLOT_SKILL_1: _opt_skill_1,
		EsqueletoBuildCatalog.SLOT_SKILL_2: _opt_skill_2,
		EsqueletoBuildCatalog.SLOT_BASIC_SHOT: _opt_basic_shot,
		EsqueletoBuildCatalog.SLOT_DASH: _opt_dash,
		EsqueletoBuildCatalog.SLOT_ULT: _opt_ult,
	}
	for slot_key: StringName in EsqueletoBuildCatalog.ALL_SLOTS:
		var ob: OptionButton = _slot_options[slot_key]
		MenuThemeUtil.style_option(ob)
		ob.item_selected.connect(_on_slot_selected.bind(slot_key))
	_btn_player_1.pressed.connect(_on_player_1_tab_pressed)
	_btn_player_2.pressed.connect(_on_player_2_tab_pressed)
	MenuThemeUtil.style_menu_button(_btn_player_1, false)
	MenuThemeUtil.style_menu_button(_btn_player_2, false)


func configure_for_vs() -> void:
	_player_tabs.visible = true
	_subtitle.visible = false
	bind_player(1)


func configure_for_training() -> void:
	_player_tabs.visible = false
	_subtitle.visible = true
	bind_player(1)


func bind_player(player_id: int) -> void:
	_player_id = clampi(player_id, 1, 2)
	if _subtitle.visible:
		_subtitle.text = "Jogador %d" % _player_id
	_refresh_player_tab_styles()
	refresh_from_run_config()


func refresh_from_run_config() -> void:
	var build := RunConfig.get_esqueleto_build(_player_id)
	for slot_key: StringName in EsqueletoBuildCatalog.ALL_SLOTS:
		var ob: OptionButton = _slot_options[slot_key]
		var skill_id: StringName = build.get(slot_key, EsqueletoBuildCatalog.get_default_skill_for_slot(slot_key))
		MenuThemeUtil.fill_esqueleto_build_slot_option(ob, slot_key, skill_id)


func set_visible_panel(show_panel: bool) -> void:
	if visible == show_panel:
		return
	visible = show_panel
	panel_visibility_changed.emit(show_panel)


func _refresh_player_tab_styles() -> void:
	if not _player_tabs.visible:
		return
	MenuThemeUtil.style_menu_button(_btn_player_1, _player_id == 1)
	MenuThemeUtil.style_menu_button(_btn_player_2, _player_id == 2)


func _on_player_1_tab_pressed() -> void:
	bind_player(1)


func _on_player_2_tab_pressed() -> void:
	bind_player(2)


func _on_slot_selected(_index: int, slot_key: StringName) -> void:
	var ob: OptionButton = _slot_options[slot_key]
	var skill_id := MenuThemeUtil.get_esqueleto_build_slot_option_id(ob)
	RunConfig.set_esqueleto_build_slot(_player_id, slot_key, skill_id)
