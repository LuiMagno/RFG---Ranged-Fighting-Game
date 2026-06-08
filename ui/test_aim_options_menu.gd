extends Control

@onready var opt_aim_mode: OptionButton = $Center/MainPanel/VBox/Scroll/AimBox/AimModeRow/OptAimMode
@onready var _lock_on_sep: HSeparator = $Center/MainPanel/VBox/Scroll/AimBox/LockOnSep
@onready var _lock_on_section_label: Label = $Center/MainPanel/VBox/Scroll/AimBox/LockOnSectionLabel
@onready var chk_lock_on_face_default: CheckBox = $Center/MainPanel/VBox/Scroll/AimBox/ChkLockOnFaceDefault
@onready var lbl_lock_on_hint: Label = $Center/MainPanel/VBox/Scroll/AimBox/LblLockOnHint
@onready var opt_aim_assist_level: OptionButton = $Center/MainPanel/VBox/Scroll/AimBox/AssistLevelRow/OptAimAssistLevel
@onready var slider_assist_angle_window: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/AssistAngleWindowRow/HSliderAssistAngleWindow
)
@onready var lbl_assist_angle_window: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/AssistAngleWindowRow/LblAssistAngleWindowVal
)
@onready var slider_assist_strength: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/AssistStrengthRow/HSliderAssistStrength
)
@onready var lbl_assist_strength: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/AssistStrengthRow/LblAssistStrengthVal
)
@onready var slider_assist_max_correction: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/AssistMaxCorrectionRow/HSliderAssistMaxCorrection
)
@onready var lbl_assist_max_correction: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/AssistMaxCorrectionRow/LblAssistMaxCorrectionVal
)
@onready var slider_aim_deadzone: HSlider = $Center/MainPanel/VBox/Scroll/AimBox/DeadzoneRow/HSliderAimDeadzone
@onready var lbl_aim_deadzone: Label = $Center/MainPanel/VBox/Scroll/AimBox/DeadzoneRow/LblAimDeadzoneVal
@onready var slider_aim_upper_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/UpperThresholdRow/HSliderAimUpperThreshold
)
@onready var lbl_aim_upper_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/UpperThresholdRow/LblAimUpperThresholdVal
)
@onready var slider_aim_lower_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/LowerThresholdRow/HSliderAimLowerThreshold
)
@onready var lbl_aim_lower_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/LowerThresholdRow/LblAimLowerThresholdVal
)
@onready var slider_aim_up_threshold: HSlider = $Center/MainPanel/VBox/Scroll/AimBox/UpThresholdRow/HSliderAimUpThreshold
@onready var lbl_aim_up_threshold: Label = $Center/MainPanel/VBox/Scroll/AimBox/UpThresholdRow/LblAimUpThresholdVal
@onready var slider_aim_up_diagonal_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/UpDiagonalThresholdRow/HSliderAimUpDiagonalThreshold
)
@onready var lbl_aim_up_diagonal_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/UpDiagonalThresholdRow/LblAimUpDiagonalThresholdVal
)
@onready var slider_aim_down_diagonal_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/DownDiagonalThresholdRow/HSliderAimDownDiagonalThreshold
)
@onready var lbl_aim_down_diagonal_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/DownDiagonalThresholdRow/LblAimDownDiagonalThresholdVal
)
@onready var slider_aim_down_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/DownThresholdRow/HSliderAimDownThreshold
)
@onready var lbl_aim_down_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/DownThresholdRow/LblAimDownThresholdVal
)
@onready var slider_auto_aim_up_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoUpThresholdRow/HSliderAutoAimUpThreshold
)
@onready var lbl_auto_aim_up_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoUpThresholdRow/LblAutoAimUpThresholdVal
)
@onready var slider_auto_aim_up_diagonal_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoUpDiagonalThresholdRow/HSliderAutoAimUpDiagonalThreshold
)
@onready var lbl_auto_aim_up_diagonal_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoUpDiagonalThresholdRow/LblAutoAimUpDiagonalThresholdVal
)
@onready var slider_auto_aim_forward_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoForwardThresholdRow/HSliderAutoAimForwardThreshold
)
@onready var lbl_auto_aim_forward_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoForwardThresholdRow/LblAutoAimForwardThresholdVal
)
@onready var slider_auto_aim_down_diagonal_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoDownDiagonalThresholdRow/HSliderAutoAimDownDiagonalThreshold
)
@onready var lbl_auto_aim_down_diagonal_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoDownDiagonalThresholdRow/LblAutoAimDownDiagonalThresholdVal
)
@onready var slider_auto_aim_down_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoDownThresholdRow/HSliderAutoAimDownThreshold
)
@onready var lbl_auto_aim_down_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/AutoDownThresholdRow/LblAutoAimDownThresholdVal
)
@onready var slider_hybrid_up_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/HybridUpThresholdRow/HSliderHybridUpThreshold
)
@onready var lbl_hybrid_up_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/HybridUpThresholdRow/LblHybridUpThresholdVal
)
@onready var slider_hybrid_down_threshold: HSlider = (
	$Center/MainPanel/VBox/Scroll/AimBox/HybridDownThresholdRow/HSliderHybridDownThreshold
)
@onready var lbl_hybrid_down_threshold: Label = (
	$Center/MainPanel/VBox/Scroll/AimBox/HybridDownThresholdRow/LblHybridDownThresholdVal
)
@onready var slider_aim_sensitivity: HSlider = $Center/MainPanel/VBox/Scroll/AimBox/SensitivityRow/HSliderAimSensitivity
@onready var lbl_aim_sensitivity: Label = $Center/MainPanel/VBox/Scroll/AimBox/SensitivityRow/LblAimSensitivityVal
@onready var slider_aim_smoothing: HSlider = $Center/MainPanel/VBox/Scroll/AimBox/SmoothingRow/HSliderAimSmoothing
@onready var lbl_aim_smoothing: Label = $Center/MainPanel/VBox/Scroll/AimBox/SmoothingRow/LblAimSmoothingVal
@onready var chk_aim_smoothing: CheckBox = $Center/MainPanel/VBox/Scroll/AimBox/ChkAimSmoothing
@onready var chk_aim_debug: CheckBox = $Center/MainPanel/VBox/Scroll/AimBox/ChkAimDebug
@onready var btn_back: Button = $Center/MainPanel/VBox/ButtonRow/BtnBack
@onready var _main_panel: Panel = $Center/MainPanel


