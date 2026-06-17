extends CharacterBody2D
class_name EsqueletoTurret

## Torreta do Esqueleto: estacionária, sentinela, foguete, fortaleza, morteiro ou escudo balístico.

enum Mode { STATIONARY, SENTINEL, ROCKET_CHARGE, ROCKET_FLIGHT, FORTRESS, MORTAR, SHIELD }

const TERRAIN_COLLISION_MASK := 49
const GRAVITY_ACCEL := 1500.0
const SENTINEL_Y_TOLERANCE_PX := 72.0
const SENTINEL_DISTANCE_DEADBAND_PX := 28.0
const LEG_SWING_SPEED := 11.0
const LEG_SWING_AMOUNT := 0.42
const ROCKET_HIT_RADIUS_PX := 26.0
const ROCKET_LAUNCH_SPEED := 140.0
const ROCKET_BOUNCE_DAMPING := 0.82
const PROJECTILE_PUSH_RADIUS_PX := 120.0
const PROJECTILE_PUSH_STRENGTH := 280.0
const FORTRESS_TRANSFORM_S := 0.45
const FORTRESS_BODY_SCALE := Vector2(1.35, 1.35)
const FORTRESS_BASE_SCALE := Vector2(1.28, 1.18)
const FORTRESS_HITBOX_SIZE := Vector2(52, 50)
const FORTRESS_HITBOX_OFFSET := Vector2(0, -2)
const MORTAR_TRANSFORM_S := 0.42
const MORTAR_BARREL_ANGLE_DEG := 60.0
const MORTAR_HITBOX_SIZE := Vector2(44, 38)
const MORTAR_CEILING_SAFE_Y := 64.0
const MORTAR_MAX_LAUNCH_SPEED := 1700.0
const MORTAR_SIM_DT := 0.012
const SHIELD_TRANSFORM_S := 0.38
const SHIELD_HITBOX_SIZE := Vector2(58, 46)

var _owner: Player
var _game: Node
var _mode: Mode = Mode.STATIONARY
var _hp: int = 30
var _shots_left: int = 5
var _fire_cooldown_left: float = 0.0
var _shot_damage: int = 20
var _shot_interval_s: float = 2.5
var _shot_speed: float = 420.0
var _settled: bool = false
var _walk_speed: float = 95.0
var _follow_range: float = 380.0
var _preferred_distance: float = 185.0
var _leg_phase: float = 0.0
var _rocket_charge_left: float = 0.0
var _rocket_accel: float = 1850.0
var _rocket_max_speed: float = 920.0
var _rocket_turn_rad_s: float = 1.65
var _rocket_bounces_left: int = 1
var _rocket_base_damage: int = 36
var _rocket_damage_bonus: int = 0
var _rocket_radius: float = 150.0
var _rocket_knockback_x: float = 520.0
var _rocket_knockback_up: float = 260.0
var _rocket_overcharge_speed_threshold: float = 220.0
var _rocket_speed_mul: float = 1.0
var _rocket_dir: Vector2 = Vector2.RIGHT
var _rocket_exploded: bool = false
var _charge_pulse: float = 0.0
var _damage_resistance_mul: float = 1.0
var _fortress_windup_left: float = 0.0
var _fortress_aim_windup_s: float = 2.5
var _fortress_aim_turn_rad_s: float = deg_to_rad(55.0)
var _burst_size: int = 3
var _burst_spread_deg: float = 8.0
var _fortress_lifetime_left: float = 0.0
var _mortar_launch_angle_deg: float = 60.0
var _mortar_blast_radius: float = 120.0
var _mortar_knockback_x: float = 380.0
var _mortar_knockback_up: float = 200.0
var _shield_lifetime_left: float = 0.0
var _shield_intercept_cd_left: float = 0.0
var _shield_intercept_interval_s: float = 0.42
var _shield_intercept_speed: float = 640.0
var _shield_intercept_range: float = 520.0
var _shield_charge_pulse: float = 0.0
var _mortar_prediction_mul: float = 1.0

var _mortar_shell_scene: PackedScene = preload("res://projectiles/esqueleto_turret_mortar/esqueleto_turret_mortar_shell.tscn")

@onready var _head_pivot: Node2D = $HeadPivot
@onready var _muzzle: Marker2D = $HeadPivot/Muzzle
@onready var _base_plate: Polygon2D = $BasePlate
@onready var _base_rim: Polygon2D = $BaseRim
@onready var _head_body: Polygon2D = $HeadPivot/HeadBody
@onready var _barrel: Polygon2D = $HeadPivot/Barrel
@onready var _barrel_tip: Polygon2D = $HeadPivot/BarrelTip
@onready var _thruster: Polygon2D = $HeadPivot/ThrusterFlame
@onready var _legs_root: Node2D = $LegsRoot
@onready var _leg_l_pivot: Node2D = $LegsRoot/LegLPivot
@onready var _leg_r_pivot: Node2D = $LegsRoot/LegRPivot
@onready var _anchor_root: Node2D = $AnchorRoot
@onready var _anchor_l: Polygon2D = $AnchorRoot/AnchorL
@onready var _anchor_r: Polygon2D = $AnchorRoot/AnchorR
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _shield_root: Node2D = $ShieldRoot
@onready var _shield_panel_l: Polygon2D = $ShieldRoot/ShieldPanelL
@onready var _shield_panel_r: Polygon2D = $ShieldRoot/ShieldPanelR
@onready var _shield_front: Polygon2D = $ShieldRoot/ShieldFront
@onready var _shield_glow: Polygon2D = $ShieldRoot/ShieldGlow
@onready var _shield_intercept: Area2D = $ShieldIntercept

var _explosion_scene: PackedScene = preload("res://projectiles/explosion/explosion.tscn")


func setup(owner_player: Player, game: Node, config: Dictionary) -> void:
	_owner = owner_player
	_game = game
	_mode = Mode.STATIONARY
	_hp = int(config.get("vida", 30))
	_shots_left = int(config.get("disparos", 5))
	_shot_damage = int(config.get("dano_tiro", 20))
	_shot_interval_s = float(config.get("intervalo_disparo_s", 2.5))
	_shot_speed = float(config.get("velocidade_tiro", 420.0))
	if _owner != null:
		add_collision_exception_with(_owner)
	_apply_team_colors()
	_settled = is_on_floor()


