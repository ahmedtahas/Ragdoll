extends Node2D

var config_path = "res://config.cfg"
var config = ConfigFile.new()
var load_response = config.load(config_path)


func _ready() -> void:
	pass

func update_config(section, key, value) -> void:
	config.set_value(section, key, value)
	config.save(config_path)

func get_value(section, key):
	return config.get_value(section, key)