func _ready() -> void:
	RunConfig.clear_shoot_mouse_bindings_for_menu()
	MenuThemeUtil.apply_main_panel_style(_main_panel)
	MenuThemeUtil.fill_test_aim_mode_option(opt_aim_mode)
	MenuThemeUtil.fill_test_aim_assist_level_option(opt_aim_assist_level)
	MenuThemeUtil.style_option(opt_aim_mode)
	MenuThemeUtil.style_option(opt_aim_assist_level)
	for sl in [
		slider_aim_deadzone,
		slider_aim_upper_threshold,
		slider_aim_lower_threshold,
		slider_aim_up_threshold,
		slider_aim_up_diagonal_threshold,
		slider_aim_down_diagonal_threshold,
		slider_aim_down_threshold,
		slider_auto_aim_up_threshold,
		slider_auto_aim_up_diagonal_threshold,
		slider_auto_aim_forward_threshold,
		slider_auto_aim_down_diagonal_threshold,
		slider_auto_aim_down_threshold,
		slider_hybrid_up_threshold,
		slider_hybrid_down_threshold,
		slider_aim_sensitivity,
		slider_aim_smoothing,
		slider_assist_angle_window,
		slider_assist_strength,
		slider_assist_max_correction,
	]:
		MenuThemeUtil.style_hslider(sl)
	MenuThemeUtil.style_checkbox(chk_aim_smoothing)
	MenuThemeUtil.style_checkbox(chk_aim_debug)
	MenuThemeUtil.style_checkbox(chk_lock_on_face_default)
	MenuThemeUtil.style_menu_button(btn_back, true)
	opt_aim_mode.select(
		clampi(int(RunConfig.test_aim_mode), 0, maxi(opt_aim_mode.item_count - 1, 0))
	)
	for i in range(opt_aim_assist_level.item_count):
		if opt_aim_assist_level.get_item_id(i) == int(RunConfig.test_aim_assist_level):
			opt_aim_assist_level.select(i)
			break
	slider_assist_angle_window.value = RunConfig.test_aim_assist_angle_window
	slider_assist_strength.value = RunConfig.test_aim_assist_strength
	slider_assist_max_correction.value = RunConfig.test_aim_assist_max_correction
	slider_aim_deadzone.min_value = 0.20
	slider_aim_deadzone.max_value = 0.35
	slider_aim_deadzone.step = 0.01
	slider_aim_deadzone.value = RunConfig.test_aim_deadzone
	slider_aim_upper_threshold.min_value = 5.0
	slider_aim_upper_threshold.max_value = 45.0
	slider_aim_upper_threshold.step = 1.0
	slider_aim_upper_threshold.value = RunConfig.test_aim_upper_angle_threshold
	slider_aim_lower_threshold.min_value = -45.0
	slider_aim_lower_threshold.max_value = -5.0
	slider_aim_lower_threshold.step = 1.0
	slider_aim_lower_threshold.value = RunConfig.test_aim_lower_angle_threshold
	slider_aim_up_threshold.min_value = 45.0
	slider_aim_up_threshold.max_value = 85.0
	slider_aim_up_threshold.step = 1.0
	slider_aim_up_threshold.value = RunConfig.test_aim_up_threshold
	slider_aim_up_diagonal_threshold.min_value = 15.0
	slider_aim_up_diagonal_threshold.max_value = 75.0
	slider_aim_up_diagonal_threshold.step = 1.0
	slider_aim_up_diagonal_threshold.value = RunConfig.test_aim_up_diagonal_threshold
	slider_aim_down_diagonal_threshold.min_value = -75.0
	slider_aim_down_diagonal_threshold.max_value = -15.0
	slider_aim_down_diagonal_threshold.step = 1.0
	slider_aim_down_diagonal_threshold.value = RunConfig.test_aim_down_diagonal_threshold
	slider_aim_down_threshold.min_value = -85.0
	slider_aim_down_threshold.max_value = -45.0
	slider_aim_down_threshold.step = 1.0
	slider_aim_down_threshold.value = RunConfig.test_aim_down_threshold
	slider_auto_aim_up_threshold.min_value = 45.0
	slider_auto_aim_up_threshold.max_value = 85.0
	slider_auto_aim_up_threshold.step = 1.0
	slider_auto_aim_up_threshold.value = RunConfig.test_auto_aim_up_threshold
	slider_auto_aim_up_diagonal_threshold.min_value = 15.0
	slider_auto_aim_up_diagonal_threshold.max_value = 75.0
	slider_auto_aim_up_diagonal_threshold.step = 1.0
	slider_auto_aim_up_diagonal_threshold.value = RunConfig.test_auto_aim_up_diagonal_threshold
	slider_auto_aim_forward_threshold.min_value = 5.0
	slider_auto_aim_forward_threshold.max_value = 45.0
	slider_auto_aim_forward_threshold.step = 1.0
	slider_auto_aim_forward_threshold.value = RunConfig.test_auto_aim_forward_threshold
	slider_auto_aim_down_diagonal_threshold.min_value = -75.0
	slider_auto_aim_down_diagonal_threshold.max_value = -15.0
	slider_auto_aim_down_diagonal_threshold.step = 1.0
	slider_auto_aim_down_diagonal_threshold.value = RunConfig.test_auto_aim_down_diagonal_threshold
	slider_auto_aim_down_threshold.min_value = -85.0
	slider_auto_aim_down_threshold.max_value = -45.0
	slider_auto_aim_down_threshold.step = 1.0
	slider_auto_aim_down_threshold.value = RunConfig.test_auto_aim_down_threshold
	slider_hybrid_up_threshold.min_value = 0.05
	slider_hybrid_up_threshold.max_value = 0.95
	slider_hybrid_up_threshold.step = 0.01
	slider_hybrid_up_threshold.value = RunConfig.test_hybrid_manual_up_threshold
	slider_hybrid_down_threshold.min_value = -0.95
	slider_hybrid_down_threshold.max_value = -0.05
	slider_hybrid_down_threshold.step = 0.01
	slider_hybrid_down_threshold.value = RunConfig.test_hybrid_manual_down_threshold
	slider_aim_sensitivity.min_value = 0.50
	slider_aim_sensitivity.max_value = 2.00
	slider_aim_sensitivity.step = 0.05
	slider_aim_sensitivity.value = RunConfig.test_aim_sensitivity
	slider_aim_smoothing.min_value = 0.03
	slider_aim_smoothing.max_value = 0.35
	slider_aim_smoothing.step = 0.01
	slider_aim_smoothing.value = RunConfig.test_aim_smoothing
	chk_aim_smoothing.button_pressed = RunConfig.test_aim_smoothing_enabled
	chk_aim_debug.button_pressed = RunConfig.test_aim_debug
	chk_lock_on_face_default.button_pressed = RunConfig.test_lock_on_face_default
	opt_aim_mode.item_selected.connect(_on_aim_mode_selected)
	opt_aim_assist_level.item_selected.connect(_on_aim_assist_level_selected)
	chk_lock_on_face_default.toggled.connect(_on_lock_on_face_default_toggled)
	slider_assist_angle_window.value_changed.connect(_on_assist_angle_window_changed)
	slider_assist_strength.value_changed.connect(_on_assist_strength_changed)
	slider_assist_max_correction.value_changed.connect(_on_assist_max_correction_changed)
	slider_aim_deadzone.value_changed.connect(_on_aim_deadzone_changed)
	slider_aim_upper_threshold.value_changed.connect(_on_aim_upper_threshold_changed)
	slider_aim_lower_threshold.value_changed.connect(_on_aim_lower_threshold_changed)
	slider_aim_up_threshold.value_changed.connect(_on_aim_up_threshold_changed)
	slider_aim_up_diagonal_threshold.value_changed.connect(_on_aim_up_diagonal_threshold_changed)
	slider_aim_down_diagonal_threshold.value_changed.connect(_on_aim_down_diagonal_threshold_changed)
	slider_aim_down_threshold.value_changed.connect(_on_aim_down_threshold_changed)
	slider_auto_aim_up_threshold.value_changed.connect(_on_auto_aim_up_threshold_changed)
	slider_auto_aim_up_diagonal_threshold.value_changed.connect(_on_auto_aim_up_diagonal_threshold_changed)
	slider_auto_aim_forward_threshold.value_changed.connect(_on_auto_aim_forward_threshold_changed)
	slider_auto_aim_down_diagonal_threshold.value_changed.connect(_on_auto_aim_down_diagonal_threshold_changed)
	slider_auto_aim_down_threshold.value_changed.connect(_on_auto_aim_down_threshold_changed)
	slider_hybrid_up_threshold.value_changed.connect(_on_hybrid_up_threshold_changed)
	slider_hybrid_down_threshold.value_changed.connect(_on_hybrid_down_threshold_changed)
	slider_aim_sensitivity.value_changed.connect(_on_aim_sensitivity_changed)
	slider_aim_smoothing.value_changed.connect(_on_aim_smoothing_changed)
	chk_aim_smoothing.toggled.connect(_on_aim_smoothing_toggled)
	chk_aim_debug.toggled.connect(_on_aim_debug_toggled)
	btn_back.pressed.connect(_on_back_pressed)
	_refresh_aim_slider_labels()
	_refresh_aim_controls_enabled()
	_refresh_lock_on_controls()
	_refresh_aim_assist_controls()
	opt_aim_mode.grab_focus()


