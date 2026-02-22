extends Node


#Blacklisting zones that are most likely copied from vanilla
const vanilla_zones_blacklist := ["tent_zone", "hub_building_zone", "aquarium_zone", "tutorial_zone", "island_tiny_zone", "island_med_zone", "island_big_zone", "void_zone"]
const entry_exit_hack := ["*entrance*"]

onready var zone_select = preload("res://mods/adamantris.MapGlueAPI/zone_select.tscn")
onready var zone_ui = preload("res://mods/adamantris.MapGlueAPI/zone_UI.tscn")
onready var zone_container = preload("res://mods/adamantris.MapGlueAPI/zone_container.tscn")

var lure_node
var vanilla_zone_node

var packed_maps := {}

var map_scene_files := {}

var mod_zones := {}

var zone_scales := {} #Because Godot forgets the original scale of the zone node

var mod_envs := {}

var zone_prefixes := []
func _ready():
	get_tree().connect("node_added", self, "on_node_add")
	yield(get_tree().create_timer(1), "timeout") #Letting everything else load in first
	lure_node = get_node_or_null("/root/SulayreLure")
	if is_instance_valid(lure_node):
		handle_lure_maps()
	
	elif is_instance_valid(lure_node) == false:
		print("[MapGlue] oh no apparently lure is NOT valid")
		
	else:
		print("[MapGlue] something went COMPLETELY wrong")
	


func handle_lure_maps():
	print("[MapGlue] yup lure loaded lets wait for a sec")
	var instanced_zone_ui = zone_ui.instance()
	self.add_child(instanced_zone_ui)
	yield(get_tree().create_timer(1), "timeout")

	for map in lure_node.modded_maps:
		var map_name = map.get("name")
		var packed_scene = map.get("scene")
		var instanced_map = packed_scene.instance()
		var zone_parent = instanced_map.get_node("zones")
		for zone_child in zone_parent.get_children():
			var zone_name = map_name + "_"
			
			if zone_child.name in vanilla_zones_blacklist:
				#print("blacklisted, continue")
				continue
				
			
			zone_child.name = zone_name + zone_child.name
			print("non-blacklist found, changed to " + zone_child.name)
				
			#var zone_node = instanced_map.get_node("zones/main_zone")
			#var zone_name = map.get("name") + "_zone"
			var env_node = instanced_map.get_node("WorldEnvironment")
			var spawn_pos = instanced_map.get_node("spawn_position")
			
			
			
			zone_scales[zone_child.name] = zone_child.scale
			zone_child.get_parent().remove_child(zone_child)
#			zone_node.name = map.get("name") + "_zone"
			
			var new_tele_entry = zone_container.instance()
			new_tele_entry.get_node("Label").text = zone_child.name
			instanced_zone_ui.get_node("CanvasLayer/PopupPanel/ScrollContainer/VBoxContainer").add_child(new_tele_entry)

			if zone_child.name.match("*main_zone"):
				var tele_marker = Position3D.new()
				tele_marker.name = "tele_marker"
				zone_child.add_child(tele_marker)
				tele_marker.translation = spawn_pos.translation
#
			mod_zones[zone_child.name] = zone_child
			
			if not zone_name in zone_prefixes:
				zone_prefixes.append(zone_name)
#			instanced_map.remove_child(env_node)
#			mod_envs[map.get("name") + "_" + env_node.name] = env_node
			
		instanced_map.queue_free()

func on_node_add(node):
	if node.name == "zones" and str(node.get_path()).begins_with("/root/world"):
		vanilla_zone_node = node
		
		var select_instance = zone_select.instance()
		vanilla_zone_node.get_node("main_zone").add_child(select_instance)
		var select_area = select_instance.get_node("Area")
		select_area.connect("body_entered", self, "on_body_enter")
		
		var origin_offset_mult = 1
		for zone_entry in mod_zones.keys():
			print("adding zone " + zone_entry)
			var new_origin = Vector3(0, 200 * origin_offset_mult, 0)
			var mod_zone = mod_zones.get(zone_entry)

			mod_zone.global_transform.origin = new_origin
			vanilla_zone_node.add_child(mod_zone)
			mod_zone.scale = zone_scales.get(zone_entry)
			origin_offset_mult += 1
			
	# i am not proud of what follows
	if "zone_id" in node and "spawn_id" in node:
		var node_path = str(node.get_path())
	
		var split_string_array = node_path.split("/", false)
		var added_zone_name = split_string_array[7] # our zones are always at spot 7 (0-indexed)
		if added_zone_name in vanilla_zones_blacklist or added_zone_name == "main_zone":
			#print("vanilla zone, returning")
			return
		
		for zone_prefix in zone_prefixes:
			if added_zone_name.match(zone_prefix + "*"):
				node.zone_id = zone_prefix + node.zone_id
				break
				
func on_body_enter(body):
	if body.name == "player" and body.owner_id == Network.STEAM_ID:
		get_node("zone_UI/CanvasLayer/PopupPanel").popup()
		
func tele_button_pressed(destination: String):
	var player = get_node("/root/world/Viewport/main/entities/player")
	player.world._enter_zone(destination, -1)
	var zone_spawn_point = vanilla_zone_node.get_node(destination + "/tele_marker")
	player.global_transform.origin = zone_spawn_point.global_transform.origin
	
