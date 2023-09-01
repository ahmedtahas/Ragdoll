extends Node2D

@onready var container: HBoxContainer = $Menu/ScrollContainer/HBoxContainer
@onready var connected_peer_ids: Array = []
@onready var client_id: int
@onready var server_id: int
@onready var server_ip: Label = $Menu/ScrollContainer/HBoxContainer/Label
@onready var client_ip: String = "192.168.0.21"

@onready var bot: PackedScene = preload("res://scenes/game/character/bot.tscn")

@onready var character_dictionary: Dictionary = {
	"crock": preload("res://scenes/game/character/crock.tscn"),
	"zeina": preload("res://scenes/game/character/zeina.tscn"),
	"tin": preload("res://scenes/game/character/tin.tscn"),
	"holstar": preload("res://scenes/game/character/holstar.tscn"),
	"roki_roki": preload("res://scenes/game/character/roki_roki.tscn"),
	"paranoc": preload("res://scenes/game/character/paranoc.tscn"),
	"kaliber": preload("res://scenes/game/character/kaliber.tscn"),
	"meri": preload("res://scenes/game/character/meri.tscn"),
	"moot": preload("res://scenes/game/character/moot.tscn"),
	"buccarold": preload("res://scenes/game/character/buccarold.tscn"),
	"raldorone": preload("res://scenes/game/character/raldorone.tscn"),
}
@onready var skill_dictionary: Dictionary = {
	"dagger": preload("res://scenes/game/tools/dagger.tscn"),
	"bullet": preload("res://scenes/game/tools/bullet.tscn"),
	"clone": preload("res://scenes/game/character/clone.tscn"),
	"meteor": preload("res://scenes/game/tools/meteor.tscn")
}

@onready var multiplayer_peer = ENetMultiplayerPeer.new()
@onready var addr
@onready var new_peer

const PORT = 8910


func _ready() -> void:
	Global.world = self
	Global.spawner = $Spawner
	Global.camera = $MTC
	Global.server_skill = $ServerSkill
	Global.client_skill = $ClientSkill
	Global.opponent_died.connect(opponent_died)
	Global.player_died.connect(player_died)
	Global.bots_defeated = 0
	if Global.mode == "single":
		var player_instance = character_dictionary.get(Global.player_selection).instantiate()
		var bot_instance = bot.instantiate()
		$Spawner.add_child(bot_instance)
		bot_instance.transform = $Point2.transform
		$Spawner.add_child(player_instance)
		player_instance.transform = $Point1.transform

		$Menu.hide()
	$Pause.get_child(0).hide()
	$Pause.get_child(1).hide()
	$Exit.hide()
	$Won.hide()
	$Lost.hide()
	get_tree().paused = false
	if Global.mode == "multi":
		$Pause.get_child(2).hide()
		server_ip.text = IP.get_local_addresses()[9]
		for i in range(IP.get_local_addresses().size()):
			var label = server_ip.duplicate()
			label.text = IP.get_local_addresses()[i] + "  //  "
			container.add_child(label)
		multiplayer.peer_connected.connect(peer_connected)
		multiplayer.peer_disconnected.connect(peer_disconnected)
		multiplayer.connected_to_server.connect(connected_to_server)
		multiplayer.connection_failed.connect(connection_failed)


#called on every peer
func peer_connected(id):
	print("peer connected  ::  ", id)


#called on every peer
func peer_disconnected(id):
	print("peer disconnected  ::  ", id)


#called only on client
func connected_to_server():
	print("connected to server")


#called only on client
func connection_failed():
	print("connection failed")


@rpc("any_peer", "reliable", "call_local")
func slowdown(time_scale: float, duration: float):
	Engine.time_scale = time_scale
	await get_tree().create_timer(time_scale * duration).timeout
	Engine.time_scale = 1


@rpc("any_peer", "call_remote", "reliable", 1)
func set_opponent(selection):
	Global.opponent_selection = selection


@rpc("call_local", "any_peer", "reliable")
func get_opponent_id():
	if multiplayer_peer.get_unique_id() > 1000:
		return 1
	else:
		for id in connected_peer_ids:
			if id != 1:
				return id