func _refresh_aim_slider_labels() -> void:
	lbl_aim_deadzone.text = MenuThemeUtil.format_aim_deadzone(float(slider_aim_deadzone.value))
	lbl_aim_upper_threshold.text = MenuThemeUtil.format_aim_angle_threshold(float(slider_aim_upper_threshold.value))
	lbl_aim_lower_threshold.text = MenuThemeUtil.format_aim_angle_threshold(float(slider_aim_lower_threshold.value))
	lbl_aim_up_threshold.text = MenuThemeUtil.format_aim_angle_threshold(float(slider_aim_up_threshold.value))
	lbl_aim_up_diagonal_threshold.text = MenuThemeUtil.format_aim_angle_threshold(
		float(slider_aim_up_diagonal_threshold.value)
	)
	lbl_aim_down_diagonal_threshold.text = MenuThemeUtil.format_aim_angle_threshold(
		float(slider_aim_down_diagonal_threshold.value)
	)
	lbl_aim_down_threshold.text = MenuThemeUtil.format_aim_angle_threshold(float(slider_aim_down_threshold.value))
	lbl_auto_aim_up_threshold.text = MenuThemeUtil.format_aim_angle_threshold(float(slider_auto_aim_up_threshold.value))
	lbl_auto_aim_up_diagonal_threshold.text = MenuThemeUtil.format_aim_angle_threshold(
		float(slider_auto_aim_up_diagonal_threshold.value)
	)
	lbl_auto_aim_forward_threshold.text = MenuThemeUtil.format_aim_angle_threshold(
		float(slider_auto_aim_forward_threshold.value)
	)
	lbl_auto_aim_down_diagonal_threshold.text = MenuThemeUtil.format_aim_angle_threshold(
		float(slider_auto_aim_down_diagonal_threshold.value)
	)
	lbl_auto_aim_down_threshold.text = MenuThemeUtil.format_aim_angle_threshold(
		float(slider_auto_aim_down_threshold.value)
	)
	lbl_hybrid_up_threshold.text = MenuThemeUtil.format_hybrid_manual_threshold(
		float(slider_hybrid_up_threshold.value)
	)
	lbl_hybrid_down_threshold.text = MenuThemeUtil.format_hybrid_manual_threshold(
		float(slider_hybrid_down_threshold.value)
	)
	lbl_aim_sensitivity.text = MenuThemeUtil.format_aim_sensitivity(float(slider_aim_sensitivity.value))
	lbl_aim_smoothing.text = MenuThemeUtil.format_aim_smoothing(float(slider_aim_smoothing.value))
	lbl_assist_angle_window.text = MenuThemeUtil.format_aim_assist_angle_window(
		float(slider_assist_angle_window.value)
	)
	lbl_assist_strength.text = MenuThemeUtil.format_aim_assist_strength(float(slider_assist_strength.value))
	lbl_assist_max_correction.text = MenuThemeUtil.format_aim_assist_max_correction(
		float(slider_assist_max_correction.value)
	)


