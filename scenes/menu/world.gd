extends Node2D


@onready var connected_peer_ids = []
@onready var client_id
@onready var server_id
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
	"raldorone": preload("res://scenes/game/character/raldorone.tscn"),
	"buccarold": preload("res://scenes/game/character/single_buccarold.tscn")
}
@onready var skill_dictionary: Dictionary = {
	"dagger": preload("res://scenes/game/tools/dagger.tscn"),
	"bullet": preload("res://scenes/game/tools/bullet.tscn"),
	"clone": preload("res://scenes/game/character/clone.tscn"),
	"meteor": preload("res://scenes/game/tools/meteor.tscn")
}


@onready var multiplayer_peer = ENetMultiplayerPeer.new()
@onready var addr
@onready var client_addr
@onready var new_peer

const PORT = 8910

func _ready() -> void:
	Global.world = self
	Global.spawner = $Spawner
	Global.camera = $MTC
	Global.server_skill = $ServerSkill
	Global.client_skill = $ClientSkill
	var addrs = IP.get_local_addresses()
	addr = addrs[3]
	client_addr = addrs[7]
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
	CharacterSelection.opponent = selection


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
	get_node("Spawner/1/LocalCharacter/Head").freeze = true
	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			client_id = new_peer_id
			await get_tree().create_timer(3).timeout
			get_node("Spawner/1/LocalCharacter/Head").freeze = false
			rpc_id(new_peer_id,"set_opponent", CharacterSelection.own)
			rpc("add_newly_connected_player_character", new_peer_id)
#			add_newly_connected_player_character(new_peer_id)
			rpc_id(new_peer_id, "add_previously_connected_player_characters", 1)
			add_player_character(new_peer_id)
	)


func _on_join_pressed() -> void:
	$Menu.hide()
	multiplayer_peer.create_client(addr, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(
		func(_peer_):
			client_id = multiplayer.get_unique_id()
			server_id = _peer_
			await get_tree().create_timer(2).timeout
			rpc_id(_peer_,"set_opponent", CharacterSelection.own)
	)


func add_player_character(peer_id):
	connected_peer_ids.append(peer_id)

	var player_character

	if peer_id == multiplayer.get_unique_id():
		player_character = character_dictionary.get(CharacterSelection.own).instantiate()
	else:
		player_character = character_dictionary.get(CharacterSelection.opponent).instantiate()

	player_character.set_multiplayer_authority(peer_id)
	$Spawner.add_child(player_character, true)
	if peer_id == 1:
		player_character.transform = $Point1.transform
	else:
		player_character.transform = $Point2.transform


@rpc("call_remote", "reliable")
func add_skill(skill_name: String, pos: Vector2) -> void:
	var skill = skill_dictionary.get(skill_name).instantiate()
	$ClientSkill.add_child(skill)
	skill.global_position = pos
	skill.set_multiplayer_authority(client_id)


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

