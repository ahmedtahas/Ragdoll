extends Node2D


@onready var character_name: String = "meri"

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var local_body: RigidBody2D = $LocalCharacter/Body
@onready var meri: Node2D = get_node("../meri")
@onready var meri_local_body: Node2D = get_node("../meri/LocalCharacter")


func _ready() -> void:
	get_node("LocalCharacter").load_skin(character_name)
	character.get_node("RemoteUI").visible = false
	character.get_node("LocalUI").visible = false
	Global.camera.add_target(local_body)
	character.ignore_self()
	ignore_local_meri()
	for part in get_node("LocalCharacter").get_children():
		part.set_power(character_name)
		part.locate(meri.get_node("LocalCharacter/" + part.name).global_position)
		part.rotate(meri.get_node("LocalCharacter/" + part.name).global_rotation)
		part.teleport()
	meri.move_signal.connect(character.move_signal)


func ignore_local_meri() -> void:
	for original in meri.get_node("LocalCharacter").get_children():
		for clone in get_node("LocalCharacter").get_children():
			original.add_collision_exception_with(clone)


func _exit_tree() -> void:
	Global.camera.remove_target(local_body)
