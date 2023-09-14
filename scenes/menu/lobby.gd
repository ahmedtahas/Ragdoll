extends CanvasLayer

enum Message{
	id,
	join,
	user_connected,
	user_disconnected,
	lobby,
	candidate,
	offer,
	answer,
	checkIn,
	server_lobby_info,
	remove_lobby,
	list,
	characters
}

var peer = WebSocketMultiplayerPeer.new()
var id = 0
var rtc_peer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var host_id : int
var lobby_value = ""
var lobby_info = {}
@onready var lobby_container = $ScrollContainer/LobbyContainer


func _ready() -> void:
	multiplayer.connected_to_server.connect(rtc_server_connected)
	multiplayer.peer_connected.connect(rtc_peer_connected)
	multiplayer.peer_disconnected.connect(rtc_peer_disconnected)


func _enter_tree() -> void:
	$StartGame.disabled = true
	$ConnectToServer.disabled = false


func rtc_server_connected() -> void:
	print("RTC server connected")


func rtc_peer_connected(peer_id) -> void:
	$StartGame.disabled = false
	Global.opponent_id = peer_id
	if Global.is_host:
		$CreateLobby.text = "Player Joined"
	print("rtc peer connected " + str(peer_id), "  to  ", multiplayer.get_unique_id())


func rtc_peer_disconnected(peer_id) -> void:
	print("rtc peer disconnected " + str(peer_id))


func lobby_selected(lobby_name: String) -> void:
	$LobbyCode.text = lobby_name
	$CreateLobby.text = "Join Lobby"


func _process(delta) -> void:
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)

			if data.message == Message.characters:
				if Global.is_host:
					Global.opponent_selection = data.client_selection
				else:
					Global.opponent_selection = data.host_selection

				get_tree().change_scene_to_file("res://scenes/menu/world.tscn")


			if data.message == Message.id:
				id = data.id
				Global.player_id = data.id

				connected(id)
			if data.message == Message.list:
				var lobby_list = data.list
				var button
				for lobby in lobby_list:
					button = Button.new()
					button.text = lobby
					button.pressed.connect(lobby_selected.bind(button.text))
					lobby_container.add_child(button)

			if data.message == Message.user_connected:
				#GameManager.Players[data.id] = data.player
				createPeer(data.id)

			if data.message == Message.lobby:
				host_id = data.host
				lobby_value = data.lobby_value
				if host_id == multiplayer.get_unique_id():
					$CreateLobby.text = "Waiting For Player"
					Global.is_host = true
				else:
					$CreateLobby.text = "Joined Lobby"
				$CreateLobby.disabled = true

			if data.message == Message.candidate:
				if rtc_peer.has_peer(data.orgPeer):
					rtc_peer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)

			if data.message == Message.offer:
				if rtc_peer.has_peer(data.orgPeer):
					rtc_peer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)

			if data.message == Message.answer:
				if rtc_peer.has_peer(data.orgPeer):
					rtc_peer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)
	pass


func connected(id) -> void:
	rtc_peer.create_mesh(id)
	$ConnectToServer.text = "Connected To Server"
	multiplayer.multiplayer_peer = rtc_peer


#web rtc connection
func createPeer(id) -> void:
	if id != self.id:
		var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
		})

		peer.session_description_created.connect(self.offer_created.bind(id))
		peer.ice_candidate_created.connect(self.ice_candidate_created.bind(id))
		rtc_peer.add_peer(peer, id)

		if !host_id == self.id:
			peer.create_offer()
		pass


func offer_created(type, data, id) -> void:
	if !rtc_peer.has_peer(id):
		return

	rtc_peer.get_peer(id).connection.set_local_description(type, data)

	if type == "offer":
		send_offer(id, data)
	else:
		send_answer(id, data)
	pass


func send_offer(id, data) -> void:
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.offer,
		"data": data,
		"Lobby": lobby_value
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass


func send_answer(id, data) -> void:
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.answer,
		"data": data,
		"Lobby": lobby_value
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass


func ice_candidate_created(midName, indexName, sdpName, id) -> void:
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.candidate,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		"Lobby": lobby_value
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass


func connect_to_server(ip: String = "ws://127.0.0.1:8915") -> void:
	peer.create_client(ip)


func connect_to_server_button() -> void:
	connect_to_server()
	$ConnectToServer.disabled = true
	pass # Replace with function body.


func start_game() -> void:
	StartGame.rpc()


@rpc("any_peer", "call_local")
func StartGame() -> void:
	var message = {
		"message": Message.remove_lobby,
		"lobbyID" : lobby_value
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	$StartGame.text = "Starting The Game"
	$StartGame.disabled = true
#	var scene = load("res://Multiplayer Tutorial Source Files/testScene.tscn").instantiate()
#	get_tree().root.add_child(scene)
#

func create_join_lobby() -> void:
	var message ={
		"id" : id,
		"message" : Message.lobby,
		"name" : "",
		"character": Global.player_selection,
		"lobby_value" : $LobbyCode.text
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.


func _on_lobby_code_text_changed(new_text: String) -> void:
	if new_text == "":
		$CreateLobby.text = "Create Lobby"
		return
	$CreateLobby.text = "Join Lobby"
