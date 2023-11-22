extends Node2D

@onready var config_path = "res://config.cfg"
@onready var config = ConfigFile.new()
@onready var load_response = config.load(config_path)


func _ready() -> void:
	pass


func update_config(section, key, value) -> void:
	config.set_value(section, key, value)
	config.save(config_path)


func get_value(section, key):
	return config.get_value(section, key)