func _refresh_aim_controls_enabled() -> void:
	var free_continuous := (
		RunConfig.is_free_aim_right_stick_test() or RunConfig.is_free_aim_left_stick_test()
	)
	var three_way := RunConfig.is_right_stick_3_way_test()
	var five_way := RunConfig.is_right_stick_5_way_test()
	var auto_aim := RunConfig.is_auto_aim_5_way_test()
	var auto_aim_360 := RunConfig.is_auto_aim_360_test()
	var hybrid_manual := RunConfig.is_hybrid_manual_test()
	var lock_on_face := RunConfig.is_lock_on_face_test()
	var aim_assist := RunConfig.is_aim_assist_test_active()
	var angled_test := RunConfig.uses_angled_shot_test()
	var smooth_on := free_continuous and RunConfig.test_aim_smoothing_enabled
	var has_aim_tuning := free_continuous or RunConfig.is_quantized_right_stick_test()
	_set_aim_slider_interactive(slider_aim_deadzone, has_aim_tuning and not auto_aim_360 and not hybrid_manual)
	_set_aim_slider_interactive(slider_aim_upper_threshold, three_way)
	_set_aim_slider_interactive(slider_aim_lower_threshold, three_way)
	_set_aim_slider_interactive(slider_aim_up_threshold, five_way)
	_set_aim_slider_interactive(slider_aim_up_diagonal_threshold, five_way)
	_set_aim_slider_interactive(slider_aim_down_diagonal_threshold, five_way)
	_set_aim_slider_interactive(slider_aim_down_threshold, five_way)
	_set_aim_slider_interactive(slider_auto_aim_up_threshold, auto_aim)
	_set_aim_slider_interactive(slider_auto_aim_up_diagonal_threshold, auto_aim)
	_set_aim_slider_interactive(slider_auto_aim_forward_threshold, auto_aim)
	_set_aim_slider_interactive(slider_auto_aim_down_diagonal_threshold, auto_aim)
	_set_aim_slider_interactive(slider_auto_aim_down_threshold, auto_aim)
	_set_aim_slider_interactive(slider_hybrid_up_threshold, hybrid_manual)
	_set_aim_slider_interactive(slider_hybrid_down_threshold, hybrid_manual)
	_set_aim_slider_interactive(slider_aim_sensitivity, free_continuous)
	_set_aim_slider_interactive(slider_aim_smoothing, smooth_on)
	chk_aim_smoothing.disabled = not free_continuous
	chk_aim_debug.disabled = not (angled_test or lock_on_face or aim_assist)


