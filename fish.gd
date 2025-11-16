extends Node2D

enum FishType  {BLINKY, SCHOOLFISH, SUBMARINE}

@export var anim_speed_scale:float = 1.0
@export var fish_type:FishType = FishType.BLINKY

var left_or_right:int
var anim_sprite:AnimatedSprite2D


func _ready() -> void:
	left_or_right = 1	# 1= right / 0 = left
	
	for f in get_children():
		f.visible = false
	
	match fish_type:
		FishType.BLINKY:
			anim_sprite = $sprite_blinky
		FishType.SCHOOLFISH:
			anim_sprite = $sprite_schoolfish
		FishType.SUBMARINE:
			anim_sprite = $sprite_submarine
			
	anim_sprite.speed_scale = anim_speed_scale
	anim_sprite.play()
	anim_sprite.visible = true

	
func _process(delta: float) -> void:
	# FSM
	if anim_sprite.position.x >= 1500:
		left_or_right = 0
		anim_sprite.scale.x *= -1
	if anim_sprite.position.x <= -100:
		left_or_right = 1
		anim_sprite.scale.x *= -1

	# Movement
	if left_or_right == 1:
		anim_sprite.position.x += int(1 * anim_speed_scale)
	else:
		anim_sprite.position.x -= int(1 * anim_speed_scale)


		
