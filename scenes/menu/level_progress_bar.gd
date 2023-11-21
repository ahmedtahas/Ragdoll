extends TextureProgressBar


func _enter_tree() -> void:
	get_child(0).position = Vector2(value / (max_value - min_value) * 1024, 32)
