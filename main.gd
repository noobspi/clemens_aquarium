extends Node2D

var fish_scene = preload("res://fish.tscn")

## collection of all fish_layerX in our aquarium 
var fish_layer:Array[Node2D]



## removes EVERY node(fish) from EVERY fish-layer
func clear_aquarium():
	for fl in fish_layer:
		for f in fl.get_children():
			f.queue_free()	# delete and remove this node/fish from node-tree

## Returns a rnd fish name
func get_random_fish_name() -> String:
	var fish_names: Array[String] = [
			"Finny", "Gilly", "Bubbles", "Splash", "Jawsy", "Nemo", "Dory", "Squirt", "Reefy", "Wiggles",
			"Puffer", "Scales", "Zippy", "Chum", "Snappy", "Tide", "Coral", "Flash", "Salty", "Guppy",
			"Tuna", "Pike", "Perch", "Minnow", "Blob", "Ripples", "Aqua", "Skipper", "Anchor", "Bluey",
			"Waver", "Fizzy", "Gloop", "Noodle", "Opal", "Pebble", "Shell", "Twist", "Vortex", "Wisp",
			"Dart", "Echo", "Fable", "Gale", "Haze", "Ink", "Jolt", "Kite", "Lace", "Mossy"
		]
	var random_index = randi_range(0, fish_names.size() - 1)
	return fish_names[random_index].capitalize()

## Returns all fish in the aquarium
func get_all_fish() -> Array[Fish]:
	var all_fish:Array[Fish] = []
	for fl in fish_layer:
		for f in fl.get_children():
			all_fish.append(f as Fish)		# collect all fishes
	return all_fish

## Return a rnd fish from a rnd layer. Null, if aquarium  is empty
func get_random_fish() -> Fish:
	var all_fish = get_all_fish()
	if all_fish.size() < 1:			# Upps, not a single fish
		return null
	var rnd_idx = randi_range(0, all_fish.size() - 1)
	var rnd_fish = all_fish[rnd_idx] as Fish
	print("Picked random fish <%s>" % rnd_fish.name)
	return rnd_fish


## Returns a rnd point on the screen / viewport
func _get_random_point_in_aquarium() -> Vector2:
	var MARGIN:int = 200
	var viewport_size: Vector2 = get_viewport_rect().size
	var random_x: float = randf_range(0 + MARGIN, viewport_size.x - MARGIN)
	var random_y: float = randf_range(0 + MARGIN, viewport_size.y - MARGIN)
	return Vector2(random_x, random_y)


## Creates a new fish of TYPE (sprite) at position POS. Adds the new fish to the fish_layer[layer]
func create_fish(pos:Vector2, type:Fish.FishType, layer:int = 0) -> Fish:
	var fish_name = get_random_fish_name() + "_" + str(Fish.FishType.keys()[type]).capitalize()
	var new_fish:Fish = fish_scene.instantiate()
	new_fish.fish_type = type
	new_fish.position = pos
	new_fish.name = fish_name
	new_fish.debug_ai = true
	var safe_layer = 0 	# add safly the new fish to layer
	if not(layer < 0 or layer > fish_layer.size()-1):
		safe_layer = layer
	fish_layer[safe_layer].add_child(new_fish)
	
	print("NEW fish <%s> in fish_layer%s at position=%s" % [fish_name, safe_layer, pos])
	return new_fish


## Creates a rnd fish on a rnd layer at global_position
func create_rnd_fish(global_pos:Vector2):
	var rnd_type = randi_range(0, Fish.FishType.keys().size() - 1) as Fish.FishType
	var rnd_layer = randi_range(0, fish_layer.size() - 1)
	var new_fish = create_fish(global_pos, rnd_type, rnd_layer)
	new_fish.connect("reached_target", _on_fish_reached_target)	


## happy easter
func start_easter_egg() -> void:
	print("🐣 Start Easter-Egg")
	var duration: float = 5.0
	var pf2d:PathFollow2D = $Aquarium/train/train_path/train_pathfollow
	var train:Node2D = $Aquarium/train

	train.visible = true
	pf2d.progress_ratio = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(pf2d, "progress_ratio", 1.0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	train.visible = false

func _ready() -> void:
	# init random-seed
	randomize()

	# init fish-layer
	fish_layer.append($Aquarium/fish_layer0)
	fish_layer.append($Aquarium/fish_layer1)
	fish_layer.append($Aquarium/fish_layer2)
	fish_layer.append($Aquarium/fish_layer3)



## process user-input
func _input(event: InputEvent) -> void:
	# KEYBOARD
	if event is InputEventKey:
		if event.pressed and not event.echo:
			var kc = event.keycode
			if kc == Key.KEY_A:
				create_rnd_fish(get_global_mouse_position())
			elif kc == Key.KEY_E:
				start_easter_egg()
			elif event.keycode == Key.KEY_C:
				print("Clean house")
				clear_aquarium()				
			elif event.keycode == Key.KEY_ESCAPE or event.keycode == Key.KEY_Q :
				get_tree().quit()
	# MOUSE
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var test_fish = get_random_fish()
			test_fish.swim_to(event.global_position, 2.0)


## the fish reached his target... what's next?
func _on_fish_reached_target(fish: Fish) -> void:
	pass
	#print("<%s> reached goal, swim_to %s" % [fish.name, new_target])
