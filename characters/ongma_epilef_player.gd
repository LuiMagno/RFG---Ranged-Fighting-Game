extends EsqueletoPlayer
class_name OngmaEpilefPlayer

## Personagem de teste / laboratório: herda todo o kit do Esqueleto (tiro carregado, triplo, raio, dash duplo, etc.).
## Experimente mecânicas aqui com overrides mínimos; o que for comum a vários lutadores deve subir para `Player`.

## Impulso diagonal ao saltar encostado a uma parede (não gasta `max_jumps`; no máximo uma vez por voo até ao solo).
## Por defeito mais forte que o pulo normal (`jump_speed` 650) para ler como “kick” de parede.
@export var wall_jump_horizontal_speed: float = 768.0
@export var wall_jump_vertical_speed: float = 984.0
@export_range(0.05, 0.6, 0.01) var wall_jump_visual_duration: float = 0.22
## Multiplicador de cor no pico do flash (corpo + arco); decai até branco ao longo de `wall_jump_visual_duration`.
@export var wall_jump_body_flash: Color = Color(1.38, 0.78, 1.52, 1.0)
## Distância máxima dos raios laterais (proximidade à parede sem precisar de empurrar com o direcional).
@export_range(4.0, 40.0, 1.0) var wall_detect_distance: float = 40.0
## Origem do raio em relação ao `global_position` (tipicamente um pouco acima do centro da hitbox).
@export var wall_detect_vertical_offset: float = -18.0
## Após o wall jump, bloqueia input horizontal “para dentro” da parede durante este tempo (não anula o impulso diagonal).
@export_range(0.0, 0.35, 0.01) var wall_jump_move_grace: float = 0.14

var _wall_jump_used_this_airborne: bool = false
var _wall_jump_flash_left: float = 0.0
var _wall_jump_move_grace_left: float = 0.0
## +1 = afastar para a direita, -1 = para a esquerda (mesmo sinal que `velocity.x` após o kick).
var _wall_jump_free_axis_sign: float = 0.0


func _physics_process(delta: float) -> void:
	if is_on_floor():
		_wall_jump_move_grace_left = 0.0
		_wall_jump_free_axis_sign = 0.0
	else:
		_wall_jump_move_grace_left = maxf(0.0, _wall_jump_move_grace_left - delta)
	super._physics_process(delta)
	if is_on_floor():
		_wall_jump_used_this_airborne = false

	if _wall_jump_flash_left > 0.0:
		var u := clampf(_wall_jump_flash_left / maxf(wall_jump_visual_duration, 0.0001), 0.0, 1.0)
		_wall_jump_flash_left = maxf(0.0, _wall_jump_flash_left - delta)
		var mult := Color.WHITE.lerp(wall_jump_body_flash, u)
		if _body_visual != null:
			_body_visual.modulate *= mult
		if _bow_visual != null:
			_bow_visual.modulate *= mult


func _get_move_axis() -> float:
	var a := super._get_move_axis()
	if _wall_jump_move_grace_left <= 0.0:
		return a
	if absf(a) < 0.02:
		return a
	if a * _wall_jump_free_axis_sign < 0.0:
		return 0.0
	return a


func is_ongma_epilef() -> bool:
	return true


func _try_special_air_jump() -> bool:
	if not input_enabled or _control_lock_left > 0.0:
		return false
	if is_on_floor() or _wall_jump_used_this_airborne:
		return false
	var away_x := _get_wall_jump_away_sign()
	if absf(away_x) < 0.1:
		return false

	if _dash_time_left > 0.0:
		_dash_time_left = 0.0
		_dash_cd_left = float(_get_dash_stats().get("cooldown", 0.3))

	velocity.x = away_x * wall_jump_horizontal_speed
	velocity.y = -wall_jump_vertical_speed
	_wall_jump_used_this_airborne = true
	_wall_jump_flash_left = wall_jump_visual_duration
	_wall_jump_free_axis_sign = away_x
	_wall_jump_move_grace_left = wall_jump_move_grace
	return true


func _get_wall_jump_away_sign() -> float:
	if is_on_wall_only():
		var wn := get_wall_normal()
		if absf(wn.x) >= 0.1:
			return signf(wn.x)
	var from := global_position + Vector2(0.0, wall_detect_vertical_offset)
	var d_left := _wall_ray_hit_dist(from, Vector2.LEFT)
	var d_right := _wall_ray_hit_dist(from, Vector2.RIGHT)
	var hit_left := d_left >= 0.0
	var hit_right := d_right >= 0.0
	if hit_left and not hit_right:
		return 1.0
	if hit_right and not hit_left:
		return -1.0
	if hit_left and hit_right:
		return 1.0 if d_left < d_right else -1.0
	return 0.0


func _wall_ray_hit_dist(from: Vector2, dir: Vector2) -> float:
	var to := from + dir.normalized() * wall_detect_distance
	var pq := PhysicsRayQueryParameters2D.create(from, to)
	pq.collision_mask = collision_mask
	pq.exclude = [get_rid()]
	var space := get_world_2d().direct_space_state
	var r := space.intersect_ray(pq)
	if r.is_empty():
		return -1.0
	return from.distance_to(r["position"] as Vector2)
