extends ScrollContainer

@onready var character_text: RichTextLabel = $"../CharacterSelection/RichTextLabel"
@onready var display: Node2D = $"../SubViewportContainer/SubViewport/Camera2D/Display"

func _ready() -> void:
	vertical_scroll_mode = 3
	for button in get_node("ButtonContainer").get_children():
		button.pressed.connect(close_character_menu.bind(button.name))
	close_character_menu("crock")


func close_character_menu(character: String) -> void:
	hide()
	if display.get_child_count() > 0:
		display.get_child(0).queue_free()
	character_text.text = "[center]" + character.to_upper()[0] + character.right(character.length() - 1) + "[center]"
	var character_template = load("res://scenes/game/character/" + character + ".tscn").instantiate()
	display.add_child(character_template)
	character_template.get_node("Character/Body").freeze = true


