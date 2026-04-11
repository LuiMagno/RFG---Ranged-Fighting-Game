extends Arrow
class_name HomingMissile

@export var homing_turn_deg_per_sec: float = 120.0
@export var homing_lead_time: float = 0.06
@export var homing_min_speed: float = 340.0
@export var homing_full_strength_time: float = 1.1
@export var homing_fade_out_time: float = 1.0
@export var homing_stop_distance: float = 95.0

var _target: Player
var _base_speed: float = 0.0
var _age_s: float = 0.0


func set_homing_target(target: Player) -> void:
	_target = target


func setup(
	owner_player: Player,
	initial_velocity: Vector2,
	gravity_override: float = INF,
	bounces_override: int = -1,
	damage_override: int = -1,
	size_multiplier: float = 1.0,
	is_archer_carrier: bool = false,
	cluster_spread_deg: float = 7.0
) -> void:
	# Força gravidade 0 e sem ricochete (míssil).
	super.setup(owner_player, initial_velocity, 0.0, 0, damage_override, size_multiplier, false, cluster_spread_deg)
	_base_speed = maxf(homing_min_speed, initial_velocity.length())
	_age_s = 0.0
	gravity_accel = 0.0
	bounces_left = 0


func _physics_process(delta: float) -> void:
	_age_s += delta
	# Steering antes do move.
	if _target != null and is_instance_valid(_target):
		var tgt_pos := _target.global_position
		# Pequeno "lead" baseado na velocidade atual do alvo.
		if _target is CharacterBody2D:
			tgt_pos += (_target as CharacterBody2D).velocity * homing_lead_time
		var to_tgt := tgt_pos - global_position
		var dist := to_tgt.length()
		# Perto do alvo, para de virar (abre janela de dodge passando "de lado").
		if dist > homing_stop_distance:
			var desired_dir := to_tgt.normalized()
			var current_dir := velocity.normalized() if velocity.length_squared() > 0.001 else desired_dir
			var ang_diff := current_dir.angle_to(desired_dir)
			# Homing enfraquece com o tempo (fica mais "desviável" se você sobreviver ao começo).
			var strength := 1.0
			if _age_s > homing_full_strength_time:
				var t := (_age_s - homing_full_strength_time) / maxf(0.001, homing_fade_out_time)
				strength = clampf(1.0 - t, 0.0, 1.0)
			var max_turn := deg_to_rad(homing_turn_deg_per_sec) * delta * strength
			if max_turn > 0.0:
				velocity = velocity.rotated(clampf(ang_diff, -max_turn, max_turn))

	# Mantém velocidade mais ou menos constante (míssil lento, mas firme).
	var spd := velocity.length()
	if spd < _base_speed and spd > 0.01:
		velocity = velocity * (_base_speed / spd)
	elif spd <= 0.01:
		velocity = Vector2.RIGHT * _base_speed

	super._physics_process(delta)

