extends HBoxContainer


func _ready():
	$Button.connect("pressed", self, "on_button_press") 



func on_button_press():
	print("ive been pressed")
	get_node("/root/adamantrisMapGlueAPI").tele_button_pressed($Label.text)
	var popup = get_node("../../..") #cringe path
	popup.visible = false
