extends CanvasLayer


func _ready() -> void:
	if not is_multiplayer_authority():
		visible = false