extends Node2D

var fish_scene = preload("res://fish.tscn")

## collection of all fish_layerX in our aquarium 
var fish_layer:Array[Node2D]


## removes EVERY node(fish) from EVERY fish-layer
func clear_aquarium():
	for fl in fish_layer:
		for f in fl.get_children():
			f.queue_free()	# delete and remove this node/fish from node-tree

## Returns a rnd FishType
func get_random_fish_type() -> Fish.FishType:
	var rnd_ft_idx = randi_range(0, Fish.FishType.keys().size() - 1)
	var ft = rnd_ft_idx as Fish.FishType
	return ft

## Returns rnd FishLayer Index
func get_random_fish_layer_idx() -> int:
	return randi_range(0, fish_layer.size() - 1)


## Return a rnd fish from a rnd layer. Null, if aquarium  is empty
func get_random_fish() -> Fish:
	var all_fish = []
	for fl in fish_layer:
		for f in fl.get_children():
			all_fish.append(f)		# collect all fishes
	if all_fish.size() < 1:			# Upps, not a single fish
		return null
	var rnd_idx = randi_range(0, all_fish.size() - 1)
	var rnd_fish = all_fish[rnd_idx] as Fish
	print("Picked random fish <%s>" % rnd_fish.name)
	return rnd_fish


## Returns a rnd point on the screen / viewport
func get_random_point_in_aquarium() -> Vector2:
	var MARGIN:int = 200
	var viewport_size: Vector2 = get_viewport_rect().size
	var random_x: float = randf_range(0 + MARGIN, viewport_size.x - MARGIN)
	var random_y: float = randf_range(0 + MARGIN, viewport_size.y - MARGIN)
	return Vector2(random_x, random_y)


## Creates a new fish of TYPE (sprite) at position POS. Adds the new fish to the fish_layer[layer]
func create_fish(pos:Vector2, type:Fish.FishType, layer:int = 0) -> Fish:
	var new_fish:Fish = fish_scene.instantiate()
	new_fish.fish_type = type
	new_fish.position = pos
	
	var safe_layer = 0 	# add safly the new fish to layer
	if not(layer < 0 or layer > fish_layer.size()-1):
		safe_layer = layer
	fish_layer[safe_layer].add_child(new_fish)
	
	print("NEW fish <%s> added at %s , type=%s, layer=%s" % [new_fish.name, pos, type, safe_layer])
	return new_fish

## happy easter
func start_easter_egg() -> void:
	print("Start Easter-Egg")
	var duration: float = 5.0
	var pf2d:PathFollow2D = $Aquarium/train/train_path/train_pathfollow
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
	# KEYBOARD
	if event is InputEventKey:
		if event.pressed and not event.echo:
			var kc = event.keycode
			if kc == Key.KEY_A:
				var rnd_layer = get_random_fish_layer_idx()
				var rnd_type = get_random_fish_type()
				var mouse_pos = get_global_mouse_position()
				var new_fish = create_fish(mouse_pos, rnd_type, rnd_layer)
				new_fish.connect("reached_target", _on_fish_reached_target)
			elif kc == Key.KEY_E:
				start_easter_egg()
			elif event.keycode == Key.KEY_C:
				clear_aquarium()
				print("Cleaned house")
			elif event.keycode == Key.KEY_ESCAPE or event.keycode == Key.KEY_Q :
				get_tree().quit()
	# MOUSE
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# pick a rnd fish and let him swim to the mouse-pos in 2sec
			var test_fish:Fish = get_random_fish()
			test_fish.swim_linear_to(event.global_position, 2.0)

func _on_timer_timeout() -> void:
	start_easter_egg()


## ai: the fish reached his target... now what to do?
func _on_fish_reached_target(fish: Fish) -> void:	
	var new_target:Vector2 = get_random_point_in_aquarium()
	#print("<%s> reached goal, swim_to %s" % [fish.name, new_target])
	fish.look_to(new_target)
	fish.swim_linear_to(new_target, 2.0)
