extends Node


# blacklisting zones that are most likely copied from vanilla
const vanilla_zones_blacklist := ["tent_zone", "hub_building_zone", "aquarium_zone", "tutorial_zone", "island_tiny_zone", "island_med_zone", "island_big_zone", "void_zone"]
const zones_pos = Vector3(0, 1000, 0) # off to nirvana
const zone_pos = 7

onready var zone_select = preload("res://mods/adamantris.MapGlueAPI/zone_select.tscn")
onready var zone_ui = preload("res://mods/adamantris.MapGlueAPI/zone_UI.tscn")
onready var zone_container = preload("res://mods/adamantris.MapGlueAPI/zone_container.tscn")

var lure_node
var vanilla_zone_node
var player

var packed_maps := {}

var map_scene_files := {}

var mod_zones := {}
var zone_scales := {} # because Godot forgets the original scale of the zone node upon reattach
var mod_envs := {}
var zone_prefixes := []


func _ready():
	get_tree().connect("node_added", self, "on_node_add")
	
	# letting every other mod load in first
	yield(get_tree().create_timer(1), "timeout")
	
	lure_node = get_node_or_null("/root/SulayreLure")
	if is_instance_valid(lure_node):
		handle_lure_maps()
	
	elif is_instance_valid(lure_node) == false:
		print("[MapGlue] No valid Lure instance found.")


func handle_lure_maps():
	var instanced_zone_ui = zone_ui.instance()
	self.add_child(instanced_zone_ui)
	print("[MapGlue] Lure found, waiting for one second to let everything else load in first")
	yield(get_tree().create_timer(1), "timeout")

	for map in lure_node.modded_maps:
		var map_name = map.get("name")
		var van_packed_scene = map.get("scene")
		var instanced_map = van_packed_scene.instance()
		var zone_parent = instanced_map.get_node("zones")
		
		for zone_child in zone_parent.get_children():
			var zone_name = map_name + "_"
			if zone_child.name in vanilla_zones_blacklist:
				continue
				
			zone_child.name = zone_name + zone_child.name
			var env_node = instanced_map.get_node("WorldEnvironment")
			var spawn_pos = instanced_map.get_node("spawn_position")
			
			zone_scales[zone_child.name] = zone_child.scale
			zone_child.get_parent().remove_child(zone_child)
			
			var new_tele_entry = zone_container.instance()
			new_tele_entry.get_node("Label").text = zone_child.name
			instanced_zone_ui.get_node("CanvasLayer/PopupPanel/ScrollContainer/VBoxContainer").add_child(new_tele_entry)

			if zone_child.name.match("*main_zone"):
				var tele_marker = Position3D.new()
				tele_marker.name = "tele_marker"
				zone_child.add_child(tele_marker)
				tele_marker.translation = spawn_pos.translation
				
				# if we dont set the owner, the tele marker wont persist to the new packed scene
				tele_marker.owner = zone_child

			# we are creating a modified packed scene to instance every time the vanilla world gets added to the tree
			# that way the previous problem of nodes being able to be attached to the vanilla map only once disappears!
			var scene_repack = PackedScene.new()
			scene_repack.pack(zone_child)
			mod_zones[zone_child.name] = scene_repack
			
			if not zone_name in zone_prefixes:
				zone_prefixes.append(zone_name)
			
		instanced_map.queue_free()

# this is all cringe
func on_node_add(node):
	
	# we need a reference to the player for zone changing
	if "actor_type" in node and node.actor_type == "player" and node.owner_id == Network.STEAM_ID:
		player = get_node("/root/world/Viewport/main/entities/player")
	
	# for connecting signals
	if node.name == "spawn" and node.get_class() == "Button" and "playerhud" in str(node.get_path()):
		node.connect("pressed", self, "on_respawn_pressed")
		
	# for adding the teleporter to the main zone
	if node.name == "zones" and str(node.get_path()).begins_with("/root/world"):
		print("[MapGlue] new world found, attaching mod zones...")
		vanilla_zone_node = node
		
		var select_instance = zone_select.instance()
		vanilla_zone_node.get_node("main_zone").add_child(select_instance)
		var select_area = select_instance.get_node("Area")
		select_area.connect("body_entered", self, "on_body_enter")
		
			
	# i am not proud of what follows
	elif "zone_id" in node and "spawn_id" in node:
		var node_path = node.get_path()
		
		if node_path.get_name_count() < zone_pos + 1: #because name count isnt 0-indexed which makes sense
			return
		
		var added_zone_name = node_path.get_name(zone_pos)

		
		# some mod map portals seem to connect to a vanilla zone, for which why the third "or" instance is getting checked
		if added_zone_name in vanilla_zones_blacklist or added_zone_name == "main_zone" or node.zone_id in vanilla_zones_blacklist:
			return
		
		for zone_prefix in zone_prefixes:
			if added_zone_name.match(zone_prefix + "*"):
				node.zone_id = zone_prefix + node.zone_id
				break


func on_body_enter(body):
	if body.name == "player" and body.owner_id == Network.STEAM_ID:
		get_node("zone_UI/CanvasLayer/PopupPanel").popup()
		
func tele_button_pressed(destination: String):
	print("[MapGlue] A teleport button has been pressed, instancing map...")
	
	var to_match
	for prefix in zone_prefixes:
		if destination.match(prefix + "*"):
			to_match = prefix
			break
			
	for zone_candidate in mod_zones.keys():
		if zone_candidate.match(to_match + "*"):
			var mod_zone_instance = mod_zones.get(zone_candidate).instance()
			vanilla_zone_node.add_child(mod_zone_instance)
			mod_zone_instance.global_transform.origin += zones_pos
	
	
	player.world._enter_zone(destination, -1)
	var zone_spawn_point = vanilla_zone_node.get_node(destination + "/tele_marker")
	player.global_transform.origin = zone_spawn_point.global_transform.origin
	
func on_respawn_pressed():
	print("[MapGlue] Respawn button pressed, removing mod zones...")
	var free_queue = []
	for child in vanilla_zone_node.get_children():
		if child.name in vanilla_zones_blacklist or child.name == "main_zone":
			continue
			
		elif child.name in mod_zones:
			free_queue.append(child)
			
	yield(get_tree().create_timer(0.4), "timeout") # 0.3 from screentransition + 0.1 to make sure we're back in main zone
	for queued in free_queue:
		queued.queue_free()

