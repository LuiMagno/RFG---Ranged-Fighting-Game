extends Node2D
class_name DamageNumbersLayer

const DAMAGE_NUMBER_SCENE := preload("res://ui/damage_number.tscn")


func spawn_for_player(victim: Player, amount: int) -> void:
	if victim == null or not is_instance_valid(victim):
		return
	var tier := _tier_for_amount(amount)
	var world_pos := victim.global_position + Vector2(randf_range(-14.0, 14.0), -52.0)
	var dn := DAMAGE_NUMBER_SCENE.instantiate() as DamageNumber
	if dn == null:
		return
	add_child(dn)
	dn.setup(amount, tier, world_pos)


func _tier_for_amount(amount: int) -> String:
	if amount >= 28:
		return "heavy"
	if amount >= 15:
		return "normal"
	return "light"
