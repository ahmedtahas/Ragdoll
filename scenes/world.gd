extends Node2D


@onready var room: Vector2 = Vector2(20420, -10180)

@onready var connected_peer_ids = []
@onready var client_id


var multiplayer_peer = ENetMultiplayerPeer.new()

const PORT = 7777
const ADDRESS = "127.0.0.1"
const clientaddr = "192.168.0.21"


@rpc("any_peer", "reliable", "call_local")
func slowdown(time_scale: float, duration: float):
	Engine.time_scale = time_scale
	await get_tree().create_timer(time_scale * duration).timeout
	Engine.time_scale = 1

	
@rpc("any_peer", "call_remote", "reliable", 1)
func set_opponent(selection):
	print(multiplayer.get_unique_id(), " 's  opponent is  ", CharacterSelection.opponent)
	CharacterSelection.opponent = selection
	
	print(multiplayer.get_unique_id(), " 's  opponent is  ", CharacterSelection.opponent)
#	rpc_id(multiplayer.get_remote_sender_id(), "_set_bolen", true)
	
	
@rpc("call_local", "any_peer", "reliable")
func get_opponent_id():
	if multiplayer_peer.get_unique_id() > 1000:
		return 1
	else:
		for id in connected_peer_ids:
			if id != 1:
				return id
		
		
func get_inside_position(pos: Vector2, player_name: StringName) -> Vector2:
	var player = get_node("Spawner/" + player_name)
	if pos.x > room.x:
		pos.x = room.x - player.radius.x
	elif pos.x < player.radius.x:
		pos.x = player.radius.x
	if pos.y < room.y:
		pos.y = room.y + player.radius.x
	elif pos.y > -player.radius.x:
		pos.y -= player.radius.x
	return pos


func _on_host_pressed() -> void:
	$NetworkInfo/NetworkSideDisplay.text = "Server"
	$Menu.visible = false
	multiplayer_peer.create_server(PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	$NetworkInfo/UniquePeerID.text = str(multiplayer.get_unique_id())
	add_player_character(1)
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
	$NetworkInfo/NetworkSideDisplay.text = "Client"
	$Menu.visible = false
	multiplayer_peer.create_client(clientaddr, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(
		func(_peer_):
			await get_tree().create_timer(2).timeout
			rpc_id(1,"set_opponent", CharacterSelection.own)
	)
	$NetworkInfo/UniquePeerID.text = str(multiplayer.get_unique_id())
	
		
func add_player_character(peer_id):
	connected_peer_ids.append(peer_id)
	
	var player_character
	
	if peer_id == multiplayer.get_unique_id():
		player_character = load("res://scenes/game/character/" + CharacterSelection.own + ".tscn").instantiate()
	else:
		player_character = load("res://scenes/game/character/" + CharacterSelection.opponent + ".tscn").instantiate()

	player_character.set_multiplayer_authority(peer_id)
	print(player_character.name, "   ::  ", multiplayer.get_unique_id(), "   ::  ", connected_peer_ids)
	$Spawner.add_child(player_character, true)
	if peer_id == 1:
		player_character.transform = $Point1.transform
	else:
		player_character.transform = $Point2.transform
	
	
@rpc("call_remote", "reliable")
func add_skill(skill_name: String) -> void:
	var skill = load("res://scenes/game/tools/" + skill_name + ".tscn").instantiate()
	print("SKILLLLLLLLL     ", multiplayer.get_unique_id())
	$ClientSkill.add_child(skill, true)
	skill.set_multiplayer_authority(client_id)
	
	
@rpc("call_remote", "reliable")
func remove_skill() -> void:
	for child in $ClientSkill.get_children():
		child.queue_free()
	
	
@rpc	
func add_newly_connected_player_character(new_peer_id):
	print(new_peer_id, "  :---------:  ", multiplayer.get_unique_id())
	add_player_character(new_peer_id)
	
	
@rpc
func add_previously_connected_player_characters(peer_id) -> void:
	connected_peer_ids.append(peer_id)


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	print(node, "   spawned   by ", multiplayer.get_unique_id())
	pass # Replace with function body.
