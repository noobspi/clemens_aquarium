@tool
class_name Fish extends Node2D

## fish has reached (moved) its target point 
signal reached_target(fish: Fish)

## Possible Fish-Types. Defines sprite-asset and AI behaviour
enum FishType {
	Blinky, 
	Schoolfish, 
	Jellyfish, 
	Submarine
}

## AI-State: what can the fish do?
enum AiState {
	IdleUndecided, IdleSwimLeft, IdleSwimRight, IdleWooble, 
	SwimTo, 
	ChangeLayer
}
## What is the fish currently doing? 
var ai_current_state: AiState


const DURATION_TURN:float = 0.1		# in seconds for a turning from left-to-right and vice-versa
const GLOBAL_BOUNDARY_LEFT = 200 
const GLOBAL_BOUNDARY_RIGHT = 1720
const AQUARIUM_MARGIN:int = 200

const IDLE_TIME_MIN: float = 3.0
const IDLE_TIME_MAX: float = 10.0
@onready var idle_timer:Timer = $stop_idle_mode

var sprite:AnimatedSprite2D
var sprite_orig_scale: Vector2


## FishType defines the visible sprite, the possible swim-style, etc
@export var fish_type:FishType = FishType.Blinky:
	set = set_fish_type	
func set_fish_type(value:FishType):
	fish_type = value
	setup_sprite()

## Swim speed of the fish. in pixel/sec
@export var swim_speed:int = 200

## Animation speed-scale
@export var anim_speed_scale:float = 1.0:
	set = set_anim_speed_scale

func set_anim_speed_scale(value:float):
	anim_speed_scale = value
	setup_sprite()

## Wooble in idle-mode: how far (in px)
@export var wobble_radius: float = 20.0
@export var wooble_x_freq: float = 0.1
@export var wooble_y_freq: float = 0.3
var wooble_current_angle_x: float = 0.0
var wooble_current_angle_y: float = 0.0
var wooble_global_center: Vector2 = Vector2.ZERO


## Show AI thougts on console?
@export var debug_ai: bool = false
func print_ai (s: String) -> void:
	if debug_ai:
		print("🐟 " + s)



## Returns a rnd point on the screen / viewport
func get_random_point_in_aquarium() -> Vector2i:
	var viewport_size: Vector2 = get_viewport_rect().size
	var random_x = randi_range(0 + AQUARIUM_MARGIN, int(viewport_size.x) - AQUARIUM_MARGIN)
	var random_y = randi_range(0 + AQUARIUM_MARGIN, int(viewport_size.y) - AQUARIUM_MARGIN)
	return Vector2i(random_x, random_y)


## Reset the idle timer to a rnd time, or disables timer in godot-editor
func reset_idle_timer():
	if Engine.is_editor_hint():			# dont swim in the editor-window ;)
		idle_timer.stop()
	else:
		var t:float = randf_range(IDLE_TIME_MIN, IDLE_TIME_MAX)
		print_ai("<%s> Restart idle-timer to 🎲 %.1f sec" % [name, t])
		idle_timer.wait_time = t
		idle_timer.start()


## Setup animated-sprites: which fish to display? disable all other fish-types (sprites)
func setup_sprite() -> void:
	# 1. Hide all sprites
	for f in get_children():
		if f is AnimatedSprite2D:
			f.visible = false
	# 2. Select the correct sprite
	match fish_type:
		FishType.Blinky:
			sprite = $sprite_blinky
		FishType.Schoolfish:
			sprite = $sprite_schoolfish
		FishType.Submarine:
			sprite = $sprite_submarine
		FishType.Jellyfish:
			sprite = $sprite_jellyfish
	# 3. Apply properties and show
	if is_instance_valid(sprite):
		if not Engine.is_editor_hint():		# dont swim in the editor
			sprite.play()
		sprite_orig_scale = sprite.scale
		sprite.speed_scale = anim_speed_scale
		sprite.visible = true


## after anmiation, fish looks to the left
func look_left() -> void:
	var new_scale_x = -abs(sprite_orig_scale.x)	 # Ensure facing Left (negative scale)
	var tween = create_tween()
	tween.tween_property(sprite, "scale:x", new_scale_x, DURATION_TURN)


## after anmiation, fish looks to the right
func look_right() -> void:
	var new_scale_x = abs(sprite_orig_scale.x) # Ensure facing Left (negative scale)
	var tween = create_tween()
	tween.tween_property(sprite, "scale:x", new_scale_x, DURATION_TURN)


## fish turns left or right, depends on the global_position of target
func look_to(global_target:Vector2) -> void:
	if global_target.x < sprite.global_position.x:
		look_left()
	else:
		look_right()


## wooble (sinus on x- and y-axes) around a wooble_global_center-point using delta time
func wooble(radius: float, delta: float) -> void:
	# 1. Calculate the change in angle based on delta and frequency (Hz). Frequency * TAU gives the angular speed in radians/second
	var angular_speed_x = wooble_x_freq * TAU
	var angular_speed_y = wooble_y_freq * TAU

	# 2. Increment the current angle (phase)
	wooble_current_angle_x += angular_speed_x * delta
	wooble_current_angle_y += angular_speed_y * delta

	# 3. Keep the angle wrapped between 0 and TAU (optional, but good practice)
	wooble_current_angle_x = fmod(wooble_current_angle_x, TAU)
	wooble_current_angle_y = fmod(wooble_current_angle_y, TAU)

	# 4. Calculate the offsets using the current angle as input to sin()
	var x_offset = radius * sin(wooble_current_angle_x)
	var y_offset = radius * sin(wooble_current_angle_y)

	# 5. Apply the offsets to the global center position
	global_position = wooble_global_center + Vector2(x_offset, y_offset)