func get_owner_player() -> Player:
	return _owner


func is_sentinel() -> bool:
	return _mode == Mode.SENTINEL


func is_rocket_mode() -> bool:
	return _mode == Mode.ROCKET_CHARGE or _mode == Mode.ROCKET_FLIGHT


func is_fortress() -> bool:
	return _mode == Mode.FORTRESS


func is_mortar() -> bool:
	return _mode == Mode.MORTAR


func is_shield() -> bool:
	return _mode == Mode.SHIELD


func is_evolved_mode() -> bool:
	return _mode == Mode.FORTRESS or _mode == Mode.MORTAR or _mode == Mode.SHIELD


func _can_begin_evolution() -> bool:
	return (
		(_mode == Mode.STATIONARY or _mode == Mode.SENTINEL)
		and _settled
		and not is_rocket_mode()
		and not is_evolved_mode()
	)


func can_transform_to_sentinel() -> bool:
	return _mode == Mode.STATIONARY and _settled and _shots_left > 0 and not is_rocket_mode()


func can_transform_to_rocket() -> bool:
	return _can_begin_evolution()


func can_transform_to_fortress() -> bool:
	return _can_begin_evolution()


func can_transform_to_mortar() -> bool:
	return _can_begin_evolution()


func can_transform_to_shield() -> bool:
	return _can_begin_evolution()


func transform_to_sentinel(config: Dictionary) -> void:
	if not can_transform_to_sentinel():
		return
	_mode = Mode.SENTINEL
	_hp = mini(_hp, int(config.get("vida", 20)))
	_shots_left = int(config.get("disparos", 10))
	_shot_damage = int(config.get("dano_tiro", 11))
	_shot_interval_s = float(config.get("intervalo_disparo_s", 1.15))
	_shot_speed = float(config.get("velocidade_tiro", _shot_speed))
	_walk_speed = float(config.get("walk_speed", 95.0))
	_follow_range = float(config.get("follow_range", 380.0))
	_preferred_distance = float(config.get("preferred_distance", 185.0))
	_fire_cooldown_left = 0.08
	if _legs_root != null:
		_legs_root.visible = true
		_legs_root.modulate.a = 0.0
		_legs_root.scale = Vector2.ONE
		var tween := create_tween()
		tween.tween_property(_legs_root, "modulate:a", 1.0, 0.2)
	if _head_pivot != null:
		_head_pivot.position.y = -4.0
	add_to_group("esqueleto_turret_sentinels")
	SfxManager.play("hit_heavy", global_position, 0.72, -6.0)


func transform_to_fortress(config: Dictionary) -> void:
	if not can_transform_to_fortress():
		return
	if is_sentinel():
		remove_from_group("esqueleto_turret_sentinels")
	_mode = Mode.FORTRESS
	velocity = Vector2.ZERO
	_hp = int(config.get("vida", 80))
	_damage_resistance_mul = float(config.get("resistencia_mul", 0.3))
	_shots_left = int(config.get("rajadas", 12))
	_shot_damage = int(config.get("dano_tiro", 14))
	_shot_interval_s = float(config.get("intervalo_raja_s", 2.0))
	_shot_speed = float(config.get("velocidade_tiro", 380.0))
	_fortress_aim_windup_s = float(config.get("mira_s", 2.5))
	_fortress_windup_left = _fortress_aim_windup_s
	_fortress_aim_turn_rad_s = deg_to_rad(float(config.get("mira_graus_s", 55.0)))
	_burst_size = maxi(1, int(config.get("flechas_por_raja", 3)))
	_burst_spread_deg = float(config.get("espalhamento_graus", 8.0))
	_fire_cooldown_left = 0.0
	var volleys := maxi(1, _shots_left)
	var windup_s := _fortress_aim_windup_s
	var interval_s := _shot_interval_s
	var duration_s := float(config.get("duracao_s", 0.0))
	if duration_s <= 0.0:
		duration_s = volleys * (windup_s + interval_s) + windup_s * 0.25
	_fortress_lifetime_left = duration_s
	_apply_fortress_hitbox()
	_play_fortress_transform_visual()
	SfxManager.play("ult_start", global_position, 0.55, -8.0)


func transform_to_mortar(config: Dictionary) -> void:
	if not can_transform_to_mortar():
		return
	if is_sentinel():
		remove_from_group("esqueleto_turret_sentinels")
	_mode = Mode.MORTAR
	velocity = Vector2.ZERO
	_hp = int(config.get("vida", 30))
	_shots_left = int(config.get("disparos", 6))
	_shot_damage = int(config.get("dano", 24))
	_shot_interval_s = float(config.get("intervalo_s", 4.0))
	_mortar_launch_angle_deg = float(config.get("angulo_cano_graus", 60.0))
	_mortar_blast_radius = float(config.get("raio", 120.0))
	_mortar_knockback_x = float(config.get("knockback_x", 380.0))
	_mortar_knockback_up = float(config.get("knockback_up", 200.0))
	_mortar_prediction_mul = float(config.get("previsao_mul", 1.0))
	_fire_cooldown_left = _shot_interval_s * 0.35
	_play_mortar_transform_visual()
	_apply_mortar_hitbox()
	SfxManager.play("grenade_throw", global_position, 0.82, -6.0)


func transform_to_shield(config: Dictionary) -> void:
	if not can_transform_to_shield():
		return
	if is_sentinel():
		remove_from_group("esqueleto_turret_sentinels")
	_mode = Mode.SHIELD
	velocity = Vector2.ZERO
	_hp = int(config.get("vida", 60))
	_shield_lifetime_left = float(config.get("duracao_s", 12.0))
	_shield_intercept_interval_s = float(config.get("intercepto_intervalo_s", 0.42))
	_shield_intercept_speed = float(config.get("intercepto_velocidade", 640.0))
	_shield_intercept_range = float(config.get("intercepto_alcance", 520.0))
	_shield_intercept_cd_left = 0.15
	_shield_charge_pulse = 0.0
	_shots_left = 0
	_play_shield_transform_visual()
	_apply_shield_hitbox()
	SfxManager.play("ult_start", global_position, 0.48, -8.0)


func _apply_mortar_hitbox() -> void:
	if _collision_shape == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = MORTAR_HITBOX_SIZE
	_collision_shape.shape = rect
	_collision_shape.position = Vector2(0, -2)


