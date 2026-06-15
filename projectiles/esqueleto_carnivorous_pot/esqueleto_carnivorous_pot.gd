extends CharacterBody2D
class_name EsqueletoCarnivorousPot

## Vaso de planta: arco com gravidade; ao tocar terreno vira planta carnívora.

const TERRAIN_COLLISION_MASK := 49

var _owner: Player
var _game: Node
var _plant_config: Dictionary = {}
var _gravity_accel: float = 1500.0
var _planted: bool = false

@onready var _pot_body: Polygon2D = $PotBody
@onready var _sprout: Polygon2D = $Sprout


func setup(owner_player: Player, game: Node, throw_velocity: Vector2, config: Dictionary) -> void:
	_owner = owner_player
	_game = game
	velocity = throw_velocity
	_plant_config = config
	_gravity_accel = float(config.get("gravity", 1500.0))
	if _owner != null:
		add_collision_exception_with(_owner)


func _ready() -> void:
	add_to_group("esqueleto_carnivorous_pots")
	collision_mask = TERRAIN_COLLISION_MASK


func _physics_process(delta: float) -> void:
	if _planted:
		return
	velocity.y += _gravity_accel * delta
	var col := move_and_collide(velocity * delta)
	if col == null:
		return
	var n := col.get_normal()
	global_position = col.get_position() + n * 3.0
	_plant_on_surface(n)


func _plant_on_surface(normal: Vector2) -> void:
	if _planted:
		return
	_planted = true
	SfxManager.play("grenade_bounce", global_position, 0.95, -3.0)
	if _game != null and _game.has_method("spawn_esqueleto_carnivorous_plant"):
		_game.spawn_esqueleto_carnivorous_plant(_owner, global_position, _plant_config)
	queue_free()
