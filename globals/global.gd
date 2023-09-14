extends Node

@onready var room: Vector2
@onready var camera: Camera2D
@onready var world: Node2D
@onready var spawner: Node2D
@onready var server_skill: Node2D
@onready var client_skill: Node2D
@onready var player: Node2D
@onready var opponent: Node2D
@onready var player_selection: String
@onready var opponent_selection: String
@onready var mode: String
@onready var bots_defeated: int = 0
@onready var switch: bool = false
@onready var is_host: bool = false
@onready var player_id: int
@onready var opponent_id: int

const ring: Vector2 = Vector2(20420, -10180)
const little_ring: Vector2 = Vector2(10210, -5090)
const ui_left: Vector2 = Vector2.ZERO
const ui_right: Vector2 = Vector2(960, 0)
const left_stick_position: Vector2 = Vector2(1664, 824)
const left_area_position: Vector2 = Vector2(1536, 696)
const right_stick_position: Vector2 = Vector2(256, 824)
const right_area_position: Vector2 = Vector2(128, 696)

signal black_out
signal two_players_joined
signal hit
signal trapped
signal freezed
signal pushed
signal damaged
signal stunned
signal bot_died
signal player_died
signal opponent_died


func _ready() -> void:
	trapped.connect(_trapped)
	room = ring


func _trapped(_trap: bool) -> void:
	if _trap:
		room = little_ring
	else:
		room = ring


func is_inside(pos: Vector2) -> bool:
	if pos.x > room.x:
		return false
	elif pos.x < 0:
		return false
	if pos.y < room.y:
		return false
	elif pos.y > 0:
		return false
	return true


func get_inside_coordinates(pos: Vector2) -> Vector2:
	if pos.x > room.x:
		pos.x = room.x - 120
	elif pos.x < 0:
		pos.x = 120
	if pos.y < room.y:
		pos.y = room.y + 120
	elif pos.y > 0:
		pos.y = -120
	return pos


func avoid_enemies(vector: Vector2) -> Vector2:
	var list: Dictionary = {}
	for object in camera.targets:
		if object is Marker2D and not object == player.center:
			list[object.global_position] = object.get_child(0).position.x
	for object in list:
		if ((player.center.global_position + vector) - object).length() < (list[object] * 1.5):
			vector = vector.normalized() * (vector.length() + (list[object] * 1.5))
			if ((player.center.global_position + vector) - object).length() < (list[object] * 1.5):
				vector = vector.normalized() * (vector.length() + (list[object]))
	vector = get_inside_coordinates(player.center.global_position + vector) - player.center.global_position
	for object in list:
		if ((player.center.global_position + vector) - object).length() < (list[object] * 1.5):
			vector = vector.normalized() * (vector.length() - (list[object] * 1.5))
			if ((player.center.global_position + vector) - object).length() < (list[object] * 1.5):
				vector = vector.normalized() * (vector.length() - (list[object]))
	vector = get_inside_coordinates(player.center.global_position + vector)
	return vector
