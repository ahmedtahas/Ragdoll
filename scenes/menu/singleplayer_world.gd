extends Node2D


@onready var room: Vector2 = Vector2(20420, -10180)

@onready var player: Node2D

@onready var bot: Node2D = preload("res://scenes/game/character/bot.tscn").instantiate()

@onready var character_dictionary: Dictionary = {
	"crock": preload("res://scenes/game/character/single_crock.tscn"),
	"zeina": preload("res://scenes/game/character/single_zeina.tscn"),
	"tin": preload("res://scenes/game/character/single_tin.tscn"),
	"holstar": preload("res://scenes/game/character/single_holstar.tscn"),
	"roki_roki": preload("res://scenes/game/character/single_roki_roki.tscn"),
	"paranoc": preload("res://scenes/game/character/single_paranoc.tscn"),
	"kaliber": preload("res://scenes/game/character/single_kaliber.tscn")
}


func _ready() -> void:
	Global.world = self
	Global.spawner = $Spawner
	Global.camera = $MTC
	player = character_dictionary.get(CharacterSelection.own).instantiate()
	Global.player = player
	Global.bot = bot
	Global.spawner.add_child(player)
	player.transform = $Point1.transform
	Global.spawner.add_child(bot)
	bot.transform = $Point2.transform
	Global.camera.add_target(player.get_node("LocalCharacter/Body"))
	Global.camera.add_target(bot.get_node("LocalCharacter/Body"))
	
	
func slow_motion(time_scale: float, duration: float):
	Engine.time_scale = time_scale
	await get_tree().create_timer(time_scale * duration).timeout
	Engine.time_scale = 1
	
	
func get_inside_position(pos: Vector2) -> Vector2:
	if pos.x > room.x:
		pos.x = room.x - player.radius.x
	elif pos.x < player.radius.x:
		pos.x = player.radius.x
	if pos.y < room.y:
		pos.y = room.y + player.radius.x
	elif pos.y > -player.radius.x:
		pos.y -= player.radius.x
	return pos
