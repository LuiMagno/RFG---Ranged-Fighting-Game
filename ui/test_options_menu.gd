extends Control

@onready var chk_dummy_shoot: CheckBox = $Center/MainPanel/VBox/TrainingBox/ChkDummyShoot
@onready var opt_ko_camera_impact: OptionButton = $Center/MainPanel/VBox/VisualBox/KoCameraRow/OptKoCameraImpact
@onready var opt_vs_intro: OptionButton = $Center/MainPanel/VBox/VisualBox/VsIntroRow/OptVsIntro
@onready var btn_aim_options: Button = $Center/MainPanel/VBox/AimNavBox/BtnAimOptions
@onready var lbl_aim_summary: Label = $Center/MainPanel/VBox/AimNavBox/LblAimSummary
@onready var opt_esqueleto_projetil_vel: OptionButton = (
	$Center/MainPanel/VBox/EsqueletoBox/ProjetilVelRow/OptEsqueletoProjetilVel
)
@onready var btn_back: Button = $Center/MainPanel/VBox/ButtonRow/BtnBack
@onready var _main_panel: Panel = $Center/MainPanel


func _ready() -> void:
	RunConfig.clear_shoot_mouse_bindings_for_menu()
	MenuThemeUtil.apply_main_panel_style(_main_panel)
	MenuThemeUtil.style_checkbox(chk_dummy_shoot)
	MenuThemeUtil.fill_ko_camera_impact_option(opt_ko_camera_impact)
	MenuThemeUtil.style_option(opt_ko_camera_impact)
	MenuThemeUtil.fill_vs_intro_option(opt_vs_intro)
	MenuThemeUtil.style_option(opt_vs_intro)
	MenuThemeUtil.style_menu_button(btn_aim_options, false)
	MenuThemeUtil.fill_esqueleto_projetil_velocidade_option(opt_esqueleto_projetil_vel)
	MenuThemeUtil.style_option(opt_esqueleto_projetil_vel)
	MenuThemeUtil.style_menu_button(btn_back, true)
	chk_dummy_shoot.button_pressed = RunConfig.training_dummy_shoot
	opt_ko_camera_impact.select(
		clampi(int(RunConfig.ko_camera_impact_style), 0, maxi(opt_ko_camera_impact.item_count - 1, 0))
	)
	opt_vs_intro.select(
		clampi(int(RunConfig.vs_intro_style), 0, maxi(opt_vs_intro.item_count - 1, 0))
	)
	MenuThemeUtil.select_esqueleto_projetil_velocidade_option(
		opt_esqueleto_projetil_vel, int(RunConfig.esqueleto_projetil_velocidade)
	)
	chk_dummy_shoot.toggled.connect(_on_dummy_shoot_toggled)
	opt_ko_camera_impact.item_selected.connect(_on_ko_camera_impact_selected)
	opt_vs_intro.item_selected.connect(_on_vs_intro_selected)
	btn_aim_options.pressed.connect(_on_aim_options_pressed)
	opt_esqueleto_projetil_vel.item_selected.connect(_on_esqueleto_projetil_vel_selected)
	btn_back.pressed.connect(_on_back_pressed)
	_refresh_aim_summary()
	chk_dummy_shoot.grab_focus()


func _refresh_aim_summary() -> void:
	lbl_aim_summary.text = MenuThemeUtil.get_test_aim_summary_with_assist()


func _on_dummy_shoot_toggled(pressed: bool) -> void:
	RunConfig.training_dummy_shoot = pressed


func _on_ko_camera_impact_selected(index: int) -> void:
	RunConfig.ko_camera_impact_style = index as RunConfig.KoCameraImpactStyle


func _on_vs_intro_selected(index: int) -> void:
	RunConfig.vs_intro_style = index as RunConfig.VsIntroStyle


func _on_aim_options_pressed() -> void:
	var err := get_tree().change_scene_to_file(MenuPaths.SCENE_TEST_AIM_OPTIONS)
	if err != OK:
		push_error("Mira (teste): falha ao abrir menu (%s)." % error_string(err))


func _on_esqueleto_projetil_vel_selected(_index: int) -> void:
	RunConfig.esqueleto_projetil_velocidade = (
		MenuThemeUtil.get_esqueleto_projetil_velocidade_option_id(opt_esqueleto_projetil_vel)
		as RunConfig.EsqueletoProjetilVelocidade
	)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MenuPaths.SCENE_MAIN_MENU)