func _apply_shield_hitbox() -> void:
	if _collision_shape == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = SHIELD_HITBOX_SIZE
	_collision_shape.shape = rect
	_collision_shape.position = Vector2(0, -2)


func _play_mortar_transform_visual() -> void:
	if _legs_root != null:
		_legs_root.visible = true
		var leg_tween := create_tween()
		leg_tween.set_parallel(true)
		leg_tween.tween_property(_legs_root, "scale", Vector2(0.15, 0.25), MORTAR_TRANSFORM_S)
		leg_tween.tween_property(_legs_root, "modulate:a", 0.0, MORTAR_TRANSFORM_S)
	if _anchor_root != null:
		_anchor_root.visible = true
		_anchor_root.modulate.a = 0.0
		_anchor_root.scale = Vector2(1.0, 0.2)
		var anchor_tween := create_tween()
		anchor_tween.set_parallel(true)
		anchor_tween.tween_property(_anchor_root, "modulate:a", 1.0, MORTAR_TRANSFORM_S)
		anchor_tween.tween_property(_anchor_root, "scale", Vector2.ONE, MORTAR_TRANSFORM_S)
	if _head_pivot != null:
		var face := _facing_sign()
		var barrel_ang := -deg_to_rad(_mortar_launch_angle_deg) * face
		var body_tween := create_tween()
		body_tween.set_parallel(true)
		body_tween.tween_property(_head_pivot, "scale", Vector2(1.12, 1.12), MORTAR_TRANSFORM_S)
		body_tween.tween_property(_head_pivot, "rotation", barrel_ang, MORTAR_TRANSFORM_S)
		body_tween.tween_property(_head_pivot, "position:y", -5.0, MORTAR_TRANSFORM_S)
	if _base_plate != null:
		create_tween().tween_property(_base_plate, "scale", Vector2(1.15, 1.08), MORTAR_TRANSFORM_S)
	if _base_rim != null:
		create_tween().tween_property(_base_rim, "scale", Vector2(1.15, 1.08), MORTAR_TRANSFORM_S)


func _play_shield_transform_visual() -> void:
	if _legs_root != null:
		_legs_root.visible = false
	if _anchor_root != null:
		_anchor_root.visible = false
	if _head_pivot != null:
		var head_tween := create_tween()
		head_tween.set_parallel(true)
		head_tween.tween_property(_head_pivot, "scale", Vector2(0.55, 0.55), SHIELD_TRANSFORM_S)
		head_tween.tween_property(_head_pivot, "position:y", 2.0, SHIELD_TRANSFORM_S)
		head_tween.tween_property(_head_pivot, "rotation", 0.0, SHIELD_TRANSFORM_S)
	if _base_plate != null:
		create_tween().tween_property(_base_plate, "scale", Vector2(1.35, 1.0), SHIELD_TRANSFORM_S)
	if _base_rim != null:
		create_tween().tween_property(_base_rim, "scale", Vector2(1.35, 1.0), SHIELD_TRANSFORM_S)
	if _shield_root != null:
		_shield_root.visible = true
		_shield_root.modulate.a = 0.0
		_shield_root.scale = Vector2(0.7, 1.0)
		var shield_tween := create_tween()
		shield_tween.set_parallel(true)
		shield_tween.tween_property(_shield_root, "modulate:a", 1.0, SHIELD_TRANSFORM_S)
		shield_tween.tween_property(_shield_root, "scale", Vector2.ONE, SHIELD_TRANSFORM_S)
	_layout_shield_intercept()
	if _shield_intercept != null:
		_shield_intercept.visible = true
		_shield_intercept.monitoring = true


func _layout_shield_intercept() -> void:
	if _shield_intercept == null:
		return
	var face := _facing_sign()
	_shield_intercept.scale.x = absf(_shield_intercept.scale.x) * face
	if _shield_intercept.has_node("ShieldInterceptShape"):
		var col := _shield_intercept.get_node("ShieldInterceptShape") as CollisionShape2D
		if col != null:
			col.position.x = 18.0 * face


func _apply_fortress_hitbox() -> void:
	if _collision_shape == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = FORTRESS_HITBOX_SIZE
	_collision_shape.shape = rect
	_collision_shape.position = FORTRESS_HITBOX_OFFSET


func get_hurt_collision_rect() -> Rect2:
	if _collision_shape == null or _collision_shape.shape == null:
		return Rect2(global_position - FORTRESS_HITBOX_SIZE * 0.5, FORTRESS_HITBOX_SIZE)
	var half := FORTRESS_HITBOX_SIZE * 0.5
	return Rect2(_collision_shape.global_position - half, FORTRESS_HITBOX_SIZE)


func _play_fortress_transform_visual() -> void:
	if _legs_root != null:
		_legs_root.visible = true
		var leg_tween := create_tween()
		leg_tween.set_parallel(true)
		leg_tween.tween_property(_legs_root, "scale", Vector2(0.15, 0.25), FORTRESS_TRANSFORM_S)
		leg_tween.tween_property(_legs_root, "modulate:a", 0.0, FORTRESS_TRANSFORM_S)
	if _head_pivot != null:
		var body_tween := create_tween()
		body_tween.set_parallel(true)
		body_tween.tween_property(_head_pivot, "scale", FORTRESS_BODY_SCALE, FORTRESS_TRANSFORM_S)
		body_tween.tween_property(_head_pivot, "position:y", -6.0, FORTRESS_TRANSFORM_S)
	if _base_plate != null:
		var plate_tween := create_tween()
		plate_tween.tween_property(_base_plate, "scale", FORTRESS_BASE_SCALE, FORTRESS_TRANSFORM_S)
	if _base_rim != null:
		var rim_tween := create_tween()
		rim_tween.tween_property(_base_rim, "scale", FORTRESS_BASE_SCALE, FORTRESS_TRANSFORM_S)
	if _anchor_root != null:
		_anchor_root.visible = true
		_anchor_root.modulate.a = 0.0
		_anchor_root.scale = Vector2(1.0, 0.2)
		var anchor_tween := create_tween()
		anchor_tween.set_parallel(true)
		anchor_tween.tween_property(_anchor_root, "modulate:a", 1.0, FORTRESS_TRANSFORM_S)
		anchor_tween.tween_property(_anchor_root, "scale", Vector2.ONE, FORTRESS_TRANSFORM_S)


