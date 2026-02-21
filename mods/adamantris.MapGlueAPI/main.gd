extends Node


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
	yield(get_tree().create_timer(1), "timeout")
	for map in lure_node.modded_maps:
		var packed_scene = map.get("scene")
		var instanced_map = packed_scene.instance()
		var zone_node = instanced_map.get_node("zones/main_zone")
		var env_node = instanced_map.get_node("WorldEnvironment")
		
		zone_node.get_parent().remove_child(zone_node)
		zone_node.name = map.get("name") + "_zone"
		mod_zones[zone_node.name] = zone_node
		
		instanced_map.remove_child(env_node)
		mod_envs[map.get("name") + "_" + env_node.name] = env_node
		
		instanced_map.queue_free()

func on_node_add(node):
	if node.name == "zones" and str(node.get_path()).begins_with("/root/world"):
		vanilla_zone_node = node
		var origin_offset_mult = 0
		for zone_entry in mod_zones.keys():
			print("adding zone " + zone_entry)
			var new_origin = Vector3(200 * origin_offset_mult, 200, 0)
			var mod_zone = mod_zones.get(zone_entry)
			mod_zone.global_transform.origin = new_origin
			vanilla_zone_node.add_child(mod_zone)
			origin_offset_mult += 1
