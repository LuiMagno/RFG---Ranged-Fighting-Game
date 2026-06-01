extends Node2D

## Geometria do palco «Patamares + abismo». Patamares layer 16: topo fino + one-way (sem paredes laterais).
## Chão Far/Bridge layer 32. Ver Player (wall jump / drop through).

const ONE_WAY_MARGIN_PX := 6.0
const PLATFORM_TOP_COLLIDER_H := 10.0
const ARENA_PLATFORM_LAYER_BIT := 16


func _ready() -> void:
	_configure_arena_static_bodies(self)


func _configure_arena_static_bodies(node: Node) -> void:
	for c in node.get_children():
		if c is StaticBody2D:
			var body := c as StaticBody2D
			var is_platform := (body.collision_layer & ARENA_PLATFORM_LAYER_BIT) != 0
			for ch in body.get_children():
				if ch is CollisionShape2D and (ch as CollisionShape2D).shape != null:
					var cs := ch as CollisionShape2D
					if is_platform:
						_shrink_shape_to_platform_top(cs)
					cs.one_way_collision = is_platform
					if is_platform:
						cs.one_way_collision_margin = ONE_WAY_MARGIN_PX
		_configure_arena_static_bodies(c)


func _shrink_shape_to_platform_top(cs: CollisionShape2D) -> void:
	if cs.shape is RectangleShape2D:
		var dup := cs.shape.duplicate() as RectangleShape2D
		var full_h := dup.size.y
		var thin_h := minf(PLATFORM_TOP_COLLIDER_H, full_h)
		dup.size = Vector2(dup.size.x, thin_h)
		cs.shape = dup
		cs.position = Vector2(0.0, -full_h * 0.5 + thin_h * 0.5)
