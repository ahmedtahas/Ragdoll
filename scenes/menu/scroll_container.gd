extends ScrollContainer

@onready var character_text: Label = $"../CharacterSelection/Text"
@onready var character_button: Button = $"../CharacterSelection"
@onready var display: Node2D = $"../SubViewportContainer/SubViewport/Camera2D/Display"

func _ready() -> void:
	vertical_scroll_mode = SCROLL_MODE_SHOW_NEVER
	character_text.hide()
	for button in get_child(0).get_children():
		if button is Button:
			button.pressed.connect(close_character_menu.bind(button.name))
	close_character_menu("crock")


func close_character_menu(character: String) -> void:
	get_parent().character = character
	hide()
	character_button.show()
	character_text.show()
	if display.get_child_count() > 0:
		display.get_child(0).queue_free()
	character_text.text = character.to_upper()[0] + character.right(character.length() - 1)
	var character_template = load("res://scenes/game/character/" + character + ".tscn").instantiate()
	display.add_child(character_template)
	character_template.get_node("Character/Body").freeze = true