func begin_rocket_transform(config: Dictionary) -> void:
	if not can_transform_to_rocket():
		return
	var shot_energy := _shots_left
	_shots_left = 0
	_mode = Mode.ROCKET_CHARGE
	_rocket_charge_left = float(config.get("charge_s", 0.3))
	_rocket_base_damage = int(config.get("dano_base", 36))
	_rocket_radius = float(config.get("raio", 150.0))
	_rocket_knockback_x = float(config.get("knockback_x", 520.0))
	_rocket_knockback_up = float(config.get("knockback_up", 260.0))
	_rocket_accel = float(config.get("aceleracao", 1850.0))
	_rocket_max_speed = float(config.get("vel_max", 920.0))
	_rocket_turn_rad_s = deg_to_rad(float(config.get("tracking_graus_s", 95.0)))
	_rocket_bounces_left = int(config.get("ricochetes", 1))
	_rocket_overcharge_speed_threshold = float(config.get("sobrecarga_vel_inimigo", 220.0))
	_rocket_damage_bonus = shot_energy * int(config.get("bonus_dano_por_tiro", 4))
	_rocket_speed_mul = 1.0 + shot_energy * float(config.get("bonus_vel_por_tiro", 0.1))
	velocity = Vector2.ZERO
	_charge_pulse = 0.0
	if _thruster != null:
		_thruster.visible = true
		_thruster.modulate.a = 0.35
	if _legs_root != null and _legs_root.visible:
		var tween := create_tween()
		tween.tween_property(_legs_root, "scale", Vector2(0.35, 0.5), _rocket_charge_left)
	if _barrel != null:
		_barrel.color = Color(0.95, 0.42, 0.18, 1.0)
	if _barrel_tip != null:
		_barrel_tip.color = Color(1.0, 0.72, 0.22, 1.0)
	SfxManager.play("ult_start", global_position, 0.42, -10.0)


func take_damage(amount: int) -> void:
	if amount <= 0 or _rocket_exploded:
		return
	if _mode == Mode.FORTRESS:
		amount = maxi(1, int(ceil(float(amount) * _damage_resistance_mul)))
	_hp -= amount
	if _hp <= 0:
		_destroy()


func _ready() -> void:
	add_to_group("esqueleto_turrets")
	collision_mask = TERRAIN_COLLISION_MASK
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(46.0)
	if _collision_shape != null and _collision_shape.shape != null:
		_collision_shape.shape = _collision_shape.shape.duplicate(true)
	_apply_team_colors()


func _physics_process(delta: float) -> void:
	if _mode == Mode.ROCKET_CHARGE:
		_process_rocket_charge(delta)
		return
	if _mode == Mode.ROCKET_FLIGHT:
		_process_rocket_flight(delta)
		return
	if _mode == Mode.FORTRESS:
		_process_fortress(delta)
		return
	if _mode == Mode.MORTAR:
		_process_mortar(delta)
		return
	if _mode == Mode.SHIELD:
		_process_shield(delta)
		return
	if not _settled:
		_process_falling(delta)
		return
	if _mode == Mode.SENTINEL:
		_process_sentinel_movement(delta)
	_process_combat(delta)


func _process_rocket_charge(delta: float) -> void:
	velocity = Vector2.ZERO
	_rocket_charge_left -= delta
	_charge_pulse += delta * 18.0
	if _thruster != null:
		_thruster.modulate.a = 0.35 + sin(_charge_pulse) * 0.2
		_thruster.scale.x = 0.8 + sin(_charge_pulse * 1.4) * 0.25
	_update_aim_visual()
	if _rocket_charge_left <= 0.0:
		_launch_rocket()


func _launch_rocket() -> void:
	_mode = Mode.ROCKET_FLIGHT
	floor_snap_length = 0.0
	_rocket_dir = Vector2.RIGHT if (_owner != null and _owner.player_id == 1) else Vector2.LEFT
	var opponent := _find_opponent()
	if opponent != null:
		var aim := _target_offset(opponent)
		if aim.length_squared() > 1.0:
			_rocket_dir = aim.normalized()
	_head_pivot.rotation = _rocket_dir.angle()
	velocity = _rocket_dir * ROCKET_LAUNCH_SPEED * _rocket_speed_mul
	if _thruster != null:
		_thruster.visible = true
		_thruster.modulate.a = 0.95
	SfxManager.play("shoot_magic", global_position, 1.05, -4.0)


func _process_rocket_flight(delta: float) -> void:
	var opponent := _find_opponent()
	if opponent != null:
		var to_enemy := _target_offset(opponent)
		if to_enemy.length_squared() > 4.0:
			var desired := to_enemy.normalized()
			var current := velocity.normalized() if velocity.length_squared() > 1.0 else desired
			var ang_diff := current.angle_to(desired)
			var max_turn := _rocket_turn_rad_s * delta
			velocity = velocity.rotated(clampf(ang_diff, -max_turn, max_turn))
			_rocket_dir = velocity.normalized() if velocity.length_squared() > 1.0 else desired
	if velocity.length_squared() < 1.0:
		velocity = _rocket_dir * ROCKET_LAUNCH_SPEED
	var max_spd := _rocket_max_speed * _rocket_speed_mul
	var spd := velocity.length()
	if spd < max_spd:
		velocity += velocity.normalized() * _rocket_accel * delta if spd > 0.01 else _rocket_dir * _rocket_accel * delta
		spd = velocity.length()
		if spd > max_spd:
			velocity = velocity.normalized() * max_spd
	_head_pivot.rotation = velocity.angle() if velocity.length_squared() > 1.0 else _head_pivot.rotation
	if _thruster != null:
		_thruster.rotation = PI
		_thruster.scale.x = 0.9 + clampf(spd / max_spd, 0.0, 1.0) * 0.55
	var prev_pos := global_position
	move_and_slide()
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col == null:
			continue
		if _rocket_bounces_left > 0:
			_rocket_bounces_left -= 1
			var n := col.get_normal()
			velocity = velocity.bounce(n) * ROCKET_BOUNCE_DAMPING
			global_position += n * 3.0
			_rocket_dir = velocity.normalized() if velocity.length_squared() > 1.0 else _rocket_dir
			SfxManager.play("ricochet", global_position, 1.0, -6.0)
			return
		_rocket_explode(null)
		return
	if global_position.distance_to(prev_pos) < 0.5 and spd > 120.0:
		_rocket_explode(null)
		return
	var hit := _find_rocket_hit_player()
	if hit != null:
		_rocket_explode(hit)


