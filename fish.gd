@tool
class_name Fish extends Node2D

signal reached_target(fish: Fish)

enum FishType  {BLINKY, SCHOOLFISH, SUBMARINE, JELLYFISH}
enum SwimTo {LEFT, RIGHT}

const DURATION_TURN:float = 0.1		# in seconds for a turning from left-to-right and vice-versa
const GLOBAL_BOUNDARY_LEFT = 200 
const GLOBAL_BOUNDARY_RIGHT = 1720


## swim speed of the fish. in pixel/sec
@export var swim_speed:int = 200
## animation speed-scale
@export var anim_speed_scale:float = 1.0:
	set = set_anim_speed_scale
## FishType reflects the visible sprite, the possible swim-style, etc
@export var fish_type:FishType = FishType.BLINKY:
	set = set_fish_type

var fsm__moving_left_or_right:SwimTo = SwimTo.RIGHT
var anim_sprite:AnimatedSprite2D

func set_fish_type(value:FishType):
	fish_type = value
	_setup_sprite()
func set_anim_speed_scale(value:float):
	anim_speed_scale = value
	_setup_sprite()


## Setup animated-sprites: which fish to display? disable all other fish-types (sprites)
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
		FishType.JELLYFISH:
			anim_sprite = $sprite_jellyfish
	# 3. Apply properties and show
	if is_instance_valid(anim_sprite):
		if not Engine.is_editor_hint():		# dont swim in the editor
			anim_sprite.play()
		anim_sprite.speed_scale = anim_speed_scale
		anim_sprite.visible = true


## after anmiation, fish looks to the left
func look_left() -> void:
	var new_scale_x = -abs(anim_sprite.scale.x)	 # Ensure facing Left (negative scale)
	#anim_sprite.scale.x = new_scale_x
	var tween = create_tween()
	tween.tween_property(anim_sprite, "scale:x", new_scale_x, DURATION_TURN)

## after anmiation, fish looks to the right
func look_right() -> void:
	var new_scale_x = abs(anim_sprite.scale.x) # Ensure facing Left (negative scale)
	#anim_sprite.scale.x = new_scale_x
	var tween = create_tween()
	tween.tween_property(anim_sprite, "scale:x", new_scale_x, DURATION_TURN)

## fish turns left or right, depends on the global_position of target
func look_to(global_target:Vector2) -> void:
	if global_target.x < anim_sprite.global_position.x:
		look_left()
	else:
		look_right()


## NOT USED anymore!!
func swim_left_right() -> void:
	if Engine.is_editor_hint():		# dont swim in the editor
			return
	# FSM
	if anim_sprite.position.x <= 100:
		fsm__moving_left_or_right = SwimTo.RIGHT
		anim_sprite.scale.x *= -1
	
	if anim_sprite.position.x >= 1500:
		fsm__moving_left_or_right = SwimTo.LEFT
		anim_sprite.scale.x *= -1
	# Movement
	if fsm__moving_left_or_right == SwimTo.RIGHT:
		anim_sprite.position.x += 1
	else:
		anim_sprite.position.x -= 1


## Swim from left to right an back. turn araound at the boundaries left and right. 
## Is called per frame, with respect to delta-time
func swim_left_right2(delta: float) -> void:
	if Engine.is_editor_hint():	# dont swim in the editor-window ;)
		return
	
	# if currently moving left (0) and hit the left boundary
	if fsm__moving_left_or_right == SwimTo.LEFT and anim_sprite.global_position.x <= GLOBAL_BOUNDARY_LEFT:
		look_right()
		fsm__moving_left_or_right = SwimTo.RIGHT # Switch to Moving Right

	# if currently moving right (1) and hit the right boundary
	if fsm__moving_left_or_right == SwimTo.RIGHT and anim_sprite.global_position.x >= GLOBAL_BOUNDARY_RIGHT:
		look_left()
		fsm__moving_left_or_right = SwimTo.LEFT # Switch to Moving Left

	# setup movement
	var direction = 0
	if fsm__moving_left_or_right == SwimTo.RIGHT:
		direction = 1	# Moving Right
	else:
		direction = -1	# Moving Left
		
	# Apply movement smoothly using delta-time
	anim_sprite.position.x += direction * swim_speed * delta



## swim / tween linear to the target coordinate (global_position) in seconds
func swim_linear_to(global_target: Vector2, duration: float):
	#print("<%s> swin linear_to %s in %.1f sec" % [name, global_target, duration]	)
	look_to(global_target)
	var tween = create_tween()
	tween.tween_property(anim_sprite, "global_position", global_target, duration).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	emit_signal("reached_target", self)
	

func _ready() -> void:
	_setup_sprite()
	# init FSM for swim-direction
	if fsm__moving_left_or_right == SwimTo.LEFT:
		look_left()
	else: # If starting right
		look_right()


func _process(delta: float) -> void:
	#swim_left_right()
	swim_left_right2(delta)



		
