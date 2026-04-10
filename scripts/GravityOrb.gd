extends Area2D
class_name GravityOrb

## Dano ao jogador: o CollisionShape2D usa o mesmo raio `_current_radius()` (borda do orbe).
## Atração de players/projéteis e o anel visual externo usam esse mesmo raio.

@export var lifetime: float = 4.5
@export var base_radius: float = 170.0
@export var max_radius: float = 320.0
## Crescimento do raio de atração por projétil absorvido (bem visível a cada hit).
@export var radius_bonus_per_absorb: float = 14.0
@export var pull_strength_player: float = 1100.0
@export var pull_strength_projectile: float = 6800.0
## Raio de absorção = fração do raio atual (cresce junto com o orbe e com o hitbox de dano).
@export_range(0.05, 0.95, 0.01) var absorb_radius_ratio: float = 0.5
@export var absorb_radius_min: float = 44.0
@export var base_damage: int = 12
@export var damage_per_absorb: int = 2
## Polígono circular tem raio ~24 no espaço local (para escalar visual = raio mundo).
@export var visual_poly_radius: float = 24.0
## Núcleo: fração do raio atual + um pouco por absorção (tudo escala junto com o círculo externo).
@export var core_radius_base_ratio: float = 0.26
@export var core_radius_per_absorb: float = 0.02
@export_range(0.05, 0.9, 0.01) var core_radius_max_ratio: float = 0.46
@export var launch_speed_min: float = 160.0
@export var launch_speed_max: float = 260.0
@export var absorb_pulse_scale: float = 0.38
@export var absorb_pulse_decay: float = 7.0

var _owner: Player
var _vel: Vector2 = Vector2.ZERO
var _absorbed: int = 0
var _absorb_pulse: float = 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _visual_outer: Polygon2D = get_node_or_null("VisualOuter") as Polygon2D
@onready var _visual_absorb: Polygon2D = get_node_or_null("VisualAbsorb") as Polygon2D
@onready var _visual_core: Polygon2D = get_node_or_null("VisualCore") as Polygon2D

var _core_color_base := Color(0.72, 0.35, 1.0, 0.92)
var _core_color_flash := Color(1.0, 0.82, 1.0, 1.0)
var _absorb_color_base := Color(0.86, 0.55, 1.0, 0.32)
var _absorb_color_flash := Color(1.0, 0.72, 1.0, 0.55)


func setup(owner_player: Player, initial_velocity: Vector2) -> void:
	_owner = owner_player
	_vel = initial_velocity


func set_charge_t(charge_t: float) -> void:
	charge_t = clampf(charge_t, 0.0, 1.0)
	var spd := lerpf(launch_speed_min, launch_speed_max, charge_t)
	if _vel.length_squared() > 0.001:
		_vel = _vel.normalized() * spd
	else:
		_vel = (Vector2.RIGHT if (_owner != null and _owner.player_id == 1) else Vector2.LEFT) * spd


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if _visual_core != null:
		_visual_core.modulate = _core_color_base
	if _visual_absorb != null:
		_visual_absorb.modulate = _absorb_color_base
	_apply_radius(_current_radius())


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	_absorb_pulse = maxf(0.0, _absorb_pulse - absorb_pulse_decay * delta)
	if _visual_core != null:
		_visual_core.modulate = _visual_core.modulate.lerp(_core_color_base, delta * 5.5)
	if _visual_absorb != null:
		_visual_absorb.modulate = _visual_absorb.modulate.lerp(_absorb_color_base, delta * 5.5)

	global_position += _vel * delta

	var r := _current_radius()
	_pull_enemy_player(delta, r)
	_pull_enemy_projectiles(delta, r)
	_apply_visuals(r)


func _current_radius() -> float:
	return mini(max_radius, base_radius + float(_absorbed) * radius_bonus_per_absorb)