func _on_host_pressed() -> void:
	$Menu.hide()
	multiplayer_peer.create_server(PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	add_player_character(1)
	server_id = multiplayer.get_unique_id()
	get_node("Spawner/1/Character/Head").freeze = true
	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			client_id = new_peer_id
			await get_tree().create_timer(3).timeout
			get_node("Spawner/1/Character/Head").freeze = false
			rpc_id(new_peer_id,"set_opponent", Global.player_selection)
			rpc("add_newly_connected_player_character", new_peer_id)
#			add_newly_connected_player_character(new_peer_id)
			rpc_id(new_peer_id, "add_previously_connected_player_characters", 1)
			add_player_character(new_peer_id)
	)


func _on_join_pressed() -> void:
	$Menu.hide()
	multiplayer_peer.create_client(client_ip, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(
		func(_peer_):
			client_id = multiplayer.get_unique_id()
			server_id = _peer_
			await get_tree().create_timer(2).timeout
			rpc_id(_peer_,"set_opponent", Global.player_selection)
	)


func add_player_character(peer_id):
	connected_peer_ids.append(peer_id)

	var player_character

	if peer_id == multiplayer.get_unique_id():
		player_character = character_dictionary.get(Global.player_selection).instantiate()
	else:
		player_character = character_dictionary.get(Global.opponent_selection).instantiate()

	player_character.set_multiplayer_authority(peer_id)
	$Spawner.add_child(player_character, true)
	if peer_id == 1:
		player_character.transform = $Point1.transform
	else:
		player_character.transform = $Point2.transform


func add_skill(skill_name: String, pos: Vector2) -> void:
	var skill = skill_dictionary.get(skill_name).instantiate()
	skill.set_multiplayer_authority(client_id)
	$ClientSkill.add_child(skill)
	skill.global_position = pos


@rpc("call_remote", "reliable")
func remove_skill() -> void:
	for child in $ClientSkill.get_children():
		child.queue_free()


@rpc
func add_newly_connected_player_character(new_peer_id):
	add_player_character(new_peer_id)


@rpc
func add_previously_connected_player_characters(peer_id) -> void:
	connected_peer_ids.append(peer_id)



func _on_line_edit_text_changed(new_text: String) -> void:
	client_ip = new_text



func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if Global.mode == "single":
				pause()
			else:
				surrender()


func pause() -> void:
	if get_tree().paused:
		Global.player.skill_joy_stick.skill_signal.disconnect(Global.player.skill_signal)
		get_tree().paused = false
		$Pause.get_child(0).hide()
		$Pause.get_child(1).hide()
		$Pause.get_child(2).show()
		Global.player.skill_joy_stick.skill_signal.connect(Global.player.skill_signal)
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


func surrender() -> void:
	if $Exit.visible:
		Global.player.skill_joy_stick.disconnect("skill_signal", Global.player.skill_signal)
		$Exit.hide()
		Global.player.skill_joy_stick.skill_signal.connect(Global.player.skill_signal)
	else:
		Global.player.skill_joy_stick.disconnect("skill_signal", Global.player.skill_signal)
		$Exit.show()
		Global.player.skill_joy_stick.skill_signal.connect(Global.player.skill_signal)


func player_died() -> void:
	await get_tree().create_timer(2).timeout
	$Lost.show()
	if Global.mode == "single":
		$Lost/MarginContainer/VBoxContainer/VBoxContainer/MarginContainer/Label.text = "You defeated " + str(Global.bots_defeated) + " enemies"
	await get_tree().create_timer(10).timeout
	main_menu()


func opponent_died() -> void:
	if Global.mode == "single":
		Global.bots_defeated += 1
		await get_tree().create_timer(6).timeout
		var bot_instance = bot.instantiate()
		$Spawner.add_child(bot_instance)
		if Global.player.center.global_position.x > Global.room.x / 2:
			bot_instance.transform = $Point1.transform
		else:
			bot_instance.transform = $Point2.transform
		Global.player.health.damage_bot(0)
	else:
		await get_tree().create_timer(2).timeout
		$Won.show()
