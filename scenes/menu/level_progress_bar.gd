extends TextureProgressBar


func _enter_tree() -> void:
	get_child(0).position = Vector2(value / 100 * 1024, 32)
