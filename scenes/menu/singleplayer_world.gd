extends Node2D

@onready var player: Node2D

@onready var bot: Node2D = preload("res://scenes/game/character/bot.tscn").instantiate()

@onready var character_dictionary: Dictionary = {
	"crock": preload("res://scenes/game/character/single_crock.tscn"),
	"zeina": preload("res://scenes/game/character/single_zeina.tscn"),
	"tin": preload("res://scenes/game/character/single_tin.tscn"),
	"holstar": preload("res://scenes/game/character/single_holstar.tscn"),
	"roki_roki": preload("res://scenes/game/character/single_roki_roki.tscn"),
	"paranoc": preload("res://scenes/game/character/single_paranoc.tscn"),
	"kaliber": preload("res://scenes/game/character/single_kaliber.tscn"),
	"meri": preload("res://scenes/game/character/single_meri.tscn"),
	"moot": preload("res://scenes/game/character/single_moot.tscn"),
	"buccarold": preload("res://scenes/game/character/single_buccarold.tscn"),
	"raldorone": preload("res://scenes/game/character/single_raldorone.tscn")
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
	$Pause.get_child(0).hide()
	$Pause.get_child(1).hide()
	get_tree().paused = false


func slow_motion(time_scale: float, duration: float):
	Engine.time_scale = time_scale
	await get_tree().create_timer(time_scale * duration).timeout
	Engine.time_scale = 1


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			pause()


func pause() -> void:
	if get_tree().paused:
		player.skill_joy_stick.disconnect("skill_signal", player.skill_signal)
		get_tree().paused = false
		$Pause.get_child(0).hide()
		$Pause.get_child(1).hide()
		$Pause.get_child(2).show()
		player.skill_joy_stick.skill_signal.connect(player.skill_signal)
	else:
		get_tree().paused = true
		$Pause.get_child(0).show()
		$Pause.get_child(1).show()
		$Pause.get_child(2).hide()


func change_character() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/character_selection.tscn")


func main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _exit_tree() -> void:
	get_tree().paused = false
