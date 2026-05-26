extends Node2D

## Geometria do palco «Patamares + abismo». `Area2D` Pit* ligados em `Game`.
## `StaticBody2D` em **collision_layer 16** (layer 5 «ArenaPlatforms»): só jogadores (mask 19) colidem;
## projéteis com mask 11 (flecha, bola de fogo, mísseis) não incluem essa layer — atravessam; chão/paredes ficam na layer 1.
## `one_way_collision`: salto de baixo atravessa; apoio por cima.

const ONE_WAY_MARGIN_PX := 6.0


func _ready() -> void:
	_apply_one_way_collision_to_platforms(self)


func _apply_one_way_collision_to_platforms(node: Node) -> void:
	for c in node.get_children():
		if c is StaticBody2D:
			for ch in c.get_children():
				if ch is CollisionShape2D and (ch as CollisionShape2D).shape != null:
					var cs := ch as CollisionShape2D
					cs.one_way_collision = true
					cs.one_way_collision_margin = ONE_WAY_MARGIN_PX
		_apply_one_way_collision_to_platforms(c)