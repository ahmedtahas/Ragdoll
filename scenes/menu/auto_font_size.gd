extends RichTextLabel


func _enter_tree() -> void:
	if len(text) > 7:
		print(get_theme_font_size("normal_font_size"))
		print(text)
#		add_theme_font_size_override("normal_font_size", 25)
