extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Button.connect("pressed", self, "on_button_press") # Replace with function body.



func on_button_press():
	print("ive been pressed")
	get_node("/root/adamantrisMapGlueAPI").tele_button_pressed($Label.text)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