func _set_aim_slider_interactive(sl: HSlider, enabled: bool) -> void:
	sl.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	sl.modulate = Color.WHITE if enabled else Color(0.55, 0.58, 0.62, 1.0)


func _on_aim_mode_selected(index: int) -> void:
	RunConfig.test_aim_mode = index as RunConfig.TestAimMode
	if not RunConfig.is_lock_on_face_test():
		RunConfig.test_lock_on_face_default = false
		chk_lock_on_face_default.button_pressed = false
	_refresh_aim_controls_enabled()
	_refresh_lock_on_controls()


func _on_aim_deadzone_changed(value: float) -> void:
	RunConfig.test_aim_deadzone = value
	lbl_aim_deadzone.text = MenuThemeUtil.format_aim_deadzone(value)


func _on_aim_upper_threshold_changed(value: float) -> void:
	RunConfig.test_aim_upper_angle_threshold = value
	lbl_aim_upper_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_aim_lower_threshold_changed(value: float) -> void:
	RunConfig.test_aim_lower_angle_threshold = value
	lbl_aim_lower_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_aim_up_threshold_changed(value: float) -> void:
	RunConfig.test_aim_up_threshold = value
	lbl_aim_up_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_aim_up_diagonal_threshold_changed(value: float) -> void:
	RunConfig.test_aim_up_diagonal_threshold = value
	lbl_aim_up_diagonal_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_aim_down_diagonal_threshold_changed(value: float) -> void:
	RunConfig.test_aim_down_diagonal_threshold = value
	lbl_aim_down_diagonal_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_aim_down_threshold_changed(value: float) -> void:
	RunConfig.test_aim_down_threshold = value
	lbl_aim_down_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_auto_aim_up_threshold_changed(value: float) -> void:
	RunConfig.test_auto_aim_up_threshold = value
	lbl_auto_aim_up_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_auto_aim_up_diagonal_threshold_changed(value: float) -> void:
	RunConfig.test_auto_aim_up_diagonal_threshold = value
	lbl_auto_aim_up_diagonal_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_auto_aim_forward_threshold_changed(value: float) -> void:
	RunConfig.test_auto_aim_forward_threshold = value
	lbl_auto_aim_forward_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_auto_aim_down_diagonal_threshold_changed(value: float) -> void:
	RunConfig.test_auto_aim_down_diagonal_threshold = value
	lbl_auto_aim_down_diagonal_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_auto_aim_down_threshold_changed(value: float) -> void:
	RunConfig.test_auto_aim_down_threshold = value
	lbl_auto_aim_down_threshold.text = MenuThemeUtil.format_aim_angle_threshold(value)