func _find_rocket_hit_player() -> Player:
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Player):
			continue
		var pl := n as Player
		if pl == _owner or pl.hp <= 0:
			continue
		var rect := pl.get_body_collision_rect() if pl.has_method("get_body_collision_rect") else Rect2(pl.global_position - Vector2(12, 24), Vector2(24, 48))
		if rect.get_center().distance_to(global_position) <= ROCKET_HIT_RADIUS_PX + rect.size.length() * 0.15:
			return pl
	return null


func _rocket_explode(direct_hit: Player) -> void:
	if _rocket_exploded:
		return
	_rocket_exploded = true
	var center := global_position
	var radius := _rocket_radius
	var damage := _rocket_base_damage + _rocket_damage_bonus
	var overcharge := false
	if direct_hit != null and direct_hit.velocity.length() >= _rocket_overcharge_speed_threshold:
		overcharge = true
		radius *= 1.35
		damage = int(round(float(damage) * 1.25))
	SfxManager.play("explosion", center, 1.0 if overcharge else 0.92, -2.0 if overcharge else 0.0)
	for i in range(3 if overcharge else 2):
		var puff := _explosion_scene.instantiate() as Node2D
		if puff == null or get_tree().current_scene == null:
			continue
		get_tree().current_scene.add_child(puff)
		puff.global_position = center + Vector2(randf_range(-18.0, 18.0), randf_range(-14.0, 14.0))
		if overcharge:
			puff.scale = Vector2.ONE * 1.2
	_push_nearby_projectiles(center, radius)
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Player):
			continue
		var pl := n as Player
		if pl == _owner:
			continue
		var feet := pl.global_position
		if center.distance_to(feet) > radius + 28.0:
			continue
		pl.take_damage(damage)
		SfxManager.play("hit_heavy", feet, 1.0, -4.0)
		var away := feet - center
		if away.length_squared() < 4.0:
			away = _rocket_dir if _rocket_dir.length_squared() > 0.01 else Vector2.RIGHT
		else:
			away = away.normalized()
		pl.apply_knockback(Vector2(away.x * _rocket_knockback_x, -_rocket_knockback_up))
	queue_free()


func _push_nearby_projectiles(center: Vector2, blast_radius: float) -> void:
	var push_radius := maxf(blast_radius, PROJECTILE_PUSH_RADIUS_PX)
	for n in get_tree().get_nodes_in_group("arrows"):
		_push_node_if_near(n, center, push_radius)
	for n in get_tree().get_nodes_in_group("grenades"):
		_push_node_if_near(n, center, push_radius)


func _push_node_if_near(node: Node, center: Vector2, push_radius: float) -> void:
	if node == self or not is_instance_valid(node) or not (node is CharacterBody2D):
		return
	var body := node as CharacterBody2D
	if body.global_position.distance_to(center) > push_radius:
		return
	var away: Vector2 = body.global_position - center
	if away.length_squared() < 1.0:
		away = _rocket_dir
	else:
		away = away.normalized()
	body.velocity += away * PROJECTILE_PUSH_STRENGTH


func _process_falling(delta: float) -> void:
	velocity.y += GRAVITY_ACCEL * delta
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	move_and_slide()
	if is_on_floor():
		velocity = Vector2.ZERO
		_settled = true
		_fire_cooldown_left = _shot_interval_s


func _process_sentinel_movement(delta: float) -> void:
	var opponent := _find_opponent()
	var move_dir := 0.0
	if opponent != null:
		var offset := _target_offset(opponent)
		if absf(offset.y) <= SENTINEL_Y_TOLERANCE_PX:
			var horiz_dist := absf(offset.x)
			if horiz_dist > _follow_range:
				move_dir = signf(offset.x)
			elif horiz_dist > _preferred_distance + SENTINEL_DISTANCE_DEADBAND_PX:
				move_dir = signf(offset.x)
			elif horiz_dist < _preferred_distance - SENTINEL_DISTANCE_DEADBAND_PX:
				move_dir = -signf(offset.x)
	velocity.x = move_dir * _walk_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY_ACCEL * delta
	move_and_slide()
	_animate_legs(delta, move_dir)


func _animate_legs(delta: float, move_dir: float) -> void:
	if _leg_l_pivot == null or _leg_r_pivot == null:
		return
	if absf(move_dir) < 0.01:
		_leg_l_pivot.rotation = lerpf(_leg_l_pivot.rotation, 0.0, 8.0 * delta)
		_leg_r_pivot.rotation = lerpf(_leg_r_pivot.rotation, 0.0, 8.0 * delta)
		return
	_leg_phase += delta * LEG_SWING_SPEED * signf(move_dir)
	var swing := sin(_leg_phase) * LEG_SWING_AMOUNT
	_leg_l_pivot.rotation = swing
	_leg_r_pivot.rotation = -swing


func _process_fortress(delta: float) -> void:
	velocity = Vector2.ZERO
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY_ACCEL * delta
	move_and_slide()
	_fortress_lifetime_left -= delta
	if _fortress_lifetime_left <= 0.0:
		_destroy()
		return
	_process_fortress_combat(delta)


func _process_fortress_combat(delta: float) -> void:
	if _shots_left <= 0:
		_destroy()
		return
	if _fortress_windup_left > 0.0:
		_fortress_windup_left -= delta
		_update_fortress_aim_windup(delta)
		return
	_fire_cooldown_left -= delta
	if _fire_cooldown_left > 0.0:
		return
	_fire_fortress_burst()
	_shots_left -= 1
	if _shots_left <= 0:
		_destroy()
		return
	_fire_cooldown_left = _shot_interval_s
	_fortress_windup_left = _fortress_aim_windup_s


func _update_fortress_aim_windup(delta: float) -> void:
	if _head_pivot == null:
		return
	var opponent := _find_opponent()
	if opponent == null:
		return
	var target_angle := _target_offset(opponent).angle()
	var max_turn := _fortress_aim_turn_rad_s * delta
	_head_pivot.rotation = move_toward(_head_pivot.rotation, target_angle, max_turn)