## Distância em que projéteis são absorvidos (mesma lógica do anel interno visual).
func _absorb_radius(r: float) -> float:
	var from_ratio := r * absorb_radius_ratio
	return clampf(from_ratio, absorb_radius_min, r * 0.92)


## Raio visual/físico do núcleo — cresce com o orbe e um pouco a cada absorção.
func _core_radius(r: float) -> float:
	var extra := core_radius_per_absorb * float(_absorbed)
	var frac := clampf(core_radius_base_ratio + extra, 0.05, core_radius_max_ratio)
	return r * frac


func _apply_radius(r: float) -> void:
	if _shape != null and _shape.shape != null:
		_shape.shape = _shape.shape.duplicate(true)
	if _shape != null and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius = r


func _apply_visuals(r: float) -> void:
	var pr := maxf(1.0, visual_poly_radius)
	var outer_scale := r / pr
	var ar := _absorb_radius(r)
	var absorb_scale := ar / pr
	var cr := _core_radius(r)
	var core_scale := (cr / pr) * (1.0 + absorb_pulse_scale * _absorb_pulse)
	if _visual_outer != null:
		_visual_outer.scale = Vector2.ONE * outer_scale
	if _visual_absorb != null:
		_visual_absorb.scale = Vector2.ONE * absorb_scale
	if _visual_core != null:
		_visual_core.scale = Vector2.ONE * core_scale


func _pull_enemy_player(delta: float, radius_now: float) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	var players := get_tree().get_nodes_in_group("players")
	for n in players:
		if not (n is Player):
			continue
		var pl := n as Player
		if pl == _owner:
			continue
		var to_center := global_position - pl.global_position
		var dist := to_center.length()
		if dist <= 0.001 or dist > radius_now:
			continue
		var dir := to_center / dist
		var strength := pull_strength_player * (1.0 - (dist / radius_now))
		pl.apply_external_force(dir * strength * delta)


func _pull_enemy_projectiles(delta: float, radius_now: float) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return

	for n in get_tree().get_nodes_in_group("arrows"):
		if not (n is Arrow):
			continue
		var a := n as Arrow
		if a.is_queued_for_deletion():
			continue
		if a.get_owner_player() == _owner:
			continue
		_apply_pull_to_body(a, delta, radius_now)

	for n2 in get_tree().get_nodes_in_group("grenades"):
		if not (n2 is Grenade):
			continue
		var g := n2 as Grenade
		if g.is_queued_for_deletion():
			continue
		if g.get_owner_player() == _owner:
			continue
		_apply_pull_to_body(g, delta, radius_now)


func _apply_pull_to_body(body: Node2D, delta: float, radius_now: float) -> void:
	var to_center := global_position - body.global_position
	var dist := to_center.length()
	if dist <= 0.001:
		return
	if dist > radius_now:
		return
	if dist <= _absorb_radius(radius_now):
		_absorb_projectile(body)
		return
	var dir := to_center / dist
	var strength := pull_strength_projectile * (1.0 - (dist / radius_now))
	if body is CharacterBody2D:
		var cb := body as CharacterBody2D
		cb.velocity += dir * strength * delta
	else:
		body.global_position += dir * (strength * 0.12) * delta


func _absorb_projectile(body: Node2D) -> void:
	if body == null or not is_instance_valid(body):
		return
	_absorbed += 1
	_absorb_pulse = 1.0
	if _visual_core != null:
		_visual_core.modulate = _core_color_flash
	if _visual_absorb != null:
		_visual_absorb.modulate = _absorb_color_flash
	_apply_radius(_current_radius())
	_apply_visuals(_current_radius())
	if not body.is_queued_for_deletion():
		body.queue_free()


func _damage_now() -> int:
	return base_damage + _absorbed * damage_per_absorb


func _on_body_entered(body: Node) -> void:
	if not (body is Player):
		return
	var pl := body as Player
	if _owner != null and pl == _owner:
		return
	pl.take_damage(_damage_now())
	queue_free()
