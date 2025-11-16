extends Node2D

@onready var left_or_right:int = 1	# 1= right / 0 = left
@onready var testfish: Node2D = $sprite_fish1



func _process(delta: float) -> void:
	if testfish.position.x >= 1000:
		left_or_right = 0
		testfish.scale.x *= -1
	if testfish.position.x <= 100:
		left_or_right = 1
		testfish.scale.x *= -1

	if left_or_right == 1:
		testfish.position.x += 1
	else:
		testfish.position.x -= 1


	
	
	