func _fire_fortress_burst() -> void:
	if _game == null or not _game.has_method("spawn_esqueleto_turret_shot") or _head_pivot == null:
		return
	var muzzle_global := _head_pivot.global_position if _muzzle == null else _muzzle.global_position
	var base_dir := Vector2.RIGHT.rotated(_head_pivot.rotation)
	var center := float(_burst_size - 1) * 0.5
	for i in _burst_size:
		var spread := deg_to_rad(_burst_spread_deg) * (float(i) - center)
		var dir := base_dir.rotated(spread)
		_game.call(
			"spawn_esqueleto_turret_shot",
			_owner,
			muzzle_global,
			dir * _shot_speed,
			_shot_damage,
		)
	SfxManager.play("shoot_magic", muzzle_global, 0.82, -2.0)


func _process_mortar(delta: float) -> void:
	velocity = Vector2.ZERO
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY_ACCEL * delta
	move_and_slide()
	if _shots_left <= 0:
		_destroy()
		return
	_fire_cooldown_left -= delta
	if _fire_cooldown_left > 0.0:
		return
	var opponent := _find_opponent()
	if opponent == null:
		_fire_cooldown_left = 0.5
		return
	_fire_mortar_shell(opponent)
	_shots_left -= 1
	if _shots_left <= 0:
		_fire_cooldown_left = 0.0
		return
	_fire_cooldown_left = _shot_interval_s


func _fire_mortar_shell(opponent: Player) -> void:
	if _mortar_shell_scene == null or get_tree().current_scene == null:
		return
	var muzzle_global := _head_pivot.global_position if _muzzle == null else _muzzle.global_position
	var target := opponent.global_position
	var launch_vel := _calc_mortar_velocity(muzzle_global, target, GRAVITY_ACCEL, _mortar_launch_angle_deg)
	if _head_pivot != null and launch_vel.length_squared() > 1.0:
		_head_pivot.rotation = launch_vel.angle()
	var shell := _mortar_shell_scene.instantiate() as EsqueletoTurretMortarShell
	if shell == null:
		return
	get_tree().current_scene.add_child(shell)
	shell.global_position = muzzle_global
	shell.setup(
		_owner,
		launch_vel,
		_shot_damage,
		_mortar_blast_radius,
		_mortar_knockback_x,
		_mortar_knockback_up,
	)
	SfxManager.play("shoot_magic", muzzle_global, 0.75, -8.0)


func _calc_mortar_velocity(origin: Vector2, target: Vector2, gravity: float, preferred_deg: float) -> Vector2:
	var dx := target.x - origin.x
	var dy := target.y - origin.y
	if absf(dx) < 12.0:
		dx = 12.0 * signf(_facing_sign())

	var ground_y := target.y
	var best_vel := Vector2.ZERO
	var best_miss := INF

	for angle_deg in range(38, 68):
		var vel := _mortar_velocity_for_angle(dx, dy, gravity, float(angle_deg))
		if vel == Vector2.ZERO:
			continue
		if vel.length() > MORTAR_MAX_LAUNCH_SPEED:
			continue
		if not _mortar_clears_ceiling(origin, vel, gravity):
			continue
		var miss := _mortar_ground_miss(origin, ground_y, target.x, vel, gravity)
		if miss < best_miss:
			best_miss = miss
			best_vel = vel

	for extra_deg: float in [preferred_deg, preferred_deg - 4.0, preferred_deg + 4.0, 52.0, 58.0]:
		var vel := _mortar_velocity_for_angle(dx, dy, gravity, extra_deg)
		if vel == Vector2.ZERO or vel.length() > MORTAR_MAX_LAUNCH_SPEED:
			continue
		if not _mortar_clears_ceiling(origin, vel, gravity):
			continue
		var miss := _mortar_ground_miss(origin, ground_y, target.x, vel, gravity)
		if miss < best_miss:
			best_miss = miss
			best_vel = vel

	if best_miss > _mortar_blast_radius * 0.35:
		var searched := _mortar_velocity_search(origin, ground_y, target.x, gravity, dx, preferred_deg)
		if searched.length_squared() > 1.0:
			var search_miss := _mortar_ground_miss(origin, ground_y, target.x, searched, gravity)
			if search_miss < best_miss:
				best_vel = searched

	if best_vel.length_squared() < 1.0:
		for angle_deg: float in [preferred_deg, 52.0, 48.0, 56.0]:
			var vel := _mortar_velocity_for_angle(dx, dy, gravity, angle_deg)
			if vel == Vector2.ZERO:
				continue
			if not _mortar_clears_ceiling(origin, vel, gravity):
				continue
			return vel

	return best_vel


func _mortar_ground_miss(
	origin: Vector2,
	ground_y: float,
	target_x: float,
	vel: Vector2,
	gravity: float,
) -> float:
	var impact := _mortar_simulate_ground_impact(origin, ground_y, vel, gravity)
	return absf(impact.x - target_x)


func _mortar_simulate_ground_impact(
	origin: Vector2,
	ground_y: float,
	vel: Vector2,
	gravity: float,
) -> Vector2:
	var pos := origin
	var v := vel
	var dt := MORTAR_SIM_DT
	var prev_pos := pos
	for _step in 500:
		prev_pos = pos
		pos += v * dt
		v.y += gravity * dt
		if v.y > 0.0 and prev_pos.y <= ground_y and pos.y >= ground_y:
			var span := pos.y - prev_pos.y
			var alpha: float = 0.5
			if span > 0.01:
				alpha = clampf((ground_y - prev_pos.y) / span, 0.0, 1.0)
			return Vector2(lerpf(prev_pos.x, pos.x, alpha), ground_y)
	return pos


func _mortar_velocity_for_angle(dx: float, dy: float, gravity: float, angle_deg: float) -> Vector2:
	var dir := _mortar_launch_direction(dx, angle_deg)
	var theta := dir.angle()
	var denom := dy - dx * tan(theta)
	if absf(denom) < 0.5:
		return Vector2.ZERO
	var cos_t := cos(theta)
	if absf(cos_t) < 0.02:
		return Vector2.ZERO
	var v_sq := gravity * dx * dx / (2.0 * cos_t * cos_t * denom)
	if v_sq <= 1.0:
		return Vector2.ZERO
	return dir * sqrt(v_sq)


