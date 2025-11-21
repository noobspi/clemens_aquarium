extends Sprite2D


func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale:x", -1.0, 0.5)\
		.set_ease(Tween.EASE_OUT)
