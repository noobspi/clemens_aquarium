extends Node2D

var fish_scene = preload("res://fish.tscn")
var fish_layer:Array[Node2D]		# array of all fish depth-of-layer: fish_layer[2] => $Aquarium/fish_layer2


## remove EVERY fish from EVERY fish-layer (in node-tree)
func clear_aquarium():
	for fl in fish_layer:
		for f in fl.get_children():
			f.queue_free()	# delete and remove this node/fish from node-tree


## Creates a new fish of TYPE (sprite) at position POS
func create_fish(pos:Vector2, type:Fish.FishType) -> Fish:
	var new_fish:Fish = fish_scene.instantiate()
	new_fish.fish_type = type
	new_fish.anim_speed_scale = 3.3
	new_fish.position = pos
	return new_fish

func start_easter_egg() -> void:
	print("Start Easter-Egg")
	var duration: float = 5.0
	var pf2d:PathFollow2D = $Aquarium/fish_layer3/train/train_path/train_pathfollow
	pf2d.progress_ratio = 0.0	
	var tween: Tween = create_tween()
	
	tween.tween_property(pf2d, "progress_ratio", 1.0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	

func _ready() -> void:
	# init fish-layer
	fish_layer.append($Aquarium/fish_layer0)
	fish_layer.append($Aquarium/fish_layer1)
	fish_layer.append($Aquarium/fish_layer2)
	fish_layer.append($Aquarium/fish_layer3)

## process user-input
func _input(event: InputEvent) -> void:
	# KEYBOARD EVENT
	if event is InputEventKey:
		if event.pressed and not event.echo:
			var kc = event.keycode
			# CREATE a new fish in different layer
			if kc == Key.KEY_1:
				print("Key 1 pressed: Create a new fish.")
				var f = create_fish(get_global_mouse_position(), Fish.FishType.BLINKY)		# TODO
				fish_layer[0].add_child(f)
			elif kc == Key.KEY_2:
				print("Key 2 pressed: Create a new fish.")
				var f = create_fish(get_global_mouse_position(), Fish.FishType.BLINKY)		# TODO
				fish_layer[1].add_child(f)
			elif kc == Key.KEY_3:
				print("Key 3 pressed: Create a new fish.")
				var f = create_fish(get_global_mouse_position(), Fish.FishType.SCHOOLFISH)	# TODO
				fish_layer[2].add_child(f)
			elif kc == Key.KEY_4:
				print("Key 4 pressed: Create a new fish.")
				var f = create_fish(get_global_mouse_position(), Fish.FishType.SUBMARINE)		# TODO
				fish_layer[3].add_child(f)
			elif kc == Key.KEY_E:
				start_easter_egg()
				
				
		# CLEAR aquarium: remove all fish :(
			elif event.keycode == Key.KEY_C:
				print("Key C pressed: Clean aquarium.")
				clear_aquarium()
		# QUIT
			elif event.keycode == Key.KEY_ESCAPE:
				print("ESC key pressed: Exit.")
				get_tree().quit()


func _on_timer_timeout() -> void:
	start_easter_egg()