func _mortar_velocity_search(
	origin: Vector2,
	ground_y: float,
	target_x: float,
	gravity: float,
	dx: float,
	preferred_deg: float,
) -> Vector2:
	var best_vel := Vector2.ZERO
	var best_miss := INF
	var angles: Array[float] = []
	for deg in range(40, 67):
		angles.append(float(deg))
	angles.append(preferred_deg)
	for speed_i in range(400, int(MORTAR_MAX_LAUNCH_SPEED) + 1, 20):
		var speed := float(speed_i)
		for angle_deg: float in angles:
			var dir := _mortar_launch_direction(dx, angle_deg)
			var vel: Vector2 = dir * speed
			if not _mortar_clears_ceiling(origin, vel, gravity):
				continue
			var miss := _mortar_ground_miss(origin, ground_y, target_x, vel, gravity)
			if miss < best_miss:
				best_miss = miss
				best_vel = vel
	return best_vel


func _mortar_launch_direction(dx: float, angle_deg: float) -> Vector2:
	var rad := deg_to_rad(angle_deg)
	if dx >= 0.0:
		return Vector2(cos(rad), -sin(rad)).normalized()
	return Vector2(-cos(rad), -sin(rad)).normalized()


func _mortar_clears_ceiling(origin: Vector2, vel: Vector2, gravity: float) -> bool:
	if vel.y >= 0.0:
		return origin.y >= MORTAR_CEILING_SAFE_Y
	var apex_y := origin.y - vel.y * vel.y / (2.0 * gravity)
	return apex_y >= MORTAR_CEILING_SAFE_Y


func _mortar_land_miss(origin: Vector2, target: Vector2, vel: Vector2, gravity: float) -> float:
	return _mortar_ground_miss(origin, target.y, target.x, vel, gravity)


func _process_shield(delta: float) -> void:
	velocity = Vector2.ZERO
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY_ACCEL * delta
	move_and_slide()
	_shield_lifetime_left -= delta
	_shield_charge_pulse += delta * 6.0
	_shield_intercept_cd_left = maxf(0.0, _shield_intercept_cd_left - delta)
	_update_shield_charge_visual()
	_try_fire_shield_intercept()
	if _shield_lifetime_left <= 0.0:
		_destroy()


func _try_fire_shield_intercept() -> void:
	if _shield_intercept_cd_left > 0.0 or _game == null:
		return
	if not _game.has_method("spawn_esqueleto_turret_intercept_shot"):
		return
	var threat := _find_shield_threat()
	if threat == null:
		return
	var spawn := _shield_intercept_spawn()
	var intercept_vel := _solve_shield_intercept_velocity(threat, spawn)
	if intercept_vel.length_squared() < 16.0:
		return
	_game.call("spawn_esqueleto_turret_intercept_shot", _owner, spawn, intercept_vel)
	_shield_intercept_cd_left = _shield_intercept_interval_s
	SfxManager.play("ricochet", spawn, 0.7, 4.0)


func _shield_intercept_spawn() -> Vector2:
	var face := _facing_sign()
	return global_position + Vector2(24.0 * face, -8.0)


func _find_shield_threat() -> Node2D:
	var best: Node2D = null
	var best_score := INF
	var face := _facing_sign()
	var guard_pos := _owner.global_position if _owner != null else global_position
	for n in get_tree().get_nodes_in_group("arrows"):
		if not (n is Arrow):
			continue
		var ar := n as Arrow
		if not is_instance_valid(ar) or ar.is_queued_for_deletion():
			continue
		var owner_pl := ar.get_owner_player()
		if owner_pl == null or owner_pl == _owner:
			continue
		if _is_shield_unblockable(ar):
			continue
		if not _is_incoming_threat(ar.global_position, ar.velocity, face, guard_pos):
			continue
		var score := ar.global_position.distance_to(guard_pos)
		if score < best_score:
			best_score = score
			best = ar
	for n in get_tree().get_nodes_in_group("grenades"):
		if not (n is Grenade):
			continue
		var gr := n as Grenade
		if not is_instance_valid(gr) or gr.is_queued_for_deletion():
			continue
		var owner_pl := gr.get_owner_player()
		if owner_pl == null or owner_pl == _owner:
			continue
		if not _is_incoming_threat(gr.global_position, gr.velocity, face, guard_pos):
			continue
		var score := gr.global_position.distance_to(guard_pos)
		if score < best_score:
			best_score = score
			best = gr
	return best


func _is_incoming_threat(
	pos: Vector2,
	vel: Vector2,
	face: float,
	guard_pos: Vector2,
) -> bool:
	if global_position.distance_to(pos) > _shield_intercept_range:
		return false
	var to_threat := pos - global_position
	if to_threat.x * face < -28.0:
		return false
	var to_guard := guard_pos - pos
	if to_guard.length_squared() < 96.0:
		return true
	if vel.length_squared() < 36.0:
		return to_guard.x * face > -24.0
	return vel.dot(to_guard) > 0.0


func _threat_velocity(threat: Node2D) -> Vector2:
	if threat is CharacterBody2D:
		return (threat as CharacterBody2D).velocity
	return Vector2.ZERO


func _solve_shield_intercept_velocity(threat: Node2D, spawn: Vector2) -> Vector2:
	var threat_pos := threat.global_position
	var threat_vel := _threat_velocity(threat)
	var rel := threat_pos - spawn
	var shot_speed := maxf(_shield_intercept_speed, 120.0)
	var lead_t := rel.length() / shot_speed
	var a := threat_vel.length_squared() - shot_speed * shot_speed
	if absf(a) > 0.01:
		var b := 2.0 * rel.dot(threat_vel)
		var c := rel.length_squared()
		var disc := b * b - 4.0 * a * c
		if disc >= 0.0:
			var sqrt_disc := sqrt(disc)
			var t1 := (-b - sqrt_disc) / (2.0 * a)
			var t2 := (-b + sqrt_disc) / (2.0 * a)
			if t1 > 0.04:
				lead_t = t1
			elif t2 > 0.04:
				lead_t = t2
	lead_t = clampf(lead_t, 0.04, 0.75)
	var aim_point := threat_pos + threat_vel * lead_t
	var dir := aim_point - spawn
	if dir.length_squared() < 16.0:
		dir = rel
	if dir.length_squared() < 1.0:
		return Vector2.ZERO
	return dir.normalized() * shot_speed


