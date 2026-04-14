extends Node

# Singleton em Project Settings → Autoload (nome: RunConfig).
# Não use class_name RunConfig aqui — conflita com o autoload.

enum Mode { VS_PLAYER, TRAINING }

## Teclado e mouse vs controle (por jogador). O mapa em runtime é aplicado em `Game._ensure_input_map()`.
enum InputScheme { KEYBOARD_MOUSE, GAMEPAD }

var mode: Mode = Mode.VS_PLAYER

var training_dummy_shoot: bool = true
var training_dummy_interval: float = 3.0

# Personagem: 0 = pistoleiro, 1 = arqueiro, 2 = mago, 3 = esqueleto, 4 = ongma epilef (teste). Ver Game._assign_player_script.
var p1_character: int = 0
var p2_character: int = 1

var p1_input_scheme: InputScheme = InputScheme.KEYBOARD_MOUSE
## No Vs só um jogador pode usar teclado+mouse; o outro usa controle (padrão: P2 em controle).
var p2_input_scheme: InputScheme = InputScheme.GAMEPAD
## Índice SDL do comando (0 = primeiro ligado). Usado só quando o esquema desse jogador é GAMEPAD.
var p1_joy_device: int = 0
var p2_joy_device: int = 1

var _ui_gamepad_navigation_ready: bool = false


func _ready() -> void:
	ensure_ui_gamepad_navigation()


func is_player_using_gamepad(player_id: int) -> bool:
	if player_id == 1:
		return p1_input_scheme == InputScheme.GAMEPAD
	return p2_input_scheme == InputScheme.GAMEPAD


## Palavra curta para textos de HUD (tiro / soltar).
func get_shoot_hint_token_for_player(player_id: int) -> String:
	if is_player_using_gamepad(player_id):
		return "RB"
	return "mouse"


## Linha de ajuda no menu principal (controles gerais).
func get_main_menu_controls_hint() -> String:
	return "Menus: cruz direcional ou analógico esquerdo • A ou Enter para confirmar • B para voltar • No Vs: Start ou Enter para pausar • No combate, escolha a entrada no Vs ou no Treino"


## Nos menus, remove o clique esquerdo do mouse em `p1_shoot` / `p2_shoot` para os botões funcionarem.
func clear_p1_shoot_mouse_binding() -> void:
	_clear_mouse_left_from_action("p1_shoot")


func clear_p2_shoot_mouse_binding() -> void:
	_clear_mouse_left_from_action("p2_shoot")


func clear_shoot_mouse_bindings_for_menu() -> void:
	clear_p1_shoot_mouse_binding()
	clear_p2_shoot_mouse_binding()


func _clear_mouse_left_from_action(action_name: StringName) -> void:
	if not InputMap.has_action(action_name):
		return
	var to_remove: Array = []
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			to_remove.append(ev)
	for ev in to_remove:
		InputMap.action_erase_event(action_name, ev)


## Só um jogador pode estar em `KEYBOARD_MOUSE` no Vs. `prefer_player_id` = quem acabou de escolher teclado+mouse (1 ou 2).
func resolve_exclusive_keyboard_mouse(prefer_player_id: int) -> void:
	if p1_input_scheme != InputScheme.KEYBOARD_MOUSE or p2_input_scheme != InputScheme.KEYBOARD_MOUSE:
		return
	if prefer_player_id == 1:
		p2_input_scheme = InputScheme.GAMEPAD
	else:
		p1_input_scheme = InputScheme.GAMEPAD


## Garante estado válido antes de montar o InputMap (ex.: saves antigos com os dois em teclado+mouse).
func ensure_valid_input_scheme_pair() -> void:
	if p1_input_scheme == InputScheme.KEYBOARD_MOUSE and p2_input_scheme == InputScheme.KEYBOARD_MOUSE:
		p2_input_scheme = InputScheme.GAMEPAD


## Garante `ui_*` com teclado + qualquer comando (device -1) para navegação nos menus.
func ensure_ui_gamepad_navigation() -> void:
	if _ui_gamepad_navigation_ready:
		return
	_ui_gamepad_navigation_ready = true

	_ensure_action_exists("ui_left", 0.5)
	_ensure_action_exists("ui_right", 0.5)
	_ensure_action_exists("ui_up", 0.5)
	_ensure_action_exists("ui_down", 0.5)
	_ensure_action_exists("ui_accept", 0.5)
	_ensure_action_exists("ui_cancel", 0.5)

	_add_key_unique("ui_left", KEY_LEFT)
	_add_key_unique("ui_right", KEY_RIGHT)
	_add_key_unique("ui_up", KEY_UP)
	_add_key_unique("ui_down", KEY_DOWN)
	_add_key_unique("ui_accept", KEY_ENTER)
	_add_key_unique("ui_accept", KEY_SPACE)
	_add_key_unique("ui_cancel", KEY_ESCAPE)

	var any_dev := -1
	_add_joy_button_unique("ui_accept", any_dev, JOY_BUTTON_A)
	_add_joy_button_unique("ui_cancel", any_dev, JOY_BUTTON_B)

	_add_joy_button_unique("ui_up", any_dev, JOY_BUTTON_DPAD_UP)
	_add_joy_button_unique("ui_down", any_dev, JOY_BUTTON_DPAD_DOWN)
	_add_joy_button_unique("ui_left", any_dev, JOY_BUTTON_DPAD_LEFT)
	_add_joy_button_unique("ui_right", any_dev, JOY_BUTTON_DPAD_RIGHT)

	_add_joy_axis_motion_unique("ui_left", any_dev, JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis_motion_unique("ui_right", any_dev, JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis_motion_unique("ui_up", any_dev, JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis_motion_unique("ui_down", any_dev, JOY_AXIS_LEFT_Y, 1.0)


func _ensure_action_exists(action_name: StringName, deadzone: float = 0.5) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, deadzone)


func _add_key_unique(action_name: StringName, keycode: Key) -> void:
	_ensure_action_exists(action_name)
	for e in InputMap.action_get_events(action_name):
		if e is InputEventKey and (e as InputEventKey).keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action_name, ev)


func _add_joy_button_unique(action_name: StringName, device: int, button: JoyButton) -> void:
	_ensure_action_exists(action_name)
	for e in InputMap.action_get_events(action_name):
		if e is InputEventJoypadButton:
			var jb := e as InputEventJoypadButton
			if jb.device == device and jb.button_index == button:
				return
	var j := InputEventJoypadButton.new()
	j.device = device
	j.button_index = button
	InputMap.action_add_event(action_name, j)


func _add_joy_axis_motion_unique(action_name: StringName, device: int, axis: JoyAxis, axis_value: float) -> void:
	_ensure_action_exists(action_name)
	for e in InputMap.action_get_events(action_name):
		if e is InputEventJoypadMotion:
			var jm := e as InputEventJoypadMotion
			if jm.device == device and jm.axis == axis and is_equal_approx(jm.axis_value, axis_value):
				return
	var m := InputEventJoypadMotion.new()
	m.device = device
	m.axis = axis
	m.axis_value = axis_value
	InputMap.action_add_event(action_name, m)
