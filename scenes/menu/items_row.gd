extends HBoxContainer


@onready var new_row: HBoxContainer


func add_item(item: TextureButton) -> void:
	if get_child_count() == 6:
		if not new_row or new_row.get_child_count() == 6:
			new_row = duplicate()
			for child in new_row.get_children():
				child.queue_free()
			new_row.add_child(item)
			get_parent().add_row(new_row)
		else:
			new_row.add_child(item)
		return
	add_child(item)