func _is_shield_unblockable(body: Arrow) -> bool:
	var flags := body.get_shot_flags()
	if flags.get("esqueleto_feixe", false):
		return true
	if flags.get("esqueleto_chuva_osso", false):
		return true
	if flags.get("esqueleto_torreta_escudo_intercept", false):
		return true
	return false


func _update_shield_charge_visual() -> void:
	var pulse := 0.08 * sin(_shield_charge_pulse * 2.2)
	if _shield_glow != null:
		_shield_glow.modulate.a = 0.35 + pulse
	if _shield_front != null:
		_shield_front.modulate = Color(0.72, 0.78, 0.9, 0.95)
	if _shield_panel_l != null:
		_shield_panel_l.modulate = Color(0.58, 0.62, 0.72, 0.92)
	if _shield_panel_r != null:
		_shield_panel_r.modulate = Color(0.62, 0.66, 0.76, 0.92)


func _facing_sign() -> float:
	if _owner != null:
		return 1.0 if _owner.player_id == 1 else -1.0
	return 1.0


func _process_combat(delta: float) -> void:
	_update_aim_visual()
	if _shots_left <= 0:
		return
	_fire_cooldown_left -= delta
	if _fire_cooldown_left > 0.0:
		return
	var opponent := _find_opponent()
	if opponent == null:
		_fire_cooldown_left = 0.35
		return
	_fire_at(opponent)
	_shots_left -= 1
	if _shots_left <= 0:
		queue_free()
	else:
		_fire_cooldown_left = _shot_interval_s


func _update_aim_visual() -> void:
	if _head_pivot == null:
		return
	var opponent := _find_opponent()
	if opponent == null:
		return
	var to_enemy := _target_offset(opponent)
	if to_enemy.length_squared() < 1.0:
		return
	_head_pivot.rotation = to_enemy.angle()


func _target_offset(opponent: Player) -> Vector2:
	if opponent.has_method("get_body_collision_rect"):
		var body_rect: Rect2 = opponent.get_body_collision_rect()
		if body_rect.size.length_squared() > 1.0:
			return body_rect.get_center() - global_position
	return opponent.global_position - global_position


func _find_opponent() -> Player:
	if _owner == null:
		return null
	return AutoAimFiveWayUtil.find_valid_opponent(_owner)


func _fire_at(opponent: Player) -> void:
	if _game == null or not _game.has_method("spawn_esqueleto_turret_shot"):
		return
	var muzzle_global := _head_pivot.global_position if _muzzle == null else _muzzle.global_position
	var aim := opponent.global_position - muzzle_global
	if opponent.has_method("get_body_collision_rect"):
		var body_rect: Rect2 = opponent.get_body_collision_rect()
		if body_rect.size.length_squared() > 1.0:
			aim = body_rect.get_center() - muzzle_global
	if aim.length_squared() < 1.0:
		aim = Vector2.RIGHT if (_owner != null and _owner.player_id == 1) else Vector2.LEFT
	else:
		aim = aim.normalized()
	var vel := aim * _shot_speed
	_game.call("spawn_esqueleto_turret_shot", _owner, muzzle_global, vel, _shot_damage)


func _apply_team_colors() -> void:
	var base := Color(0.78, 0.74, 0.66, 1.0)
	var rim := Color(0.42, 0.38, 0.34, 1.0)
	var head := Color(0.86, 0.82, 0.74, 1.0)
	var barrel_c := Color(0.58, 0.54, 0.48, 1.0)
	var tip := Color(0.92, 0.88, 0.62, 1.0)
	var bone := Color(0.86, 0.82, 0.74, 1.0)
	var bone_dark := Color(0.72, 0.68, 0.6, 1.0)
	if _owner != null and _owner.player_id == 2:
		base = Color(0.66, 0.72, 0.78, 1.0)
		rim = Color(0.34, 0.38, 0.44, 1.0)
		head = Color(0.74, 0.80, 0.86, 1.0)
		barrel_c = Color(0.48, 0.52, 0.58, 1.0)
		tip = Color(0.62, 0.78, 0.92, 1.0)
		bone = Color(0.74, 0.80, 0.86, 1.0)
		bone_dark = Color(0.58, 0.66, 0.74, 1.0)
	if _base_plate != null:
		_base_plate.color = base
	if _base_rim != null:
		_base_rim.color = rim
	if _head_body != null:
		_head_body.color = head
	if _mode != Mode.ROCKET_CHARGE and _mode != Mode.ROCKET_FLIGHT:
		if _barrel != null:
			_barrel.color = barrel_c
		if _barrel_tip != null:
			_barrel_tip.color = tip
	if _mode == Mode.FORTRESS:
		if _barrel != null:
			_barrel.color = barrel_c.darkened(0.08)
		if _barrel_tip != null:
			_barrel_tip.color = tip
		if _anchor_l != null:
			_anchor_l.color = rim
		if _anchor_r != null:
			_anchor_r.color = rim
	if _mode == Mode.MORTAR:
		if _barrel != null:
			_barrel.color = barrel_c.darkened(0.12)
		if _barrel_tip != null:
			_barrel_tip.color = tip.darkened(0.05)
		if _anchor_l != null:
			_anchor_l.color = rim
		if _anchor_r != null:
			_anchor_r.color = rim
	if _mode == Mode.SHIELD:
		_update_shield_charge_visual()
	if _legs_root != null:
		for child in _legs_root.get_children():
			_color_leg_tree(child, bone, bone_dark)


func _color_leg_tree(node: Node, bone: Color, bone_dark: Color) -> void:
	if node is Polygon2D:
		if node.name.contains("Foot"):
			node.color = bone_dark
		else:
			node.color = bone
	for child in node.get_children():
		_color_leg_tree(child, bone, bone_dark)


func _destroy() -> void:
	if _rocket_exploded:
		return
	if _shield_intercept != null:
		_shield_intercept.monitoring = false
	SfxManager.play("explosion_small", global_position)
	var e := _explosion_scene.instantiate() as Node2D
	if e != null and get_tree().current_scene != null:
		get_tree().current_scene.add_child(e)
		e.global_position = global_position
	queue_free()
