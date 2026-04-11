extends Node2D

@export var lifetime: float = 0.09
@export var start_scale: float = 1.6
@export var end_scale: float = 5.0

@onready var puff: Polygon2D = $Puff

func _ready() -> void:
	scale = Vector2.ONE * start_scale
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * end_scale, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(puff, "color:a", 0.0, lifetime)
	tw.tween_callback(queue_free)

