class_name Fish
extends Node2D

enum FishType  {BLINKY, SCHOOLFISH, SUBMARINE}

@export var anim_speed_scale:float = 1.0
@export var fish_type:FishType = FishType.BLINKY

var fsm__moving_left_or_right:int = 0 	# 0 = left, 1 = right
var anim_sprite:AnimatedSprite2D


# Setup animated-sprites: which fish to display?
func _setup_sprite() -> void:
	# 1. Hide all sprites
	for f in get_children():
		if f is AnimatedSprite2D:
			f.visible = false
	
	# 2. Select the correct sprite
	match fish_type:
		FishType.BLINKY:
			anim_sprite = $sprite_blinky
		FishType.SCHOOLFISH:
			anim_sprite = $sprite_schoolfish
		FishType.SUBMARINE:
			anim_sprite = $sprite_submarine
	
	# 3. Apply properties and show
	if is_instance_valid(anim_sprite):
		anim_sprite.speed_scale = anim_speed_scale
		anim_sprite.play()
		anim_sprite.visible = true

func _ready() -> void:
	fsm__moving_left_or_right = 1
	_setup_sprite()
	


	
func _process(delta: float) -> void:
	# FSM
	if anim_sprite.position.x >= 1500:
		fsm__moving_left_or_right = 0
		anim_sprite.scale.x *= -1
	if anim_sprite.position.x <= -100:
		fsm__moving_left_or_right = 1
		anim_sprite.scale.x *= -1

	# Movement
	if fsm__moving_left_or_right == 1:
		anim_sprite.position.x += int(1 * anim_speed_scale)
	else:
		anim_sprite.position.x -= int(1 * anim_speed_scale)


		
