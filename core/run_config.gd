extends Node

# Singleton em Project Settings → Autoload (nome: RunConfig).
# Não use class_name RunConfig aqui — conflita com o autoload.

enum Mode { VS_PLAYER, TRAINING }

var mode: Mode = Mode.VS_PLAYER

var training_dummy_shoot: bool = true
var training_dummy_interval: float = 3.0

# Personagem: 0 = pistoleiro, 1 = arqueiro, 2 = mago, 3 = esqueleto, 4 = ongma epilef (teste). Ver Game._assign_player_script.
var p1_character: int = 0
var p2_character: int = 1


## O duelo (`main.tscn`) adiciona o botão esquerdo do rato a `p1_shoot`; sem limpar, o menu deixa de receber cliques.
func clear_p1_shoot_mouse_binding() -> void:
	if not InputMap.has_action("p1_shoot"):
		return
	var to_remove: Array = []
	for ev in InputMap.action_get_events("p1_shoot"):
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			to_remove.append(ev)
	for ev in to_remove:
		InputMap.action_erase_event("p1_shoot", ev)
