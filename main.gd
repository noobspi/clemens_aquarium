extends Node2D

@onready var left_or_right:int = 1	# 1= right / 0 = left



func _process(delta: float) -> void:
	if $sprite_fish1.position.x >= 1000:
		left_or_right = 0
		$sprite_fish1.scale.x *= -1
	if $sprite_fish1.position.x <= 100:
		left_or_right = 1
		$sprite_fish1.scale.x *= -1

	if left_or_right == 1:
		$sprite_fish1.position.x += 1
	else:
		$sprite_fish1.position.x -= 1


	
	
	
