extends Node2D



func _on_child_entered_tree(_node: Node) -> void:
	print(get_child_count())
	if get_child_count() == 2:
		Global.two_players_joined.emit()