## swim / tween linear to the target coordinate (global_position) in seconds
func swim_to(global_target: Vector2, duration: float):
	var ai_last_state = ai_current_state
	ai_current_state = AiState.SwimTo #fsm__is_catching = true
	idle_timer.paused = true
	#print("<%s> swin linear_to %s in %.1f sec" % [name, global_target, duration])
	
	look_to(global_target)
	var tween = create_tween()
	tween.tween_property(sprite, "global_position", global_target, duration).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# re-set idle swim-direction after catching
	if ai_last_state == AiState.IdleSwimLeft:
		look_left()
	else:
		look_right()

	# reset previous idle-state (if left or right, dice otherwise)
	if ai_last_state == AiState.IdleSwimLeft or ai_last_state == AiState.IdleSwimRight:
		ai_current_state = ai_last_state
	else:
		ai_current_state = AiState.IdleUndecided
	
	idle_timer.paused = false
	print_ai("<%s> reached target. switch back to %s" % [name,  str(AiState.keys()[ai_current_state])])
	emit_signal("reached_target", self)	# now shout out to the world: "I'm here, i reached my target!"


## Dice and Return what to do next: Wooble, Left, Right  
func get_random_idle_state() -> AiState:
	var dice: float = randf()
	if dice < 0.20:
		print_ai("<%s> Idle by 🎲 WOOBLE around %s" % [name, wooble_global_center])
		return AiState.IdleWooble
	elif dice < 0.60:
		print_ai("<%s> Idle by 🎲 SWIM-LEFT" % [name])
		return AiState.IdleSwimLeft
	else:
		print_ai("<%s> Idle by 🎲 SWIM-RIGHT" % [name])
		return AiState.IdleSwimRight


## Is called per frame, with respect to delta-time. only executes, if not in idle-mode or in the godot-editor
## Swim from left to right an back; or stand still and Wooble around. turns around at the boundaries left and right. 
func idle_mode(delta:float) -> void:
	if Engine.is_editor_hint():			# dont swim in the editor-window ;)
		return
	
	# 1. FSM - decide what to do in idle-mode, if undecided
	if ai_current_state == AiState.IdleUndecided:
		ai_current_state = get_random_idle_state()

	# 2. FSM - check, if fish needs to turn around, cause of hitting the aquarium boundaries
	if ai_current_state == AiState.IdleSwimLeft and sprite.global_position.x <= GLOBAL_BOUNDARY_LEFT:
		ai_current_state = AiState.IdleSwimRight
		print_ai("<%s> Reached left bondary, turn to %s" % [name, str(AiState.keys()[ai_current_state])])
	if ai_current_state == AiState.IdleSwimRight and sprite.global_position.x >= GLOBAL_BOUNDARY_RIGHT:
		ai_current_state = AiState.IdleSwimLeft
		print_ai("<%s> Reached right bondary, turn to %s" % [name, str(AiState.keys()[ai_current_state])])
	
	# 3. actualy move the fish in idle-mode, with respect to delta-time
	match ai_current_state:
		AiState.IdleWooble:
			wooble(25.0, delta)
		AiState.IdleSwimLeft:
			look_left()	# i know its silly. but on some rnd circumstances, some spooky effects happend?!
			sprite.position.x -= swim_speed * delta
		AiState.IdleSwimRight:
			look_right()
			sprite.position.x += swim_speed * delta

	# if ai_current_state == AiState.IdleWooble:
	# 	wooble(10.0, delta)
	# elif ai_current_state == AiState.IdleSwimRight:
	# 	sprite.position.x += swim_speed * delta
	# elif ai_current_state == AiState.IdleSwimLeft:
	# 	sprite.position.x -= swim_speed * delta

## stop idle-mode: What's next? 33% Wooble, 33% Idle again, 33% Swim-to
## Submarine is different: it won't catch a virtual target on its own 
func _on_stop_idle_mode_timeout() -> void:
	var dice: float = randf()	# roll a dice
	if dice < 0.5 or fish_type == FishType.Submarine:
		print_ai("<%s> ⏰ STOPPED idle-mode, now 🎲 IDLE again" % [name])
		ai_current_state = AiState.IdleUndecided
		look_left()
	else:
		var t = get_random_point_in_aquarium()
		var d = randf_range(2.0, 4.5)
		print_ai("<%s> ⏰ STOPPED idle, now 🎲 SWIM-TO 🎲 %s in 🎲 %.1f sec" % [name, t, d])
		swim_to(t, d)
	reset_idle_timer()


func _ready() -> void:
	# init animated sprite and idle-timer
	setup_sprite()
	reset_idle_timer()

	# init ai/fsm
	if randf() < 0.5:
		ai_current_state = AiState.IdleSwimLeft
		look_left()
	else:
		ai_current_state = AiState.IdleSwimRight
		look_right()
	print_ai("<%s> is born, now %s" % [name, str(AiState.keys()[ai_current_state])])


	# Store the initial position as the center
	wooble_global_center = global_position
	# Initialize angles to a random value to avoid synchronized starts
	wooble_current_angle_x = randf_range(0.0, TAU)
	wooble_current_angle_y = randf_range(0.0, TAU)



func _process(delta: float) -> void:
	idle_mode(delta)
