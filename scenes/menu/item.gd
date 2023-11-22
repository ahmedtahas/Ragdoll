extends TextureButton

@onready var texture_path: String


func add_item(path: String) -> void:
	print("item")
	var new_item = duplicate()
	new_item.texture_normal = load(path)
	new_item.texture_path = path
	get_parent().add_item(new_item)


func _pressed() -> void:
	print("pressed" + texture_path)
