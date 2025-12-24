@tool
class_name Fish extends Node2D

## fish has reached (moved) its target point 
signal reached_target(fish: Fish)

## Possible Fish-Types. Defines sprite-asset and AI behaviour
enum FishType {
	Blinky, 
	Schoolfish, 
	Jellyfish, 
	Submarine,
	Coralfish
}

## AI-State: what can the fish do?
enum AiState {
	IdleUndecided, IdleSwimLeft, IdleSwimRight, IdleWooble, 
	SwimTo, 
	ChangeLayer
}
## What is the fish currently doing? 
var ai_current_state: AiState = AiState.IdleUndecided


const DURATION_TURN:float = 0.1		# in seconds for a turning from left-to-right and vice-versa
const GLOBAL_BOUNDARY_LEFT = 200 
const GLOBAL_BOUNDARY_RIGHT = 1720
const AQUARIUM_MARGIN:int = 200

const IDLE_TIME_MIN: float = 3.0
const IDLE_TIME_MAX: float = 10.0
@onready var idle_timer:Timer = $stop_idle_mode

# the active/shown sprite and area2d, and the original-scale of the sprite
var sprite:AnimatedSprite2D
var area:Area2D
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
var wobble_current_angle_x: float = 0.0
var wobble_current_angle_y: float = 0.0
var wobble_global_center: Vector2 = Vector2.ZERO


## Show AI thougts on console?
@export var debug_ai: bool = false
func print_ai (s: String) -> void:
	if debug_ai:
		print("🐟 " + s)


## AI-Dice ratio between idle-mode and do-some-action (ie. SwimTo). 0.25 = 25% chance for idle
@export var ai_ratio_idle_vs_action: float = 0.5

## AI-Dice ratio between wobble and swim left/right in idle-mode. 025 = 25% chance for wooble
@export var ai_ratio_wobble_vs_swimlr: float = 0.5


## Returns the Name/Ident of an AiState - i.e. "IdleSwimLeft"
func get_aistate_identifier(enum_item) -> String:
	return str(AiState.keys()[enum_item])


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


## Setup animated-sprites: which fish to display? disable all other fish-types (sprites). 
## Register input-event callback 
func setup_sprite() -> void:
	# 1. Hide all active-areas/sprites
	for i in get_children():
		if i is Area2D:
			i.visible = false
	# 2. Select the correct sprite
	match fish_type:
		FishType.Blinky:
			sprite = $blinky/sprite_blinky
		FishType.Schoolfish:
			sprite = $schoolfish/sprite_schoolfish
		FishType.Submarine:
			sprite = $submarine/sprite_submarine
		FishType.Jellyfish:
			sprite = $jellyfish/sprite_jellyfish
		FishType.Coralfish:
			sprite = $coralfish/sprite_coralfish
	# 3. Apply properties and show
	if is_instance_valid(sprite):
		var active_area: Area2D = sprite.get_parent() as Area2D
		# Connect the click event from the currently active Area2D child
		if is_instance_valid(active_area):
			active_area.input_event.connect(_on_area_2d_input_event)
			active_area.visible = true
			area = active_area
			print("Setup Sprite ")
		sprite_orig_scale = sprite.scale
		sprite.speed_scale = anim_speed_scale
		if not Engine.is_editor_hint():		# dont swim in the editor
			sprite.play()


## after anmiation, fish looks to the left
func look_left() -> void:
	var new_scale_x = -1.0 #-abs(sprite_orig_scale.x)	 # Ensure facing Left (negative scale)
	var tween = create_tween()
	tween.tween_property(area, "scale:x", new_scale_x, DURATION_TURN)


## after anmiation, fish looks to the right
func look_right() -> void:
	var new_scale_x = +1.0 # abs(sprite_orig_scale.x) # Ensure facing Left (negative scale)
	var tween = create_tween()
	tween.tween_property(area, "scale:x", new_scale_x, DURATION_TURN)


## fish turns left or right, depends on the global_position of target
func look_to(global_target:Vector2) -> void:
	if global_target.x < area.global_position.x:
		look_left()
	else:
		look_right()


## wooble (sinus on x- and y-axes) around a wobble_global_center-point using delta time
func wooble(radius: float, delta: float) -> void:
	# 1. Calculate the change in angle based on delta and frequency (Hz). Frequency * TAU gives the angular speed in radians/second
	var angular_speed_x = wooble_x_freq * TAU
	var angular_speed_y = wooble_y_freq * TAU

	# 2. Increment the current angle (phase)
	wobble_current_angle_x += angular_speed_x * delta
	wobble_current_angle_y += angular_speed_y * delta

	# 3. Keep the angle wrapped between 0 and TAU (optional, but good practice)
	wobble_current_angle_x = fmod(wobble_current_angle_x, TAU)
	wobble_current_angle_y = fmod(wobble_current_angle_y, TAU)

	# 4. Calculate the offsets using the current angle as input to sin()
	var x_offset = radius * sin(wobble_current_angle_x)
	var y_offset = radius * sin(wobble_current_angle_y)

	# 5. Apply the offsets to the global center position
	global_position = wobble_global_center + Vector2(x_offset, y_offset)