func _on_hybrid_up_threshold_changed(value: float) -> void:
	RunConfig.test_hybrid_manual_up_threshold = value
	lbl_hybrid_up_threshold.text = MenuThemeUtil.format_hybrid_manual_threshold(value)


func _on_hybrid_down_threshold_changed(value: float) -> void:
	RunConfig.test_hybrid_manual_down_threshold = value
	lbl_hybrid_down_threshold.text = MenuThemeUtil.format_hybrid_manual_threshold(value)


func _on_aim_sensitivity_changed(value: float) -> void:
	RunConfig.test_aim_sensitivity = value
	lbl_aim_sensitivity.text = MenuThemeUtil.format_aim_sensitivity(value)


func _on_aim_smoothing_changed(value: float) -> void:
	RunConfig.test_aim_smoothing = value
	lbl_aim_smoothing.text = MenuThemeUtil.format_aim_smoothing(value)


func _on_aim_smoothing_toggled(pressed: bool) -> void:
	RunConfig.test_aim_smoothing_enabled = pressed
	_refresh_aim_controls_enabled()


func _on_aim_debug_toggled(pressed: bool) -> void:
	RunConfig.test_aim_debug = pressed


func _refresh_lock_on_controls() -> void:
	var lock_on_mode := RunConfig.is_lock_on_face_test()
	_lock_on_sep.visible = lock_on_mode
	_lock_on_section_label.visible = lock_on_mode
	chk_lock_on_face_default.visible = lock_on_mode
	lbl_lock_on_hint.visible = lock_on_mode
	chk_lock_on_face_default.disabled = not lock_on_mode
	if lock_on_mode:
		lbl_lock_on_hint.text = "Na partida: L (P1) / O ou Select alterna horizontal ↔ lock-on"


