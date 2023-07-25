extends Node2D


@onready var character_name: String = "meri"

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var local_body: RigidBody2D = $LocalCharacter/Body
@onready var remote_body: CharacterBody2D = $RemoteCharacter/Body
@onready var meri: Node2D
@onready var meri_local_body: Node2D


func _ready() -> void:
	get_node("LocalCharacter").load_skin(character_name)
	character.get_node("RemoteUI").visible = false
	character.get_node("LocalUI").visible = false
	if get_parent().name == "ClientSkill":
		meri = Global.spawner.get_node(str(Global.world.client_id))
		if multiplayer.is_server():
			get_node("LocalCharacter").queue_free()
			Global.camera.add_target(remote_body)
			character.ignore_remote()
			ignore_remote_meri()
		
		else:
			get_node("RemoteCharacter").queue_free()
			Global.camera.add_target(local_body)
			character.ignore_local()
			ignore_local_meri()
			meri_local_body = meri.get_node("LocalCharacter/Body")
			for part in get_node("LocalCharacter").get_children():
				part.set_power(character_name)
				part.locate(meri.get_node("LocalCharacter/" + part.name).global_position)
				part.rotate(meri.get_node("LocalCharacter/" + part.name).global_rotation)
				part.teleport()
			meri.move_signal.connect(character.move_signal)
	
	else:
		meri = Global.spawner.get_node(str(Global.world.server_id))
		if multiplayer.is_server():
			get_node("RemoteCharacter").queue_free()
			Global.camera.add_target(local_body)
			character.ignore_local()
			ignore_local_meri()
			meri_local_body = meri.get_node("LocalCharacter/Body")
			for part in get_node("LocalCharacter").get_children():
				part.set_power(character_name)
				part.locate(meri.get_node("LocalCharacter/" + part.name).global_position)
				part.rotate(meri.get_node("LocalCharacter/" + part.name).global_rotation)
				part.teleport()
			meri.move_signal.connect(character.move_signal)
		
		else:
			get_node("LocalCharacter").queue_free()
			Global.camera.add_target(remote_body)
			character.ignore_remote()
			ignore_remote_meri()


func ignore_local_meri() -> void:
	for original in meri.get_node("LocalCharacter").get_children():
		for clone in get_node("LocalCharacter").get_children():
			original.add_collision_exception_with(clone)


func ignore_remote_meri() -> void:
	for original in meri.get_node("RemoteCharacter").get_children():
		for clone in get_node("RemoteCharacter").get_children():
			original.add_collision_exception_with(clone)


func _exit_tree() -> void:
	if Global.xnor(get_parent().name == "ClientSkill", multiplayer.is_server()):
		Global.camera.remove_target(remote_body)
	else:
		Global.camera.remove_target(local_body)
