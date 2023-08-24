extends Node2D


@onready var path: String
@onready var sync: Node2D = get_node("../Extra")

@onready var head: RigidBody2D = $Head

@onready var body: RigidBody2D = $Body

@onready var rua: RigidBody2D = $RUA
@onready var rla: RigidBody2D = $RLA
@onready var rf: RigidBody2D = $RF

@onready var lua: RigidBody2D = $LUA
@onready var lla: RigidBody2D = $LLA
@onready var lf: RigidBody2D = $LF

@onready var stomach: RigidBody2D = $Stomach

@onready var hip: RigidBody2D = $Hip

@onready var rul: RigidBody2D = $RUL
@onready var rll: RigidBody2D = $RLL
@onready var rk: RigidBody2D = $RK

@onready var lul: RigidBody2D = $LUL
@onready var lll: RigidBody2D = $LLL
@onready var lk: RigidBody2D = $LK


func load_skin(character_name: String) -> void:
	path = "res://assets/sprites/character/equipped/" + character_name + "/"
	for child in get_children():
		if FileAccess.file_exists(path + child.name + ".png") and child.has_node("Sprite"):
			child.get_node("Sprite").texture = load(path + child.name + ".png")
	if get_node("RF").has_node("Sprite"):
		get_node("RF/Sprite").weapon_collision(character_name)
	if get_node("LF").has_node("Sprite"):
		get_node("LF/Sprite").weapon_collision(character_name)
	get_node("../RemoteCharacter").copy()


func _physics_process(_delta: float) -> void:
	if CharacterSelection.mode == "world":
		sync.head_pos = head.global_position
		sync.head_rot = head.global_rotation

		sync.body_pos = body.global_position
		sync.body_rot = body.global_rotation

		sync.rua_pos = rua.global_position
		sync.rua_rot = rua.global_rotation
		sync.rla_pos = rla.global_position
		sync.rla_rot = rla.global_rotation
		sync.rf_pos = rf.global_position
		sync.rf_rot = rf.global_rotation

		sync.lua_pos = lua.global_position
		sync.lua_rot = lua.global_rotation
		sync.lla_pos = lla.global_position
		sync.lla_rot = lla.global_rotation
		sync.lf_pos = lf.global_position
		sync.lf_rot = lf.global_rotation

		sync.stomach_pos = stomach.global_position
		sync.stomach_rot = stomach.global_rotation

		sync.hip_pos = hip.global_position
		sync.hip_rot = hip.global_rotation

		sync.rul_pos = rul.global_position
		sync.rul_rot = rul.global_rotation
		sync.rll_pos = rll.global_position
		sync.rll_rot = rll.global_rotation
		sync.rk_pos = rk.global_position
		sync.rk_rot = rk.global_rotation

		sync.lul_pos = lul.global_position
		sync.lul_rot = lul.global_rotation
		sync.lll_pos = lll.global_position
		sync.lll_rot = lll.global_rotation
		sync.lk_pos = lk.global_position
		sync.lk_rot = lk.global_rotation