## swim / tween linear to the target coordinate (global_position) in seconds
func swim_to(global_target: Vector2, duration: float):
	var ai_last_state = ai_current_state
	ai_current_state = AiState.SwimTo
	idle_timer.paused = true
	#print("<%s> swin linear_to %s in %.1f sec" % [name, global_target, duration])
	
	look_to(global_target)
	var tween = create_tween()
	tween.tween_property(self, "global_position", global_target, duration).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


	# reset previous idle-state (if left or right, dice otherwise)
	if ai_last_state == AiState.IdleSwimLeft or ai_last_state == AiState.IdleSwimRight:
		ai_current_state = ai_last_state
	else:
		ai_current_state = AiState.IdleUndecided
	
	idle_timer.paused = false
	print_ai("<%s> Reached target. Switch back to %s" % [name, get_aistate_identifier(ai_current_state)])
	
	# now shout out to the world: "I'm here, i reached my target!"
	emit_signal("reached_target", self)	


## Dice and Return what to do next: Wooble, Left, Right. use ai_ratio_wobble_vs_swimlr
func get_random_idle_state() -> AiState:
	var dice: float = randf()
	if dice < ai_ratio_wobble_vs_swimlr:
		print_ai("<%s> Idle by 🎲 WOOBLE around %s" % [name,wobble_global_center])
		return AiState.IdleWooble
	else:
		var dice_lr: float = randf()
		if dice_lr < 0.5:
			print_ai("<%s> Idle by 🎲 SWIM-LEFT" % [name])
			return AiState.IdleSwimLeft
		else:
			print_ai("<%s> Idle by 🎲 SWIM-RIGHT" % [name])
			return AiState.IdleSwimRight


## Is called per frame, with respect to delta-time. only executes, if not in idle-mode or in the godot-editor
## Swim from left to right an back; or stand still and Wooble around. turns around at the boundaries left and right. 
func process_idle(delta:float) -> void:
	if Engine.is_editor_hint():			# dont swim in the editor-window ;)
		return
	
	# 1. FSM - decide what to do in idle-mode, if undecided
	if ai_current_state == AiState.IdleUndecided:
		ai_current_state = get_random_idle_state()

	# 2. FSM - check, if fish needs to turn around, cause of hitting the aquarium boundaries
	if ai_current_state == AiState.IdleSwimLeft and sprite.global_position.x <= GLOBAL_BOUNDARY_LEFT:
		ai_current_state = AiState.IdleSwimRight
		print_ai("<%s> Reached left bondary, turn to %s" % [name, get_aistate_identifier(ai_current_state)])
	if ai_current_state == AiState.IdleSwimRight and sprite.global_position.x >= GLOBAL_BOUNDARY_RIGHT:
		ai_current_state = AiState.IdleSwimLeft
		print_ai("<%s> Reached right bondary, turn to %s" % [name, get_aistate_identifier(ai_current_state)])
	
	# 3. actualy move the fish in idle-mode, with respect to delta-time
	match ai_current_state:
		AiState.IdleWooble:
			wooble(wobble_radius, delta)
		AiState.IdleSwimLeft:
			look_left()	# i know its silly. but on some rnd circumstances, some spooky effects happend?!
			position.x -= swim_speed * delta
		AiState.IdleSwimRight:
			look_right()
			position.x += swim_speed * delta

## stop idle-mode: What's next? use ai_ratio_idle_vs_action
## Note: submarine is different, it won't catch a virtual target on its own 
func _on_stop_idle_mode_timeout() -> void:
	var dice: float = randf()
	if dice < ai_ratio_idle_vs_action:
		print_ai("<%s> ⏰ STOPPED idle-mode, now do 🎲 IDLE again" % [name])
		ai_current_state = AiState.IdleUndecided
		look_left()
	else:
		var t = get_random_point_in_aquarium()
		var d = randf_range(2.0, 4.5)
		print_ai("<%s> ⏰ STOPPED idle, now do 🎲 SWIM-TO 🎲 %s in 🎲 %.1f sec" % [name, t, d])
		swim_to(t, d)
	reset_idle_timer()


func _ready() -> void:
	# init animated sprite and idle-timer
	setup_sprite()
	reset_idle_timer()

	# init ai/fsm to IDLE-SWIM
	if randf() < 0.5:
		ai_current_state = AiState.IdleSwimLeft
		look_left()
	else:
		ai_current_state = AiState.IdleSwimRight
		look_right()
	print_ai("<%s> is born, now do 🎲 %s" % [name, get_aistate_identifier(ai_current_state)])


	# Store the initial params for woobling around a center with 2 sin
	wobble_global_center = global_position
	wobble_current_angle_x = randf_range(0.0, TAU)
	wobble_current_angle_y = randf_range(0.0, TAU)



func _process(delta: float) -> void:
	process_idle(delta)


## Handles all input events that occur within the fish's Area2D collision shape
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Check specifically for a left mouse button click release
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			on_fish_clicked(event.global_position)

## Action to take when the fish is successfully clicked
func on_fish_clicked(click_position: Vector2) -> void:
	# Ignore clicks if the fish is already swimming to a destination
	var new_val:bool = !debug_ai 
	print("Clicked on <%s> set debug_ai to %s" % [name, new_val])
	debug_ai = new_val
	