func _on_lock_on_face_default_toggled(pressed: bool) -> void:
	RunConfig.test_lock_on_face_default = pressed


func _refresh_aim_assist_controls() -> void:
	var active := RunConfig.is_aim_assist_test_active()
	_set_aim_slider_interactive(slider_assist_angle_window, active)
	_set_aim_slider_interactive(slider_assist_strength, active)
	_set_aim_slider_interactive(slider_assist_max_correction, active)


func _on_aim_assist_level_selected(_index: int) -> void:
	RunConfig.test_aim_assist_level = (
		MenuThemeUtil.get_test_aim_assist_level_option_id(opt_aim_assist_level)
		as RunConfig.TestAimAssistLevel
	)
	match RunConfig.test_aim_assist_level:
		RunConfig.TestAimAssistLevel.LOW:
			RunConfig.test_aim_assist_strength = 0.25
			slider_assist_strength.value = 0.25
		RunConfig.TestAimAssistLevel.HIGH:
			RunConfig.test_aim_assist_strength = 0.5
			slider_assist_strength.value = 0.5
	_refresh_aim_assist_controls()
	_refresh_aim_controls_enabled()
	lbl_assist_strength.text = MenuThemeUtil.format_aim_assist_strength(
		float(slider_assist_strength.value)
	)


func _on_assist_angle_window_changed(value: float) -> void:
	RunConfig.test_aim_assist_angle_window = value
	lbl_assist_angle_window.text = MenuThemeUtil.format_aim_assist_angle_window(value)


func _on_assist_strength_changed(value: float) -> void:
	RunConfig.test_aim_assist_strength = value
	lbl_assist_strength.text = MenuThemeUtil.format_aim_assist_strength(value)


func _on_assist_max_correction_changed(value: float) -> void:
	RunConfig.test_aim_assist_max_correction = value
	lbl_assist_max_correction.text = MenuThemeUtil.format_aim_assist_max_correction(value)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MenuPaths.SCENE_TEST_OPTIONS)
