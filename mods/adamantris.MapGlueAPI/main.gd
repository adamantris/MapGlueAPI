extends Node

onready var zone_select = preload("res://mods/adamantris.MapGlueAPI/zone_select.tscn")
onready var zone_ui = preload("res://mods/adamantris.MapGlueAPI/zone_UI.tscn")
onready var zone_container = preload("res://mods/adamantris.MapGlueAPI/zone_container.tscn")

var lure_node
var vanilla_zone_node

export var packed_maps := {}

export var map_scene_files := {}

export var mod_zones := {}

export var mod_envs := {}

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
		var packed_scene = map.get("scene")
		var instanced_map = packed_scene.instance()
		var zone_node = instanced_map.get_node("zones/main_zone")
		var env_node = instanced_map.get_node("WorldEnvironment")
		var spawn_pos = instanced_map.get_node("spawn_position")
		
		zone_node.get_parent().remove_child(zone_node)
		zone_node.name = map.get("name") + "_zone"
		
		var new_tele_entry = zone_container.instance()
		new_tele_entry.get_node("Label").text = zone_node.name
		instanced_zone_ui.get_node("CanvasLayer/PopupPanel/ScrollContainer/VBoxContainer").add_child(new_tele_entry)
		
		var tele_marker = Position3D.new()
		tele_marker.name = "tele_marker"
		zone_node.add_child(tele_marker)
		tele_marker.transform = spawn_pos.transform
		
		mod_zones[zone_node.name] = zone_node
		
		instanced_map.remove_child(env_node)
		mod_envs[map.get("name") + "_" + env_node.name] = env_node
		
		instanced_map.queue_free()

func on_node_add(node):
	if node.name == "zones" and str(node.get_path()).begins_with("/root/world"):
		vanilla_zone_node = node
		
		var select_instance = zone_select.instance()
		vanilla_zone_node.get_node("main_zone").add_child(select_instance)
		var select_area = select_instance.get_node("Area")
		select_area.connect("body_entered", self, "on_body_enter")
		
		var origin_offset_mult = 0
		for zone_entry in mod_zones.keys():
			print("adding zone " + zone_entry)
			var new_origin = Vector3(200 * origin_offset_mult, 200, 0)
			var mod_zone = mod_zones.get(zone_entry)

			mod_zone.global_transform.origin = new_origin
			vanilla_zone_node.add_child(mod_zone)
			origin_offset_mult += 1

func on_body_enter(body):
	if body.name == "player" and body.owner_id == Network.STEAM_ID:
		get_node("zone_UI/CanvasLayer/PopupPanel").popup()
		
func tele_button_pressed(destination: String):
	var player = get_node("/root/world/Viewport/main/entities/player")
	player.world._enter_zone(destination, -1)
	var zone_spawn_point = vanilla_zone_node.get_node(destination + "/tele_marker")
	player.global_transform.origin = zone_spawn_point.global_transform.origin
	
